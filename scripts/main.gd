extends Node2D

const PlayerController=preload("res://scripts/player/player_controller.gd")
const EnemyDirector=preload("res://scripts/enemies/enemy_director.gd")
const BossDirector=preload("res://scripts/boss/boss_router.gd")
const EncounterDirector=preload("res://scripts/level/encounter_director.gd")
const LevelDirector=preload("res://scripts/level/level_director.gd")
const EffectPool=preload("res://scripts/effects/effect_pool.gd")
const Pose = preload("res://scripts/player/pose.gd")
const Presentation = preload("res://scripts/player/presentation.gd")
const MenuLayout=preload("res://scripts/ui/menu_layout.gd")
const TouchLayout = preload("res://scripts/ui/touch_layout.gd")
const Controls = preload("res://scripts/controls.gd")
const AudioDirector = preload("res://scripts/audio_director.gd")
# Original single-level run-and-gun. World coordinates are independent of viewport.
const RIFLE = preload("res://resources/weapons/rifle.tres")
const SPREAD = preload("res://resources/weapons/spread.tres")
const LevelCatalog=preload("res://scripts/level/level_catalog.gd")
const TerrainQuery=preload("res://scripts/level/terrain_query.gd")
const SpillwayDirector=preload("res://scripts/level/spillway_director.gd")
const HazardDirector=preload("res://scripts/level/hazard_director.gd")
var hazards=HazardDirector.new()
var platform_motion=preload("res://scripts/level/platform_motion.gd").new()
var rockfalls=preload("res://scripts/level/rockfall_director.gd").new()
var citadel=preload("res://scripts/boss/cliff_citadel.gd").new()
var destroyed_targets={}
var completed_encounters={}
var consumed_pickups={}
var checkpoint_snapshot={}
var checkpoint_y=435.0
var replay_route_index=0
var replay_strafe=1
var debug_run=false
const CameraDirector=preload("res://scripts/level/camera_director.gd")
var terrain=TerrainQuery.new()
var camera_y=0.0
var camera_anchor_y=435.0
var highest_climb=0.0
var checkpoint_order=-1
var last_safe_landing=Vector2(100,435)
var level: Resource=LevelCatalog.FACTORY
var LENGTH=level.length
var GROUND=level.ground
var presentation = Presentation.new()
var last_shot = {"position":Vector2.ZERO,"direction":Vector2.RIGHT}
var shot_flash = 0.0
var reduced_flash = false
var reduced_shake = false
var low_effects = false
var shake_remaining = 0.0
var started_at_checkpoint=false
var replay: Node
var telemetry: Node
var result_age = 0.0
var player = Vector2(100, GROUND)
var velocity = Vector2.ZERO
var camera_x = 0.0
var facing = 1
var hp = 3
var invincible = 0.0
var cooldown = 0.0
var weapon_id="rifle"
# Derived legacy diagnostics entry only; weapon_id is the single runtime authority.
var weapon: bool:
	get:return weapon_id=="spread"
	set(value):weapon_id="spread" if value else "rifle"
var rapid_fire=false
var pickup_notice=""
var pickup_notice_age=0.0
var weapons=preload("res://scripts/weapons/weapon_director.gd").new()
var pickup_director=preload("res://scripts/weapons/pickup_director.gd").new()
var score = 0
var checkpoint_x=level.boss_checkpoint.x
var checkpoint_score=0
var encounters=EncounterDirector.new()
var checkpoint = false
var mode = "menu"
var settings_return = "menu"
var menu_selection = 0
var warned_boss = false
var credits_dialog: AcceptDialog
var time = 0.0
var enemies: Array = []
var bullets: Array = []
var particles: Array = []
var effect_pool=EffectPool.new()
var visual_effects: Array = effect_pool.active
var pickups: Array = []
var touches: Dictionary = {}
var touch_owners: Dictionary = {}
var stick_owner = -999
var stick_offset = Vector2.ZERO
var platforms = level.all_platforms()
var warden=preload("res://scripts/boss/spillway_warden.gd").new()
var completion_committed=false
var unlocked_levels=["iron_factory"]
var best_scores={"iron_factory":0,"spillway":0,"redrock":0}
var save_error=false
var boss_intro=0.0
var boss_shot=0.0
var boss_defeated=false
var boss_hp = 55
var boss_timer = 0.0
var boss_phase = 0
var boss_active = false
var auto_fire = false
var audio: Node
var coyote = 0.0
var jump_buffer = 0.0
var drop_platform_y=INF
var elapsed = 0.0
var button_scale = 1.0
var button_opacity = 0.5
var music_volume = 0.65
var sound_volume = 0.8
var best_score = 0
var crouching = false
var flash = 0.0
var jump_was_down = false
var font: Font = ThemeDB.fallback_font

