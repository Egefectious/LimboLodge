class_name FloatingText extends Label

signal finished

enum Type { NORMAL, PERFECT, LINE_TOTAL, MULT }

func setup(value: String, start_pos: Vector2, color: Color, type: Type = Type.NORMAL):
	text = value
	position = start_pos
	modulate = color
	scale = Vector2.ZERO
	z_index = 100 
	
	# Font setup
	add_theme_font_override("font", load("res://Assets/Fonts/Creepster-Regular.ttf"))
	add_theme_color_override("font_outline_color", Color.BLACK)
	
	var tween = create_tween()
	
	match type:
		Type.NORMAL:
			add_theme_font_size_override("font_size", 32)
			add_theme_constant_override("outline_size", 4)
			tween.set_parallel(true)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position:y", start_pos.y - 50, 0.5)
			tween.chain().tween_property(self, "modulate:a", 0.0, 0.2)
			
		Type.PERFECT:
			add_theme_font_size_override("font_size", 38)
			add_theme_constant_override("outline_size", 6)
			tween.set_parallel(true)
			tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(self, "position:y", start_pos.y - 70, 0.8)
			tween.tween_property(self, "modulate", Color.WHITE, 0.1).set_delay(0.0) # Flash white
			tween.tween_property(self, "modulate", color, 0.2).set_delay(0.1)
			tween.chain().tween_property(self, "modulate:a", 0.0, 0.3)

		Type.MULT:
			add_theme_font_size_override("font_size", 64)
			add_theme_constant_override("outline_size", 12)
			scale = Vector2(0.5, 0.5)
			tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.4).set_trans(Tween.TRANS_BOUNCE)
			tween.parallel().tween_property(self, "rotation", randf_range(-0.1, 0.1), 0.4)
			tween.chain().tween_interval(0.3) # Hang time
			tween.chain().tween_property(self, "scale", Vector2.ZERO, 0.2)
			
		Type.LINE_TOTAL:
			add_theme_font_size_override("font_size", 48)
			add_theme_constant_override("outline_size", 8)
			tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(self, "position:y", start_pos.y - 80, 1.0)
			tween.chain().tween_property(self, "modulate:a", 0.0, 0.3)
	
	tween.tween_callback(func(): finished.emit())
	tween.tween_callback(queue_free)
