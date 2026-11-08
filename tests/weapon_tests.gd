extends RefCounted
func run(game: Node,check: Callable):
	game.start_level("redrock",true);game.enemies.clear();game.pickups.clear()
	var w=game.weapons
	check.call(w.SPECS.size()==5 and game.weapon_id=="rifle" and not game.rapid_fire,"five configured weapons start with unboosted baseline rifle")
	game.weapons.equip(game,"machine");game.weapons.equip(game,"rapid")
	w.fire(game)
	var old=game.bullets[0].duplicate(true)
	check.call(game.bullets.size()==1 and is_equal_approx(game.cooldown,.085) and absf(game.bullets[0].vel.length()-920)<.1,"M plus R changes cadence and flight speed by one configured multiplier")
	w.equip(game,"rapid");check.call(game.rapid_fire and game.score==0,"duplicate R does not stack or award score")
	w.equip(game,"spread")
	check.call(game.bullets[0].weapon_id=="machine" and game.bullets[0].vel==old.vel,"switching weapons preserves existing projectile payload and velocity")
	game.bullets.clear();w.fire(game)
	check.call(game.bullets.size()==5 and game.bullets[0].batch==game.bullets[4].batch,"five-pellet salvo shares one bounded batch budget")
	game.bullets.clear();game.weapons.equip(game,"laser");w.fire(game)
	check.call(is_equal_approx(game.cooldown,.4) and w.beams.size()==1 and game.rapid_fire,"laser keeps normal cadence with R retained but inactive")
	game.invincible=0;game.hurt()
	check.call(game.weapon_id=="laser" and game.rapid_fire,"nonlethal damage retains current weapon and single R enhancement")
	game.invincible=0;game.hp=1;game.hurt()
	check.call(game.mode=="dead" and game.weapon_id=="rifle" and not game.rapid_fire and game.bullets.is_empty() and w.beams.is_empty(),"death immediately drops equipment and clears live projectiles and beams")
	game.reset_game();game.weapon_id="laser";w.fire(game)
	var beam_age=w.beams[0].age
	game.pause_game();game.step(.2)
	check.call(w.beams[0].age==beam_age,"pause freezes visible beam lifetime")
	game.reset_game()
	check.call(game.weapon_id=="rifle" and not game.rapid_fire and w.beams.is_empty() and game.bullets.is_empty(),"retry clears equipment R projectiles beams and per-shot state")
	game.enemies.clear();game.pickups.clear();game.player=Vector2(300,435);game.facing=1
	var muzzle: Vector2=game.player_muzzle().position
	var far=game.EnemyDirector.create(muzzle+Vector2(150,34),0,0)
	var near=game.EnemyDirector.create(muzzle+Vector2(80,34),0,1)
	game.enemies=[far,near]
	game.spawn_bullet(muzzle,Vector2(12000,0),true);w.step(game,1.0/60)
	check.call(near.hp==1 and far.hp==2,"swept high-speed bullet chooses nearest target despite reversed enemy array")
	game.bullets.clear();game.enemies.clear();game.score=0
	for i in range(4):game.enemies.append(game.EnemyDirector.create(muzzle+Vector2(70+i*80,34),0,i))
	game.weapon_id="laser";game.rapid_fire=false;w.fire(game)
	check.call(game.enemies.size()==1 and game.score==300,"laser penetrates exactly three ordinary targets and scores each death once")
	var score=game.score
	for i in range(8):w.advance_visuals(game,.02)
	check.call(game.score==score and w.beams.is_empty(),"laser residual rendering never applies a second damage event")
	game.start_level("spillway",true);game.enemies.clear();game.pickups.clear()
	var target=game.encounters.targets[0]
	game.player=target.pos-Vector2(100,0);game.facing=1;game.weapon_id="laser"
	var behind=game.EnemyDirector.create(target.pos+Vector2(70,0),0,0);game.enemies=[behind]
	w.fire(game)
	check.call(target.hp==3 and behind.hp==2,"laser deals configured damage to relay and stops before the enemy behind it")
	w.fire(game);var target_score=game.score;w.fire(game)
	check.call(game.destroyed_targets.has("relay") and target_score==300 and game.score<=400,"relay destruction reward is issued once under laser fire")
	game.start_level("spillway",true);game.player=game.level.boss_checkpoint;game.citadel.reset();game.step(.01);game.boss_intro=0;game.enemies.clear();game.pickups.clear()
	var parts=game.BossDirector.parts(game)
	var batch={"id":9,"weapon_id":"spread","boss_part":"","boss_damage":0}
	for i in range(5):w.apply_hit(game,{"kind":"boss","target":parts[0],"point":parts[0].box.get_center(),"id":parts[0].id},1,batch)
	check.call(game.warden.arms[0]==10,"one five-pellet salvo deals at most two damage to a boss")
	w.apply_hit(game,{"kind":"boss","target":parts[1],"point":parts[1].box.get_center(),"id":parts[1].id},1,batch)
	check.call(game.warden.arms[1]==12,"same salvo cannot switch to a second boss part")
	var center=game.warden.boxes(game)[2].get_center()
	game.BossDirector.hit(game,center,3)
	check.call(game.warden.core==48,"laser-sized damage cannot bypass warden core armor")
	game.start_level("redrock",true);game.player=game.level.boss_checkpoint;game.citadel.step(game,0);game.boss_intro=0
	game.citadel.age=.5;center=game.citadel.boxes(game)[2].get_center();game.BossDirector.hit(game,center,3)
	check.call(game.citadel.core==42,"citadel closed window blocks configurable damage")
	game.citadel.age=2.1;game.BossDirector.hit(game,center,3)
	check.call(game.citadel.core==39 and game.citadel.ports==[8,8],"open citadel window accepts laser damage without requiring side-port destruction")
	game.start_level("redrock",true);game.enemies.clear();game.pickups.clear();game.weapon_id="fireball"
	game.touches[0]="up";w.fire(game)
	var f=game.bullets[0];muzzle=f.pos
	check.call(f.pos==game.player_muzzle().position and f.direction.y<-.99,"spiral fireball is born at the exact upward-facing shared muzzle")
	w.step(game,.08)
	check.call(absf(f.pos.x-muzzle.x)>5 and f.pos.y<muzzle.y,"fireball oscillation rotates with upward aim instead of a fixed world-axis wave")
	game.facing=-1;game.touches.clear();w.step(game,.04)
	check.call(f.direction.y<-.99 and f.damage==2,"already emitted fireball retains its direction and damage after turning")
	game.start_level("iron_factory",true)
	var item=game.pickups[0];game.player=item.pos;game.pickup_director.step(game)
	check.call(game.weapon_id=="machine" and game.consumed_pickups.has(item.id),"authored pickup uses stable ID and typed equipment")
	game.commit_checkpoint(game.level.spawn);game.weapon_id="laser";game.rapid_fire=true;game.reset_game(true)
	var repeated=false
	for p in game.pickups:
		if p.id==item.id:repeated=true
	check.call(not repeated and game.weapon_id=="rifle" and not game.rapid_fire,"first-level checkpoint keeps committed consumption while restoring baseline equipment")
	var supply={}
	for p in game.pickups:
		if p.get("attempt",false):supply=p
	game.player=supply.pos;game.pickup_director.step(game);game.reset_game(true)
	var supplies=0
	for p in game.pickups:
		if p.get("attempt",false):supplies+=1
	check.call(supplies==1 and game.score==game.checkpoint_score,"boss attempt supplies exactly one optional S again without reward farming")
	game.weapon_id="fireball";game.rapid_fire=true;game.start_level("spillway",true)
	check.call(game.weapon_id=="rifle" and not game.rapid_fire and w.beams.is_empty(),"cross-level transition clears all weapon and enhancement state")
	# Natural maximum cadence, no battle: verify no partial volleys or hidden capacity loss.
	game.enemies.clear();game.pickups.clear();game.player=Vector2(300,435);game.weapon_id="spread";game.rapid_fire=true
	var peak=0
	for i in range(600):
		game.cooldown-=1.0/60
		if game.cooldown<=0:w.fire(game)
		w.step(game,1.0/60);w.advance_visuals(game,1.0/60);peak=maxi(peak,w.friendly_count(game))
	check.call(peak<=80 and w.capacity_waits==0 and int(w.shot_counts.get("spread",0))>=35,"ten simulated seconds of S plus R stay bounded without dropped salvos")
	var telemetry=game.telemetry
	var previous_output=telemetry.output;var previous_enabled=telemetry.enabled
	var file=FileAccess.open("res://work/weapons/telemetry-fixture.csv",FileAccess.WRITE)
	telemetry.output=file;telemetry.enabled=true;telemetry._process(1.0/60);file.flush()
	telemetry.enabled=previous_enabled;telemetry.output=previous_output;file.close()
	var row=FileAccess.get_file_as_string("res://work/weapons/telemetry-fixture.csv").strip_edges().split(",")
	check.call(row.size()==27 and row[22]=="spread" and row[23]=="true","telemetry writes complete weapon R batch beam and damage fields")
	game.start_level("redrock",true);game.hp=1;game.invincible=0;game.auto_fire=true;game.weapon_id="machine"
	game.player=Vector2(85,700);game.step(1.0/60)
	check.call(game.mode=="dead" and not w.shot_counts.has("machine") and game.audio.current_track=="failure","fatal fall cannot emit an automatic shot or replace failure music")
	game.auto_fire=false;game.reset_game();game.hp=1;game.invincible=0;game.pickups.clear();game.enemies.clear()
	game.spawn_bullet(game.player-Vector2(0,25),Vector2.ZERO,false);w.step(game,1.0/60)
	check.call(game.mode=="dead" and game.bullets.is_empty(),"lethal swept enemy hit safely clears the array during projectile iteration")
	game.start_level("iron_factory",true)
