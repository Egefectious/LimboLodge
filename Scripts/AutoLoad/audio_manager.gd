extends Node

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer # New separate player for background noise
var sounds: Dictionary = {}
var current_pitch = 1.0

func _ready():
	# 1. Setup Music Player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Master"
	ambience_player.volume_db = -5.0 # Slightly quieter so it doesn't overpower
	add_child(ambience_player)
	
	# 2. Load sounds (Added new ones)
	_load_sound("draw", "res://Assets/Audio/draw.wav")
	_load_sound("place", "res://Assets/Audio/place.wav")
	_load_sound("slide", "res://Assets/Audio/slide.wav")
	_load_sound("error", "res://Assets/Audio/error.wav")
	_load_sound("win", "res://Assets/Audio/win.mp3")
	
	# --- NEW SOUNDS ---
	# Short, high-pitched click/tick for hovering
	_load_sound("hover", "res://Assets/Audio/hover.ogg") 
	# Satisfying button press
	_load_sound("click", "res://Assets/Audio/click.mp3") 
	# Coin jar or cash register sound
	_load_sound("buy", "res://Assets/Audio/buy.wav") 
	# Magical chime/bell for perfect matches
	_load_sound("chime", "res://Assets/Audio/chime.wav") 
	# Fast ticking for score counting
	_load_sound("score_tick", "res://Assets/Audio/score_tick.wav")
	
	#Ambience
	play_ambience("res://Assets/Audio/ambience.wav")

func _load_sound(key: String, path: String):
	if FileAccess.file_exists(path):
		sounds[key] = load(path)
	else:
		print("Warning: Sound missing at ", path)
		
func play_ambience(path: String):
	if FileAccess.file_exists(path):
		if ambience_player.stream == null or ambience_player.stream.resource_path != path:
			ambience_player.stream = load(path)
			ambience_player.play()

func reset_pitch():
	current_pitch = 1.0
	
func play_sequential(key: String, increment: float = 0.05, max_pitch: float = 2.5):
	play(key, Vector2(current_pitch, current_pitch))
	current_pitch = min(current_pitch + increment, max_pitch)

func play(key: String, pitch_range: Vector2 = Vector2(1.0, 1.0)):
	if sounds.has(key):
		var p = AudioStreamPlayer.new()
		p.stream = sounds[key]
		p.bus = "Master"
		p.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
		p.finished.connect(p.queue_free)
		add_child(p)
		p.play()

func play_music(path: String):
	if FileAccess.file_exists(path):
		var music_stream = load(path)
		music_player.stream = music_stream
		music_player.play()
		
func stop_music():
	music_player.stop()
