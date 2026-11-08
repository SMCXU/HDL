extends SceneTree
var failed = 0
var count = 0
var game: Node
func check(value: bool,message: String):
	count += 1
	if value: print("PASS ",message)
	else:
		failed += 1
		push_error("FAIL "+message)
func _initialize(): call_deferred("run")
func run():
	var save_path = "user://settings.cfg"
	var had_save = FileAccess.file_exists(save_path)
	var previous_save = FileAccess.get_file_as_string(save_path) if had_save else ""
	var extra_saves={}
	for path in ["user://settings.backup.cfg","user://settings.pending.cfg"]:extra_saves[path]=FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.debug_run=true
	game.set_process(false)
	game.set_physics_process(false)
	game.reset_game()
	check(game.hp==3 and game.enemies.size()==3,"new run creates healthy player and first bounded encounter")
	game.touches[0] = "right"
	for i in range(60): game.step(1.0/60)
	check(absf(game.player.x-345)<1,"movement is fixed-step and correctly scaled")
	game.touches.clear()
	game.touches[0] = "jump"
	game.step(1.0/60)
	check(game.velocity.y<0,"jump starts from ground")
	for i in range(90): game.step(1.0/60)
	check(absf(game.player.y-game.GROUND)<1,"holding jump does not repeatedly auto-jump")
	game.touches.clear()
	game.player = Vector2(700,340)
	game.velocity = Vector2(0,450)
	game.step(1.0/30)
	check(absf(game.player.y-350)<1,"fast fall lands on one-way platform without tunneling")
	game.player = Vector2(700,400)
	game.velocity = Vector2(0,-350)
	game.step(1.0/60)
	check(game.player.y>350 and game.velocity.y<0,"platform can be crossed from below")
	game.hp=3
	game.invincible=0
	game.hurt()
	game.hurt()
	check(game.hp==2,"invincibility prevents duplicate damage")
	game.reset_game()
	game.touches[0]="fire"
	game.step(1.0/60)
	check(game.bullets.size()==1,"rifle emits one projectile")
	game.bullets.clear()
	game.cooldown=0
	game.weapon=true
	game.step(1.0/60)
	check(game.bullets.size()==5,"spread emits five distinct projectiles")
	game.reset_game()
	game.player=Vector2(1100,310)
	game.step(1.0/60)
	check(game.weapon_id=="machine" and game.pickups.size()==4,"typed machine pickup equips and is consumed once")
	game.reset_game(true)
	check(game.checkpoint and game.player.x==game.LevelDirector.CHECKPOINT_X and game.hp==3 and not game.weapon and game.enemies.is_empty(),"checkpoint reset clears encounter and restores baseline")
	game.player.x=game.LevelDirector.BOSS_TRIGGER+100
	game.step(1.0/60)
	check(game.boss_active and game.boss_hp==55,"arena activates fresh boss")
	game.boss_intro=0
	game.boss_hp=1
	game.spawn_bullet(game.BossDirector.POSITION+Vector2(50,120),Vector2.ZERO,true)
	game.step(1.0/60)
	check(game.mode=="won" and game.score>=2000 and not game.boss_active,"boss defeat ends run exactly once")
	game.reset_game(true)
	check(game.mode=="playing" and game.boss_hp==55 and game.bullets.is_empty(),"retry cleans previous boss and projectiles")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode=="paused" and game.touches.is_empty(),"focus loss pauses and clears held input")
	game.reset_game()
	game.mode = "paused"
	game.activate_menu(Vector2(480,360))
	check(game.mode=="settings","pause menu opens settings")
	game.change_setting(8,1)
	check(game.mode=="paused","settings returns to paused state without resuming combat")
	var broken = ConfigFile.new()
	broken.set_value("controls","scale","invalid")
	broken.set_value("audio","music",-20)
	broken.set_value("progress","best_score","invalid")
	broken.save(save_path)
	game.button_scale=1.0
	game.load_settings()
	check(game.button_scale==1.0 and game.music_volume==0,"malformed save types fall back and numeric ranges are clamped")
	game.reset_game(true)
	game.player.x=game.LevelDirector.BOSS_TRIGGER+100
	game.step(1.0/60)
	game.boss_intro=0
	game.boss_timer=0
	game.bullets.clear()
	game.step(1.0/60)
	var fan_count = game.bullets.size()
	game.boss_intro=0
	game.boss_timer=0
	game.bullets.clear()
	game.step(1.0/60)
	check(fan_count==5 and game.bullets.size()==3,"boss alternates fan and aimed attacks")
	game.reset_game()
	game.enemies.clear()
	for face in [-1,1]:
		game.facing=face
		for up in [false,true]:
			for moving in [false,true]:
				game.touches.clear()
				if up: game.touches[1]="up"
				if moving: game.touches[2]="right" if face==1 else "left"
				game.touches[3]="fire"
				game.cooldown=0
				game.bullets.clear()
				game.step(1.0/60)
				var shot=game.bullets[0]
				var muzzle=game.last_shot
				check((shot.pos-shot.vel/60).distance_to(muzzle.position)<0.01 and shot.vel.normalized().distance_to(muzzle.direction)<0.01,"bullet starts at shared muzzle for face=%d up=%s moving=%s" % [face,up,moving])
	game.touches.clear()
	game.crouching=true
	game.velocity=Vector2.ZERO
	check(game.player_muzzle().position.y>game.player.y-30,"crouch muzzle follows lowered pose")
	game.button_scale=1.3
	for button in game.control_buttons():
		check(game.control_at(button[0])==button[1],"scaled touch center maps to "+button[1])
	var touch=InputEventScreenTouch.new()
	touch.index=7
	touch.pressed=true
	touch.position=game.control_buttons()[5][0]
	game._input(touch)
	var drag=InputEventScreenDrag.new()
	drag.index=7
	drag.position=Vector2(480,200)
	game._input(drag)
	check(not game.pressed("fire"),"dragging finger off fire releases held action")
	game.visual_effect(game.player,"explosion",0.6)
	var previous_age=game.visual_effects[-1].age
	game.pause_game()
	game._process(0.2)
	check(game.visual_effects[-1].age==previous_age and game.touches.is_empty(),"pause freezes effects and clears touches")
	game.reset_game()
	game.hp=1
	game.invincible=0
	game.hurt()
	game._process(1.0)
	check(game.mode=="dead" and game.presentation.frame()==19,"death reaches final pose without blocking game result")
	var count_before=game.bullets.size()
	game.touches[0]="fire"
	game.step(1.0/60)
	check(game.bullets.size()==count_before,"dead player cannot emit bullets")
	game.reset_game()
	check(game.visual_effects.is_empty() and game.presentation.state=="idle" and game.shot_flash==0,"retry clears presentation and effect pool")
	for i in range(200): game.visual_effect(game.player,"impact",0.2)
	check(game.visual_effects.size()==64,"effect capacity remains bounded during burst")
	game.advance_effects(0.3)
	check(game.visual_effects.is_empty(),"expired effects are returned to reusable pool")
	game.reset_game(true)
	game.player.x=game.LevelDirector.BOSS_TRIGGER+100
	game.step(1.0/60)
	game.spawn_bullet(game.BossDirector.POSITION+Vector2(50,120),Vector2.ZERO,true)
	game.step(1.0/60)
	check(game.boss_hp==55,"boss intro shield blocks damage while visibly active")
	game.boss_intro=0
	game.boss_hp=1
	game.spawn_bullet(game.BossDirector.POSITION+Vector2(50,120),Vector2.ZERO,true)
	game.step(1.0/60)
	var final_score=game.score
	game.step(1.0/60)
	check(game.mode=="won" and game.score==final_score and game.bullets.is_empty(),"victory clears danger and cannot be awarded twice")
	game.reset_game()
	var reachable=true
	var jump_height=540.0*540.0/(2*1450.0)
	for platform in game.platforms:
		if game.GROUND-platform.position.y>jump_height: reachable=false
	check(reachable,"all authored platform tops are within jump reach from ground")
	game.player=Vector2(700,350)
	game.velocity=Vector2.ZERO
	game.touches[0]="down"
	game.step(1.0/60)
	check(game.crouching and absf(game.player.y-350)<0.01,"player can crouch on a raised platform")
	for scale in [0.8,1.0,1.3]:
		game.button_scale=scale
		var fits=true
		for button in game.control_buttons():
			var radius=game.TouchLayout.radius(button[1],scale)
			if button[0].x-radius<0 or button[0].x+radius>960 or button[0].y-radius<0 or button[0].y+radius>540: fits=false
		check(fits,"touch controls fit canvas at scale %.1f" % scale)
	game.reset_game()
	game.audio.clear_effects()
	var warning_slot=-1
	for i in range(game.audio.voices.size()):
		game.audio.voices[i].stream=game.audio.streams.shot
		game.audio.voices[i].play()
		game.audio.priorities[i]=1
	game.audio.effect("warning")
	for i in range(game.audio.voices.size()):
		if game.audio.priorities[i]==6: warning_slot=i
	check(warning_slot>=0,"critical warning can replace a lower-priority occupied voice")
	game.audio.clear_effects()
	for i in range(10): game.reset_game()
	var stable_memory=Performance.get_monitor(Performance.MEMORY_STATIC)
	for i in range(20):
		game.reset_game(i%2==0)
		for j in range(60): game.step(1.0/60)
	var memory_delta=Performance.get_monitor(Performance.MEMORY_STATIC)-stable_memory
	check(memory_delta<maxf(stable_memory*0.1,20*1024*1024),"20 logical retries stay within static-memory delta budget (not Android soak)")
	game.reset_game()
	game.button_scale=1.0
	var stick_center=game.TouchLayout.stick_center(1.0)
	var stick_radius=game.TouchLayout.stick_radius(1.0)
	game.touch_press(11,stick_center)
	check(not game.pressed("right") and not game.pressed("up"),"joystick dead zone ignores a centered resting thumb")
	game.touch_move(11,stick_center+Vector2(.65,-.65)*stick_radius)
	check(game.pressed("right") and game.pressed("up"),"one joystick finger supports intentional diagonal aiming")
	game.touch_move(11,stick_center+Vector2(.65,-.45)*stick_radius)
	check(game.pressed("up"),"direction hysteresis tolerates small thumb wobble")
	game.touch_move(11,stick_center+Vector2(.1,-.1)*stick_radius)
	check(not game.pressed("right") and not game.pressed("up"),"returning to joystick dead zone releases direction")
	game.touch_press(12,stick_center+Vector2.RIGHT*stick_radius*.7)
	check(not game.touches.has(12),"second finger cannot steal captured direction stick")
	game.touch_release(11)
	var jump_center=game.control_buttons()[4][0]
	var fire_center=game.control_buttons()[5][0]
	game.touch_press(21,jump_center)
	game.touch_move(21,fire_center)
	check(not game.pressed("fire") and not game.pressed("jump"),"sliding jump finger into fire does not switch actions")
	game.touch_move(21,jump_center)
	check(game.pressed("jump") and not game.pressed("fire"),"captured jump can reenter its original button only")
	game.touch_press(22,fire_center)
	game.touch_press(23,stick_center+Vector2.RIGHT*stick_radius*.7)
	check(game.pressed("right") and game.pressed("jump") and game.pressed("fire"),"independent captured fingers combine move jump and fire logically")
	game.pause_game()
	check(game.touch_owners.is_empty() and game.stick_owner==-999 and game.stick_offset==Vector2.ZERO,"pause clears all captured finger ownership")
	game.reset_game()
	check(game.encounters.arenas.size()==27,"level defines 27 bounded encounters across three sectors")
	game.player.x=game.encounters.gate_x+100
	game.step(1.0/60)
	check(game.player.x<=game.encounters.gate_x-20,"living encounter blocks bypassing its exit")
	game.enemies.clear()
	game.encounters.step(game,1.0/60)
	check(game.encounters.index==1,"defeated encounter opens immediately without a timer")
	game.reset_game()
	for arena_index in range(9):
		game.player.x=game.encounters.arenas[arena_index].left
		game.encounters.step(game,1.0/60)
		game.enemies.clear()
		game.score=900+arena_index
		game.encounters.step(game,1.0/60)
	check(game.checkpoint and game.checkpoint_x==game.LevelDirector.SECTORS[1].start_x+100,"first sector completion establishes next-sector checkpoint")
	game.reset_game(true)
	check(game.encounters.index==9 and game.enemies.size()==3 and game.score==908,"checkpoint retry restores score and only next sector first group")
	game.reset_game()
	check(game.score==0 and game.encounters.index==0,"full restart clears checkpoint progress and score")
	check(not quit_on_go_back,"Android back is routed by game instead of engine automatic quit")
	game.mode="menu"
	game.activate_menu(Vector2(20,300))
	check(game.mode=="menu","menu background tap does not start a run")
	game.activate_menu(Vector2(480,375))
	check(game.mode=="settings" and game.settings_return=="menu","settings opens only through its visible button")
	var old_scale=game.button_scale
	game.activate_menu(Vector2(900,180))
	check(game.button_scale==old_scale,"settings outside rows cannot change values")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.mode=="menu","Android back returns settings to originating menu")
	game.reset_game()
	game.touches[1]="right"
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.mode=="paused" and game.touches.is_empty(),"Android back pauses and releases gameplay input")
	game.activate_menu(Vector2(480,375))
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.mode=="paused","settings back preserves paused state rather than resuming combat")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.mode=="playing","back from pause resumes cleanly")
	game.mode="dead"
	game.result_age=0
	game.activate_menu(Vector2(480,300))
	check(game.mode=="dead","death presentation ignores premature retry tap")
	game.result_age=1
	game.activate_menu(Vector2(480,300))
	check(game.mode=="playing","visible retry button starts after death presentation")
	game.start_level("spillway",true)
	check(game.level.id=="spillway" and game.encounters.arenas.size()==11 and game.level.climb_route.size()==54 and game.level.sectors.size()==6,"spillway registers six vertical sectors and eleven encounters")
	check(game.hp==3 and not game.weapon and game.score==0 and game.camera_y==0,"entering a new level resets health weapon score and camera")
	game.player.x=810
	game.step(1.0/60)
	check(game.player.x==810 and not game.encounters.blocks_progress(),"optional relay never blocks the vertical route")
	var relay_point=game.encounters.targets[0].pos-Vector2(0,35)
	for i in range(6):game.encounters.hit_target(game,relay_point)
	var relay_score=game.score
	check(game.destroyed_targets.has("relay") and not game.encounters.blocks_progress(),"optional relay awards a reward without becoming an exit gate")
	game.encounters.hit_target(game,relay_point)
	check(game.score==relay_score,"destroyed target cannot award score twice")
	game.score=789
	game.consumed_pickups["fixture"]=true
	game.commit_checkpoint(game.level.checkpoint_points[0],0)
	game.destroyed_targets.node_a=true;game.score=9999;game.consumed_pickups["after_checkpoint"]=true
	game.reset_game(true)
	check(game.player==game.level.checkpoint_points[0] and game.score==789 and game.destroyed_targets.has("relay") and not game.destroyed_targets.has("node_a"),"checkpoint restores same-level position score and committed target state")
	check(game.consumed_pickups.has("fixture") and not game.consumed_pickups.has("after_checkpoint"),"checkpoint pickup state is copied rather than aliased")
	game.start_level("spillway",true)
	var vent=game.hazards.entries[0]
	game.player=Vector2(vent.area.position.x+25,vent.area.end.y);game.invincible=0
	vent.state="warning";vent.age=0
	game.step(.01)
	check(game.hp==3,"vent warning does not apply damage")
	vent.state="active";vent.age=0
	game.step(.01);game.step(.01)
	check(game.hp==2,"active vent damages once within player invulnerability window")
	var hazard_age=vent.age
	game.pause_game();game.step(2)
	check(vent.age==hazard_age,"paused game freezes environmental danger timers")
	game.reset_game();game.destroyed_targets.node_a=true;game.hazards.step(game,.01)
	check(game.hazards.entries[2].state=="disabled","destroyed supply node permanently disables its electric area")
	game.last_safe_landing=Vector2(300,435);game.player=Vector2(85,700);game.invincible=5
	game.recover_fall()
	check(game.player==game.last_safe_landing and game.hp==2 and game.invincible==1,"fall recovery repositions even during invulnerability and applies one health cost")
	game.hp=1;game.recover_fall()
	check(game.mode=="dead","last-health fall enters normal death lifecycle")
	game.start_level("spillway",true)
	var hidden_floor=false
	for r in game.terrain.near(Vector2(110,435)):
		if r.has_point(Vector2(110,436)):hidden_floor=true
	check(not hidden_floor,"outside the visible starting deck there is no invisible global floor")
	for target in game.encounters.targets:target.hp=0;game.destroyed_targets[target.id]=true
	game.encounters.refresh_gate(game)
	game.player=game.level.checkpoint_points[1];game.enemies.clear();game.CameraDirector.update(game,0,true)
	game.spawn_bullet(game.player+Vector2(70,-35),Vector2.RIGHT*300,true)
	game.step(.01)
	check(not game.bullets.is_empty() and game.camera_y< -1000,"upper-world projectiles survive and camera follows vertical coordinates")
	check(game.camera_x==0,"vertical camera never tracks player horizontal position")
	game.commit_checkpoint(game.level.checkpoint_points[0],0)
	game.player=game.level.checkpoint_points[1];game.velocity=Vector2.ZERO
	game.encounters.step(game,.01)
	check(game.checkpoint_order==1 and game.checkpoint_x<game.level.checkpoint_points[0].x,"higher checkpoint commits even when its x coordinate moves left")
	game.reset_game(true)
	check(game.checkpoint_id()=="spillway:power" and game.player==game.level.checkpoint_points[1],"stable checkpoint ID restores the higher-left checkpoint")
	var committed_height=game.highest_climb
	game.player=game.level.climb_route[20];game.velocity=Vector2.ZERO;game.CameraDirector.update(game,0,true)
	game.CameraDirector.update(game,.1)
	check(game.camera_x==0 and game.highest_climb==committed_height,"camera can return downward without decreasing recorded climb progress")
	game.player=Vector2(300,435);game.velocity=Vector2.ZERO;game.CameraDirector.update(game,0,true)
	game.player.y-=60;game.velocity.y=-200;game.CameraDirector.update(game,.1)
	check(game.camera_y==0,"ordinary jump inside camera dead zone does not drag the view upward")
	game.player=Vector2(80,-1000);game.velocity=Vector2.ZERO
	game.warden.step(game,.01)
	check(not game.boss_active,"boss does not activate just because player is horizontally near its coordinates")
	game.player=game.level.boss_checkpoint;game.bullets.clear();game.step(.01)
	check(game.boss_active and game.boss_hp==72 and game.warden.arms==[12,12],"second boss activates with independent arms and core")
	game.boss_intro=0
	var body=game.warden.boxes(game)
	game.BossDirector.hit(game,body[2].get_center())
	check(game.warden.core==48,"armored core ignores damage until both weapons are destroyed")
	for i in range(12):game.BossDirector.hit(game,body[0].get_center())
	check(game.warden.arms==[0,12] and game.warden.core==48,"arm destruction only changes the struck part")
	for i in range(12):game.BossDirector.hit(game,body[1].get_center())
	game.BossDirector.hit(game,body[2].get_center())
	check(game.warden.core==47 and game.boss_hp==47,"destroying both arms exposes a separately damageable core")
	game.warden.attack="laser";game.warden.age=.6;game.warden.locked=true;game.warden.lock_point=game.player+Vector2(0,-25)
	var locked_point=game.warden.lock_point
	game.player.x-=50;game.warden.step(game,.05)
	check(game.warden.lock_point==locked_point,"locked laser does not continue tracking the moving player")
	game.warden.core=1;game.BossDirector.hit(game,body[2].get_center())
	var won_score=game.score
	game.BossDirector.defeated(game)
	check(game.mode=="won" and game.score==won_score,"second boss completes once and cannot award repeated victory score")
	var unlocked_before=game.unlocked_levels.duplicate();var best_before=game.best_scores.duplicate()
	game.complete_level()
	check(game.unlocked_levels==unlocked_before and game.best_scores==best_before,"debug completion does not mutate real unlock or best score")
	for i in range(20):
		game.start_level("iron_factory",true)
		game.start_level("spillway",true)
	check(game.get_child_count()==4 and game.audio.voices.size()==12 and game.enemies.is_empty() and game.destroyed_targets.is_empty(),"twenty logical level switches keep nodes bounded and clear level state")
	game.start_level("iron_factory",true)
	check(game.hp==3 and game.boss_hp==55 and game.player==Vector2(100,435) and game.camera_y==0,"returning to factory restores original spawn boss and horizontal camera")
	game.unlocked_levels=["iron_factory"]
	game.mode="level_select"
	game.activate_menu(Vector2(480,250))
	check(game.mode=="playing" and game.level.id=="spillway" and not game.debug_run,"fresh-save second-level card starts a formal run through pointer input")
	game.leave_to_selection()
	game.activate_menu(Vector2(780,250))
	check(game.mode=="playing" and game.level.id=="redrock" and game.hp==3 and not game.debug_run,"fresh-save third-level card starts a fresh formal run through pointer input")
	check(game.unlocked_levels==["iron_factory"],"manual level selection does not fabricate campaign completion")
	for index in range(3):
		game.leave_to_selection();game.menu_selection=index
		var confirm=InputEventKey.new();confirm.keycode=KEY_ENTER;confirm.pressed=true
		game._input(confirm)
		check(game.mode=="playing" and game.level.id==["iron_factory","spillway","redrock"][index],"keyboard confirmation enters selected mission %d without unlock prerequisites" % (index+1))
	game.leave_to_selection()
	game.navigate_back()
	check(game.mode=="menu","Android back leaves level selection without exiting application")
	var legacy=ConfigFile.new()
	legacy.set_value("progress","best_score",1111)
	legacy.set_value("audio","music",.4)
	legacy.save(save_path)
	game.best_scores={"iron_factory":0,"spillway":0};game.load_settings()
	check(game.best_scores.iron_factory==1111 and not "spillway" in game.unlocked_levels and is_equal_approx(game.music_volume,.4),"legacy score and settings migrate without guessing a level unlock")
	game.start_level("iron_factory",false)
	game.score=2222;game.mode="won";game.complete_level()
	var saved=ConfigFile.new();saved.load(save_path)
	check("spillway" in game.unlocked_levels and "spillway" in saved.get_value("progress","unlocked_level_ids",[]) and saved.get_value("scores","iron_factory",0)==2222,"real first-level completion persists unlock and independent score atomically")
	game.mode="level_select";game.activate_menu(Vector2(480,250))
	check(game.level.id=="spillway" and game.mode=="playing" and game.hp==3 and not game.weapon,"unlocked card enters a fresh second-level run")
	load("res://tests/weapon_tests.gd").new().run(game,check)
	load("res://tests/level03_tests.gd").new().run(game,check)
	test_platform_drop()
	game.start_level("iron_factory",true)
	var node_count = game.get_child_count()
	for i in range(60*60*20):
		if game.mode != "playing": game.reset_game()
		game.step(1.0/60)
	check(game.get_child_count()==node_count and game.bullets.size()<100 and game.particles.size()<200,"20-minute simulated soak keeps audio voices and transient objects bounded")
	if had_save:
		var restore = FileAccess.open(save_path,FileAccess.WRITE)
		restore.store_string(previous_save)
		restore.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	for path in extra_saves:
		if extra_saves[path]==null:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var restore_extra=FileAccess.open(path,FileAccess.WRITE)
			restore_extra.store_string(extra_saves[path]);restore_extra.close()
	game.audio.shutdown()
	await create_timer(.25).timeout
	game.queue_free()
	await create_timer(.5).timeout
	print("RESULT ",count-failed,"/",count," passed")
	quit(1 if failed else 0)

