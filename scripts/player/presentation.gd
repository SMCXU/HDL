extends RefCounted
var clock = 0.0
var state = "idle"
var state_age = 0.0
var hurt_remaining = 0.0
var landing_remaining = 0.0
var shot_remaining = 0.0
var previous_crouch = false
var rise_remaining = 0.0

func reset():
	clock = 0
	state = "idle"
	state_age = 0
	hurt_remaining = 0
	landing_remaining = 0
	shot_remaining = 0
	previous_crouch = false
	rise_remaining = 0

func update(dt: float,velocity: Vector2,crouch: bool,dead: bool):
	clock += dt
	hurt_remaining = maxf(0,hurt_remaining-dt)
	landing_remaining = maxf(0,landing_remaining-dt)
	shot_remaining = maxf(0,shot_remaining-dt)
	rise_remaining = maxf(0,rise_remaining-dt)
	if previous_crouch and not crouch: rise_remaining = 0.18
	previous_crouch = crouch
	var next = "idle"
	if dead: next = "dead"
	elif hurt_remaining>0: next = "hurt"
	elif velocity.y < -10: next = "jump"
	elif velocity.y > 10: next = "fall"
	elif crouch: next = "crouch"
	elif rise_remaining>0: next = "rise"
	elif landing_remaining>0: next = "land"
	elif absf(velocity.x)>1: next = "run"
	if next != state:
		state = next
		state_age = 0
	else: state_age += dt

func frame() -> int:
	match state:
		"run": return 1+int(clock*12)%6
		"jump": return 7
		"fall": return 8
		"land": return 24+mini(3,int(state_age*24))
		"crouch": return 28+mini(3,int(state_age*24))
		"rise": return 32+mini(3,int(state_age*24))
		"hurt": return 14
		"dead": return mini(19,15+int(state_age*9))
	return 20+int(clock*5)%4
