extends RefCounted
const CYAN=Color("56dbea")
static func weapon_icon(view: Node,p: Vector2,id: String):
	view.draw_line(p,p+Vector2(29,0),CYAN,3)
	view.draw_line(p+Vector2(7,2),p+Vector2(5,9),CYAN,3)
	view.draw_line(p+Vector2(17,2),p+Vector2(20,8),CYAN,3)
	view.draw_line(p+Vector2(10,-5),p+Vector2(19,-5),CYAN,2)
	if id=="spread": view.draw_line(p+Vector2(26,3),p+Vector2(34,3),CYAN,2)

	if id=="machine":
		for x in [12,17,22]:view.draw_line(p+Vector2(x,-3),p+Vector2(x,-9),CYAN,2)
	elif id=="laser":view.draw_line(p+Vector2(30,0),p+Vector2(44,0),Color("eefeff"),1)
	elif id=="fireball":view.draw_circle(p+Vector2(32,-1),4,Color("ffab54"))

static func draw(view: Node,game: Node):
	var safe=game.safe_insets()
	var top=Vector2(0,safe.y)
	var left=top+Vector2(safe.x,0)
	var right=top-Vector2(safe.z,0)
	if game.level.id=="redrock":draw_redrock_top(view,game,left,top,right)
	else:
		view.panel(Rect2(Vector2(20,17)+left,Vector2(245,64)))
		view.label(Vector2(32,40)+left,"钢铁突围 / IRON BREAKOUT",16,CYAN)
		for i in range(3):
			var q=Vector2(33+i*31,53)+left
			view.draw_colored_polygon(PackedVector2Array([q+Vector2(6,0),q+Vector2(29,0),q+Vector2(23,12),q+Vector2(0,12)]),CYAN if i<game.hp else Color("263642"))
		weapon_icon(view,Vector2(140,57)+left,game.weapon_id)
		view.label(Vector2(181,65)+left,game.weapons.title(game),16,Color("c0d0d9"))
		if game.rapid_fire:view.label(Vector2(240,65)+left,"R",14,Color("b0f274") if game.weapon_id!="laser" else Color("617463"))
		view.panel(Rect2(Vector2(300,18)+top,Vector2(420,36)))
		view.label(Vector2(311,42)+top,game.objective_text(),15,Color("b9dce4"))
		view.panel(Rect2(Vector2(740,18)+right,Vector2(140,36)))
		view.label(Vector2(754,42)+right,"%06d" % game.score,21,CYAN)
		view.panel(Rect2(Vector2(893,18)+right,Vector2(43,36)))
		view.draw_line(Vector2(907,28)+right,Vector2(907,44)+right,CYAN,3)
		view.draw_line(Vector2(921,28)+right,Vector2(921,44)+right,CYAN,3)
	if game.pickup_notice_age>0:view.label(Vector2(405,145),game.pickup_notice,18,Color("f5d99b"))
	var stick_center=game.TouchLayout.stick_center(game.button_scale,safe)
	var stick_radius=game.TouchLayout.stick_radius(game.button_scale)
	var stick_alpha=minf(1.0,game.button_opacity*1.3) if game.level.id=="redrock" else game.button_opacity
	view.draw_circle(stick_center,stick_radius,Color(0.02,0.07,0.11,stick_alpha*0.8))
	view.draw_arc(stick_center,stick_radius,0,TAU,48,Color(0.3,0.86,0.92,stick_alpha),2)
	view.draw_arc(stick_center,stick_radius*0.23,0,TAU,24,Color(0.3,0.86,0.92,stick_alpha*0.3),1)
	view.draw_line(stick_center-Vector2(stick_radius-8,0),stick_center+Vector2(stick_radius-8,0),Color(0.3,0.86,0.92,stick_alpha*0.15),1)
	view.draw_line(stick_center-Vector2(0,stick_radius-8),stick_center+Vector2(0,stick_radius-8),Color(0.3,0.86,0.92,stick_alpha*0.15),1)
	for angle in [0.0,PI/2,PI,-PI/2]:
		view.draw_set_transform(stick_center+Vector2.from_angle(angle)*stick_radius*0.77,angle)
		view.draw_colored_polygon(PackedVector2Array([Vector2(5,0),Vector2(-4,-5),Vector2(-4,5)]),Color(0.4,0.9,0.95,stick_alpha*0.65))
	view.draw_set_transform(Vector2.ZERO)
	var knob=stick_center+game.stick_offset*0.65
	view.draw_circle(knob,22*game.button_scale,Color(0.2,0.6,0.7,stick_alpha*0.6))
	view.draw_arc(knob,22*game.button_scale,0,TAU,24,CYAN*Color(1,1,1,stick_alpha),2)
	for item in game.control_buttons():
		if item[1] in ["left","right","up","down"]: continue
		var center=item[0]
		var action=item[1]
		var active=game.pressed(action)
		var radius=game.TouchLayout.radius(action,game.button_scale)
		var alpha=minf(1.0,game.button_opacity*1.3) if game.level.id=="redrock" else game.button_opacity
		var color=Color(0.3,0.86,0.92,minf(1,alpha+(0.25 if active else 0)))
		view.draw_circle(center,radius,Color(0.02,0.07,0.11,alpha*(0.95 if active else 0.75)))
		view.draw_arc(center,radius,0,TAU,32,color,2)
		view.draw_arc(center,radius-4,-0.7,0.7,12,color,2)
		if action in ["left","right","up","down"]:
			var angle={"right":0.0,"down":PI/2,"left":PI,"up":-PI/2}[action]
			view.draw_set_transform(center,angle)
			view.draw_colored_polygon(PackedVector2Array([Vector2(9,0),Vector2(-6,-8),Vector2(-6,8)]),color)
			view.draw_set_transform(Vector2.ZERO)
		else:
			if game.level.id=="redrock":
				draw_action_icon(view,center,action,color)
			elif action=="fire":
				view.draw_line(center+Vector2(-5,-18),center+Vector2(9,-5),color,6)
				view.draw_line(center+Vector2(5,-20),center+Vector2(14,-11),color,3)
			else:
				view.draw_line(center+Vector2(0,-3),center+Vector2(0,-20),color,3)
				view.draw_polyline(PackedVector2Array([center+Vector2(-7,-13),center+Vector2(0,-20),center+Vector2(7,-13)]),color,3)
			view.label(center+Vector2(-16,17),"射击" if action=="fire" else "跳跃",16,color)

