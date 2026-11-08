extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
func _initialize():call_deferred("run")
var game: Node
func edge(from: Vector2,to: Vector2,phase=0.0,moving_index=-1) -> Dictionary:
	game.platform_motion.reset(game.level);game.terrain.dynamic_surfaces=game.platform_motion.surfaces
	game.platform_motion.clock=phase
	game.player=from;game.velocity=Vector2.ZERO;game.jump_was_down=false;game.coyote=.1;game.jump_buffer=0;game.drop_platform_y=INF
	var landed=false
	for frame in range(150):
		game.platform_motion.step(game,1.0/60)
		var target=game.platform_motion.route_point(moving_index,to) if moving_index>=0 else to
		game.touches[0]="right" if game.player.x<target.x-3 else "left" if game.player.x>target.x+3 else ""
		if frame==0:game.touches[0]+="+jump"
		game.PlayerController.step(game,1.0/60)
		if game.velocity.y==0 and absf(game.player.y-target.y)<1 and absf(game.player.x-target.x)<40:landed=true;break
	return {"from":str(from),"to":str(to),"phase":phase,"moving_index":moving_index,"reached":landed,"actual":str(game.player)}
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.start_level("redrock",true)
	var edges=[];var previous=game.level.spawn
	for i in range(game.level.climb_route.size()):
		edges.append(edge(previous,game.level.climb_route[i],0,i))
		previous=game.level.climb_route[i]
	for branch in game.level.branch_routes:
		for i in range(1,branch.size()):edges.append(edge(branch[i-1],branch[i]))
	for spec in game.level.moving_data:
		var index=int(spec.route_index)
		for phase in [0.0,1.9,3.8,5.7,7.6]:
			edges.append(edge(game.level.climb_route[index-1],game.level.climb_route[index],phase,index))
			# Departure from actual ferry position at each phase.
			var offset=sin(phase*spec.speed/spec.amplitude)*spec.amplitude
			edges.append(edge(game.level.climb_route[index]+Vector2(offset,0),game.level.climb_route[index+1],phase,index+1))
	game.start_level("redrock",true)
	var trace=[]
	for frame in range(60*240):
		game.invincible=2;game.touches[-9001]=Policy.actions(game);game.step(1.0/60)
		if frame%300==0:trace.append({"s":game.elapsed,"player":str(game.player),"route":game.replay_route_index,"core":game.citadel.core,"mode":game.mode})
		if game.mode in ["won","dead"]:break
	var ok=true
	for e in edges:ok=ok and e.reached
	var result={"validation_type":"isolated fixed-step physics edges no battle; invulnerable whole-route input replay, not manual timing or Android performance","edges":edges,"all_edges_reachable":ok,"route_result":game.mode,"route_simulated_s":game.elapsed,"checkpoint_order":game.checkpoint_order,"ports":game.citadel.ports,"core":game.citadel.core,"trace":trace}
	var f=FileAccess.open("res://work/level03/route.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("EDGES ",ok," ROUTE ",game.mode," PLAYER ",game.player," CORE ",game.citadel.core)
	game.audio.shutdown();await create_timer(.2).timeout;game.queue_free();await create_timer(.3).timeout;quit(0 if ok and result.route_result=="won" else 1)
