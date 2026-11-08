@tool
extends SceneTree
func _initialize():
	var settings = EditorInterface.get_editor_settings()
	settings.set_setting("export/android/android_sdk_path",OS.get_environment("ANDROID_SDK_ROOT"))
	settings.set_setting("export/android/java_sdk_path",OS.get_environment("HDL_JAVA_PATH"))
	settings.set_setting("export/android/debug_keystore",ProjectSettings.globalize_path("res://work/debug.keystore"))
	settings.set_setting("export/android/debug_keystore_user","androiddebugkey")
	settings.set_setting("export/android/debug_keystore_pass","android")
	ResourceSaver.save(settings,settings.resource_path)
	quit()
