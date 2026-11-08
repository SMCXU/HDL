extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
func _initialize():call_deferred("run")
func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.start_level("spillway",true)
	var jumps=[];var previous=game.level.spawn
	game.encounters.active=false
	var reachability_route=Array(game.level.climb_route)
	for target in reachability_route:
		game.player=previous;game.velocity=Vector2.ZERO;game.jump_was_down=false;game.coyote=.1;game.jump_buffer=0
		var reached=false
		for i in range(100):
			game.touches[0]="right" if game.player.x<target.x-2 else "left" if game.player.x>target.x+2 else ""
			if target.y<previous.y:game.touches[0]+="+jump"
			game.PlayerController.step(game,1.0/60)
			if game.velocity.y==0 and absf(game.player.y-target.y)<1 and absf(game.player.x-target.x)<12:reached=true;break
		jumps.append({"from":[previous.x,previous.y],"to":[target.x,target.y],"reached":reached,"camera_x":game.camera_x,"actual":[game.player.x,game.player.y]})
		previous=target
	game.start_level("spillway",true)
	var trace=[]
	for frame in range(60*300):
		game.invincible=2
		game.touches[-9001]=Policy.actions(game)
		game.step(1.0/60)
		if frame%300==0:trace.append({"s":game.elapsed,"position":[game.player.x,game.player.y],"velocity":[game.velocity.x,game.velocity.y],"route":game.replay_route_index,"mode":game.mode,"arms":game.warden.arms.duplicate(),"core":game.warden.core})
		if game.mode in ["won","dead"]:break
	var passed=true
	for j in jumps:passed=passed and j.reached
	var changes=0;var last_direction=0;var run_length=0;var longest_run=0;var max_dx=0.0;var prior=game.level.spawn
	for point in reachability_route:
		var direction=int(sign(point.x-prior.x))
		max_dx=maxf(max_dx,absf(point.x-prior.x))
		if direction!=last_direction:
			if last_direction!=0:changes+=1
			run_length=0
		last_direction=direction;run_length+=1;longest_run=maxi(longest_run,run_length);prior=point
	var result={"validation_type":"logical isolated jump checks without godmode; separate invulnerable full-route input replay; not human timing or Android performance","level_id":game.level.id,"width":game.level.length,"net_climb":game.level.spawn.y-game.level.climb_route[-1].y,"direction_changes":changes,"longest_same_direction_jumps":longest_run,"max_step_center_dx":max_dx,"all_jumps_reachable":passed,"jumps":jumps,"camera_x":game.camera_x,"checkpoint_order":game.checkpoint_order,"route_result":game.mode,"route_simulated_s":game.elapsed,"player":[game.player.x,game.player.y],"destroyed_targets":game.destroyed_targets,"trace":trace}
	game.start_level("spillway",true)
	for frame in range(60*300):
		game.invincible=2
		var actions=Policy.actions(game)
		if not game.boss_active:actions=actions.replace("fire","")
		game.touches[-9001]=actions;game.step(1.0/60)
		if game.mode in ["won","dead"]:break
	result["unbroken_optional_nodes_route_won"]=game.mode=="won" and game.destroyed_targets.is_empty()
	DirAccess.make_dir_recursive_absolute("res://work/vertical")
	var file=FileAccess.open("res://work/vertical/route-current.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("JUMPS ",passed," ROUTE ",game.mode," POSITION ",game.player," ARMS ",game.warden.arms," CORE ",game.warden.core)
	game.audio.shutdown();await create_timer(.2).timeout;game.queue_free();await create_timer(.3).timeout
	quit(0 if passed and result.route_result=="won" and result.unbroken_optional_nodes_route_won else 1)
