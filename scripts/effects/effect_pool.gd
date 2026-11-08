extends RefCounted
# Fixed-capacity recycled event dictionaries; effects never own gameplay objects.
var active: Array=[]
var free: Array=[]
const CAPACITY=64
func emit(position: Vector2,kind: String,duration: float,delay=0.0,direction=Vector2.RIGHT):
	if active.size()>=CAPACITY:
		# Oldest decoration is expendable; gameplay bullets are not part of this pool.
		free.append(active.pop_front())
	var event: Dictionary=free.pop_back() if not free.is_empty() else {}
	event.assign({"pos":position,"kind":kind,"age":-delay,"duration":duration,"direction":direction})
	active.append(event)
func advance(dt: float):
	for i in range(active.size()-1,-1,-1):
		active[i].age+=dt
		if active[i].age>=active[i].duration: free.append(active.pop_at(i))
func clear():
	while not active.is_empty(): free.append(active.pop_back())
