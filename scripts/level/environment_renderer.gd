extends RefCounted
# Texture modules use separate parallax rates. Mirror adjacent tiles so their edges match.
static func repeat_texture(view: Node,texture: Texture2D,source: Rect2,y: float,width: float,height: float,scroll: float,tint: Color):
	var first=int(floor(scroll/width))
	var remainder=fposmod(scroll,width)
	for i in range(-1,3):
		var x=i*width-remainder
		var mirrored=(first+i)%2!=0
		view.draw_set_transform(Vector2(x+width if mirrored else x,y),0,Vector2(-1 if mirrored else 1,1))
		view.sprite(texture,source,Rect2(0,0,width,height),tint)
	view.draw_set_transform(Vector2.ZERO)

static func draw(view: Node,game: Node):
	var cam=game.camera_x-view.shake_x()
	var sector=game.level.section(game.player.x)
	var second=game.level.sectors[1].start_x
	var third=game.level.sectors[2].start_x
	var tint=Color(0.82,0.90,1)
	if game.player.x>third-200:
		tint=Color(1,0.88,0.72).lerp(Color(1,0.65,0.65),clampf((game.player.x-third+200)/400,0,1))
	elif game.player.x>second-200:
		tint=Color(0.82,0.90,1).lerp(Color(1,0.88,0.72),clampf((game.player.x-second+200)/400,0,1))
	repeat_texture(view,view.backdrop,Rect2(Vector2.ZERO,view.backdrop.get_size()),0,960,540,cam*0.16,tint)
	# Midground authored steel supports/pipes, independent of skyline and physics.
	var support: Rect2=view.structure_regions[0]
	var support_source=Rect2(support.position+Vector2(0,42),support.size-Vector2(0,42))
	repeat_texture(view,view.structures,support_source,330,330,105,cam*0.55,Color(0.38,0.47,0.58,0.78))
	for i in range(3):
		var x=fposmod(i*420-cam*0.35,1260)-100
		var sweep=sin(game.time*0.25+i)*100
		view.draw_colored_polygon(PackedVector2Array([Vector2(x,173),Vector2(x+140+sweep,310),Vector2(x+230+sweep,310)]),Color(0.4,0.7,0.95,0.04))
		if not game.low_effects:
			for j in range(2):
				var age=fposmod(game.time*0.2+j*0.5,1)
				view.EffectRenderer.frame(view,6+int(age*2.9),Rect2(x+65+sin(age*4)*8,370-age*65,38+age*22,30+age*20),Color(0.8,0.85,0.9,(1-age)*0.24))
		if sector.start_x>=second:
			var point=Vector2(x+130,240)
			view.draw_line(point-Vector2(65,0),point+Vector2(65,0),Color("536474"),3)
			view.draw_line(point,point+Vector2(0,45+sin(game.time+i)*5),Color("9a8b5c"),2)
		if sector.start_x>=third:
			view.draw_circle(Vector2(x,173),7,Color(1,0.2,0.1,0.10+sin(game.time*5)*0.08))
	# World layer: ground top coincides with the collision plane.
	for i in range(6):
		var x=i*200-fposmod(cam,200)
		view.sprite(view.structures,view.structure_regions[0],Rect2(x,435,201,105))
	var gate=view.world(Vector2(game.level.gate_x,435))
	if gate.x<1150 and gate.x> -250:
		view.sprite(view.structures,view.structure_regions[2],Rect2(gate.x-110,180,220,255))
