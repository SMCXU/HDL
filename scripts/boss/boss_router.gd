extends RefCounted
const Factory=preload("res://scripts/boss/boss_director.gd")
# Legacy coordinates remain available to first-level diagnostic callers.
const POSITION=Factory.POSITION
const DRAW_RECT=Factory.DRAW_RECT
const MUZZLE=Factory.MUZZLE
const CORE=Factory.CORE
static func step(game: Node,dt: float):
	if game.level.id=="redrock":game.citadel.step(game,dt)
	elif game.level.id=="spillway":game.warden.step(game,dt)
	else:Factory.step(game,dt)
static func hit(game: Node,point: Vector2,damage=1) -> bool:
	if game.level.id=="redrock":return game.citadel.hit(game,point,damage)
	if game.level.id=="spillway":return game.warden.hit(game,point,damage)
	if not game.boss_active or not DRAW_RECT.has_point(point):return false
	if game.boss_intro<=0:game.boss_hp=maxi(0,game.boss_hp-damage)
	game.burst(point,Color.ORANGE)
	if game.boss_hp<=0:defeated(game)
	return true
static func defeated(game: Node):
	if game.mode!="playing":return
	if game.level.id=="iron_factory":Factory.defeated(game);return
	game.boss_active=false;game.boss_defeated=true;game.result_age=0;game.shot_flash=0;game.clear_input()
	game.score+=2000;game.mode="won"
	for i in range(6):game.visual_effect(game.level.boss_position+Vector2((i%3)*36,int(i/3)*70),"explosion",.65,i*.12)
	game.audio.effect("boss_death");game.audio.play_music("victory",false);game.complete_level();game.telemetry.record_run("won")

static func parts(game: Node) -> Array:
	if not game.boss_active:return []
	var ready=game.boss_intro<=0
	if game.level.id=="iron_factory":return [{"id":"factory:core","box":DRAW_RECT,"damageable":ready,"hp":game.boss_hp}]
	var result=[]
	if game.level.id=="spillway":
		var boxes=game.warden.boxes(game)
		for i in range(2):
			if game.warden.arms[i]>0:result.append({"id":"warden:arm%d"%i,"box":boxes[i],"damageable":ready,"hp":game.warden.arms[i]})
		result.append({"id":"warden:core","box":boxes[2],"damageable":ready and game.warden.arms[0]<=0 and game.warden.arms[1]<=0,"hp":game.warden.core})
	else:
		var boxes=game.citadel.boxes(game)
		for i in range(2):
			if game.citadel.ports[i]>0:result.append({"id":"citadel:port%d"%i,"box":boxes[i],"damageable":ready,"hp":game.citadel.ports[i]})
		result.append({"id":"citadel:core","box":boxes[2],"damageable":ready and game.citadel.core_open(),"hp":game.citadel.core})
	return result
