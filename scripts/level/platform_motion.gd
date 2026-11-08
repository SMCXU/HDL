extends RefCounted
# Analytic horizontal motion; no physics bodies or unbounded transient nodes.
var entries: Array=[]
var surfaces: Array=[]
var clock=0.0
var rider=""
func reset(level: Resource):
	clock=0;rider="";entries=level.moving_data.duplicate(true);surfaces.clear()
	for p in entries:
		p.rect=Rect2(p.center-Vector2(p.width/2,0),Vector2(p.width,16));p.delta=0.0
		surfaces.append(p.rect)
func step(game: Node,dt: float):
	clock+=dt
	for i in range(entries.size()):
		var p=entries[i];var old: Rect2=p.rect
		var shift=sin(clock*p.speed/p.amplitude)*p.amplitude
		p.rect=Rect2(p.center+Vector2(shift-p.width/2,0),old.size);p.delta=p.rect.position.x-old.position.x
		surfaces[i]=p.rect
		if rider==p.id:
			if game.velocity.y==0 and absf(game.player.y-old.position.y)<1 and game.player.x>=old.position.x-9 and game.player.x<=old.end.x+9:
				game.player.x+=p.delta
			else:rider=""
func landed(feet: Vector2):
	rider=""
	for p in entries:
		if absf(feet.y-p.rect.position.y)<.5 and feet.x>p.rect.position.x-9 and feet.x<p.rect.end.x+9:rider=p.id;return
func is_moving_height(y: float) -> bool:
	for p in entries:
		if absf(y-p.rect.position.y)<1:return true
	return false
func route_point(index: int,fallback: Vector2) -> Vector2:
	for p in entries:
		if p.route_index==index:return Vector2(p.rect.get_center().x,p.rect.position.y)
	return fallback