func _ready():
	get_tree().quit_on_go_back=false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://assets/fonts/GameFont.ttf"):
		font = load("res://assets/fonts/GameFont.ttf")
	audio = AudioDirector.new()
	add_child(audio)
	replay=preload("res://scripts/debug/replay_driver.gd").new()
	add_child(replay)
	telemetry=preload("res://scripts/debug/telemetry.gd").new()
	add_child(telemetry)
	load_settings()
	terrain.rebuild(level)
	audio.set_volumes(music_volume,sound_volume)
	audio.play_music("level")
	call_deferred("apply_debug_launch")

func reset_game(from_checkpoint = false):
	started_at_checkpoint=from_checkpoint
	if level.vertical:
		if from_checkpoint and checkpoint_snapshot.get("level_id","")==level.id:
			destroyed_targets=checkpoint_snapshot.destroyed.duplicate()
			completed_encounters=checkpoint_snapshot.completed.duplicate()
			consumed_pickups=checkpoint_snapshot.consumed.duplicate()
			checkpoint_order=int(checkpoint_snapshot.get("order",-1))
			highest_climb=float(checkpoint_snapshot.get("height",0))
		else:
			from_checkpoint=false
			checkpoint_order=-1;highest_climb=0
			destroyed_targets.clear();completed_encounters.clear();consumed_pickups.clear();checkpoint_snapshot.clear()
	if not level.vertical:
		if from_checkpoint and checkpoint_snapshot.get("level_id","")==level.id:consumed_pickups=checkpoint_snapshot.consumed.duplicate()
		elif not from_checkpoint:consumed_pickups.clear();checkpoint_snapshot.clear()
	started_at_checkpoint=from_checkpoint
	replay_route_index=0;replay_strafe=1
	if level.vertical and from_checkpoint:
		while replay_route_index<level.climb_route.size() and level.climb_route[replay_route_index].y>=checkpoint_y:replay_route_index+=1
	player = Vector2(checkpoint_x,checkpoint_y) if from_checkpoint else level.spawn
	last_safe_landing=player
	velocity = Vector2.ZERO
	presentation.reset()
	shot_flash=0
	shake_remaining=0
	result_age=0
	flash=0
	crouching=false
	audio.suspend(false)
	audio.clear_effects()
	hp = 3
	weapon_id="rifle";rapid_fire=false;pickup_notice="";pickup_notice_age=0;weapons.reset()
	invincible = 1.0
	cooldown = 0
	bullets.clear()
	particles.clear()
	effect_pool.clear()
	enemies.clear()
	pickups.clear()
	warden.reset();citadel.reset();completion_committed=false
	platform_motion.reset(level);terrain.dynamic_surfaces=platform_motion.surfaces
	rockfalls.reset(level)
	boss_intro=0
	boss_shot=0
	boss_defeated=false
	boss_hp = 55
	boss_timer = 1.5
	boss_phase = 0
	boss_active = false
	checkpoint = from_checkpoint
	if not from_checkpoint:
		score = 0
		if level.id=="iron_factory":consumed_pickups.clear()
	if from_checkpoint:
		score=checkpoint_score
	else:
		checkpoint_x=level.boss_checkpoint.x if level.id=="iron_factory" else level.spawn.x
		checkpoint_y=level.spawn.y
		checkpoint_score=0
	encounters.reset(self,player.x)
	hazards.reset(level)
	pickup_director.reset(self)
	mode = "playing"
	menu_selection = 0
	warned_boss = false
	clear_input()
	jump_was_down = false
	coyote = 0.0
	jump_buffer = 0.0
	drop_platform_y=INF
	elapsed = 0.0
	CameraDirector.update(self,0,true)
	audio.play_music(level.music_at(player))

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if mode == "playing": pause_game()
		clear_input()
		if is_instance_valid(audio): audio.suspend(true)
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if is_instance_valid(audio): audio.suspend(false)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		navigate_back()

