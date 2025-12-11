class_name SlabBuilder extends Object

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

# CHANGED: Type hint is now 'SlabData', not 'Dictionary'
static func create_visual(slab_data: SlabData, scale_factor: float = 1.0) -> Control:
	var base_w = 120.0 * scale_factor
	var base_h = 100.0 * scale_factor
	
	var slab_base = Control.new()
	slab_base.custom_minimum_size = Vector2(base_w, base_h)
	slab_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var slab_panel = Panel.new()
	slab_panel.size = Vector2(base_w, base_h)
	slab_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var color_map = {
		"L": Color("#ff5555"), "I": Color("#ff9955"), "M": Color("#ffff55"),
		"B": Color("#55ff55"), "O": Color("#aa55ff")
	}
	
	var style = StyleBoxFlat.new()
	
	# CHANGED: Access properties directly from the object
	var letter = slab_data.letter 
	style.bg_color = color_map.get(letter, Color.WHITE)
	
	style.border_color = Color("#ffffff")
	style.set_border_width_all(int(5 * scale_factor))
	style.set_corner_radius_all(int(12 * scale_factor))
	style.shadow_size = int(5 * scale_factor)
	style.shadow_offset = Vector2(2, 2)
	style.shadow_color = Color(0, 0, 0, 0.5)
	slab_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(base_w, base_h)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(-5 * scale_factor))
	
	var letter_label = Label.new()
	letter_label.text = str(letter)
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_override("font", CUSTOM_FONT)
	letter_label.add_theme_font_size_override("font_size", int(52 * scale_factor))
	letter_label.add_theme_color_override("font_color", Color("#1a1520"))
	
	var number_label = Label.new()
	
	# CHANGED: Access properties directly from the object
	number_label.text = str(slab_data.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_override("font", CUSTOM_FONT)
	number_label.add_theme_font_size_override("font_size", int(32 * scale_factor))
	number_label.add_theme_color_override("font_color", Color("#1a1520"))
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	slab_base.add_child(slab_panel)
	
	return slab_base
