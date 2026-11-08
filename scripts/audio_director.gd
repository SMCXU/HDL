extends Node
# Two music players for bounded crossfade, twelve prioritized effect voices.
var music: AudioStreamPlayer
var outgoing: AudioStreamPlayer
var voices: Array[AudioStreamPlayer]=[]
var priorities: Array[int]=[]
var streams: Dictionary={}
var last_played: Dictionary={}
var music_gain=0.65
var effect_gain=0.8
var repeat_music=true
var current_track=""
var fade_age=0.4
var suspended=false
const FADE=0.4
const PRIORITY={"warning":6,"hit":5,"death":6,"boss_death":6,"pickup":4,"boss_shot":4,"explosion":3,"confirm":4,"enemy_hit":1,"machine_shot":1,"laser_shot":2,"fireball_shot":2,"shot":1,"spread":2,"enemy_shot":1}
func _ready():
	music=AudioStreamPlayer.new()
	outgoing=AudioStreamPlayer.new()
	for player in [music,outgoing]:
		add_child(player)
		player.finished.connect(_music_finished.bind(player))
	for i in range(12):
		var voice=AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
		priorities.append(0)
	for name in ["level","workshop","core","boss","machine_shot","laser_shot","fireball_shot","stone_warning","stone_impact","power_down","arm_break","vent","shot","spread","jump","land","hit","death","enemy_shot","enemy_hit","explosion","pickup","warning","boss_shot","boss_death","confirm","back","victory","failure"]:
		var path="res://assets/audio/"+name+".wav"
		if ResourceLoader.exists(path): streams[name]=load(path)

func _music_finished(player: AudioStreamPlayer):
	if repeat_music and player==music: player.play()

func play_music(track: String,looped=true):
	if not streams.has(track): return
	if current_track==track and music.playing: return
	var previous=music
	music=outgoing
	outgoing=previous
	music.stop()
	var stream: AudioStream=streams[track]
	if stream is AudioStreamWAV and looped:
		stream=stream.duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin=0
		stream.loop_end=int(stream.get_length()*stream.mix_rate)
	music.stream=stream
	music.volume_db=-80
	music.play()
	music.stream_paused=suspended
	repeat_music=looped
	current_track=track
	fade_age=0

func _process(dt):
	if suspended: return
	fade_age=minf(FADE,fade_age+dt)
	var ratio=fade_age/FADE
	music.volume_db=linear_to_db(maxf(0.0001,music_gain*0.40*ratio))
	outgoing.volume_db=linear_to_db(maxf(0.0001,music_gain*0.40*(1-ratio)))
	if ratio>=1 and outgoing.playing:
		outgoing.stop()
		outgoing.stream=null

func effect(name: String):
	if not streams.has(name) or effect_gain<=0 or suspended: return
	var now=Time.get_ticks_msec()
	var minimum=65 if name in ["enemy_shot","enemy_hit"] else 25
	if now-int(last_played.get(name,-1000))<minimum: return
	var priority=int(PRIORITY.get(name,2))
	var slot=-1
	var least=100
	for i in range(voices.size()):
		if not voices[i].playing:
			slot=i
			break
		if priorities[i]<least:
			least=priorities[i]
			slot=i
	if slot<0: return
	if voices[slot].playing and priorities[slot]>=priority: return
	last_played[name]=now
	var voice=voices[slot]
	voice.stop()
	voice.stream=streams[name]
	voice.pitch_scale=1.0 if name=="warning" else randf_range(0.97,1.03)
	priorities[slot]=priority
	voice.play()

func set_volumes(m: float,e: float):
	music_gain=m
	effect_gain=e
	for voice in voices: voice.volume_db=linear_to_db(e*0.22) if e>0 else -80
	_process(0)

func clear_effects():
	for voice in voices: voice.stop()
	last_played.clear()

func suspend(value: bool):
	suspended=value
	music.stream_paused=value
	outgoing.stream_paused=value
	clear_effects()

func _exit_tree():
	shutdown()
	voices.clear()

func prepare_level(level: Resource):
	for track in level.music_tracks:
		if not streams.has(track):
			var path="res://assets/audio/"+track+".wav"
			if ResourceLoader.exists(path):streams[track]=load(path)

func shutdown():
	suspended=true
	for player in [music,outgoing]:
		if is_instance_valid(player):player.stop();player.stream=null
	for voice in voices:
		voice.stop();voice.stream=null
	streams.clear();last_played.clear()
