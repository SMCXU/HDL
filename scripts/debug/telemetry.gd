extends Node
# Opt-in diagnostic capture. All numbers retain their original units.
var enabled = false
var elapsed = 0.0
var flush_age = 0.0
var output: FileAccess
var previous_usec=0
var game: Node
func _ready():
	game = get_parent()
	enabled = "--telemetry" in OS.get_cmdline_user_args() or FileAccess.file_exists("user://telemetry.flag")
	if enabled:
		output = FileAccess.open("user://frame-samples.csv",FileAccess.WRITE)
		if output:
			output.store_line("utc_unix,elapsed_s,frame_ms,engine_delta_ms,mode,player_x,memory_static_bytes,objects,bullets,particles,effects,audio_voices,interaction_source,invulnerable,interval_valid,level_id,checkpoint_id,player_y,camera_y,boss_phase,debug_run,run_id,weapon_id,rapid,weapon_batch,beams,weapon_damage")

func _process(dt):
	if not enabled or not output: return
	var now=Time.get_ticks_usec()
	var interval_valid=previous_usec>0
	var frame_ms=(now-previous_usec)/1000.0 if interval_valid else 0.0
	previous_usec=now
	elapsed += dt
	flush_age += dt
	var voices = 0
	for voice in game.audio.voices:
		if voice.playing: voices += 1
	output.store_line("%.3f,%.3f,%.4f,%.4f,%s,%.2f,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s,%s,%.2f,%.2f,%s,%s,%s,%s,%s,%d,%d,%d" % [Time.get_unix_time_from_system(),elapsed,frame_ms,dt*1000,game.mode,game.player.x,Performance.get_monitor(Performance.MEMORY_STATIC),Performance.get_monitor(Performance.OBJECT_COUNT),game.bullets.size(),game.particles.size(),game.visual_effects.size(),voices,"automated_debug_replay" if game.replay.enabled else "unclassified_input",str(game.replay.enabled and game.replay.invulnerable),str(interval_valid),game.level.id,game.checkpoint_id(),game.player.y,game.camera_y,game.boss_phase_label(),str(game.debug_run),game.replay.run_id,game.weapon_id,str(game.rapid_fire),game.weapons.batch_id,game.weapons.beams.size(),game.weapons.damage_total])
	if flush_age>=1:
		output.flush()
		flush_age=0
func _exit_tree():
	if output:
		output.flush()
		output.close()

func record_run(result: String):
	if not enabled: return
	var path="user://run-results-v3.csv"
	var exists=FileAccess.file_exists(path)
	var file=FileAccess.open(path,FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if not file: return
	if not exists: file.store_line("utc_unix,result,elapsed_s,checkpoint,score,player_x,interaction_source,invulnerable,level_id,debug_run")
	file.seek_end()
	file.store_line("%.3f,%s,%.3f,%s,%d,%.2f,%s,%s,%s,%s" % [Time.get_unix_time_from_system(),result,game.elapsed,str(game.started_at_checkpoint),game.score,game.player.x,"automated_debug_replay" if game.replay.enabled else "unclassified_input",str(game.replay.enabled and game.replay.invulnerable),game.level.id,str(game.debug_run)])
	file.close()
