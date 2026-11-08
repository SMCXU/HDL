extends RefCounted
var entries: Array=[]
func reset(level: Resource):
	entries=level.hazard_data.duplicate(true)
	for h in entries:
		h.age=0.0;h.state="idle"
func step(game: Node,dt: float):
	for h in entries:
		if game.boss_active or game.boss_defeated or game.destroyed_targets.has(h.source):
			h.state="disabled";continue
		if h.area.get_center().distance_to(game.player)>1100:continue
		h.age+=dt
		var duration=0.65
		match h.state:
			"warning":duration=h.warning
			"active":duration=h.active
			"cooldown":duration=h.cooldown
		if h.age>=duration:
			h.age=0
			h.state={"idle":"warning","warning":"active","active":"cooldown","cooldown":"idle"}.get(h.state,"idle")
			if h.state=="warning":game.audio.effect("warning")
		if h.state=="active" and h.area.intersects(Rect2(game.player-Vector2(10,43),Vector2(20,43))):game.hurt()
