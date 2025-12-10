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

func _ready():
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
		# Set letter color
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
		
	# Clear existing
	for child in slab_container.get_children():
		child.queue_free()
	
	if placed_slab.is_empty():
		# Show grid number when empty
		if grid_number_label:
			grid_number_label.visible = true
		if letter_indicator:
			letter_indicator.visible = true
		return
	
	# Hide grid info when slab placed
	if grid_number_label:
		grid_number_label.visible = false
	if letter_indicator:
		letter_indicator.visible = false
	
	# Create slab visual
	var slab_panel = Panel.new()
	slab_panel.custom_minimum_size = Vector2(60, 60)
	
	# Color based on letter
	var color_map = {
		"L": Color("#ff5555"),
		"I": Color("#ff9955"),
		"M": Color("#ffff55"),
		"B": Color("#55ff55"),
		"O": Color("#aa55ff")
	}
	
	var style = StyleBoxFlat.new()
	style.bg_color = color_map.get(placed_slab.letter, Color.WHITE)
	style.border_color = Color("#ffffff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_size = 4
	style.shadow_color = Color(0, 0, 0, 0.5)
	slab_panel.add_theme_stylebox_override("panel", style)
	
	# Check if perfect match
	var is_perfect = (placed_slab.letter == letter and placed_slab.number == grid_number)
	if is_perfect:
		style.border_color = Color("#ffff00")  # Gold border for perfect
		style.set_border_width_all(4)
		style.shadow_size = 8
		style.shadow_color = Color(1, 1, 0, 0.3)  # Yellow glow
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var letter_label = Label.new()
	letter_label.text = placed_slab.letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 24)
	letter_label.add_theme_color_override("font_color", Color.BLACK)
	letter_label.add_theme_constant_override("outline_size", 2)
	letter_label.add_theme_color_override("font_outline_color", Color.WHITE)
	
	var number_label = Label.new()
	number_label.text = str(placed_slab.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 18)
	number_label.add_theme_color_override("font_color", Color.BLACK)
	number_label.add_theme_constant_override("outline_size", 1)
	number_label.add_theme_color_override("font_outline_color", Color.WHITE)
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	slab_container.add_child(slab_panel)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_clicked.emit(cell_index)

func _on_mouse_entered():
	is_hovered = true
	if background and placed_slab.is_empty():
		var style = background.get_theme_stylebox("panel")
		if style:
			style.border_color = Color("#6a5f4a")  # Lighter border on hover

func _on_mouse_exited():
	is_hovered = false
	if background:
		var style = background.get_theme_stylebox("panel")
		if style:
			style.border_color = Color("#4a3f2a")  # Normal border