func navigate_back():
	if is_instance_valid(credits_dialog) and credits_dialog.visible:
		credits_dialog.queue_free()
		return
	clear_input()
	if mode=="settings":
		mode=settings_return
		menu_selection=0
	elif mode=="playing": pause_game()
	elif mode=="paused": mode="playing"
	elif mode in ["won","dead"]: mode="level_select"
	elif mode=="level_select":mode="menu"

func safe_insets() -> Vector4:
	if not OS.has_feature("android"): return Vector4.ZERO
	var safe = DisplayServer.get_display_safe_area()
	var screen = DisplayServer.screen_get_size()
	if screen.x<=0 or screen.y<=0 or safe.size.x<=0: return Vector4.ZERO
	# canvas_items aspect=keep adds letterboxing; account for that before moving HUD.
	var factor = minf(float(screen.x)/960.0,float(screen.y)/540.0)
	var margin = (Vector2(screen)-Vector2(960,540)*factor)*0.5
	return Vector4(maxf(0,safe.position.x-margin.x)/factor,maxf(0,safe.position.y-margin.y)/factor,maxf(0,screen.x-safe.end.x-margin.x)/factor,maxf(0,screen.y-safe.end.y-margin.y)/factor)

func control_at(p: Vector2) -> String:
	return TouchLayout.action_at(p,button_scale,safe_insets())

func control_buttons() -> Array:
	return TouchLayout.buttons(button_scale,safe_insets())

func player_muzzle() -> Dictionary:
	return Pose.muzzle(player,facing,crouching,pressed("up"),absf(velocity.x)>1,presentation.frame())

func pause_game():
	if mode != "playing": return
	mode="paused"
	clear_input()
	audio.clear_effects()


func clear_input():
	jump_buffer=0
	touches.clear()
	touch_owners.clear()
	stick_owner=-999
	stick_offset=Vector2.ZERO

func wants_platform_drop() -> bool:
	if not pressed("down") or pressed("left") or pressed("right") or pressed("up"):return false
	if stick_owner!=-999:
		var radius=TouchLayout.stick_radius(button_scale)
		return stick_offset.y>=radius*.65 and absf(stick_offset.x)<=radius*.25
	for action in touches.values():
		if str(action).split("+").has("down"):return true
	return Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or (Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)>.65 and absf(Input.get_joy_axis(0,JOY_AXIS_LEFT_X))<.25)

func touch_press(index: int,p: Vector2):
	var safe=safe_insets()
	var action=control_at(p)
	if action=="pause":
		pause_game()
		return
	if action in ["jump","fire"]:
		touch_owners[index]=action
		touches[index]=action
	elif p.distance_to(TouchLayout.stick_center(button_scale,safe))<=TouchLayout.stick_radius(button_scale) and stick_owner==-999:
		stick_owner=index
		touch_owners[index]="stick"
		touches[index]=TouchLayout.stick_action(p,"",button_scale,safe)
		stick_offset=TouchLayout.stick_vector(p,button_scale,safe)

func touch_move(index: int,p: Vector2):
	if mode!="playing" or not touch_owners.has(index): return
	var owner=touch_owners[index]
	var safe=safe_insets()
	if owner=="stick":
		touches[index]=TouchLayout.stick_action(p,str(touches.get(index,"")),button_scale,safe)
		stick_offset=TouchLayout.stick_vector(p,button_scale,safe)
	else:
		# Capture on press. Crossing the other button never activates that action.
		for item in control_buttons():
			if item[1]==owner:
				touches[index]=owner if p.distance_to(item[0])<=TouchLayout.radius(owner,button_scale)*1.25 else ""

