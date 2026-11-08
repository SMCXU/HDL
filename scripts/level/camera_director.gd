extends RefCounted
static func update(game: Node,dt: float,snap=false):
	if not game.level.vertical:
		game.camera_x=clampf(game.player.x-320,-220,game.LENGTH-960)
		game.camera_y=0
		return
	game.camera_x=0
	if snap:
		game.camera_anchor_y=game.player.y
		game.camera_y=clampf(game.player.y-350,game.level.world_top,0)
		return
	# Higher landings commit the climb; jumping alone does not bob the camera.
	if game.velocity.y==0:game.camera_anchor_y=game.player.y
	var target=game.camera_anchor_y-350
	var screen_y=game.player.y-game.camera_y
	if screen_y<190:target=minf(target,game.player.y-190)
	if screen_y>410:target=maxf(target,game.player.y-380)
	if game.boss_active:target=game.level.boss_checkpoint.y-350
	target=clampf(target,game.level.world_top,0)
	game.camera_y=lerpf(game.camera_y,target,1-exp(-dt*8))
