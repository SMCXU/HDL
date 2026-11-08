extends Node2D
# Original bitmap artwork and procedural overlays; rendering has no gameplay authority.
@onready var game = get_parent()

func pressed(action: String) -> bool: return game.pressed(action)
func control_buttons() -> Array: return game.control_buttons()

func rect(r: Rect2,c: Color): draw_rect(r,c)
func label(p: Vector2,s: String,size=20,c=Color.WHITE): draw_string(game.font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func shake_x() -> float:
	if game.reduced_shake or game.shake_remaining<=0: return 0
	return sin(game.time*97)*minf(2.5,game.shake_remaining*18)
func world(p: Vector2) -> Vector2: return p-Vector2(game.camera_x-shake_x(),game.camera_y)
const CYAN = Color("56dbea")
const STEEL = Color("597084")

func panel(r: Rect2, accent = CYAN):
	var p = r.position
	var z = r.size
	var points = PackedVector2Array([p+Vector2(9,0),p+Vector2(z.x,0),p+Vector2(z.x,z.y-9),p+z-Vector2(9,0),p+Vector2(0,z.y),p+Vector2(0,9)])
	draw_colored_polygon(points,Color(0.02,0.07,0.11,0.88))
	points.append(points[0])
	draw_polyline(points,accent.darkened(0.25),1.3)
	draw_line(p+Vector2(10,4),p+Vector2(z.x-10,4),accent.darkened(0.5),1)

func plate(r: Rect2):
	rect(r,Color("182a39"))
	rect(Rect2(r.position,Vector2(r.size.x,3)),STEEL)
	draw_rect(r,Color("334b5d"),false,1)
	for x in [r.position.x+5,r.end.x-6]:
		for y in [r.position.y+6,r.end.y-6]:
			rect(Rect2(x,y,2,2),Color("8b9ca7"))

const EnemyRenderer=preload("res://scripts/enemies/enemy_renderer.gd")
@onready var enemy_motion: Texture2D=load("res://assets/art/enemy-motion.png")
var enemy_regions: Array=[]
const RedrockRenderer=preload("res://scripts/level/redrock_renderer.gd")
var redrock_backdrop: Texture2D
var redrock_atlas: Texture2D
var redrock_boss: Texture2D
var redrock_regions: Array=[]
var redrock_ledges: Array=[]
const SpillwayRenderer=preload("res://scripts/level/spillway_renderer.gd")
var spillway_backdrop: Texture2D
var spillway_atlas: Texture2D
var spillway_regions: Array=[]
const EnvironmentRenderer=preload("res://scripts/level/environment_renderer.gd")
const WeaponRenderer=preload("res://scripts/weapons/weapon_renderer.gd")
const HudRenderer=preload("res://scripts/ui/hud_renderer.gd")
const EffectRenderer=preload("res://scripts/effects/effect_renderer.gd")
@onready var fx: Texture2D=load("res://assets/art/combat-fx.png")
@onready var transitions: Texture2D=load("res://assets/art/player-transitions.png")
@onready var motion: Texture2D = load("res://assets/art/player-motion.png")
@onready var backdrop: Texture2D = load("res://assets/art/factory.png")
@onready var structures: Texture2D = load("res://assets/art/structures.png")
var structure_regions: Array = []

func _ready():
	var enemy_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/enemy-motion.json"))
	for region in enemy_data.enemies: enemy_regions.append(Rect2(region[0],region[1],region[2],region[3]))
	# Atlas regions are measured from the original transparent sheet and kept in JSON.
	var atlas = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/regions.json"))
	for region in atlas.structures: structure_regions.append(Rect2(region[0],region[1],region[2],region[3]))

func sprite(texture: Texture2D,region: Rect2,destination: Rect2,tint = Color.WHITE):
	draw_texture_rect_region(texture,destination,region,tint)

func soldier(p: Vector2,c: Color,face: int,walking: bool,crouch=false,aim_up=false):
	var state_frame=game.presentation.frame()
	var frame=state_frame
	if game.mode!="dead": frame=game.Pose.frame_for(state_frame,aim_up,walking)
	var profile=game.Pose.PROFILE
	var region: Rect2=profile.regions[frame]
	var factor=profile.scales[frame]
	var texture=transitions if profile.atlas_ids[frame]==1 else motion
	var size=region.size*factor
	var foot=profile.feet[frame]*factor
	var tint=Color.WHITE
	if game.presentation.hurt_remaining>0: tint=Color(1.25,1.15,1.1)
	draw_set_transform(p,0,Vector2(face,1))
	if aim_up and game.mode!="dead":
		# Upper body holds the correct weapon direction; hips/legs continue moving.
		var leg_height=21.0
		var upper_height=region.size.y-leg_height/factor
		var upper_region=Rect2(region.position,Vector2(region.size.x,upper_height))
		sprite(texture,upper_region,Rect2(-foot+Vector2(0,12 if crouch else 0),Vector2(size.x,upper_height*factor)),tint)
		var lower: Rect2=profile.regions[state_frame]
		var lower_factor=profile.scales[state_frame]
		var lower_texture=transitions if profile.atlas_ids[state_frame]==1 else motion
		var lower_size=lower.size*lower_factor
		var lower_height=minf(leg_height,lower_size.y)
		var lower_region=Rect2(lower.position+Vector2(0,lower.size.y-lower_height/lower_factor),Vector2(lower.size.x,lower_height/lower_factor))
		sprite(lower_texture,lower_region,Rect2(-profile.feet[state_frame].x*lower_factor,-lower_height,lower_size.x,lower_height),tint)
	else:
		sprite(texture,region,Rect2(-foot,size),tint)
	draw_set_transform(Vector2.ZERO)
	if game.shot_flash>0 and game.mode=="playing":
		var origin=world(game.player_muzzle().position)
		draw_set_transform(origin,game.player_muzzle().direction.angle())
		EffectRenderer.frame(self,10 if game.weapon else 9,Rect2(-6,-12,36 if game.weapon else 28,24),Color(1,1,1,0.65 if game.reduced_flash else 1))
		draw_set_transform(Vector2.ZERO)

func prepare_level(level: Resource):
	if level.id=="redrock" and not redrock_atlas:
		redrock_backdrop=load("res://assets/art/level03/redrock-background.png")
		redrock_atlas=load("res://assets/art/level03/redrock-atlas.png")
		redrock_boss=load("res://assets/art/level03/cliff-citadel.png")
		var regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/level03/regions.json"))
		for r in regions.regions:redrock_regions.append(Rect2(r[0],r[1],r[2],r[3]))
	if level.id=="redrock":
		redrock_ledges=[]
		for r in level.all_platforms():
			var merged=r
			for i in range(redrock_ledges.size()-1,-1,-1):
				var existing: Rect2=redrock_ledges[i]
				if absf(existing.position.y-r.position.y)<1 and existing.grow(1).intersects(merged):
					merged=merged.merge(existing);redrock_ledges.remove_at(i)
			redrock_ledges.append(merged)
	if level.id!="spillway" or spillway_atlas:return
	spillway_backdrop=load("res://assets/art/level02/spillway-background.png")
	spillway_atlas=load("res://assets/art/level02/spillway-atlas.png")
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/level02/regions.json"))
	for r in data.regions:spillway_regions.append(Rect2(r[0],r[1],r[2],r[3]))
func environment():
	if game.level.id=="redrock":RedrockRenderer.draw(self,game)
	elif game.level.id=="spillway":SpillwayRenderer.draw(self,game)
	else:EnvironmentRenderer.draw(self,game)

func _draw():
	var camera_x = game.camera_x-shake_x()
	var time = game.time
	var platforms = redrock_ledges if game.level.id=="redrock" else game.platforms
	var pickups = game.pickups
	var enemies = game.enemies
	var mode = game.mode
	var invincible = game.invincible
	var player = game.player
	var facing = game.facing
	var velocity = game.velocity
	var crouching = game.crouching
	var boss_active = game.boss_active
	var boss_timer = game.boss_timer
	var boss_hp = game.boss_hp
	var bullets = game.bullets
	var particles = game.particles
	var hp = game.hp
	var weapon = game.weapon
	var score = game.score
	var checkpoint = game.checkpoint
	var button_scale = game.button_scale
	var button_opacity = game.button_opacity
	var flash = game.flash
	var menu_selection = game.menu_selection
	var auto_fire = game.auto_fire
	var music_volume = game.music_volume
	var sound_volume = game.sound_volume
	var best_score = game.best_score
	var GROUND = game.GROUND
	environment()
	if game.replay.enabled: label(Vector2(300,90),"自动压力回放 / 非人工验收 · 点击暂停可停止",15,Color("f2c37a"))
	if game.debug_run:label(Vector2(330,128),"调试预览 · 不记录解锁/成绩",14,Color("f2c37a"))
	if mode == "playing" and player.x < 550 and (not game.level.vertical or game.highest_climb<180):
		label(Vector2(340,105),"左右攀登 · 正下＋跳跃可下穿" if game.level.vertical else "清除当前威胁，解除前方封锁",16,Color("aed1dc"))
	if game.encounters.blocks_progress():
		var gate=world(Vector2(game.encounters.gate_x,435 if game.level.id=="iron_factory" or game.encounters.gate_x<4200 else -1005))
		if gate.x> -30 and gate.x<990:
			var gate_color=Color(0.9,0.3,0.2,0.75) if game.encounters.active else Color(0.3,0.8,0.9,0.45)
			draw_line(gate,gate-Vector2(0,190),gate_color,3)
			for mark in range(6):
				var y=gate.y-20-mark*29
				draw_line(Vector2(gate.x-6,y),Vector2(gate.x+6,y-10),gate_color,2)
			label(gate-Vector2(95,202),"摧毁供能节点" if game.level.id=="spillway" else "剩余威胁 %d" % game.enemies.size(),15,Color("ffb275"))
	if game.encounters.clear_age>0: label(Vector2(365,112),"封锁解除 · 继续推进",18,CYAN)
	for p in platforms:
		var r = Rect2(p.position-Vector2(camera_x,game.camera_y),p.size)
		if not r.intersects(Rect2(-100,-100,1160,740)):continue
		var platform_region: Rect2 = structure_regions[1]
		# 26 px railing above collision, deck and support below.
		if game.level.id=="redrock":RedrockRenderer.ledge(self,r)
		elif game.level.id=="spillway":SpillwayRenderer.deck(self,r)
		else:sprite(structures,platform_region,Rect2(r.position.x,r.position.y-26,r.size.x,74))
	WeaponRenderer.pickups(self,game)
	if (boss_active or game.boss_defeated) and game.level.id=="redrock":RedrockRenderer.boss(self,game)
	EnemyRenderer.draw(self,game)
	if mode != "menu":
		if invincible <= 0 or int(time*15)%2==0:
			soldier(world(player),Color("43b7b1"),facing,absf(velocity.x)>1,crouching,pressed("up"))
	if (boss_active or game.boss_defeated) and game.level.id=="spillway":SpillwayRenderer.boss(self,game)
	if (boss_active or game.boss_defeated) and game.level.id=="iron_factory":
		var p = world(game.BossDirector.POSITION)
		var boss_region: Rect2 = structure_regions[3]
		sprite(structures,boss_region,Rect2(p.x-20,p.y-12,190,217),Color(0.4,0.4,0.45) if game.boss_defeated else Color.WHITE)
		var charge = Color("ffb452") if boss_timer<0.4 else Color("ef6550")
		draw_arc(p+Vector2(95,49),25,time,time+4.8,32,charge,2)
		if boss_timer<0.4 and boss_active:
			draw_circle(p+Vector2(95,49),14,Color(1,0.7,0.3,0.25))
			var origin=world(game.BossDirector.MUZZLE)
			var hint=Color("ffb65b") if game.boss_phase%2==0 else Color("ef675c")
			label(origin+Vector2(-100,-25),"扇形扫射" if game.boss_phase%2==0 else "锁定射击",14,hint)
			if game.boss_phase%2==1:
				draw_line(origin,world(player+Vector2(0,-25)),Color(1,0.2,0.1,0.22),1)
		if game.boss_intro>0:
			draw_arc(p+Vector2(75,100),100,-PI/2,PI/2,32,CYAN,2)
			label(Vector2(370,145),"核心防御启动 / 护盾展开",18,CYAN)
		if boss_hp<25 and boss_active:
			EffectRenderer.frame(self,7,Rect2(p+Vector2(45,-30-fposmod(time*18,18)),Vector2(70,65)),Color(0.7,0.7,0.7,0.32))
		if game.boss_shot>0:
			draw_set_transform(world(game.BossDirector.MUZZLE),PI)
			EffectRenderer.frame(self,10,Rect2(-5,-18,52,36))
			draw_set_transform(Vector2.ZERO)
		label(Vector2(330,82),"核心防御机",18)
		rect(Rect2(330,90,300,10),Color("3b354b"))
		rect(Rect2(330,90,300*maxf(0,boss_hp)/55,10),Color("ee836b"))
	WeaponRenderer.projectiles(self,game)
	EffectRenderer.draw(self,game)
	for p in particles: rect(Rect2(world(p.pos),Vector2(4,4)),p.color)
	if mode != "menu":
		HudRenderer.draw(self,game)
	if flash > 0: rect(Rect2(0,0,960,540),Color(0.9,0.2,0.1,flash*(0.2 if game.reduced_flash else 1.0)))

	if mode != "playing" and (mode not in ["dead","won"] or game.result_age>0.85):
		rect(Rect2(0,0,960,540),Color(0.02,0.04,0.08,0.72))
		if mode == "settings":
			label(Vector2(270,85),"行动设置",30,Color("84e4d7"))
			var rows = ["自动射击："+("开" if auto_fire else "关"),"按钮大小：%d%%" % int(button_scale*100),"按钮透明度：%d%%" % int(button_opacity*100),"音乐音量：%d%%" % int(music_volume*100),"音效音量：%d%%" % int(sound_volume*100),"减少闪光："+("开" if game.reduced_flash else "关"),"减少震动："+("开" if game.reduced_shake else "关"),"低特效："+("开" if game.low_effects else "关"),"返回"]
			for i in range(rows.size()):
				rect(Rect2(250,125+i*39,460,34),Color("183d49") if i == menu_selection else Color("102533"))
				label(Vector2(275,149+i*39),rows[i],20)
				if i > 0 and i < 5: label(Vector2(650,149+i*39),"− / +",20,Color("f2c37a"))
			label(Vector2(250,515),"左侧减少 / 右侧增加 · 点击这里查看制作与开源许可",17)
			return
		game.MenuLayout.draw(self,game)