func test_platform_drop():
	game.start_level("spillway",true)
	var top=game.level.climb_route[8]
	game.player=top;game.velocity=Vector2.ZERO
	game.highest_climb=520;game.commit_checkpoint(game.level.checkpoint_points[0],0)
	game.touches[0]="down+jump+fire"
	game.step(1.0/60)
	check(game.player.y>top.y and game.velocity.y>0 and game.drop_platform_y==top.y,"down plus a fresh jump crosses overlapping platform rectangles downward")
	check(game.cooldown>0 and game.jump_buffer==0 and game.coyote==0,"drop consumes jump buffer while allowing simultaneous shooting")
	for i in range(60):game.PlayerController.step(game,1.0/60)
	check(game.player.y==game.level.climb_route[7].y and game.velocity.y==0,"held drop combo lands on next layer without chain dropping or bouncing")
	check(game.highest_climb==520 and game.checkpoint_order==0,"descending preserves highest progress and committed checkpoint")
	game.touches[0]="down";game.PlayerController.step(game,1.0/60)
	game.touches[0]="down+jump";game.PlayerController.step(game,1.0/60)
	check(game.velocity.y>0,"release and press jump again permits a second deliberate drop")
	game.pause_game();var frozen=game.player;var ignored=game.drop_platform_y
	game.step(.5)
	check(game.player==frozen and game.drop_platform_y==ignored,"pause preserves in-flight platform exclusion without advancing the fall")
	game.reset_game()
	check(game.drop_platform_y==INF and game.jump_buffer==0,"retry clears platform exclusion and buffered jump")
	game.player=top;game.velocity=Vector2.ZERO;game.touches[0]="down+right+jump"
	game.PlayerController.step(game,1.0/60)
	check(game.velocity.y<0 and game.drop_platform_y==INF,"diagonal down jump remains a normal jump and cannot accidentally drop")
	game.start_level("spillway",true);game.player=top
	var center=game.TouchLayout.stick_center(game.button_scale,game.safe_insets())
	var radius=game.TouchLayout.stick_radius(game.button_scale)
	game.touch_press(71,center+Vector2(0,radius*.6));game.touch_press(72,game.control_buttons()[4][0])
	game.PlayerController.step(game,1.0/60)
	check(game.velocity.y<0,"shallow touch-stick down is insufficient for a drop")
	game.reset_game();game.player=top
	game.touch_press(71,center+Vector2(0,radius*.85));game.touch_press(72,game.control_buttons()[4][0])
	game.PlayerController.step(game,1.0/60)
	check(game.velocity.y>0 and game.drop_platform_y==top.y,"deep centered touch-stick down plus captured jump triggers a drop")
	game.start_level("spillway",true);game.player=game.level.boss_checkpoint;game.touches[0]="down+jump"
	game.PlayerController.step(game,1.0/60)
	check(game.velocity.y<0 and game.drop_platform_y==INF,"summit solid floor wins over overlapping droppable platforms")
	game.start_level("iron_factory",true);game.touches[0]="down+jump"
	game.PlayerController.step(game,1.0/60)
	check(game.player.y<game.GROUND and game.drop_platform_y==INF,"first-level solid ground cannot be dropped through")
	game.reset_game();game.player=Vector2(700,350);game.touches[0]="down+jump"
	game.PlayerController.step(game,1.0/60)
	check(game.player.y>350 and game.velocity.y>0,"first-level raised one-way platform also supports deliberate dropping")
	game.start_level("spillway",true)
	check(game.drop_platform_y==INF,"changing level clears pending platform exclusion")
