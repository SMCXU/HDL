extends SceneTree
func _initialize():
	var f = FileAccess.open("res://assets/licenses/Godot.txt",FileAccess.WRITE)
	f.store_string(Engine.get_license_text()+"\n\nTHIRD PARTY LICENSES\n\n"+JSON.stringify(Engine.get_license_info(),"  ")+"\n\nCOPYRIGHTS\n\n"+JSON.stringify(Engine.get_copyright_info(),"  "))
	f.close()
	quit()
