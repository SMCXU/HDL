extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
func _initialize():call_deferred("record")
func record():
	root.size=Vector2i(960,540)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false);game.set_physics_process(false)
	for section in ["climb","boss"]:
		var path="res://work/vertical/motion/"+section
		DirAccess.make_dir_recursive_absolute(path)
		game.start_level("spillway",true)
		for target in game.encounters.targets:target.hp=0;game.destroyed_targets[target.id]=true
		game.encounters.refresh_gate(game)
		game.player=game.level.spawn if section=="climb" else game.level.boss_checkpoint
		game.CameraDirector.update(game,0,true)
		for frame in range(120 if section=="climb" else 225):
			if game.mode=="paused":game.mode="playing"
			for step in range(4):
				game.invincible=2
				game.touches[-9001]=Policy.actions(game)
				if game.mode=="playing":game.step(1.0/60)
				else:game._process(1.0/60)
			game.get_node("GameView").queue_redraw()
			await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(path+"/%04d.png" % frame)
	var info=FileAccess.open("res://work/vertical/motion/metadata.json",FileAccess.WRITE)
	info.store_string(JSON.stringify({"type":"desktop rendered sequence at 15 sampled frames per simulated second; isolated scene setups; invulnerable input replay; not Android video, human play or performance evidence"}));info.close()
	game.audio.shutdown();await create_timer(.3).timeout;game.queue_free();await create_timer(.4).timeout;quit()