static func draw_redrock_top(view: Node,game: Node,left: Vector2,top: Vector2,right: Vector2):
	view.panel(Rect2(Vector2(14,8)+left,Vector2(248,53)))
	view.label(Vector2(28,29)+left,"钢铁突围 / IRON BREAKOUT",16,Color("e6f7fa"))
	weapon_icon(view,Vector2(30,46)+left,game.weapon_id)
	view.label(Vector2(179,49)+left,game.weapons.title(game),13,Color("d3e8eb"))
	if game.rapid_fire:view.label(Vector2(237,49)+left,"R",13,Color("b0f274") if game.weapon_id!="laser" else Color("617463"))
	for i in range(3):
		var q=Vector2(92+i*26,39)+left
		view.draw_colored_polygon(PackedVector2Array([q+Vector2(4,0),q+Vector2(23,0),q+Vector2(19,10),q+Vector2(0,10)]),CYAN if i<game.hp else Color("283e48"))
	view.panel(Rect2(Vector2(335,8)+top,Vector2(290,49)))
	view.label(Vector2(398,29)+top,"03 赤岩瀑布",22,Color("defbff"))
	view.label(Vector2(353,48)+top,"向上突击 · "+("断崖要塞" if game.boss_active else "%s %d%%"%[game.level.section_at(game.player).title,clampi(int(game.highest_climb/2640*100),0,100)]),13,Color("b3d7e0"))
	view.panel(Rect2(Vector2(755,17)+right,Vector2(130,35)))
	view.label(Vector2(771,42)+right,"%06d"%game.score,24,Color("dcfaff"))
	view.panel(Rect2(Vector2(893,18)+right,Vector2(43,36)))
	for x in [907,921]:view.draw_line(Vector2(x,28)+right,Vector2(x,44)+right,CYAN,3)

static func draw_action_icon(view: Node,c: Vector2,action: String,color: Color):
	if action=="fire":
		view.draw_line(c+Vector2(-23,-12),c+Vector2(24,-12),color,5)
		view.draw_line(c+Vector2(-18,-13),c+Vector2(-25,-9),color,5)
		view.draw_line(c+Vector2(-4,-10),c+Vector2(-9,0),color,4)
		view.draw_line(c+Vector2(8,-10),c+Vector2(13,-2),color,4)
		view.draw_line(c+Vector2(13,-17),c+Vector2(17,-17),color,3)
	else:
		view.draw_circle(c+Vector2(5,-25),4,color)
		for pair in [[Vector2(3,-19),Vector2(-3,-8)],[Vector2(2,-17),Vector2(12,-13)],[Vector2(-1,-15),Vector2(-10,-19)],[Vector2(-3,-8),Vector2(8,-3)],[Vector2(-3,-8),Vector2(-13,1)]]:view.draw_line(c+pair[0],c+pair[1],color,3)