func touch_release(index: int):
	touches.erase(index)
	touch_owners.erase(index)
	if stick_owner==index:
		stick_owner=-999
		stick_offset=Vector2.ZERO

func _input(event):
	if is_instance_valid(credits_dialog) and credits_dialog.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if mode == "settings":
			if event.keycode == KEY_ESCAPE: navigate_back()
			elif event.keycode == KEY_UP: menu_selection = posmod(menu_selection-1,9)
			elif event.keycode == KEY_DOWN: menu_selection = (menu_selection+1)%9
			elif event.keycode == KEY_LEFT: change_setting(menu_selection,-1)
			elif event.keycode == KEY_RIGHT or event.keycode == KEY_ENTER: change_setting(menu_selection,1)
			return
		if mode != "playing" and (event.keycode == KEY_UP or event.keycode == KEY_DOWN):
			menu_selection = posmod(menu_selection+(1 if event.keycode==KEY_DOWN else -1),MenuLayout.items(self).size())
			return
		if mode != "playing" and event.keycode == KEY_ENTER:
			activate_selected_menu()
			return
		if event.keycode == KEY_ESCAPE:
			navigate_back()
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if mode == "menu" or mode == "won" or mode=="level_select": activate_selected_menu()
			elif mode == "dead": reset_game(checkpoint)
			elif mode == "paused": mode = "playing"
	if event is InputEventScreenTouch:
		if event.pressed:
			if mode!="playing": activate_menu(event.position)
			else: touch_press(event.index,event.position)
		else: touch_release(event.index)
	if event is InputEventScreenDrag: touch_move(event.index,event.position)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mode!="playing": activate_menu(event.position)
			else: touch_press(-1,event.position)
		else: touch_release(-1)
	if event is InputEventMouseMotion and touch_owners.has(-1): touch_move(-1,event.position)
	if event is InputEventJoypadButton and event.pressed:
		if mode == "settings":
			match event.button_index:
				JOY_BUTTON_DPAD_UP: menu_selection = posmod(menu_selection-1,9)
				JOY_BUTTON_DPAD_DOWN: menu_selection = (menu_selection+1)%9
				JOY_BUTTON_DPAD_LEFT: change_setting(menu_selection,-1)
				JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_A: change_setting(menu_selection,1)
				JOY_BUTTON_B: navigate_back()
		elif mode != "playing":
			if event.button_index == JOY_BUTTON_DPAD_UP or event.button_index == JOY_BUTTON_DPAD_DOWN: menu_selection = posmod(menu_selection+(1 if event.button_index==JOY_BUTTON_DPAD_DOWN else -1),MenuLayout.items(self).size())
			elif event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_START: activate_selected_menu()
		elif event.button_index == JOY_BUTTON_START: pause_game()

func activate_menu(p: Vector2):
	audio.effect("confirm")
	if mode == "settings":
		if Rect2(250,490,460,40).has_point(p):
			show_credits()
			return
		if not Rect2(250,125,460,351).has_point(p): return
		if fposmod(p.y-125,39)>=34: return
		var row = int((p.y-125)/39)
		if row >= 0 and row < 9: change_setting(row,-1 if p.x < 480 else 1)
		return
	if mode in ["dead","won"] and result_age<=0.85: return
	for item in MenuLayout.items(self):
		if item.rect.has_point(p) and item.enabled:
			MenuLayout.activate(self,item.action)
			return

func change_setting(row: int,direction: int):
	match row:
		0: auto_fire = not auto_fire
		1: button_scale = clampf(snappedf(button_scale+direction*0.1,0.1),0.8,1.3)
		2: button_opacity = clampf(snappedf(button_opacity+direction*0.1,0.1),0.2,0.9)
		3: music_volume = clampf(snappedf(music_volume+direction*0.1,0.1),0,1)
		4: sound_volume = clampf(snappedf(sound_volume+direction*0.1,0.1),0,1)
		5: reduced_flash = not reduced_flash
		6: reduced_shake = not reduced_shake
		7: low_effects = not low_effects
		8: mode = settings_return
	audio.set_volumes(music_volume,sound_volume)
	audio.effect("confirm")
	save_settings()


