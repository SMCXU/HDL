extends RefCounted
var entries: Array=[]
func reset(level: Resource):
	entries=level.rock_data.duplicate(true)
	for h in entries:h.state="idle";h.age=0.0;h.pos=h.area.position+Vector2(h.area.size.x/2,0)
func step(game: Node,dt: float):
	var visible=Rect2(80,game.camera_y+110,800,400)
	for h in entries:
		if game.boss_active or game.boss_defeated or not visible.encloses(h.area):
			h.state="idle";h.age=0.0;continue
		h.age+=dt
		if h.state=="idle" and h.age>.6:
			h.state="warning";h.age=0;game.audio.effect("stone_warning")
		elif h.state=="warning" and h.age>=h.warning:
			h.state="fall";h.age=0;h.pos=h.area.position+Vector2(h.area.size.x/2,0)
		elif h.state=="fall":
			h.pos.y+=h.speed*dt
			if Rect2(h.pos-Vector2(13,13),Vector2(26,26)).intersects(Rect2(game.player-Vector2(10,43),Vector2(20,43))):game.hurt()
			if h.pos.y>=h.area.end.y:
				h.state="cooldown";h.age=0;game.audio.effect("stone_impact");game.visual_effect(h.pos,"dust",.3)
		elif h.state=="cooldown" and h.age>=h.cooldown:h.state="idle";h.age=0
