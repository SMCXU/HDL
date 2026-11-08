extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(960,540);DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	for section in ["ferry","drop","boss"]:
		game.start_level("redrock",true)
		if section=="ferry":game.player=game.level.climb_route[16];game.replay_route_index=17
		elif section=="drop":
			var p=game.platform_motion.entries[0];game.player=Vector2(p.rect.get_center().x,p.rect.position.y);game.platform_motion.landed(game.player)
		else:game.player=game.level.boss_checkpoint
		game.highest_climb=game.level.spawn.y-game.player.y;game.CameraDirector.update(game,0,true)
		var path="res://work/level03/motion/"+section
		DirAccess.make_dir_recursive_absolute(path)
		for frame in range(90 if section=="ferry" else 40 if section=="drop" else 150):
			game.mode="playing"
			for substep in range(4):
				game.invincible=2
				game.touches[-9001]="down+jump" if section=="drop" else Policy.actions(game)
				game.step(1.0/60)
			game.get_node("GameView").queue_redraw();await process_frame;RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(path+"/%04d.png"%frame)
	var f=FileAccess.open("res://work/level03/motion/metadata.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"validation_type":"desktop actual rendered sequences; 4 fixed steps per frame =15 sampled frames per simulated second; isolated scene setups and invulnerability, not phone video/manual play or performance"}));f.close()
	game.audio.shutdown();await create_timer(.25).timeout;game.queue_free();await create_timer(.5).timeout;quit()
