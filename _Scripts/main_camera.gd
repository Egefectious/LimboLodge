extends Camera3D

# Drag your markers from the scene tree into these slots in the Inspector
@export var marker_start: Marker3D
@export var marker_board: Marker3D
@export var marker_shop: Marker3D

# Track where we currently are
var current_view = "start"

func _ready():
	# Force camera to start position immediately
	global_transform = marker_start.global_transform

func move_to_view(view_name: String):
	var target_marker: Marker3D
	
	# Decide which marker to go to
	if view_name == "board":
		target_marker = marker_board
	elif view_name == "shop":
		target_marker = marker_shop
	else:
		target_marker = marker_start
	
	# Create the Tween (The Animation)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Smoothly move Position and Rotation to the target marker
	tween.tween_property(self, "global_transform", target_marker.global_transform, 1.5)
	
	current_view = view_name
	
func _input(event):
	# Press 1, 2, or 3 on your keyboard to test camera moves
	if event.is_action_pressed("ui_accept"): # usually Spacebar
		move_to_view("board")
	if event.is_action_pressed("ui_cancel"): # usually Escape
		move_to_view("start")
