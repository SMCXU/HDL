extends Node
# Only debug exports accept the temporary opt-in file. Human input always has priority.
const WEAPON_IDS=["rifle","machine","spread","laser","fireball"]
const Policy=preload("res://scripts/debug/replay_policy.gd")
var game: Node
var enabled=false
var started=false
var elapsed=0.0
var duration=120.0
var invulnerable=false
var wins=0
var deaths=0
var next_report=30.0
var run_id=""
var test_mode="route"
var level_id="iron_factory"
var forced_weapon=""
var force_rapid=false
var retry_count=0
var retry_target=23
var retry_age=0.0
var retry_samples: Array=[]
var retry_sample_count=0
func _ready():
	game=get_parent()
	if not OS.is_debug_build() or not FileAccess.file_exists("user://qa-replay.json"): return
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string("user://qa-replay.json"))!=OK or not parser.data is Dictionary:return
	var config=parser.data
	level_id=str(config.get("level_id","iron_factory"))
	if level_id not in ["iron_factory","spillway","redrock"]:return
	forced_weapon=str(config.get("weapon_id",""))
	if forced_weapon!="cycle" and not forced_weapon in game.weapons.SPECS:forced_weapon=""
	force_rapid=bool(config.get("rapid",false))
	run_id=str(config.get("run_id",""))
	test_mode=str(config.get("mode","route"))
	retry_target=clampi(int(config.get("retry_count",23)),1,100)
	duration=clampf(float(config.get("duration_s",120)),10,1200)
	invulnerable=bool(config.get("invulnerable",false))
	if test_mode in ["retries","switches"]:
		# Allocate diagnostics before warmup, never retain another dictionary per retry.
		for i in range(retry_target):
			retry_samples.append({"cycle":i,"level_id":"","checkpoint":false,"memory_static_bytes":0.0,"objects":0.0,"children":0,"bullets":0,"effects":0,"audio_voice_nodes":0})
	enabled=true
	write_status("ready")
func before_step(dt: float):
	if not enabled: return
	if game.mode in ["paused","settings"]:
		if started:finish("cancelled_by_pause")
		return
	if not game.touch_owners.is_empty():
		finish("cancelled_by_human_input")
		return
	if not started:
		game.start_level(level_id,true)
		started=true
	if game.mode in ["won","dead"]:
		if game.result_age<1.1: return
		if game.mode=="won": wins+=1
		else: deaths+=1
		if test_mode=="retries":
			retry_count+=1
			# Exercise both a full restart and a real segment checkpoint retry.
			if game.level.vertical:
				if game.level.id=="spillway":game.destroyed_targets.relay=true
				game.score=900;game.commit_checkpoint(game.level.checkpoint_points[0],0)
			else:
				game.checkpoint_x=game.level.sectors[1].start_x+100
				game.checkpoint_y=435;game.checkpoint_score=900
			game.reset_game(retry_count%2==1)
			retry_age=0
			if retry_count>=retry_target:
				finish("completed")
				return
		else: game.start_level(level_id,true)
	if game.mode!="playing": return
	elapsed+=dt
	if elapsed>=duration:
		finish("completed")
		return
	if forced_weapon!="":
		game.weapon_id=WEAPON_IDS[int(elapsed/8)%5] if forced_weapon=="cycle" else forced_weapon
		game.rapid_fire=force_rapid
		game.pickups.clear() # Explicit locked/cycling QA fixture, not normal pickup acceptance.
	if invulnerable: game.invincible=maxf(game.invincible,2)
	game.touches[-9001]=Policy.actions(game)
	if test_mode in ["retries","switches"]:
		retry_age+=dt
		if retry_age>=3.0:
			var sample=retry_samples[retry_count]
			sample.level_id=game.level.id
			sample.checkpoint=game.started_at_checkpoint
			sample.memory_static_bytes=Performance.get_monitor(Performance.MEMORY_STATIC)
			sample.objects=Performance.get_monitor(Performance.OBJECT_COUNT)
			sample.children=game.get_child_count()
			sample.bullets=game.bullets.size()
			sample.effects=game.visual_effects.size()
			sample.audio_voice_nodes=game.audio.voices.size()
			retry_sample_count+=1
			if test_mode=="switches":
				retry_count+=1
				var ids=["iron_factory","spillway","redrock"]
				game.start_level(ids[(ids.find(game.level.id)+1)%ids.size()],true)
				retry_age=0
				if retry_count>=retry_target:finish("completed");return
			else:
				game.invincible=0;game.hp=1;game.hurt()
			write_status("running")
	if elapsed>=next_report:
		write_status("running")
		next_report+=30
func finish(result: String):
	game.clear_input()
	game.pause_game()
	write_status(result)
	enabled=false
func write_status(result: String):
	var file=FileAccess.open("user://qa-replay-status.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"level_id":game.level.id,"run_id":run_id,"test_mode":test_mode,"retry_count":retry_count,"retry_samples":retry_samples.slice(0,retry_sample_count),"result":result,"elapsed_s":elapsed,"duration_s":duration,"wins":wins,"deaths":deaths,"invulnerable":invulnerable,"validation_type":"single-device automated debug replay, not human play or touch hardware validation"}))
		file.close()
