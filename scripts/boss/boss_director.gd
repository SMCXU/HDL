extends RefCounted
const Level=preload("res://scripts/level/level_director.gd")
const POSITION=Level.BOSS_POSITION
const DRAW_RECT=Rect2(POSITION+Vector2(-20,-12),Vector2(190,217))
const MUZZLE=POSITION+Vector2(-18,64)
const CORE=POSITION+Vector2(95,49)
static func step(game: Node,dt: float):
	if game.player.x>Level.BOSS_TRIGGER and not game.boss_active:
		game.boss_active=true
		game.boss_intro=1.0
		game.boss_timer=1.5
		game.invincible=maxf(game.invincible,1.0)
		game.audio.play_music("boss")
		game.audio.effect("warning")
		game.enemies.clear()
		game.bullets.clear()
	if not game.boss_active: return
	game.boss_intro=maxf(0,game.boss_intro-dt)
	game.boss_shot=maxf(0,game.boss_shot-dt)
	game.boss_timer-=dt
	if game.boss_timer<0.4 and not game.warned_boss:
		game.audio.effect("warning")
		game.warned_boss=true
	if game.boss_timer<=0 and game.boss_intro<=0:
		if game.boss_phase%2==0:
			for angle in [-0.65,-0.32,0.0,0.32,0.65]:
				game.spawn_bullet(MUZZLE,Vector2.LEFT.rotated(angle)*220,false)
		else:
			var aim=(game.player+Vector2(0,-25)-MUZZLE).normalized()
			for angle in [-0.12,0.0,0.12]: game.spawn_bullet(MUZZLE,aim.rotated(angle)*280,false)
		game.audio.effect("boss_shot")
		game.boss_shot=0.12
		game.warned_boss=false
		game.boss_phase+=1
		game.boss_timer=1.5 if game.boss_hp>25 else 1.0
static func defeated(game: Node):
	if game.mode!="playing": return
	game.boss_active=false
	game.boss_defeated=true
	game.result_age=0
	game.shot_flash=0
	game.clear_input()
	game.shake_remaining=0.30
	for i in range(6):
		var offset=Vector2((i%3-1)*37,(int(i/3)-1)*45)
		game.visual_effect(CORE+offset,"explosion",0.65,i*0.10)
	game.visual_effect(CORE,"core",1.4,0.4)
	game.score+=2000
	game.mode="won"
	game.audio.effect("boss_death")
	game.audio.play_music("victory",false)
	game.complete_level()
	game.telemetry.record_run("won")
