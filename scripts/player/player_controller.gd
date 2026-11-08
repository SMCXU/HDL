extends RefCounted
# Fixed-step movement. It owns no renderer or input device objects.
static func step(game: Node,dt: float):
	var direction=float(game.pressed("right"))-float(game.pressed("left"))
	if direction!=0: game.facing=int(direction)
	if game.drop_platform_y!=INF and game.player.y>game.drop_platform_y+4:game.drop_platform_y=INF
	var surfaces=game.terrain.near(game.player)
	if game.drop_platform_y!=INF:
		# Ignore the entire current height, including overlapping catch/turn rectangles.
		surfaces=surfaces.filter(func(r):return absf(r.position.y-game.drop_platform_y)>.5)
	var floor_y=INF
	for platform in surfaces:
		if game.player.x>platform.position.x-9 and game.player.x<platform.end.x+9 and game.player.y<=platform.position.y+3:
			floor_y=minf(floor_y,platform.position.y)
	game.crouching=game.pressed("down") and game.player.y>=floor_y-2 and game.velocity.y>=0
	game.velocity.x=direction*(105 if game.crouching else 245)
	if game.player.y>=floor_y-2 and game.velocity.y>=0: game.coyote=0.10
	else: game.coyote=maxf(0,game.coyote-dt)
	var jump=game.pressed("jump")
	game.jump_buffer=maxf(0,game.jump_buffer-dt)
	var jump_edge=jump and not game.jump_was_down
	var drop=jump_edge and game.wants_platform_drop() and game.velocity.y==0 and absf(game.player.y-floor_y)<1 and game.terrain.can_drop(game.level,game.player)
	if drop:
		game.drop_platform_y=floor_y
		surfaces=surfaces.filter(func(r):return absf(r.position.y-floor_y)>.5)
		game.player.y+=1
		game.velocity.y=90
		game.coyote=0;game.jump_buffer=0;game.crouching=false;game.platform_motion.rider=""
	elif jump_edge:game.jump_buffer=0.12
	if game.jump_buffer>0 and game.coyote>0:
		game.velocity.y=-540
		game.platform_motion.rider=""
		game.coyote=0
		game.jump_buffer=0
		game.crouching=false
		game.audio.effect("jump")
	game.jump_was_down=jump
	var previous=game.player
	game.velocity.y+=1450*dt
	game.player+=game.velocity*dt
	var landing=INF
	for platform in surfaces:
		if game.player.x>platform.position.x-9 and game.player.x<platform.end.x+9:
			if previous.y<=platform.position.y+0.5 and game.player.y>=platform.position.y and game.velocity.y>=0:
				landing=minf(landing,platform.position.y)
	if game.player.y>=landing and game.velocity.y>=0:
		if game.velocity.y>150:
			game.audio.effect("land")
			game.presentation.landing_remaining=0.18
			game.visual_effect(Vector2(game.player.x,landing),"dust",0.32)
		game.player.y=landing
		game.velocity.y=0
		game.platform_motion.landed(game.player)
		if game.level.vertical and game.safe_landing_allowed(game.player):game.last_safe_landing=game.player
	game.player.x=clampf(game.player.x,game.level.play_left,game.level.play_right if game.level.play_right>0 else game.LENGTH-50)
	if game.boss_active:
		game.player.x=maxf(game.player.x,game.level.boss_left)
		if game.level.id=="spillway":game.player.x=minf(game.player.x,game.level.boss_position.x-80)
	elif game.encounters.blocks_progress(): game.player.x=minf(game.player.x,game.encounters.gate_x-20)
	if game.level.id=="iron_factory" and game.player.x>game.level.boss_checkpoint.x and (not game.checkpoint or game.checkpoint_x<game.level.boss_checkpoint.x):
		game.commit_checkpoint(game.level.boss_checkpoint)
	if game.level.vertical and game.velocity.y==0:game.highest_climb=maxf(game.highest_climb,game.level.spawn.y-game.player.y)
	game.CameraDirector.update(game,dt)
	if game.level.vertical and game.player.y>650:game.recover_fall()
	game.presentation.update(dt,game.velocity,game.crouching,false)
