extends RefCounted
static func frame(view: Node,index: int,destination: Rect2,tint=Color.WHITE):
	var cell=Vector2(view.fx.get_width()/4.0,view.fx.get_height()/3.0)
	var source=Rect2(Vector2(index%4,int(index/4))*cell,cell)
	view.sprite(view.fx,source,destination,tint)

static func draw(view: Node,game: Node):
	for event in game.visual_effects:
		if event.age<0 or event.kind.begins_with("wreck_"): continue
		var q=view.world(event.pos)
		if q.x < -150 or q.x>1110 or q.y< -150 or q.y>690:continue
		var progress=clampf(event.age/event.duration,0,1)
		if event.kind=="shell":
			view.draw_set_transform(q+Vector2(-event.age*75,-sin(progress*PI)*24),event.age*16)
			view.rect(Rect2(-2,-1,4,2),Color("d9ab5e"))
			view.draw_set_transform(Vector2.ZERO)
		elif event.kind=="impact":
			view.draw_set_transform(q,event.direction.angle())
			frame(view,11,Rect2(-3,-13,32,26),Color(1,1,1,1-progress))
			view.draw_set_transform(Vector2.ZERO)
		elif event.kind=="dust":
			frame(view,6+mini(2,int(progress*3)),Rect2(q+Vector2(-22,-10-progress*10),Vector2(44,20)),Color(0.6,0.7,0.8,(1-progress)*0.4))
		else:
			var size=120.0 if event.kind=="core" else 64.0
			if game.low_effects: size*=0.8
			var alpha=0.7 if game.reduced_flash else 1.0
			frame(view,mini(5,int(progress*6)),Rect2(q-Vector2.ONE*size*0.5,Vector2.ONE*size),Color(1,1,1,alpha))
			# Small ballistic fragments give direction without full-screen smoke.
			if not game.low_effects:
				for j in range(4):
					var velocity=Vector2.from_angle(j*1.7)*55
					var point=q+velocity*event.age+Vector2(0,event.age*event.age*65)
					view.draw_line(point,point-velocity.normalized()*3,Color(1,0.6,0.25,1-progress),2)
