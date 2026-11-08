extends SceneTree
# Actual desktop viewport plus fixed-step input; no human/device timing claim.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(960,540)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.start_level("spillway",true)
	game.player=game.level.climb_route[8];game.velocity=Vector2.ZERO
	game.highest_climb=520;game.CameraDirector.update(game,0,true)
	var out="res://work/drop-through/visual/"
	DirAccess.make_dir_recursive_absolute(out)
	var states=[]
	for frame in range(21):
		if frame>0:
			game.touches[0]="down+jump"
			for step in range(2):game.PlayerController.step(game,1.0/60)
		game.get_node("GameView").queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(out+"%02d.png"%frame)
		states.append({"frame":frame,"feet":game.player,"velocity":game.velocity,"ignored_y":str(game.drop_platform_y)})
	var file=FileAccess.open(out+"states.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"validation_type":"desktop rendered fixed-step drop fixture, no battle; not Android or human input","states":states}));file.close()
	game.audio.shutdown();await create_timer(.25).timeout;game.queue_free();await create_timer(.5).timeout;quit()
