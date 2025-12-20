class_name SlabBuilder extends Object

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

# Creates a high-quality 3D Runestone visual
static func create_visual(slab_data: SlabData, scale_factor: float = 1.0) -> Control:
	# Base size matches the grid cells roughly (scaled)
	var base_size = Vector2(75, 75) * scale_factor
	
	var slab_base = Control.new()
	slab_base.custom_minimum_size = base_size
	slab_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# --- 1. DROP SHADOW (Depth) ---
	var shadow = Panel.new()
	shadow.size = base_size
	shadow.position = Vector2(0, 4 * scale_factor) # Offset down
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.5)
	shadow_style.set_corner_radius_all(int(8 * scale_factor))
	shadow.add_theme_stylebox_override("panel", shadow_style)
	slab_base.add_child(shadow)
	
	# --- 2. STONE BODY (3D Bevel) ---
	var slab_panel = Panel.new()
	slab_panel.size = base_size
	slab_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Deep, rich colors for the stones
	var color_map = {
		"L": Color("#d32f2f"), # Crimson
		"I": Color("#f57c00"), # Amber
		"M": Color("#fbc02d"), # Gold
		"B": Color("#388e3c"), # Emerald
		"O": Color("#7b1fa2")  # Amethyst
	}
	var base_hue = color_map.get(slab_data.letter, Color(0.4, 0.4, 0.4))
	
	var stone_style = StyleBoxFlat.new()
	stone_style.bg_color = base_hue
	stone_style.set_corner_radius_all(int(8 * scale_factor))
	
	# The "3D Bevel" Trick: Thick bottom border in a darker shade
	stone_style.border_color = base_hue.darkened(0.35)
	stone_style.border_width_bottom = int(6 * scale_factor)
	stone_style.border_width_top = 0
	stone_style.border_width_left = 0
	stone_style.border_width_right = 0
	
	slab_panel.add_theme_stylebox_override("panel", stone_style)
	
	# --- 3. TEXT CONTENT (Etched Look) ---
	var vbox = VBoxContainer.new()
	vbox.size = base_size
	# Adjust alignment to account for the thick bottom border
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER 
	vbox.position = Vector2(0, -2 * scale_factor) 
	vbox.add_theme_constant_override("separation", int(-6 * scale_factor))
	
	# Letter
	var l_lbl = Label.new()
	l_lbl.text = slab_data.letter
	l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_lbl.add_theme_font_override("font", CUSTOM_FONT)
	l_lbl.add_theme_font_size_override("font_size", int(38 * scale_factor))
	l_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	# Etched Shadow
	l_lbl.add_theme_color_override("font_shadow_color", base_hue.darkened(0.6))
	l_lbl.add_theme_constant_override("shadow_offset_y", int(2 * scale_factor))
	l_lbl.add_theme_constant_override("shadow_outline_size", 0)
	
	# Number
	var n_lbl = Label.new()
	n_lbl.text = str(slab_data.number)
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_lbl.add_theme_font_override("font", CUSTOM_FONT)
	n_lbl.add_theme_font_size_override("font_size", int(28 * scale_factor))
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	n_lbl.add_theme_color_override("font_shadow_color", base_hue.darkened(0.6))
	n_lbl.add_theme_constant_override("shadow_offset_y", int(2 * scale_factor))
	
	vbox.add_child(l_lbl)
	vbox.add_child(n_lbl)
	slab_panel.add_child(vbox)
	
	slab_base.add_child(slab_panel)
	
	return slab_base
