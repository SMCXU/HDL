extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
var game: Node
func _initialize(): call_deferred("run")
func run():
	var save_path="user://settings.cfg"
	var had_save=FileAccess.file_exists(save_path)
	var previous_save=FileAccess.get_file_as_string(save_path) if had_save else ""
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_level("iron_factory",true)
	var samples=[]
	var previous=0
	for frame in range(60*600):
		# Explicitly invulnerable logical route validation. Not real-time GPU or human performance.
		game.invincible=2.0
		game.touches[-9001]=Policy.actions(game)
		game.step(1.0/60)
		if game.encounters.index!=previous:
			previous=game.encounters.index
			samples.append({"arena":previous,"elapsed_s":game.elapsed,"x":game.player.x})
		if game.mode=="won": break
	var report={"validation_type":"accelerated logical input replay; invulnerable; not human timing or Android performance","result":game.mode,"elapsed_s":game.elapsed,"arenas_completed":game.encounters.index,"arenas_total":game.encounters.arenas.size(),"player_x":game.player.x,"enemies_remaining":game.enemies.size(),"weapon_spread":game.weapon,"progress":samples}
	DirAccess.make_dir_recursive_absolute("res://work/continuation")
	var file=FileAccess.open("res://work/continuation/route-check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print(JSON.stringify(report))
	if had_save:
		var restore=FileAccess.open(save_path,FileAccess.WRITE)
		restore.store_string(previous_save)
		restore.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	game.queue_free()
	await create_timer(.3).timeout
	quit(0 if report.result=="won" else 1)
