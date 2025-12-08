extends Node3D

@export var slot_scene: PackedScene # Drag your Slot.tscn here
@export var x_gap: float = 0.5 # Distance between slots
@export var y_gap: float = 0.6

func _ready():
	spawn_grid()

func spawn_grid():
	var letters = ["L", "I", "M", "B", "O"]
	
	for x in range(5):
		for y in range(5):
			var new_slot = slot_scene.instantiate()
			add_child(new_slot)
			
			# Position logic
			new_slot.position = Vector3(x * x_gap, y * y_gap, 0)
			
			# Random Number Logic (Basic for now)
			var rand_num = randi_range(1, 15)
			new_slot.setup(x, y, letters[x], rand_num)
