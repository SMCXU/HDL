extends RefCounted
static func frame(enemy: Dictionary) -> int:
	if enemy.type==0:
		if enemy.hit>0: return 3
		if enemy.state=="warning" or enemy.shot>0: return 2
		return 1 if int(enemy.phase*6)%2 else 0
	if enemy.type==1: return 6 if enemy.state=="warning" else 5
	return 10 if enemy.hit>0 else (9 if enemy.state=="warning" else 8)

static func draw_sprite(view: Node,index: int,kind: int,position: Vector2,face: int,tint=Color.WHITE):
	var region: Rect2=view.enemy_regions[index]
	var base=[0,5,8][kind]
	var height=[56.0,46.0,36.0][kind]
	var factor=height/view.enemy_regions[base].size.y
	var size=region.size*factor
	view.draw_set_transform(position,0,Vector2(face,1))
	view.sprite(view.enemy_motion,region,Rect2(-size.x*0.42,-size.y,size.x,size.y),tint)
	view.draw_set_transform(Vector2.ZERO)

static func draw(view: Node,game: Node):
	for enemy in game.enemies:
		var p=view.world(enemy.pos)
		if p.x<30 or p.x>930:
			var side=-1 if p.x<30 else 1
			var edge=Vector2(18 if side<0 else 942,clampf(p.y-28,155,380))
			view.draw_set_transform(edge,PI if side<0 else 0)
			view.draw_colored_polygon(PackedVector2Array([Vector2(6,0),Vector2(-5,-6),Vector2(-5,6)]),Color("ff8265"))
			view.draw_set_transform(Vector2.ZERO)
		if p.x< -100 or p.x>1060 or p.y< -100 or p.y>640:continue
		var recoil=Vector2(-enemy.face*2,0) if enemy.shot>0 else Vector2.ZERO
		var tint=Color(1.4,1.2,1.1) if enemy.hit>0 else Color.WHITE
		draw_sprite(view,frame(enemy),enemy.type,p+recoil,enemy.face,tint)
		var origin=view.world(game.EnemyDirector.muzzle(enemy))
		if enemy.state=="warning":
			view.draw_circle(origin,5,Color(1,0.3,0.16,0.3))
			view.draw_line(origin+Vector2(enemy.face*8,-3),origin+Vector2(enemy.face*14,3),Color("ffb75b"),2)
		if enemy.shot>0:
			view.draw_set_transform(origin,0 if enemy.face>0 else PI)
			view.EffectRenderer.frame(view,9,Rect2(-4,-8,20,16))
			view.draw_set_transform(Vector2.ZERO)
	for event in game.visual_effects:
		if not event.kind.begins_with("wreck_") or event.age<0: continue
		var kind=int(event.kind.trim_prefix("wreck_"))
		var index=[4,7,11][kind]
		var p=view.world(event.pos)
		if kind==2: p.y=minf(435,p.y+event.age*event.age*220)
		var alpha=minf(1,(event.duration-event.age)*2)
		draw_sprite(view,index,kind,p,int(event.direction.x),Color(0.8,0.8,0.8,alpha))
