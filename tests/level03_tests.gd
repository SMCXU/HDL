extends RefCounted
func run(game: Node,check: Callable):
	game.start_level("redrock",true)
	check.call(game.level.id=="redrock" and game.level.climb_route.size()==44 and game.level.sectors.size()==6,"third level registers original six-zone 44-rise geometry")
	check.call(game.platform_motion.entries.size()==2 and game.rockfalls.entries.size()==2 and game.level.branch_routes.size()==2,"third level has two ferries two rock columns and two short branches")
	# At the first ferry waiting ledge all earlier ground guards are below the firing viewport.
	game.player=game.level.climb_route[16];game.CameraDirector.update(game,0,true)
	var teaching_safe=true
	for encounter in game.level.encounter_data:
		if encounter.id=="R03":
			var guard=game.EnemyDirector.create(encounter.positions[0],encounter.types[0],0)
			guard.timer=0;game.enemies=[guard];game.EnemyDirector.step(game,.1)
			teaching_safe=game.bullets.is_empty()
	check.call(teaching_safe,"first ferry waiting ledge is not fired on by the preceding guard")
	game.enemies.clear()
	var p=game.platform_motion.entries[0]
	game.player=Vector2(p.rect.get_center().x,p.rect.position.y);game.velocity=Vector2.ZERO;game.platform_motion.landed(game.player)
	var before=game.player
	game.platform_motion.step(game,.1)
	check.call(game.player.x>before.x and game.player.y==before.y,"standing rider follows a horizontally moving ferry without vertical drift")
	check.call(not game.safe_landing_allowed(game.player),"moving ferry cannot become a fall-recovery point")
	game.touches[0]="jump";game.PlayerController.step(game,1.0/60)
	check.call(game.velocity.y<0 and game.platform_motion.rider=="","jumping detaches rider before the next ferry movement")
	game.reset_game();p=game.platform_motion.entries[0]
	game.player=Vector2(p.rect.get_center().x,p.rect.position.y);game.velocity=Vector2.ZERO;game.platform_motion.landed(game.player)
	game.touches[0]="down+jump";game.PlayerController.step(game,1.0/60)
	check.call(game.velocity.y>0 and game.platform_motion.rider=="","down jump detaches from ferry and starts dropping")
	var time=game.platform_motion.clock
	game.pause_game();game.step(.5)
	check.call(game.platform_motion.clock==time,"paused third level freezes analytic ferry motion")
	game.reset_game()
	check.call(game.platform_motion.clock==0 and game.platform_motion.rider=="" and game.drop_platform_y==INF,"retry resets ferry phase rider and platform exclusion")
	var rock=game.rockfalls.entries[0]
	game.camera_y=rock.area.position.y-150;game.player=rock.area.get_center();game.invincible=0
	rock.state="warning";rock.age=0;game.rockfalls.step(game,.01)
	check.call(game.hp==3,"rockfall warning alone never damages the player")
	rock.state="fall";rock.pos=game.player-Vector2(0,25);rock.age=0
	game.rockfalls.step(game,.01);game.rockfalls.step(game,.01)
	check.call(game.hp==2,"active boulder deals one damage within normal invulnerability")
	rock.state="warning";rock.age=.5;game.camera_y=1000;game.rockfalls.step(game,.01)
	check.call(rock.state=="idle" and rock.age==0,"offscreen rockfall resets instead of firing an unseen pending strike")
	game.start_level("redrock",true)
	game.highest_climb=900;game.score=400;game.consumed_pickups["test"]=true
	game.commit_checkpoint(game.level.checkpoint_points[0],0)
	game.score=9000;game.highest_climb=2000;game.consumed_pickups["after"]=true
	game.reset_game(true)
	check.call(game.score==400 and game.highest_climb==900 and game.consumed_pickups.has("test") and not game.consumed_pickups.has("after"),"third-level retry restores committed score height and pickup snapshot")
	check.call(game.checkpoint_id()=="redrock:rock_merge" and game.player==game.level.checkpoint_points[0],"third-level checkpoint uses a stable independent ID")
	game.start_level("redrock",true);game.player=game.level.boss_checkpoint;game.velocity=Vector2.ZERO
	game.citadel.step(game,0);game.boss_intro=0
	check.call(game.boss_active and game.citadel.core==42 and game.enemies.is_empty(),"citadel starts only on summit and clears ordinary enemies")
	game.rockfalls.step(game,.1)
	check.call(game.rockfalls.entries[0].state=="idle","citadel encounter disables exterior rockfalls")
	var center=game.citadel.boxes(game)[2].get_center()
	game.citadel.age=.5;game.citadel.hit(game,center)
	check.call(game.citadel.core==42,"closed citadel armor blocks core damage")
	game.citadel.age=2.2;game.citadel.hit(game,center)
	check.call(game.citadel.core==41 and game.citadel.ports==[8,8],"open core can take damage while both side ports remain intact")
	var score=game.score
	var port=game.citadel.boxes(game)[0].get_center()
	for i in range(8):game.citadel.hit(game,port)
	check.call(game.citadel.ports==[0,8] and game.score==score+250,"optional left port awards a one-time reward independently of core shield")
	game.citadel.hit(game,port)
	check.call(game.score==score+250,"destroyed citadel port cannot repeatedly award points")
	for i in range(41):game.citadel.hit(game,center)
	var final_score=game.score
	game.BossDirector.defeated(game)
	check.call(game.mode=="won" and game.score==final_score,"citadel victory is committed only once")
	check.call(not "redrock" in game.unlocked_levels,"debug third-level win does not write an unlock")
	game.unlocked_levels=["iron_factory"]
	game.mode="level_select";game.MenuLayout.activate(game,"redrock")
	check.call(game.mode=="playing" and game.level.id=="redrock" and not game.debug_run,"third-level activation is available before campaign completion")
	game.start_level("spillway",false);game.mode="won";game.score=1234;game.complete_level()
	check.call("redrock" in game.unlocked_levels and int(game.best_scores.spillway)==1234,"real second-level completion unlocks third level and preserves per-level score")
	game.MenuLayout.activate(game,"next")
	check.call(game.level.id=="redrock" and not game.debug_run,"second-level next button enters a fresh formal third-level run")
	game.start_level("redrock",true)
	game.player=game.level.boss_checkpoint;game.touches[0]="down+jump";game.PlayerController.step(game,1.0/60)
	check.call(game.velocity.y<0 and game.drop_platform_y==INF,"third-level summit solid floor rejects down-through")
	game.mode="level_select"
	var cards=game.MenuLayout.items(game)
	check.call(cards.size()==4 and not cards[0].rect.intersects(cards[1].rect) and not cards[1].rect.intersects(cards[2].rect),"three level cards have independent nonoverlapping pointer targets")
	game.start_level("redrock",true);game.player=game.level.spawn;game.CameraDirector.update(game,0,true)
	check.call(game.camera_x==0 and game.camera_y==0,"third level keeps fixed horizontal camera and valid starting composition")
	game.start_level("iron_factory",true)
	check.call(game.platform_motion.entries.is_empty() and game.rockfalls.entries.is_empty() and game.terrain.dynamic_surfaces.is_empty(),"switching to factory clears all third-level dynamic geometry and hazards")

	var count=game.get_child_count()
	for i in range(30):
		game.start_level(["iron_factory","spillway","redrock"][i%3],true)
		game.step(1.0/60)
	check.call(game.get_child_count()==count and game.audio.voices.size()==12,"thirty logical three-level switches keep nodes and audio voices bounded")
