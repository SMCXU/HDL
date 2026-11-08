extends RefCounted
const Enemies=preload("res://scripts/enemies/enemy_director.gd")
var arenas: Array=[]
var index=0
var active=false
var gate_x=13800.0
var clear_age=0.0
var targets: Array=[]
func reset(game: Node,_from_x: float):
	arenas=game.level.arenas();clear_age=0
	targets=game.level.target_data.duplicate(true)
	for t in targets:t.hp=0 if game.destroyed_targets.has(t.id) else t.max_hp
	refresh_gate(game)
func refresh_gate(game: Node):
	gate_x=game.level.length;active=false
	# All relays are optional tactical rewards in the vertical redesign.

func blocks_progress() -> bool:return active
func step(game: Node,dt: float):
	clear_age=maxf(0,clear_age-dt)
	if game.boss_active or game.boss_defeated:return
	for i in range(game.enemies.size()-1,-1,-1):
		if game.enemies[i].pos.distance_to(game.player)>620:game.enemies.remove_at(i)
	for spec in arenas:
		if game.completed_encounters.has(spec.id):continue
		if spec.trigger.has_point(game.player) and game.enemies.size()+spec.positions.size()<=6:
			for i in range(spec.positions.size()):game.enemies.append(Enemies.create(spec.positions[i],spec.types[i],index*3+i))
			game.completed_encounters[spec.id]=true
	index=game.completed_encounters.size()
	for order in range(game.level.checkpoint_points.size()):
		var cp=game.level.checkpoint_points[order]
		if order>game.checkpoint_order and absf(game.player.y-cp.y)<2 and game.velocity.y==0 and absf(game.player.x-cp.x)<110:game.commit_checkpoint(cp,order)

func hit_target(game: Node,point: Vector2,damage=1) -> bool:
	for t in targets:
		if t.hp>0 and Rect2(t.pos-Vector2(24,78),Vector2(48,78)).has_point(point):
			t.hp=maxi(0,t.hp-damage);game.audio.effect("enemy_hit");game.visual_effect(point,"impact",.18)
			if t.hp==0:
				game.destroyed_targets[t.id]=true;game.score+=300
				game.visual_effect(t.pos-Vector2(0,40),"explosion",.65);game.audio.effect("power_down")
				clear_age=1.0;refresh_gate(game)
			return true
	return false