func pressed(action: String) -> bool:
	return Controls.pressed(action,touches)

func _process(dt):
	if mode in ["won","dead"]:
		result_age+=dt
		presentation.update(dt,Vector2.ZERO,crouching,mode=="dead")
		flash=maxf(0,flash-dt)
		shot_flash=maxf(0,shot_flash-dt)
		shake_remaining=maxf(0,shake_remaining-dt)
		advance_effects(dt)
	$GameView.queue_redraw()

func advance_effects(dt: float):
	weapons.advance_visuals(self,dt)
	effect_pool.advance(dt)
	for i in range(particles.size()-1,-1,-1):
		particles[i].pos += particles[i].vel*dt
		particles[i].life -= dt
		if particles[i].life <= 0: particles.remove_at(i)



func _physics_process(dt):
	replay.before_step(dt)
	if mode == "playing": step(dt)

func step(dt):
	if mode!="playing": return
	time+=dt
	advance_effects(dt)
	shot_flash=maxf(0,shot_flash-dt)
	shake_remaining=maxf(0,shake_remaining-dt)
	elapsed += dt
	flash = maxf(0,flash-dt)
	invincible = maxf(0,invincible-dt)
	cooldown -= dt
	platform_motion.step(self,dt)
	PlayerController.step(self,dt)
	if mode!="playing":bullets.clear();return
	audio.play_music(level.music_tracks[-1] if boss_active else level.music_at(player))
	if (pressed("fire") or auto_fire) and cooldown <= 0:weapons.fire(self)
	pickup_director.step(self)
	encounters.step(self,dt)
	EnemyDirector.step(self,dt)
	hazards.step(self,dt)
	rockfalls.step(self,dt)
	if mode!="playing":
		bullets.clear()
		return
	BossDirector.step(self,dt)
	weapons.step(self,dt)

func spawn_bullet(p: Vector2,v: Vector2,friendly: bool):
	bullets.append({"pos":p,"vel":v,"friendly":friendly,"life":2.5})
func hurt():
	if invincible > 0 or mode != "playing": return
	hp -= 1
	presentation.hurt_remaining=0.14
	shake_remaining=0.10
	flash = 0.15
	audio.effect("hit")
	invincible = 1.0
	burst(player+Vector2(0,-25),Color.SALMON)
	if hp <= 0:
		visual_effect(player+Vector2(0,-24),"explosion",0.65)
		mode = "dead"
		weapon_id="rifle";rapid_fire=false;pickup_notice_age=0
		bullets.clear()
		presentation.update(0,Vector2.ZERO,crouching,true)
		shot_flash=0
		weapons.beams.clear()
		clear_input()
		result_age=0
		telemetry.record_run("dead")
		audio.play_music("failure",false)
		audio.effect("death")
func burst(p: Vector2,c: Color):
	var count=4 if low_effects else 8
	for i in range(count):
		if particles.size()>=192: particles.pop_front()
		particles.append({"pos":p,"vel":Vector2.from_angle(i*TAU/8)*100,"life":0.3,"color":c})
func save_settings():
	var c = ConfigFile.new()
	c.set_value("controls","auto_fire",auto_fire)
	c.set_value("controls","scale",button_scale)
	c.set_value("controls","opacity",button_opacity)
	c.set_value("audio","music",music_volume)
	c.set_value("audio","sound",sound_volume)
	c.set_value("progress","best_score",best_score)
	c.set_value("effects","reduced_flash",reduced_flash)
	c.set_value("effects","reduced_shake",reduced_shake)
	c.set_value("effects","low",low_effects)
	c.set_value("progress","schema_version",3)
	c.set_value("progress","unlocked_level_ids",unlocked_levels)
	for id in best_scores:c.set_value("scores",id,best_scores[id])
	save_error=c.save("user://settings.pending.cfg")!=OK
	if not save_error:
		var original="user://settings.cfg"
		var backup="user://settings.backup.cfg"
		var had_original=FileAccess.file_exists(original)
		if had_original:
			DirAccess.remove_absolute(backup)
			if DirAccess.rename_absolute(original,backup)!=OK:save_error=true
		if not save_error:
			save_error=DirAccess.rename_absolute("user://settings.pending.cfg",original)!=OK
			if save_error and had_original:DirAccess.rename_absolute(backup,original)
