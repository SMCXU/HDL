extends RefCounted
const Weapons=preload("res://scripts/weapons/weapon_director.gd")
static func pickups(view: Node,game: Node):
	for item in game.pickups:
		var q=view.world(item.pos)+Vector2(0,sin(game.time*5)*3)
		if not Rect2(-30,80,1020,490).has_point(q):continue
		var c: Color=Weapons.COLORS.get(item.kind,Color.WHITE)
		var polygon=PackedVector2Array([q+Vector2(-17,-10),q+Vector2(-11,-16),q+Vector2(12,-16),q+Vector2(17,-10),q+Vector2(17,10),q+Vector2(11,16),q+Vector2(-12,16),q+Vector2(-17,10)])
		view.draw_colored_polygon(polygon,Color("14212a"));polygon.append(polygon[0]);view.draw_polyline(polygon,c,2)
		view.draw_line(q+Vector2(-12,19),q+Vector2(12,19),c.darkened(.4),1)
		view.label(q+Vector2(-7,7),Weapons.LETTERS.get(item.kind,"?"),20,c)
static func projectiles(view: Node,game: Node):
	for b in game.bullets:
		var q=view.world(b.pos)
		if not Rect2(-40,-40,1040,620).has_point(q):continue
		if b.get("kind","")=="wave":
			view.draw_arc(q+Vector2(0,9),18,PI,TAU,16,Color("ffc65a"),4);continue
		var id=b.get("weapon_id","rifle")
		if b.friendly and id=="fireball":
			var dir: Vector2=b.vel.normalized()
			if not game.low_effects:
				view.draw_line(q-dir*25,q,Color(.8,.16,.05,.38),9)
				view.draw_circle(q,10,Color(.7,.1,.02,.18))
			view.draw_circle(q,7,Color("ac381a"));view.draw_circle(q-dir*2,5,Color("ff9a34"));view.draw_circle(q+dir*2,3,Color("fff0b0"))
			continue
		var color: Color=Weapons.COLORS.get(id,Color("ffd378")) if b.friendly else Color("ff6554")
		view.draw_line(q-b.vel.normalized()*(19 if id=="machine" and b.friendly else 14 if b.friendly else 9),q,color.darkened(.4),3)
		view.draw_circle(q,2 if b.friendly else 4,color);view.draw_circle(q,1.2,Color("fff3c9"))
	for beam in game.weapons.beams:
		var a=view.world(beam.from);var b=view.world(beam.to)
		var alpha=(1-beam.age/beam.life)*(.65 if game.reduced_flash else 1)
		view.draw_line(a,b,Color(.01,.12,.17,alpha),9)
		view.draw_line(a,b,Color(.2,.85,.9,alpha),4)
		view.draw_line(a,b,Color(.9,1,1,alpha),1.5)
