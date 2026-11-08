extends RefCounted
const AMBER=Color("ffbe57")
static func part(view: Node,index: int,rect: Rect2,tint=Color.WHITE):
	view.sprite(view.spillway_atlas,view.spillway_regions[index],rect,tint)
static func deck(view: Node,rect: Rect2):
	if rect.size.x>=400:
		var source: Rect2=view.spillway_regions[0]
		view.sprite(view.spillway_atlas,Rect2(source.position+Vector2(0,128),Vector2(source.size.x,85)),Rect2(rect.position-Vector2(0,2),Vector2(rect.size.x+1,34)),Color(.75,.86,.9))
	else:part(view,0,Rect2(rect.position-Vector2(0,57),Vector2(rect.size.x+1,110)))
	view.draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("92c0c7"),1)
static func draw(view: Node,game: Node):
	var cam=Vector2(game.camera_x-view.shake_x(),game.camera_y)
	view.EnvironmentRenderer.repeat_texture(view,view.spillway_backdrop,Rect2(Vector2.ZERO,view.spillway_backdrop.get_size()),-55,1152,768,cam.x*.12,Color(.68,.77,.87))
	# Fixed-width shaft: walls scroll vertically while the camera never pans sideways.
	for x in [8,850]:
		for row in range(int(floor(cam.y/250))-1,int(floor(cam.y/250))+4):
			part(view,1,Rect2(x,row*250-cam.y,102,250),Color(.62,.72,.79))
	var mist_shift=sin(game.time*.45)*10
	part(view,5,Rect2(375+mist_shift,-80,220,760),Color(.55,.7,.86,.22 if game.low_effects else .34))

	for floor_rect in game.level.floor_rects:
		if floor_rect.position.y-cam.y< -120 or floor_rect.position.y-cam.y>650:continue
		var first=maxf(floor_rect.position.x,floor(cam.x/200)*200)
		var x=first
		while x<minf(floor_rect.end.x,cam.x+1160):
			var width=minf(200,floor_rect.end.x-x)
			deck(view,Rect2(view.world(Vector2(x,floor_rect.position.y)),Vector2(width,18)))
			x+=width
	for t in game.encounters.targets:
		var q=view.world(t.pos)
		if not Rect2(-120,-120,1200,780).has_point(q):continue
		part(view,2,Rect2(q-Vector2(34,82),Vector2(68,82)),Color.WHITE if t.hp>0 else Color(.27,.35,.4))
		if t.hp>0:
			view.label(q-Vector2(42,93),"维护继电器" if t.id=="relay" else "供能节点",13,AMBER)
			view.rect(Rect2(q-Vector2(25,88),Vector2(50*float(t.hp)/t.max_hp,3)),AMBER)
		else:view.label(q-Vector2(22,88),"已断电",13,Color("66d7d8"))
	for h in game.hazards.entries:
		var area=Rect2(view.world(h.area.position),h.area.size)
		if not area.intersects(Rect2(-120,-120,1200,780)):continue
		if h.kind=="vent":
			var source: Rect2=view.spillway_regions[3]
			view.sprite(view.spillway_atlas,Rect2(source.position+Vector2(0,170),Vector2(260,232)),Rect2(area.position.x,area.end.y-25,60,50),Color(.7,.8,.9))
		else:part(view,4,Rect2(area.position.x,area.end.y-25,area.size.x,42),Color.WHITE if h.state=="active" else Color(.35,.4,.45))
		if h.state=="warning" or h.state=="active":
			var color=AMBER if h.state=="warning" else Color("ff7152")
			view.draw_rect(area,color,false,2)
			view.label(area.position+Vector2(0,-9),"! 预警" if h.state=="warning" else "! 危险",13,color)
			if h.kind=="vent" and h.state=="active":view.EffectRenderer.frame(view,7,area,Color(.75,.86,.95,.5))
	# Fixed-size rain buffer: no node or particle allocations during play.
	for i in range(18 if game.low_effects else 52):
		var x=fposmod(i*149.3-game.time*62,1020)-30
		var y=fposmod(i*71.8+game.time*320,580)-20
		view.draw_line(Vector2(x,y),Vector2(x-5,y+16),Color(.57,.76,.88,.15),1)
static func boss(view: Node,game: Node):
	var w=game.warden;var p=view.world(game.level.boss_position);var floor_y=game.level.boss_checkpoint.y
	part(view,6,Rect2(p+Vector2(-36,0),Vector2(200,255)),Color(.35,.4,.45) if game.boss_defeated else Color.WHITE)
	for i in range(2):
		var origin=view.world(w.muzzle(game,i==1))
		if w.arms[i]>0:
			var region: Rect2=view.spillway_regions[7+i]
			part(view,7+i,Rect2(origin-Vector2(5,39),region.size*.5))
			if game.boss_active:
				view.draw_line(origin+Vector2(15,-25),origin+Vector2(15+w.arms[i]*5,-25),AMBER,3)
		elif not game.boss_defeated:part(view,7+i,Rect2(origin+Vector2(30,5),Vector2(80,42)),Color(.3,.35,.4,.7))
	if game.boss_defeated:return
	if game.boss_intro>0:view.label(Vector2(365,145),"潮汐守卫 · 武装启动",20,AMBER)
	if w.attack=="fan":
		var origin=view.world(w.muzzle(game))
		view.draw_circle(origin,10,Color(1,.65,.2,.4));view.label(origin+Vector2(-75,-26),"扇形扫射",14,AMBER)
	elif w.attack=="laser":
		var origin=view.world(w.muzzle(game,true));var target=view.world(w.lock_point)
		var live=w.age>=w.SPEC.laser_track+w.SPEC.laser_lock
		view.draw_line(origin,target,Color("ff8055") if live else AMBER,8 if live else 2)
		view.draw_circle(target,13,AMBER,false,2);view.label(target+Vector2(-25,-24),"锁定" if w.locked else "追踪",14,AMBER)
	elif w.attack=="wave":
		var q=view.world(Vector2(game.level.boss_position.x-190,floor_y))
		view.draw_line(q,q-Vector2(110,0),AMBER,3);view.label(q-Vector2(150,20),"低位冲击 · 跳跃",14,AMBER)
	elif w.attack=="strike":
		for x in [w.strike_x,minf(game.level.boss_position.x-120,w.strike_x+220)]:
			var q=view.world(Vector2(x,floor_y))
			var color=Color("ff8055") if w.age>=w.SPEC.strike_warning else AMBER
			view.draw_rect(Rect2(q-Vector2(30,200),Vector2(60,200)),color,false,2)
			view.label(q-Vector2(30,210),"落点锁定",13,color)
	view.label(Vector2(330,83),"潮汐守卫 · "+("核心超载" if w.core<=24 else "核心暴露" if w.arms[0]<=0 and w.arms[1]<=0 else "双臂武装"),18,AMBER)
	view.rect(Rect2(330,91,300,9),Color("283644"));view.rect(Rect2(330,91,300*float(game.boss_hp)/72,9),Color("f18a52"))
