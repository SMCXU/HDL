extends RefCounted
# Static spatial buckets retain all support geometry, including surfaces below the camera.
var buckets={}
var dynamic_surfaces: Array=[]
func rebuild(level: Resource):
	buckets.clear()
	var surfaces=level.all_platforms()
	surfaces.append_array(level.floor_rects)
	for r in surfaces:
		for bx in range(int(floor(r.position.x/256)),int(floor(r.end.x/256))+1):
			var key=Vector2i(bx,int(floor(r.position.y/256)))
			if not buckets.has(key):buckets[key]=[]
			buckets[key].append(r)
func near(position: Vector2) -> Array:
	var result=[]
	var bx=int(floor(position.x/256));var by=int(floor(position.y/256))
	for x in range(bx-1,bx+2):
		for y in range(by-1,by+2):
			for r in buckets.get(Vector2i(x,y),[]):
				if not result.has(r):result.append(r)
	for r in dynamic_surfaces:
		if absf(r.position.y-position.y)<300:result.append(r)
	return result

func can_drop(level: Resource,feet: Vector2) -> bool:
	if not level.allow_platform_drop:return false
	# A solid surface wins over any overlapping one-way rectangles.
	for r in level.floor_rects+level.solid_platforms:
		if absf(r.position.y-feet.y)<1 and feet.x>r.position.x-9 and feet.x<r.end.x+9:return false
	for r in near(feet):
		if absf(r.position.y-feet.y)<1 and feet.x>r.position.x-9 and feet.x<r.end.x+9:return true
	return false
