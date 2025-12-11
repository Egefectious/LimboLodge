extends Control

signal cell_clicked(cell_index: int)

@export var cell_index: int = 0
@export var grid_number: int = 1
@export var letter: String = "L"

var placed_slab: Dictionary = {}
var is_hovered: bool = false

@onready var background = $Background
@onready var grid_number_label = $GridNumber
@onready var letter_indicator = $LetterIndicator
@onready var slab_container = $SlabContainer

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	custom_minimum_size = Vector2(75, 75)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	update_display()

func setup(idx: int, num: int, ltr: String):
	cell_index = idx
	grid_number = num
	letter = ltr
	if is_node_ready():
		update_display()

func update_display():
	if grid_number_label:
		grid_number_label.text = str(grid_number)
	
	if letter_indicator:
		letter_indicator.text = letter
		var color_map = {
			"L": Color("#ff5555"),
			"I": Color("#ff9955"),
			"M": Color("#ffff55"),
			"B": Color("#55ff55"),
			"O": Color("#aa55ff")
		}
		letter_indicator.add_theme_color_override("font_color", color_map.get(letter, Color.WHITE))
	
	update_slab_display()

func place_slab(slab: Dictionary):
	placed_slab = slab
	update_slab_display()

func update_slab_display():
	if not slab_container:
		return
		
	for child in slab_container.get_children():
		child.queue_free()
	
	if placed_slab.is_empty():
		if grid_number_label:
			grid_number_label.visible = true
		if letter_indicator:
			letter_indicator.visible = true
		return
	
	if grid_number_label:
		grid_number_label.visible = false
	if letter_indicator:
		letter_indicator.visible = false
	
	# Create layered 3D slab
	var slab_base = Control.new()
	slab_base.custom_minimum_size = Vector2(65, 65)
	
	# Shadow layer
	var shadow = Panel.new()
	shadow.position = Vector2(3, 3)
	shadow.size = Vector2(65, 65)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.5)
	shadow_style.set_corner_radius_all(8)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	slab_base.add_child(shadow)
	
	# Main slab panel
	var slab_panel = Panel.new()
	slab_panel.size = Vector2(65, 65)
	
	var color_map = {
		"L": Color("#ff5555"),
		"I": Color("#ff9955"),
		"M": Color("#ffff55"),
		"B": Color("#55ff55"),
		"O": Color("#aa55ff")
	}
	
	var base_color = color_map.get(placed_slab.letter, Color.WHITE)
	
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 2)
	style.shadow_color = Color(0, 0, 0, 0.6)
	
	# Check if perfect match
	var is_perfect = (placed_slab.letter == letter and placed_slab.number == grid_number)
	if is_perfect:
		style.border_color = Color("#ffff00")
		style.set_border_width_all(4)
		style.shadow_size = 10
		style.shadow_color = Color(1, 1, 0, 0.4)
		
		# Add glow for perfect match
		var glow = Panel.new()
		glow.position = Vector2(-4, -4)
		glow.size = Vector2(73, 73)
		var glow_style = StyleBoxFlat.new()
		glow_style.bg_color = Color(1, 1, 0, 0)
		glow_style.border_color = Color(1, 1, 0, 0.3)
		glow_style.set_border_width_all(3)
		glow_style.set_corner_radius_all(10)
		glow.add_theme_stylebox_override("panel", glow_style)
		slab_base.add_child(glow)
		
		# Animate glow
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(glow_style, "border_color", Color(1, 1, 0, 0.6), 0.8)
		tween.tween_property(glow_style, "border_color", Color(1, 1, 0, 0.2), 0.8)
	else:
		style.border_color = Color("#ffffff")
	
	slab_panel.add_theme_stylebox_override("panel", style)
	
	# Highlight overlay for 3D effect
	var highlight = Panel.new()
	highlight.position = Vector2(3, 3)
	highlight.size = Vector2(59, 28)
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 1, 1, 0.2)
	highlight_style.corner_radius_top_left = 6
	highlight_style.corner_radius_top_right = 6
	highlight.add_theme_stylebox_override("panel", highlight_style)
	slab_panel.add_child(highlight)
	
	# Content
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(0, 0)
	vbox.size = Vector2(65, 65)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -2)
	
	
	var letter_label = Label.new()
	letter_label.text = placed_slab.letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_override("font", CUSTOM_FONT)
	letter_label.add_theme_font_size_override("font_size", 32)
	letter_label.add_theme_color_override("font_color", Color("#1a1520"))
	letter_label.add_theme_constant_override("outline_size", 3)
	letter_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
	
	var number_label = Label.new()
	number_label.text = str(placed_slab.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_override("font", CUSTOM_FONT)
	number_label.add_theme_font_size_override("font_size", 24)
	number_label.add_theme_color_override("font_color", Color("#1a1520"))
	number_label.add_theme_constant_override("outline_size", 2)
	number_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	
	slab_base.add_child(slab_panel)
	slab_container.add_child(slab_base)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_clicked.emit(cell_index)

func _on_mouse_entered():
	is_hovered = true
	if background and placed_slab.is_empty():
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(1.2, 1.2, 1.2), 0.1)

func _on_mouse_exited():
	is_hovered = false
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(1, 1, 1), 0.1)
