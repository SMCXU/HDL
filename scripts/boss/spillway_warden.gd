extends RefCounted
const SPEC=preload("res://resources/bosses/spillway_warden.tres")
var arms=[12,12]
var core=48
var attack=""
var age=0.0
var wait=1.0
var cycle=0
var fired=false
var locked=false
var lock_point=Vector2.ZERO
var strike_x=0.0
func reset():
	arms=[SPEC.arm_hp,SPEC.arm_hp];core=SPEC.core_hp;attack="";age=0;wait=1;cycle=0;fired=false;locked=false
func floor_y(game: Node) -> float:return game.level.boss_checkpoint.y
func boxes(game: Node) -> Array:
	var x=game.level.boss_position.x;var y=floor_y(game)
	return [Rect2(x-190,y-60,175,40),Rect2(x-170,y-130,155,44),Rect2(x+16,y-120,88,100)]
func muzzle(game: Node,upper=false) -> Vector2:
	return Vector2(game.level.boss_position.x-195,floor_y(game)-(104 if upper else 40))
func hit(game: Node,point: Vector2,damage=1) -> bool:
	if not game.boss_active:return false
	var rects=boxes(game)
	for i in range(2):
		if arms[i]>0 and rects[i].has_point(point):
			if game.boss_intro<=0:
				arms[i]=maxi(0,arms[i]-damage);game.audio.effect("enemy_hit")
				if arms[i]==0:game.visual_effect(rects[i].get_center(),"explosion",.65);game.audio.effect("arm_break")
			update_hp(game);return true
	if rects[2].has_point(point):
		if arms[0]<=0 and arms[1]<=0 and game.boss_intro<=0:
			core=maxi(0,core-damage);game.audio.effect("enemy_hit");update_hp(game)
			if core<=0:game.BossDirector.defeated(game)
		else:game.visual_effect(point,"impact",.15)
		return true
	return false
func update_hp(game: Node):game.boss_hp=maxi(0,arms[0])+maxi(0,arms[1])+maxi(0,core)
func step(game: Node,dt: float):
	if game.boss_defeated:return
	if not game.boss_active:
		if not game.level.boss_trigger_zone.has_point(game.player) or game.velocity.y!=0:return
		game.boss_active=true;game.boss_intro=1;game.enemies.clear();game.bullets.clear();game.invincible=maxf(game.invincible,1)
		game.audio.effect("warning");reset();update_hp(game)
	game.boss_intro=maxf(0,game.boss_intro-dt)
	if game.boss_intro>0:return
	if wait>0:
		wait-=dt;return
	if attack=="":
		if arms[0]>0 or arms[1]>0:
			attack="fan" if arms[0]>0 and (cycle%2==0 or arms[1]<=0) else "laser"
		else:
			var wave_exists=false
			for b in game.bullets:
				if b.get("kind","")=="wave":wave_exists=true
			attack="wave" if cycle%2==0 and not wave_exists else "strike"
		age=0;fired=false;locked=false;game.audio.effect("warning");cycle+=1
	age+=dt
	game.boss_timer=maxf(0,1-age)
	var warning=SPEC.fan_warning
	if attack=="laser":
		warning=SPEC.laser_track+SPEC.laser_lock
		if not locked:lock_point=game.player+Vector2(0,-25)
		if age>=SPEC.laser_track:locked=true
		if age>=warning and age<warning+SPEC.laser_active:
			var closest=Geometry2D.get_closest_point_to_segment(game.player+Vector2(0,-25),muzzle(game,true),lock_point)
			if closest.distance_to(game.player+Vector2(0,-25))<14:game.hurt()
	elif attack=="strike":
		warning=SPEC.strike_warning
		if not locked:strike_x=clampf(game.player.x,game.level.boss_left+80,game.level.boss_position.x-140);locked=true
		if age>=warning and age<warning+.18:
			for x in [strike_x,minf(game.level.boss_position.x-120,strike_x+220)]:
				if Rect2(x-30,floor_y(game)-200,60,200).intersects(Rect2(game.player-Vector2(10,43),Vector2(20,43))):game.hurt()
	elif attack=="wave":warning=SPEC.wave_warning
	if age>=warning and not fired:
		fired=true;game.audio.effect("boss_shot")
		if attack=="fan":
			for angle in [-.36,0.0,.36]:game.spawn_bullet(muzzle(game),Vector2.LEFT.rotated(angle)*SPEC.fan_speed,false)
		elif attack=="wave":
			game.spawn_bullet(Vector2(game.level.boss_position.x-180,floor_y(game)-9),Vector2.LEFT*SPEC.wave_speed,false)
			game.bullets[-1].kind="wave";game.bullets[-1].life=8.0
	if age>=warning+(.18 if attack in ["laser","strike"] else .05):
		attack="";wait=SPEC.recovery if core>24 else .65
