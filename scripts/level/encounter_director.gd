extends RefCounted
const Level=preload("res://scripts/level/level_director.gd")
const Enemies=preload("res://scripts/enemies/enemy_director.gd")
var arenas: Array=Level.arenas()
var index=0
var active=false
var gate_x=0.0
var clear_age=0.0
func reset(game: Node,from_x: float):
	arenas=game.level.arenas()
	index=0
	while index<arenas.size() and arenas[index].right<from_x: index+=1
	active=false
	clear_age=0
	gate_x=arenas[index].right if index<arenas.size() else game.level.length
	if index<arenas.size(): spawn(game)
func spawn(game: Node):
	var spec=arenas[index]
	for i in range(spec.positions.size()):
		game.enemies.append(Enemies.create(spec.positions[i],spec.types[i],index*3+i))
	active=true
func step(game: Node,dt: float):
	clear_age=maxf(0,clear_age-dt)
	if active and game.enemies.is_empty():
		var cleared=arenas[index]
		active=false
		index+=1
		clear_age=0.8
		game.audio.effect("confirm")
		# Remove defeated-wave danger, keep player shots and never delay opening.
		for i in range(game.bullets.size()-1,-1,-1):
			if not game.bullets[i].friendly: game.bullets.remove_at(i)
		if cleared.last_in_sector:
			var x=game.level.sectors[cleared.sector+1].start_x+100 if cleared.sector<game.level.sectors.size()-1 else game.level.boss_checkpoint.x
			game.commit_checkpoint(Vector2(x,435))
		gate_x=arenas[index].right if index<arenas.size() else game.level.length
	if not active and index<arenas.size() and game.player.x>=arenas[index].left: spawn(game)
func blocks_progress() -> bool:
	return index<arenas.size()
