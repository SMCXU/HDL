extends RefCounted
# One continuous direction surface, two separated action surfaces. No overlapping D-pad targets.
static func radius(action: String,scale: float) -> float:
	return (50.0 if action=="fire" else 44.0 if action=="jump" else 20.0)*scale
static func stick_radius(scale: float) -> float:
	return 67.0*scale
static func stick_center(scale: float,insets=Vector4.ZERO) -> Vector2:
	var r=stick_radius(scale)
	return Vector2(maxf(112,r+18)+insets.x,minf(460,540-r-8)-insets.w)
static func buttons(scale: float,insets=Vector4.ZERO) -> Array:
	var center=stick_center(scale,insets)
	var gap=stick_radius(scale)*0.65
	return [[center-Vector2(gap,0),"left"],[center+Vector2(gap,0),"right"],
		[center-Vector2(0,gap),"up"],[center+Vector2(0,gap),"down"],
		[Vector2(741-insets.z,410-insets.w),"jump"],[Vector2(884-insets.z,minf(478,540-radius("fire",scale)-8)-insets.w),"fire"]]
static func stick_vector(p: Vector2,scale: float,insets=Vector4.ZERO) -> Vector2:
	return (p-stick_center(scale,insets)).limit_length(stick_radius(scale))
static func stick_action(p: Vector2,previous: String,scale: float,insets=Vector4.ZERO) -> String:
	var offset=(p-stick_center(scale,insets))/stick_radius(scale)
	if offset.length()<0.23: return ""
	var actions=PackedStringArray()
	# Enter/exit thresholds differ: light wobble does not toggle directions.
	var x_threshold=0.22 if previous.contains("left") or previous.contains("right") else 0.36
	var y_threshold=0.34 if previous.contains("up") or previous.contains("down") else 0.55
	if absf(offset.x)>x_threshold: actions.append("right" if offset.x>0 else "left")
	if absf(offset.y)>y_threshold: actions.append("down" if offset.y>0 else "up")
	return "+".join(actions)
static func action_at(p: Vector2,scale: float,insets=Vector4.ZERO) -> String:
	if Rect2(893-insets.z,18+insets.y,43,36).has_point(p): return "pause"
	for item in buttons(scale,insets):
		if item[1] in ["fire","jump"] and p.distance_to(item[0])<=radius(item[1],scale): return item[1]
	if p.distance_to(stick_center(scale,insets))<=stick_radius(scale): return stick_action(p,"",scale,insets)
	return ""
