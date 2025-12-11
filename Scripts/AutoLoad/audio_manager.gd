extends Node

var music_player: AudioStreamPlayer
var sounds: Dictionary = {}
var current_pitch = 1.0

func _ready():
	# 1. Setup Music Player (Keep this persistent)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	# 2. Load sounds
	_load_sound("draw", "res://Assets/Audio/draw.wav")
	_load_sound("place", "res://Assets/Audio/place.wav")
	_load_sound("slide", "res://Assets/Audio/slide.wav")
	_load_sound("error", "res://Assets/Audio/error.wav")
	_load_sound("win", "res://Assets/Audio/win.mp3")
	
	# 3. Start Music
	play_music("res://Assets/Audio/music.mp3")

func _load_sound(key: String, path: String):
	if FileAccess.file_exists(path):
		sounds[key] = load(path)
	else:
		print("Warning: Sound missing at ", path)
		
func reset_pitch():
	current_pitch = 1.0
	
func play_sequential(key: String, increment: float = 0.05, max_pitch: float = 2.5):
	play(key, Vector2(current_pitch, current_pitch))
	current_pitch = min(current_pitch + increment, max_pitch)

func play(key: String, pitch_range: Vector2 = Vector2(1.0, 1.0)):
	if sounds.has(key):
		# Create a temporary player for polyphony (overlapping sounds)
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
