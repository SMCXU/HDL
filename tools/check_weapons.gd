extends SceneTree
const Policy=preload("res://scripts/debug/replay_policy.gd")
func _initialize():call_deferred("run")
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false)
	var results=[]
	for level in ["iron_factory","spillway","redrock"]:
		for id in game.weapons.SPECS:
			for rapid in [false,true]:
				game.start_level(level,true)
				if level=="iron_factory":
					game.player=game.level.boss_checkpoint+Vector2(250,0);game.encounters.reset(game,game.level.boss_checkpoint.x)
				else:game.player=game.level.boss_checkpoint
				game.enemies.clear();game.pickups.clear();game.weapon_id=id
				game.CameraDirector.update(game,0,true)
				for frame in range(60*180):
					game.weapon_id=id;game.rapid_fire=rapid;game.invincible=2
					game.touches[-9001]=Policy.actions(game);game.step(1.0/60)
					if game.mode in ["won","dead"]:break
				results.append({"level":level,"weapon":id,"rapid":rapid,"result":game.mode,"simulated_s":game.elapsed,"shots":game.weapons.shot_counts.duplicate(),"effective_damage":game.weapons.damage_total,"score":game.score,"core_remaining":game.boss_hp,"capacity_waits":game.weapons.capacity_waits})
				print(level," ",id," ",game.mode," ",game.elapsed," hp ",game.boss_hp)
	var ok=true
	for r in results:ok=ok and r.result=="won" and r.capacity_waits==0
	var budgets=[]
	for id in game.weapons.SPECS:
		for rapid in [false,true]:
			game.start_level("redrock",true);game.enemies.clear();game.pickups.clear();game.weapon_id=id;game.rapid_fire=rapid
			var peak=0;var beams=0
			for frame in range(60*20):
				game.cooldown-=1.0/60;game.advance_effects(1.0/60)
				if game.cooldown<=0:game.weapons.fire(game)
				game.weapons.step(game,1.0/60)
				peak=maxi(peak,game.weapons.friendly_count(game));beams=maxi(beams,game.weapons.beams.size())
			budgets.append({"weapon":id,"rapid":rapid,"peak_friendly":peak,"peak_beams":beams,"shots":game.weapons.shot_counts.get(id,0),"capacity_waits":game.weapons.capacity_waits})
			ok=ok and peak<=80 and beams<=4 and game.weapons.capacity_waits==0
	var f=FileAccess.open("res://work/weapons/boss-matrix.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"validation_type":"30 isolated boss setups (five weapons x three bosses x R off/on); fixed-step invulnerable input replay, weapon locked, pickups removed; not normal avoidance, human timing or device performance","all_won":ok,"results":results,"budget_cases":budgets},"  "));f.close()
	game.audio.shutdown();await create_timer(.25).timeout;game.queue_free();await create_timer(.5).timeout;quit(0 if ok else 1)
