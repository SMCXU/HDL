extends RefCounted
const SPECS=[preload("res://resources/enemies/infantry.tres"),preload("res://resources/enemies/turret.tres"),preload("res://resources/enemies/drone.tres")]
static var next_uid=0
static func create(position: Vector2,kind: int,index: int) -> Dictionary:
	next_uid+=1
	var spec=SPECS[kind]
	return {"uid":next_uid,"pos":position,"home":position.x,"home_y":position.y,"type":kind,"hp":spec.max_hp,"timer":0.7+(index%4)*0.3,"phase":float(index),"face":-1,"shot":0.0,"hit":0.0,"state":"patrol"}
static func muzzle(enemy: Dictionary) -> Vector2:
	var offset=Vector2(enemy.face*28,-34)
	if enemy.type==1: offset=Vector2(enemy.face*37,-31)
	if enemy.type==2: offset=Vector2(enemy.face*29,-32)
	return enemy.pos+offset
static func box(enemy: Dictionary) -> Rect2:
	var size=SPECS[enemy.type].hit_size
	return Rect2(enemy.pos+Vector2(-size.x/2,-size.y),size)
static func step(game: Node,dt: float):
	for enemy in game.enemies:
		if enemy.pos.distance_to(game.player)>900:continue
		var spec=SPECS[enemy.type]
		var visible=Rect2(Vector2(game.camera_x-40,game.camera_y+100),Vector2(1040,420)).has_point(enemy.pos)
		if visible:enemy.timer-=dt
		else:enemy.timer=maxf(enemy.timer,spec.warning+.1)
		enemy.phase+=dt
		enemy.shot=maxf(0,enemy.shot-dt)
		enemy.hit=maxf(0,enemy.hit-dt)
		enemy.face=1 if game.player.x>enemy.pos.x else -1
		if enemy.type==0: enemy.pos.x=enemy.home+sin(enemy.phase)*(30 if game.level.vertical else 65)
		if enemy.type==2: enemy.pos.y=enemy.home_y+sin(enemy.phase*2)*45
		enemy.state="warning" if enemy.timer<=spec.warning else "patrol"
		if visible and enemy.timer<=0 and absf(enemy.pos.x-game.player.x)<620:
			var origin=muzzle(enemy)
			game.spawn_bullet(origin,(game.player+Vector2(0,-25)-origin).normalized()*spec.speed,false)
			game.audio.effect("enemy_shot")
			enemy.timer=spec.interval
			enemy.shot=0.08
			enemy.state="fire"
		if game.player.distance_to(enemy.pos)<28: game.hurt()
