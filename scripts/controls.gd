extends RefCounted

static func pressed(action: String, touches: Dictionary) -> bool:
	for value in touches.values():
		if action in str(value).split("+"): return true
	match action:
		"left": return Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.get_joy_axis(0,JOY_AXIS_LEFT_X) < -0.35 or Input.is_joy_button_pressed(0,JOY_BUTTON_DPAD_LEFT)
		"right": return Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.get_joy_axis(0,JOY_AXIS_LEFT_X) > 0.35 or Input.is_joy_button_pressed(0,JOY_BUTTON_DPAD_RIGHT)
		"up": return Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.get_joy_axis(0,JOY_AXIS_LEFT_Y) < -0.4
		"down": return Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.get_joy_axis(0,JOY_AXIS_LEFT_Y) > 0.4
		"jump": return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0,JOY_BUTTON_A)
		"fire": return Input.is_physical_key_pressed(KEY_J) or Input.is_joy_button_pressed(0,JOY_BUTTON_X)
	return false

