extends RefCounted
const AMBER=Color("ffbc59")
static func part(view: Node,index: int,r: Rect2,tint=Color.WHITE):view.sprite(view.redrock_atlas,view.redrock_regions[index],r,tint)
static func ledge(view: Node,r: Rect2,moving=false,solid=false):
	var height=100.0 if solid else clampf(r.size.x*.29,48,90)
	part(view,3 if solid else 1 if moving else 0,Rect2(r.position-Vector2(0,2),Vector2(r.size.x,height)))
	view.draw_line(r.position,r.position+Vector2(r.size.x,0),Color("edba73"),1)
static func draw(view: Node,game: Node):
	view.draw_texture_rect(view.redrock_backdrop,Rect2(0,-65+fposmod(game.camera_y*.025,25),960,640),false)
	# Animated mist flecks are deliberately subtle: the static art supplies detail.
	if not game.low_effects:
		for i in range(14):
			var p=Vector2(410+sin(i*4.2+game.time*.4)*140,fposmod(i*43+game.time*30,600)-30)
			view.draw_line(p,p+Vector2(-2,9),Color(.6,.95,1,.12),1)
	for r in game.level.floor_rects:
		if absf(r.position.y-game.camera_y-270)<430:ledge(view,Rect2(view.world(r.position),r.size),false,true)
	for p in game.platform_motion.entries:
		var r=Rect2(view.world(p.rect.position),p.rect.size)
		if r.position.y< -100 or r.position.y>650:continue
		ledge(view,r,true)
		var start=view.world(p.center-Vector2(p.amplitude,0));var end=view.world(p.center+Vector2(p.amplitude,0))
		view.draw_line(start+Vector2(0,18),end+Vector2(0,18),Color(.3,.85,.95,.25),1)
		for sign_dir in [-1,1]:
			var q=r.get_center()+Vector2(sign_dir*(r.size.x/2+14),0)
			view.draw_line(q-Vector2(sign_dir*6,0),q+Vector2(sign_dir*6,0),Color("68e4e9"),2)
			view.draw_polyline(PackedVector2Array([q+Vector2(0,-4),q+Vector2(sign_dir*6,0),q+Vector2(0,4)]),Color("68e4e9"),2)
	for h in game.rockfalls.entries:
		if h.state in ["warning","fall"]:
			var q=view.world(h.area.position)
			view.draw_rect(Rect2(q,h.area.size),Color(1,.65,.2,.16),true)
			view.draw_rect(Rect2(q+Vector2(0,h.area.size.y-10),Vector2(h.area.size.x,10)),AMBER,false,2)
			view.label(q+Vector2(-18,-8),"! 落石",13,AMBER)
			if h.state=="fall":part(view,4,Rect2(view.world(h.pos)-Vector2(16,16),Vector2(32,32)))
	for h in game.hazards.entries:
		var q=view.world(h.area.position);var r=Rect2(q,h.area.size)
		if not r.intersects(Rect2(0,90,960,450)):continue
		part(view,5,Rect2(q+Vector2(-4,h.area.size.y-26),Vector2(58,45)))
		if h.state in ["warning","active"]:
			view.draw_rect(r,AMBER if h.state=="warning" else Color("ff764b"),false,2)
			view.label(q+Vector2(0,-8),"! 热流" if h.state=="warning" else "! 危险",13,AMBER)
			if h.state=="active":view.EffectRenderer.frame(view,7,r,Color(1,.65,.25,.8))
static func boss(view: Node,game: Node):
	var b=game.citadel;var fy=game.level.boss_checkpoint.y
	var texture=view.redrock_boss
	view.draw_texture_rect(texture,Rect2(view.world(Vector2(180,fy-245)),Vector2(600,245)),false,Color(.5,.45,.4) if game.boss_defeated else Color.WHITE)
	if game.boss_defeated:return
	var boxes=b.boxes(game)
	for i in range(2):
		var r=Rect2(view.world(boxes[i].position),boxes[i].size)
		if b.ports[i]<=0:view.draw_rect(r,Color(.08,.1,.12,.83));view.label(r.position+Vector2(0,30),"已停火",12,Color("8b9698"))
		elif game.boss_active:view.draw_line(r.position-Vector2(0,5),r.position+Vector2(r.size.x*b.ports[i]/b.PORT_HP,-5),AMBER,3)
	var core=Rect2(view.world(boxes[2].position),boxes[2].size)
	if not b.core_open():
		view.draw_rect(core,Color(.1,.15,.18,.9))
		view.draw_line(core.position+Vector2(8,0),core.end-Vector2(8,0),Color("355c67"),2)
	else:view.draw_rect(core,Color("66e9ea"),false,2)
	if b.age<1 and game.boss_active:
		var origin=view.world(boxes[b.cycle%2].get_center())
		if b.ports[b.cycle%2]>0:view.draw_circle(origin,17,Color(1,.6,.2,.3))
	if b.core<=25 and b.cycle%2==1 and b.age<1.65:
		var q=view.world(Vector2(b.strike_x,fy))
		view.draw_rect(Rect2(q-Vector2(20,200),Vector2(40,200)),AMBER,false,2)
		if b.age>=1.1:part(view,4,Rect2(q+Vector2(-15,-215+(b.age-1.1)*340),Vector2(30,30)))
	view.label(Vector2(335,86),"崖心堡垒 · "+("核心开放" if b.core_open() else "装甲蓄能"),17,AMBER)
	view.rect(Rect2(335,93,290,7),Color("283b43"));view.rect(Rect2(335,93,290*maxf(0,b.core)/b.CORE_HP,7),Color("f1a252"))
