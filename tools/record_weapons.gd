extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(960,540);DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false)
	var sheet=Image.create(960*2,540*3,false,Image.FORMAT_RGBA8)
	var ids=["rifle","machine","spread","laser","fireball"]
	for index in range(6):
		game.start_level("redrock",true);game.player=Vector2(300,435);game.invincible=0;game.enemies.clear()
		game.weapon_id=ids[index] if index<5 else "machine";game.rapid_fire=index==5
		game.pickup_notice=game.weapons.title(game)+(" · R强化" if game.rapid_fire else "");game.pickup_notice_age=10
		var folder="res://work/weapons/motion/"+game.weapon_id+("-R" if game.rapid_fire else "")
		DirAccess.make_dir_recursive_absolute(folder)
		for frame in range(35):
			game.mode="playing";game.weapon_id=ids[index] if index<5 else "machine"
			for tick in range(2):
				game.cooldown-=1.0/60
				game.advance_effects(1.0/60);game.time+=1.0/60
				if game.cooldown<=0:game.weapons.fire(game)
				game.weapons.step(game,1.0/60)
			game.presentation.update(1.0/30,Vector2.ZERO,false,false)
			game.get_node("GameView").queue_redraw();await process_frame;RenderingServer.force_draw(false)
			var shot=root.get_texture().get_image()
			shot.save_png(folder+"/%03d.png"%frame)
			if frame==(0 if index==3 else 24):sheet.blit_rect(shot,Rect2i(0,0,960,540),Vector2i((index%2)*960,int(index/2)*540))
	for level_id in ["iron_factory","spillway"]:
		game.start_level(level_id,true);game.invincible=0;game.weapon_id="laser";game.rapid_fire=true
		game.pickups.clear();game.enemies.clear()
		for i in range(5):game.pickups.append({"id":"fixture%d"%i,"pos":Vector2(game.camera_x+400+i*75,game.level.spawn.y-30),"kind":["machine","spread","laser","fireball","rapid"][i]})
		game.weapons.fire(game);game.get_node("GameView").queue_redraw();await process_frame;RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://work/weapons/hud-"+level_id+".png")
	sheet.save_png("res://work/weapons/weapons-sheet.png")
	var f=FileAccess.open("res://work/weapons/visual-metadata.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"validation_type":"actual desktop rendered weapon fixtures, two fixed steps per frame, 30 sampled frames per simulated second; no battle/manual/device/performance evidence","sheet_order":["rifle","machine","spread","laser","fireball","machine+R"]}));f.close()
	game.audio.shutdown();await create_timer(.25).timeout;game.queue_free();await create_timer(.5).timeout;quit()
