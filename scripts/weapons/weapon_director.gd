extends RefCounted
# One authority for emission, swept collision and player damage. Rendering never hits.
const SPECS={"rifle":preload("res://resources/weapons/rifle.tres"),"machine":preload("res://resources/weapons/machine.tres"),"spread":preload("res://resources/weapons/spread.tres"),"laser":preload("res://resources/weapons/laser.tres"),"fireball":preload("res://resources/weapons/fireball.tres")}
const COLORS={"rifle":Color("ffe5af"),"machine":Color("fff4c9"),"spread":Color("ffc65e"),"laser":Color("85f4f4"),"fireball":Color("ff9850"),"rapid":Color("b0f274")}
const LETTERS={"rifle":"","machine":"M","spread":"S","laser":"L","fireball":"F","rapid":"R"}
var beams: Array=[]
var batch_id=0
var damage_total=0
var shot_counts={}
var last_damage={}
var capacity_waits=0
func reset():
	beams.clear();batch_id=0;damage_total=0;shot_counts.clear();last_damage.clear();capacity_waits=0
func spec(game: Node) -> Resource:return SPECS.get(game.weapon_id,SPECS.rifle)
func title(game: Node) -> String:return spec(game).display_name
func equip(game: Node,id: String):
	if id=="rapid":game.rapid_fire=true
	elif SPECS.has(id):game.weapon_id=id
	else:return
	game.pickup_notice="R已强化" if id=="rapid" else SPECS[id].display_name
	game.pickup_notice_age=.8;game.audio.effect("pickup")
func friendly_count(game: Node) -> int:
	var count=0
	for b in game.bullets:
		if b.friendly:count+=1
	return count
func fire(game: Node) -> bool:
	if game.mode!="playing":return false
	var cfg=spec(game)
	if friendly_count(game)+cfg.spread_angles.size()>80 or (cfg.projectile_kind=="beam" and beams.size()>=4):capacity_waits+=1;return false
	var boosted=game.rapid_fire and game.weapon_id!="laser"
	game.last_shot=game.player_muzzle();game.shot_flash=.055;game.presentation.shot_remaining=.055
	batch_id+=1
	var batch={"id":batch_id,"boss_part":"","boss_damage":0,"weapon_id":game.weapon_id}
	shot_counts[game.weapon_id]=int(shot_counts.get(game.weapon_id,0))+1
	var origin: Vector2=game.last_shot.position;var aim: Vector2=game.last_shot.direction
	if cfg.projectile_kind=="beam":
		var endpoint=origin+aim*cfg.beam_length
		var hits=intersections(game,origin,endpoint,cfg.radius)
		var count=0
		for hit in hits:
			if game.mode!="playing":break
			apply_hit(game,hit,cfg.damage,batch)
			count+=1
			if hit.kind!="enemy" or count>=cfg.penetration:endpoint=hit.point;break
		beams.append({"from":origin,"to":endpoint,"age":0.0,"life":cfg.life,"batch":batch_id})
	else:
		for angle in cfg.spread_angles:
			var dir=aim.rotated(angle)
			game.bullets.append({"pos":origin,"vel":dir*cfg.projectile_speed*(1.15 if boosted else 1),"friendly":true,"life":cfg.life,"age":0.0,"origin":origin,"direction":dir,"weapon_id":game.weapon_id,"damage":cfg.damage,"radius":cfg.radius,"projectile_kind":cfg.projectile_kind,"spiral_radius":cfg.spiral_radius,"batch":batch})
	game.cooldown=cfg.interval*(.85 if boosted else 1)
	game.visual_effect(origin,"shell",.4);game.audio.effect(cfg.effect)
	return true
func advance_visuals(game: Node,dt: float):
	game.pickup_notice_age=maxf(0,game.pickup_notice_age-dt)
	for i in range(beams.size()-1,-1,-1):
		beams[i].age+=dt
		if beams[i].age>=beams[i].life:beams.remove_at(i)
# Slab intersection gives the first time in [0,1], including stationary bullets.
static func segment_t(a: Vector2,b: Vector2,box: Rect2) -> float:
	var delta=b-a;var enter=0.0;var leave=1.0
	for axis in range(2):
		if absf(delta[axis])<.00001:
			if a[axis]<box.position[axis] or a[axis]>box.end[axis]:return INF
		else:
			var x=(box.position[axis]-a[axis])/delta[axis];var y=(box.end[axis]-a[axis])/delta[axis]
			enter=maxf(enter,minf(x,y));leave=minf(leave,maxf(x,y))
			if enter>leave:return INF
	return enter
