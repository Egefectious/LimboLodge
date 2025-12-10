extends Node
class_name AudioManager

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var sounds: Dictionary = {}

func _ready():
	# 1. Setup SFX Player (For short sounds)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	# 2. Setup Music Player (For background loop)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master" 
	# Tip: You can create a "Music" bus in Godot's Audio tab later to control volume separately
	add_child(music_player)
	
	# Load sounds safely
	_load_sound("draw", "res://Assets/Audio/draw.wav")
	_load_sound("place", "res://Assets/Audio/place.wav")
	_load_sound("slide", "res://Assets/Audio/slide.wav")
	_load_sound("error", "res://Assets/Audio/error.wav")
	_load_sound("win", "res://Assets/Audio/win.mp3")
	
	# Start Music Immediately
	#play_music("res://Assets/Audio/music.mp3") # Change extension to .mp3 if needed

func _load_sound(key: String, path: String):
	if FileAccess.file_exists(path):
		sounds[key] = load(path)
	else:
		print("Warning: Sound missing at ", path)

# Play short sound effects
func play(key: String, pitch_range: Vector2 = Vector2(1.0, 1.0)):
	if sounds.has(key):
		sfx_player.stream = sounds[key]
		sfx_player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
		sfx_player.play()

# Play background music
func play_music(path: String):
	if FileAccess.file_exists(path):
		var music_stream = load(path)
		music_player.stream = music_stream
		music_player.play()
	else:
		print("Warning: Music file missing at ", path)
