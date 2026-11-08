extends SceneTree
var destination = "work/polish/visual"
var scenario = "normal"
func _initialize():
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): destination = argument.trim_prefix("--out=")
		if argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
	call_deferred("capture")

func capture():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://"+destination))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_physics_process(false)
	game.player = Vector2(350,435)
	game.camera_x = 30
	game.invincible = 0
	game.time = 2.3
	if scenario.begins_with("l2"):
		game.start_level("spillway",true)
		game.player={"l2river":Vector2(300,435),"l2climb":game.level.climb_route[12],"l2roof":game.level.climb_route[40],"l2boss":game.level.boss_checkpoint}.get(scenario,Vector2(350,435))
		game.highest_climb=maxf(0,game.level.spawn.y-game.player.y)
		game.encounters.step(game,0)
		game.time=2.3;game.invincible=0
		for h in game.hazards.entries:h.state="warning"
		if scenario=="l2boss":
			game.warden.step(game,0);game.boss_intro=0;game.warden.attack="laser";game.warden.age=.7;game.warden.locked=true;game.warden.lock_point=game.player+Vector2(-100,-25)
		game.CameraDirector.update(game,0,true)
	if scenario.begins_with("l3"):
		game.start_level("redrock",true)
		game.player={"l3start":game.level.spawn,"l3ferry":game.level.climb_route[16],"l3rock":game.level.climb_route[10],"l3boss":game.level.boss_checkpoint}.get(scenario,game.level.spawn)
		game.highest_climb=game.level.spawn.y-game.player.y;game.invincible=0
		game.encounters.step(game,0);game.CameraDirector.update(game,0,true)
		if scenario=="l3rock":game.rockfalls.entries[0].state="warning"
		if scenario=="l3boss":game.citadel.step(game,0);game.boss_intro=0;game.citadel.age=2.3
	if scenario=="selection":game.leave_to_selection()
	if scenario in ["sector2","sector3"]:
		game.player.x=game.LevelDirector.SECTORS[1 if scenario=="sector2" else 2].start_x+600
		game.enemies.clear()
		game.encounters.reset(game,game.player.x)
		game.camera_x=game.player.x-320
	if scenario=="settings": game.mode="settings"
	if scenario=="dead":
		game.hp=1
		game.hurt()
		game._process(0.6)
		game.set_process(false)
	if scenario=="dense":
		game.weapon=true
		for i in range(16): game.spawn_bullet(Vector2(600+i*20,390+(i%3)*10),Vector2(650,0),i%3!=0)
		for i in range(4): game.visual_effect(Vector2(600+i*70,410),"explosion",0.65)
	for event in game.visual_effects: event.age=0.25
	if scenario=="boss":
		game.player.x = game.LevelDirector.BOSS_TRIGGER+400
		game.camera_x = game.LENGTH-960
		game.boss_active = true
		game.boss_timer = 0.2
	if scenario in ["poses","animation","transitions","panorama"]:
		# Contact sheet samples of actual animated rendering, explicitly a desktop check.
		var montage = Image.create(960*4,540*2,false,Image.FORMAT_RGBA8)
		root.size=Vector2i(960,540)
		for i in range(8):
			if scenario=="panorama":
				game.camera_x=[0,5999,6000,6001,11999,12000,12001,18000][i]
			elif scenario=="poses":
				game.touches.clear()
				game.facing = 1 if i<4 else -1
				if i%4 in [1,2]: game.touches[0]="up"
				game.velocity=Vector2(245 if i%4==2 else 0,0)
				game.crouching=i%4==3
			elif scenario=="transitions":
				var states=["idle","idle","land","land","crouch","crouch","rise","rise"]
				game.presentation.state=states[i]
				game.presentation.state_age=0.15 if i%2 else 0.0
				game.presentation.clock=0.2 if i%2 else 0.0
				game.crouching=states[i]=="crouch"
			else:
				game.touches[0]="right"
				for j in range(5): game.step(1.0/60)
			if scenario!="transitions": game.presentation.update(0,game.velocity,game.crouching,false)
			game.shot_flash=0.05
			game.cooldown=0.14
			for j in range(2): await process_frame
			await RenderingServer.frame_post_draw
			var shot = root.get_texture().get_image()
			shot.resize(960,540)
			montage.blit_rect(shot,Rect2i(0,0,960,540),Vector2i((i%4)*960,int(i/4)*540))
		montage.save_png("res://"+destination+"/"+scenario+".png")
	else:
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://"+destination+"/"+scenario+".png")
	var metadata={"type":"desktop window simulation, not a physical Android device","scenario":scenario,"window_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"viewport_texture_size":[root.get_texture().get_width(),root.get_texture().get_height()],"note":"canvas_items keep-aspect may return only the 16:9 gameplay viewport, excluding native letterbox margins."}
	var metadata_file=FileAccess.open("res://"+destination+"/"+scenario+".json",FileAccess.WRITE)
	metadata_file.store_string(JSON.stringify(metadata,"  "))
	metadata_file.close()
	game.queue_free()
	for i in range(4): await process_frame
	quit()