func load_settings():
	var c = ConfigFile.new()
	var status=c.load("user://settings.cfg")
	if status!=OK:status=c.load("user://settings.backup.cfg")
	if status==OK:
		for key in ["reduced_flash","reduced_shake","low"]:
			var value=c.get_value("effects",key,false)
			if value is bool:
				if key=="reduced_flash": reduced_flash=value
				elif key=="reduced_shake": reduced_shake=value
				else: low_effects=value
		# Type-check every external value; malformed saves fall back safely.
		var a = c.get_value("controls","auto_fire",false)
		auto_fire = a if a is bool else false
		for key in ["scale","opacity"]:
			var v = c.get_value("controls",key,1.0 if key=="scale" else 0.5)
			if v is float or v is int:
				if key == "scale": button_scale = clampf(float(v),0.8,1.3)
				else: button_opacity = clampf(float(v),0.15,0.9)
		var m = c.get_value("audio","music",0.65)
		var e = c.get_value("audio","sound",0.8)
		if m is float or m is int: music_volume = clampf(float(m),0,1)
		if e is float or e is int: sound_volume = clampf(float(e),0,1)
		var best = c.get_value("progress","best_score",0)
		if best is int: best_score = maxi(0,best)
		best_scores.iron_factory=best_score
		for id in ["iron_factory","spillway","redrock"]:
			var value=c.get_value("scores",id,best_scores.get(id,0))
			if value is int:best_scores[id]=maxi(0,value)
		var unlocked=c.get_value("progress","unlocked_level_ids",["iron_factory"])
		if unlocked is Array or unlocked is PackedStringArray:
			for id in ["spillway","redrock"]:
				if id in unlocked and not id in unlocked_levels:unlocked_levels.append(id)


func show_credits():
	var dialog = AcceptDialog.new()
	credits_dialog = dialog
	dialog.title = "制作与开源许可"
	dialog.ok_button_text = "返回"
	var theme = Theme.new()
	theme.default_font = font
	dialog.theme = theme
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680,320)
	var text = RichTextLabel.new()
	text.custom_minimum_size = Vector2(650,310)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.fit_content = true
	text.scroll_active = false
	text.text = "钢铁突围 / 原创像素绘制与合成音频。\n字体：Noto Sans SC / SIL Open Font License 1.1。\n\n"+FileAccess.get_file_as_string("res://assets/fonts/OFL.txt")+"\n\n"+FileAccess.get_file_as_string("res://assets/licenses/Godot.txt")
	scroll.add_child(text)
	dialog.add_child(scroll)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(720,420))

# Bounded cosmetic events, separate from hit detection and projectile simulation.
func visual_effect(p: Vector2,kind: String,duration: float,delay=0.0,direction=Vector2.RIGHT):
	if low_effects and kind in ["shell","dust"]: return
	effect_pool.emit(p,kind,duration,delay,direction)

func safe_landing_allowed(point: Vector2) -> bool:
	if platform_motion.is_moving_height(point.y):return false
	for h in rockfalls.entries:
		if h.area.grow(35).has_point(point):return false
	for h in hazards.entries:
		if h.area.grow(35).has_point(point):return false
	for platform in terrain.near(point):
		if platform.size.x>=240 and absf(platform.position.y-point.y)<1 and point.x>platform.position.x+30 and point.x<platform.end.x-30:return true
	return false
