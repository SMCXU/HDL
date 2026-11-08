extends RefCounted
# A coordinated cycle prevents unrelated hazard timers producing unavoidable overlaps.
const CORE_HP=42
const PORT_HP=8
var core=CORE_HP
var ports=[PORT_HP,PORT_HP]
var age=0.0
var cycle=0
var fired=false
var strike_x=480.0
func reset():core=CORE_HP;ports=[PORT_HP,PORT_HP];age=0;cycle=0;fired=false
func boxes(game: Node) -> Array:
	var y=game.level.boss_checkpoint.y
	return [Rect2(270,y-160,75,115),Rect2(615,y-160,75,115),Rect2(450,y-175,60,140)]
func core_open() -> bool:return age>=2.0
func hit(game: Node,point: Vector2,damage=1) -> bool:
	if not game.boss_active:return false
	var b=boxes(game)
	for i in range(2):
		if ports[i]>0 and b[i].has_point(point):
			if game.boss_intro<=0:
				ports[i]=maxi(0,ports[i]-damage);game.audio.effect("enemy_hit")
				if ports[i]==0:game.score+=250;game.visual_effect(b[i].get_center(),"explosion",.65);game.audio.effect("arm_break")
			return true
	if b[2].has_point(point):
		if core_open() and game.boss_intro<=0:
			core=maxi(0,core-damage);game.audio.effect("enemy_hit");game.boss_hp=maxi(0,core)
			if core<=0:game.BossDirector.defeated(game)
		else:game.visual_effect(point,"impact",.12)
		return true
	return false
func step(game: Node,dt: float):
	if game.boss_defeated:return
	if not game.boss_active:
		if not game.level.boss_trigger_zone.has_point(game.player) or game.velocity.y!=0:return
		reset();game.boss_active=true;game.boss_hp=core;game.boss_intro=1.0
		game.enemies.clear();game.bullets.clear();game.invincible=maxf(game.invincible,1)
		game.audio.effect("warning")
	game.boss_intro=maxf(0,game.boss_intro-dt)
	if game.boss_intro>0:return
	age+=dt
	var period=4.4 if core>10 else 3.6
	if age>=period:
		age=0;cycle+=1;fired=false;strike_x=clampf(game.player.x,160,800);game.audio.effect("warning")
	if age>=1.0 and not fired:
		fired=true
		var side=cycle%2
		if ports[side]>0:
			var origin=boxes(game)[side].get_center()
			var aim=(game.player-Vector2(0,25)-origin).normalized()
			for a in [-.22,0.0,.22]:game.spawn_bullet(origin,aim.rotated(a)*200,false)
			game.audio.effect("boss_shot")
	# Only one short rock strike, ending before the core output window.
	if core<=25 and cycle%2==1 and age>=1.1 and age<1.65:
		var rock_y=game.level.boss_checkpoint.y-200+(age-1.1)*340
		if Rect2(strike_x-15,rock_y-15,30,30).intersects(Rect2(game.player-Vector2(10,43),Vector2(20,43))):game.hurt()
