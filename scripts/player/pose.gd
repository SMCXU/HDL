extends RefCounted
# Shared by projectiles, sprite placement, muzzle flash and diagnostic overlays.
const BODY_HEIGHT = 56.0
static func aim(facing: int,up: bool,moving: bool) -> Vector2:
	if up: return Vector2(facing if moving else 0,-1).normalized()
	return Vector2(facing,0)

const PROFILE=preload("res://resources/player_pose.tres")
static func frame_for(state_frame: int,up: bool,moving: bool) -> int:
	return (12 if moving else 13) if up else state_frame

static func muzzle(position: Vector2,facing: int,crouch: bool,up: bool,moving: bool,state_frame=0) -> Dictionary:
	var direction = aim(facing,up,moving)
	var frame=frame_for(state_frame,up,moving)
	var offset=(PROFILE.muzzles[frame]-PROFILE.feet[frame])*PROFILE.scales[frame]
	offset.x*=facing
	if crouch and up: offset.y+=12
	return {"position":position+offset,"direction":direction}