func intersections(game: Node,a: Vector2,b: Vector2,radius: float) -> Array:
	var hits=[]
	for enemy in game.enemies:
		var t=segment_t(a,b,game.EnemyDirector.box(enemy).grow(radius))
		if t!=INF:hits.append({"kind":"enemy","target":enemy,"t":t,"point":a.lerp(b,t),"id":"enemy:"+str(enemy.get("uid",0))})
	if game.encounters.has_method("hit_target"):
		for target in game.encounters.targets:
			if target.hp<=0:continue
			var t=segment_t(a,b,Rect2(target.pos-Vector2(24,78),Vector2(48,78)).grow(radius))
			if t!=INF:hits.append({"kind":"target","target":target,"t":t,"point":a.lerp(b,t),"id":"target:"+target.id})
	for part in game.BossDirector.parts(game):
		var t=segment_t(a,b,part.box.grow(radius))
		if t!=INF:hits.append({"kind":"boss","target":part,"t":t,"point":a.lerp(b,t),"id":part.id})
	hits.sort_custom(func(x,y):return x.t<y.t)
	return hits
func apply_hit(game: Node,hit: Dictionary,amount: int,batch: Dictionary):
	var applied=0
	if hit.kind=="enemy":
		var enemy: Dictionary=hit.target
		if enemy.hp<=0:return
		applied=mini(amount,enemy.hp);enemy.hp-=applied;enemy.hit=.1
		game.audio.effect("enemy_hit");game.visual_effect(hit.point,"impact",.18);game.burst(hit.point,Color.ORANGE)
		if enemy.hp<=0:
			game.visual_effect(enemy.pos,"wreck_%d"%enemy.type,1.4,0,Vector2(enemy.face,0));game.visual_effect(enemy.pos-Vector2(0,24),"explosion",.65)
			game.audio.effect("explosion");game.score+=100
			var index=game.enemies.find(enemy)
			if index>=0:game.enemies.remove_at(index)
	elif hit.kind=="target":
		applied=mini(amount,int(hit.target.hp))
		game.encounters.hit_target(game,hit.target.pos-Vector2(0,35),amount)
	else:
		var part: Dictionary=hit.target
		if not part.damageable:
			game.visual_effect(hit.point,"impact",.12);return
		if batch.get("weapon_id","rifle")=="spread":
			if batch.boss_part!="" and batch.boss_part!=part.id:return
			amount=mini(amount,2-int(batch.boss_damage))
			if amount<=0:return
			batch.boss_part=part.id;batch.boss_damage+=amount
		var point: Vector2=part.box.get_center() # Grown swept edge must still resolve the selected exact part.
		applied=mini(amount,int(part.hp))
		game.BossDirector.hit(game,point,amount)
	damage_total+=applied
	last_damage={"weapon_id":batch.get("weapon_id","rifle"),"batch":batch.get("id",0),"target":hit.id,"damage":applied}
func step(game: Node,dt: float):
	for i in range(game.bullets.size()-1,-1,-1):
		if game.mode!="playing":break
		var b=game.bullets[i];var old: Vector2=b.pos
		b.life-=dt
		var remove=false
		if b.friendly:
			b.age=float(b.get("age",0))+dt
			var segments=4 if b.get("projectile_kind","")=="spiral" else 1
			for substep in range(segments):
				var next: Vector2
				if segments>1:
					var age=b.age-dt+dt*(substep+1)/segments
					var theta=age*TAU/.32;var dir: Vector2=b.direction;var r=float(b.spiral_radius)
					next=b.origin+b.vel*age+dir*(cos(theta)-1)*r+dir.orthogonal()*sin(theta)*r
				else:next=old+b.vel*dt
				var hits=intersections(game,old,next,float(b.get("radius",2)))
				b.pos=next
				if not hits.is_empty():
					if not b.has("batch"):b.batch={"id":0,"boss_part":"","boss_damage":0,"weapon_id":"rifle"}
					apply_hit(game,hits[0],int(b.get("damage",1)),b.batch);remove=true;break
				old=next
		else:
			b.pos+=b.vel*dt
			var box=Rect2(game.player+Vector2(-10,-25 if game.crouching else -43),Vector2(20,25 if game.crouching else 43))
			if segment_t(old,b.pos,box)!=INF:game.hurt();remove=true
		if game.mode!="playing":game.bullets.clear();return
		remove=remove or b.life<=0 or b.pos.y>1000 or b.pos.y<game.level.world_top-200 or absf(b.pos.x-game.player.x)>1800
		if remove:game.bullets.remove_at(i)
	if game.mode in ["won","dead"]:game.bullets.clear()
