extends Control

signal cell_clicked(cell_index: int)

@export var cell_index: int = 0
@export var grid_number: int = 1
@export var letter: String = "L"

var placed_slab: SlabData = null
var is_hovered: bool = false
var base_style: StyleBoxFlat = null
var current_panel_style: StyleBoxFlat = null 
var current_panel_node: Panel = null
var original_y: float = 0.0

@onready var background = $Background
@onready var grid_number_label = $GridNumber
@onready var letter_indicator = $LetterIndicator
@onready var slab_container = $SlabContainer

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	custom_minimum_size = Vector2(75, 75)
	pivot_offset = custom_minimum_size / 2
	
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 1. SAVE the original style from the scene
		var current = background.get_theme_stylebox("panel")
		if current:
			base_style = current.duplicate()
	
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

func place_slab(slab: SlabData):
	placed_slab = slab
	update_display()

func update_display():
	if grid_number_label: grid_number_label.text = str(grid_number)
	if letter_indicator:
		letter_indicator.text = letter
		var color_map = {"L": Color("#ff5555"), "I": Color("#ff9955"), "M": Color("#ffff55"), "B": Color("#55ff55"), "O": Color("#aa55ff")}
		letter_indicator.add_theme_color_override("font_color", color_map.get(letter, Color.WHITE))
	update_slab_display()

func update_slab_display():
	if not slab_container: return
	for child in slab_container.get_children(): child.queue_free()
	
	current_panel_style = null
	current_panel_node = null
	
	if placed_slab == null:
		if grid_number_label: grid_number_label.visible = true
		if letter_indicator: letter_indicator.visible = true
		return
	
	if grid_number_label: grid_number_label.visible = false
	if letter_indicator: letter_indicator.visible = false
	
	# --- VISUAL BUILDER ---
	var slab_base = Control.new()
	slab_base.custom_minimum_size = Vector2(65, 65)
	
	var shadow = Panel.new()
	shadow.position = Vector2(3, 3)
	shadow.size = Vector2(65, 65)
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0,0,0,0.5)
	s_style.set_corner_radius_all(8)
	shadow.add_theme_stylebox_override("panel", s_style)
	slab_base.add_child(shadow)
	
	var slab_panel = Panel.new()
	slab_panel.size = Vector2(65, 65)
	
	var color_map = {"L": Color("#ff5555"), "I": Color("#ff9955"), "M": Color("#ffff55"), "B": Color("#55ff55"), "O": Color("#aa55ff")}
	var base_color = color_map.get(placed_slab.letter, Color.WHITE)
	
	current_panel_style = StyleBoxFlat.new()
	current_panel_style.bg_color = base_color
	current_panel_style.set_corner_radius_all(8)
	current_panel_style.set_border_width_all(3)
	current_panel_style.border_color = Color.WHITE
	
	current_panel_node = slab_panel
	
	if placed_slab.letter == letter and placed_slab.number == grid_number:
		current_panel_style.border_color = Color("#ffff00")
		current_panel_style.set_border_width_all(4)
	
	slab_panel.add_theme_stylebox_override("panel", current_panel_style)
	
	var glare = Panel.new()
	glare.position = Vector2(3, 3)
	glare.size = Vector2(59, 28)
	var g_style = StyleBoxFlat.new()
	g_style.bg_color = Color(1,1,1,0.2)
	g_style.corner_radius_top_left = 6
	g_style.corner_radius_top_right = 6
	glare.add_theme_stylebox_override("panel", g_style)
	slab_panel.add_child(glare)
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(65, 65)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -2)
	
	var l_lbl = Label.new()
	l_lbl.text = placed_slab.letter
	l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_lbl.add_theme_font_override("font", CUSTOM_FONT)
	l_lbl.add_theme_font_size_override("font_size", 32)
	l_lbl.add_theme_color_override("font_color", Color("#1a1520"))
	
	var n_lbl = Label.new()
	n_lbl.text = str(placed_slab.number)
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_lbl.add_theme_font_override("font", CUSTOM_FONT)
	n_lbl.add_theme_font_size_override("font_size", 24)
	n_lbl.add_theme_color_override("font_color", Color("#1a1520"))
	
	vbox.add_child(l_lbl)
	vbox.add_child(n_lbl)
	slab_panel.add_child(vbox)
	slab_base.add_child(slab_panel)
	slab_container.add_child(slab_base)

func highlight_active(active: bool):
	if not current_panel_style or not current_panel_node: return
	var tween = create_tween()
	if active:
		tween.set_loops()
		tween.tween_property(current_panel_style, "border_color", Color.GOLD, 0.5)
		tween.parallel().tween_property(current_panel_node, "scale", Vector2(1.05, 1.05), 0.5)
		tween.tween_property(current_panel_style, "border_color", Color.WHITE, 0.5)
		tween.parallel().tween_property(current_panel_node, "scale", Vector2(1.0, 1.0), 0.5)
	else:
		tween.kill()
		current_panel_node.scale = Vector2.ONE
		current_panel_style.border_color = Color.WHITE
		if placed_slab and placed_slab.letter == letter and placed_slab.number == grid_number:
			current_panel_style.border_color = Color("#ffff00")

# --- NEW: VOID SHOCKWAVE ---
func play_shockwave():
	# Creates an expanding transparent ring
	var shock = Panel.new()
	shock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shock.position = Vector2(37, 37) # Center
	shock.size = Vector2(0, 0)
	
	var s = StyleBoxFlat.new()
	s.bg_color = Color.TRANSPARENT
	s.border_width_left = 4
	s.border_width_top = 4
	s.border_width_right = 4
	s.border_width_bottom = 4
	s.border_color = Color(1, 1, 0.5, 1) # Yellow/Gold ring
	s.set_corner_radius_all(50)
	shock.add_theme_stylebox_override("panel", s)
	
	add_child(shock)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shock, "size", Vector2(150, 150), 0.5)
	tween.tween_property(shock, "position", Vector2(-38, -38), 0.5)
	tween.tween_property(s, "border_color:a", 0.0, 0.5)
	tween.chain().tween_callback(shock.queue_free)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_clicked.emit(cell_index)

func _on_mouse_entered():
	is_hovered = true
	
	if placed_slab == null:
		AudioManager.play("hover", Vector2(1.0, 1.2))
		
	# Animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	
	# Glow Effect
	if background and base_style:
		var new_style = base_style.duplicate()
		new_style.border_color = Color("#6a1b9a") # Purple Glow
		# 2. OVERRIDE with the glow style
		background.add_theme_stylebox_override("panel", new_style)

func _on_mouse_exited():
	is_hovered = false
	# Reset Animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Reset Glow
	if background and base_style:
		# 3. RESTORE the saved original style instead of removing the override
		background.add_theme_stylebox_override("panel", base_style)
