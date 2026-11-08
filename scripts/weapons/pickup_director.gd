extends RefCounted
# Stable authored IDs, never floating-coordinate strings, govern ordinary consumption.
func reset(game: Node):
	game.pickups.clear()
	for data in game.level.pickup_data:
		if not game.consumed_pickups.has(data.id):game.pickups.append(data.duplicate(true))
	# One optional S per attempt, deliberately not committed to persistent CP consumption.
	if game.level.boss_supply!=Vector2.ZERO:game.pickups.append({"id":game.level.id+":boss_supply","pos":game.level.boss_supply,"kind":"spread","attempt":true})
func step(game: Node):
	for i in range(game.pickups.size()-1,-1,-1):
		var item=game.pickups[i]
		if game.player.distance_to(item.pos)<42:
			game.weapons.equip(game,item.kind)
			if not item.get("attempt",false):game.consumed_pickups[item.id]=true
			game.pickups.remove_at(i)