func recover_fall():
	drop_platform_y=INF; coyote=0; jump_buffer=0;platform_motion.rider=""
	player=last_safe_landing
	velocity=Vector2.ZERO
	invincible=0
	hurt()
	if mode=="playing":invincible=1
	CameraDirector.update(self,0,true)

func start_level(id: String,as_debug=false):
	level=LevelCatalog.get_level(id)
	LENGTH=level.length;GROUND=level.ground
	debug_run=as_debug
	platforms=level.all_platforms();terrain.rebuild(level)
	$GameView.prepare_level(level)
	audio.prepare_level(level)
	checkpoint_snapshot.clear();destroyed_targets.clear();completed_encounters.clear();consumed_pickups.clear()
	checkpoint_order=-1;highest_climb=0
	encounters=SpillwayDirector.new() if level.vertical else EncounterDirector.new()
	reset_game()
func commit_checkpoint(point: Vector2,order=-1):
	if order>=0:checkpoint_order=order
	checkpoint=true;checkpoint_x=point.x;checkpoint_y=point.y;checkpoint_score=score
	checkpoint_snapshot={"level_id":level.id,"order":checkpoint_order,"height":highest_climb,"spawn":point,"score":score,"destroyed":destroyed_targets.duplicate(),"completed":completed_encounters.duplicate(),"consumed":consumed_pickups.duplicate()}
	audio.effect("confirm")
func objective_text() -> String:
	if level.id=="iron_factory":return "%s · %02d/%02d" % [level.section(player.x).title,mini(encounters.index+1,encounters.arenas.size()),encounters.arenas.size()]
	if boss_active:return "崖心堡垒 · 仰射核心 / 炮口可选" if level.id=="redrock" else "潮汐守卫 · 拆除武装 / 击破核心"
	var progress=clampi(int(highest_climb/(level.spawn.y-level.boss_checkpoint.y)*100),0,100)
	return "%s · 继续攀登 %d%%" % [level.section_at(player).title,progress]

func complete_level():
	if completion_committed or mode!="won":return
	completion_committed=true
	if debug_run or replay.enabled:return
	best_scores[level.id]=maxi(int(best_scores.get(level.id,0)),score)
	best_score=int(best_scores.get("iron_factory",0))
	if level.id=="iron_factory" and not "spillway" in unlocked_levels:unlocked_levels.append("spillway")
	if level.id=="spillway" and not "redrock" in unlocked_levels:unlocked_levels.append("redrock")
	save_settings()

func activate_selected_menu():
	if mode in ["dead","won"] and result_age<=.85:return
	var items=MenuLayout.items(self)
	var item=items[clampi(menu_selection,0,items.size()-1)]
	if item.enabled:MenuLayout.activate(self,item.action)
func leave_to_selection():
	clear_input();bullets.clear();weapons.beams.clear();enemies.clear();particles.clear();effect_pool.clear();audio.clear_effects()
	mode="level_select";menu_selection=0
func apply_debug_launch():
	if not OS.is_debug_build():return
	for argument in OS.get_cmdline_user_args():
		if argument in ["--level=spillway","--level=redrock"]:start_level(argument.trim_prefix("--level="),true);return
	var path="user://preview-level.json"
	if FileAccess.file_exists(path):
		var parser=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data is Dictionary and parser.data.get("level_id","") in ["spillway","redrock"]:
			start_level(parser.data.level_id,true)
			if weapons.SPECS.has(str(parser.data.get("weapon_id",""))):weapons.equip(self,str(parser.data.weapon_id))
		DirAccess.remove_absolute(path)

func checkpoint_id() -> String:
	if not checkpoint:return "start"
	if level.vertical and checkpoint_order>=0:return level.id+":"+level.checkpoint_ids[checkpoint_order]
	return level.id+":"+str(int(checkpoint_x))+":"+str(int(checkpoint_y))
func boss_phase_label() -> String:
	if level.id=="redrock":return "core_open" if citadel.core_open() else "armored"
	if level.id=="iron_factory":return str(boss_phase)
	return "arms" if warden.arms[0]>0 or warden.arms[1]>0 else "overload" if warden.core<=24 else "core"
