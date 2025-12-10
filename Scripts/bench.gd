extends Control
class_name Bench

signal slot_clicked(index: int)

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")
var slots: Array = []
var container: HBoxContainer

func _ready():
	setup_visuals()

func setup_visuals():
	# Create Label
	var label = Label.new()
	label.text = "BENCH"
	label.position = Vector2(0, -30) # Relative to this node
	label.add_theme_font_override("font", CUSTOM_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#665577"))
	add_child(label)

	# Create Container
	container = HBoxContainer.new()
	container.size = Vector2(400, 80)
	container.add_theme_constant_override("separation", 10)
	add_child(container)
	
	# Create Slots
	for i in range(5):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(70, 70)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.1, 0.14, 1)
		style.border_color = Color(0.25, 0.2, 0.3, 1)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		slot.add_theme_stylebox_override("panel", style)
		
		# Input
		slot.gui_input.connect(func(ev): _on_input(ev, i))
		
		# Center Container for alignment
		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(center)
		
		container.add_child(slot)
		slots.append(slot)

func update_display():
	for i in range(len(slots)):
		var center = slots[i].get_child(0)
		for child in center.get_children():
			child.queue_free()
			
		var data = Global.bench[i]
		if data != null:
			# Use the new SlabBuilder
			var visual = SlabBuilder.create_visual(data, 0.55)
			center.add_child(visual)

func _on_input(event: InputEvent, index: int):
	# ONLY emit if it's an actual mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(index)

func get_slot_global_position(index: int) -> Vector2:
	return slots[index].global_position + (slots[index].size / 2)
