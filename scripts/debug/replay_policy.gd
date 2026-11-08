extends RefCounted
# Input-only route policy. Used by explicitly labeled automated checks, never normal play.
static func actions(game: Node) -> String:
	if game.level.id=="redrock":return redrock_actions(game)
	if game.level.id=="spillway":return spillway_actions(game)
	var result=PackedStringArray(["fire"])
	if game.boss_active:
		if game.player.x<game.BossDirector.DRAW_RECT.position.x-160: result.append("right")
		elif game.facing<0: result.append("right")
		return "+".join(result)
	if game.enemies.is_empty():
		result.append("right")
		for pickup in game.pickups:
			if pickup.pos.x-game.player.x>125 and pickup.pos.x-game.player.x<185 and game.velocity.y==0 and game.player.y>=game.GROUND-1:
				result.append("jump")
		return "+".join(result)
	var target=game.enemies[0]
	for enemy in game.enemies:
		if absf(enemy.pos.x-game.player.x)<absf(target.pos.x-game.player.x): target=enemy
	var dx=target.pos.x-game.player.x
	var direction="right" if dx>0 else "left"
	if target.pos.y<game.GROUND-35:
		result.append("up")
		if absf(dx)>9: result.append(direction)
	elif absf(dx)>135 or game.facing!=(1 if dx>0 else -1):
		result.append(direction)
	return "+".join(result)

static func spillway_actions(game: Node) -> String:
	var result=PackedStringArray(["fire"])
	if game.boss_active:
		var x=game.level.boss_position.x
		if game.warden.arms[0]<=0 and game.warden.arms[1]>0:
			if game.player.x>x-190:game.replay_strafe=-1
			if game.player.x<x-310:game.replay_strafe=1
			result.append("right" if game.replay_strafe>0 else "left");result.append("up")
		else:
			var target=x-350
			if game.player.x<target-10:result.append("right")
			elif game.facing<0:result.append("right")
		return "+".join(result)
	var route=game.level.climb_route
	while game.replay_route_index<route.size() and game.velocity.y==0 and absf(game.player.y-route[game.replay_route_index].y)<2 and absf(game.player.x-route[game.replay_route_index].x)<65:game.replay_route_index+=1
	if game.replay_route_index<route.size():
		var target=route[game.replay_route_index]
		if absf(target.x-game.player.x)>4:result.append("right" if target.x>game.player.x else "left")
		if game.velocity.y==0 and not game.jump_was_down and target.y<game.player.y-20:result.append("jump")
	else:
		if game.player.x<360:result.append("right")
	return "+".join(result)

static func redrock_actions(game: Node) -> String:
	var result=PackedStringArray(["fire"])
	if game.boss_active:
		result.append("up")
		if absf(game.player.x-480)>4:result.append("right" if game.player.x<480 else "left")
		return "+".join(result)
	var route=game.level.climb_route
	while game.replay_route_index<route.size():
		var next=game.platform_motion.route_point(game.replay_route_index,route[game.replay_route_index])
		if game.velocity.y==0 and absf(game.player.y-next.y)<2 and absf(game.player.x-next.x)<75:game.replay_route_index+=1
		else:break
	if game.replay_route_index<route.size():
		var target=game.platform_motion.route_point(game.replay_route_index,route[game.replay_route_index])
		if absf(target.x-game.player.x)>4:result.append("right" if target.x>game.player.x else "left")
		if game.velocity.y==0 and not game.jump_was_down and target.y<game.player.y-20:result.append("jump")
	return "+".join(result)
