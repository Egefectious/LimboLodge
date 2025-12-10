extends Control

@onready var grid_container = $GridContainer
@onready var limbo_letters = $LimboLetters
@onready var current_slab_display = $RightPanel/CurrentSlabPanel/SlabDisplay
@onready var score_label = $RightPanel/StatsPanel/VBoxContainer/ScoreLabel
@onready var target_label = $RightPanel/StatsPanel/VBoxContainer/TargetLabel
@onready var draws_label = $RightPanel/StatsPanel/VBoxContainer/DrawsLabel
@onready var round_label = $RightPanel/StatsPanel/VBoxContainer/RoundLabel
@onready var encounter_label = $RightPanel/StatsPanel/VBoxContainer/EncounterLabel
@onready var draw_button = $RightPanel/HBoxContainer/DrawButton
@onready var score_button = $RightPanel/HBoxContainer/ScoreButton

var cells: Array = []
var current_slab: Dictionary = {}

const GRID_CELL = preload("res://Scenes/grid_cell.tscn")

func _ready():
	animate_limbo_letters()
	setup_grid()
	update_ui()
	draw_button.pressed.connect(_on_draw_button_pressed)
	score_button.pressed.connect(_on_score_button_pressed)

func animate_limbo_letters():
	# Float animation for LIMBO letters
	for i in range(limbo_letters.get_child_count()):
		var letter = limbo_letters.get_child(i)
		var start_y = letter.position.y
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(letter, "position:y", start_y - 3, 1.0 + i * 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(letter, "position:y", start_y + 3, 1.0 + i * 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func setup_grid():
	cells.clear()
	
	for i in range(25):
		var cell = GRID_CELL.instantiate()
		var row = i / 5
		var letter = ["L", "I", "M", "B", "O"][row]
		
		cell.setup(i, Global.grid_numbers[i], letter)
		cell.cell_clicked.connect(_on_cell_clicked)
		
		grid_container.add_child(cell)
		cells.append(cell)
	
	for i in range(25):
		if Global.placed_slabs[i] != null:
			cells[i].place_slab(Global.placed_slabs[i])

func update_ui():
	score_label.text = "\n Score: " + str(Global.current_score)
	target_label.text = " Target: " + str(Global.opponent_target)
	draws_label.text = " Draws: " + str(Global.draws_remaining) + "/" + str(Global.max_draws)
	round_label.text = " Round: " + str(Global.current_round) + "/3"
	encounter_label.text = " Encounter " + str(Global.current_encounter) + "/8"
	
	update_current_slab_display()
	
	draw_button.disabled = Global.draws_remaining <= 0 or not current_slab.is_empty()
	score_button.disabled = false

func update_current_slab_display():
	for child in current_slab_display.get_children():
		child.queue_free()
	
	if current_slab.is_empty():
		var label = Label.new()
		label.text = "Click Draw"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#666666"))
		current_slab_display.add_child(label)
		return
	
	# Create 3D slab display
	var slab_base = Control.new()
	slab_base.custom_minimum_size = Vector2(120, 100)
	
	# Shadow
	var shadow = Panel.new()
	shadow.position = Vector2(5, 5)
	shadow.size = Vector2(120, 100)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.6)
	shadow_style.corner_radius_all = 12
	shadow.add_theme_stylebox_override("panel", shadow_style)
	slab_base.add_child(shadow)
	
	var slab_panel = Panel.new()
	slab_panel.size = Vector2(120, 100)
	
	var color_map = {
		"L": Color("#ff5555"),
		"I": Color("#ff9955"),
		"M": Color("#ffff55"),
		"B": Color("#55ff55"),
		"O": Color("#aa55ff")
	}
	
	var style = StyleBoxFlat.new()
	style.bg_color = color_map.get(current_slab.letter, Color.WHITE)
	style.border_color = Color("#ffffff")
	style.border_width_all = 5
	style.corner_radius_all = 12
	style.shadow_size = 10
	style.shadow_offset = Vector2(3, 3)
	style.shadow_color = Color(0, 0, 0, 0.7)
	slab_panel.add_theme_stylebox_override("panel", style)
	
	# Highlight
	var highlight = Panel.new()
	highlight.position = Vector2(5, 5)
	highlight.size = Vector2(110, 40)
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 1, 1, 0.25)
	highlight_style.corner_radius_top_left = 10
	highlight_style.corner_radius_top_right = 10
	highlight.add_theme_stylebox_override("panel", highlight_style)
	slab_panel.add_child(highlight)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(0, 15)
	vbox.size = Vector2(120, 100)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var letter_label = Label.new()
	letter_label.text = current_slab.letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 42)
	letter_label.add_theme_color_override("font_color", Color("#1a1520"))
	letter_label.add_theme_constant_override("outline_size", 4)
	letter_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	
	var number_label = Label.new()
	number_label.text = str(current_slab.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 28)
	number_label.add_theme_color_override("font_color", Color("#1a1520"))
	number_label.add_theme_constant_override("outline_size", 3)
	number_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	
	slab_base.add_child(slab_panel)
	current_slab_display.add_child(slab_base)
	
	# Pulse animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(slab_panel, "scale", Vector2(1.05, 1.05), 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(slab_panel, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_IN_OUT)

func _on_draw_button_pressed():
	if Global.draws_remaining > 0 and current_slab.is_empty():
		current_slab = Global.draw_slab()
		update_ui()
		
		# Button press animation
		var tween = create_tween()
		tween.tween_property(draw_button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(draw_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_cell_clicked(cell_index: int):
	if current_slab.is_empty():
		show_message("Draw a slab first!", Color("#ff8888"))
		return
	
	if Global.placed_slabs[cell_index] != null:
		show_message("Cell already occupied!", Color("#ff8888"))
		return
	
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	var row = cell_index / 5
	var expected_letter = ["L", "I", "M", "B", "O"][row]
	var is_perfect = (current_slab.letter == expected_letter and current_slab.number == Global.grid_numbers[cell_index])
	
	if is_perfect:
		show_message("✨ Perfect Match! +5 coins", Color("#ffff00"))
		create_particle_burst(cells[cell_index].global_position + Vector2(37, 37))
	
	current_slab = {}
	update_ui()

func create_particle_burst(pos: Vector2):
	for i in range(12):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(1, 1, 0, 1)
		particle.position = pos
		add_child(particle)
		
		var angle = (PI * 2 / 12) * i
		var target = pos + Vector2(cos(angle), sin(angle)) * 40
		
		var tween = create_tween()
		tween.tween_property(particle, "position", target, 0.5).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func _on_score_button_pressed():
	var result = Global.calculate_score()
	Global.current_score = result.total
	Global.total_coins += result.total
	
	show_score_result(result)
	
	if Global.current_score >= Global.opponent_target:
		if Global.current_round < 3:
			var bonus_essence = (3 - Global.current_round) * 10
			Global.essence += bonus_essence
			show_message("🏆 Won Round! +" + str(bonus_essence) + " Essence", Color("#88ff88"))
		advance_round()
	else:
		if Global.current_round >= 3:
			show_message("💀 Lost Encounter!", Color("#ff5555"))
			await get_tree().create_timer(2.0).timeout
			get_tree().reload_current_scene()
		else:
			show_message("Try again next round!", Color("#ffaa55"))
			advance_round()

func show_score_result(result: Dictionary):
	var popup = AcceptDialog.new()
	popup.title = "Round Score"
	
	var result_text = "═══════════════════\n"
	result_text += "   SCORE: %d\n" % result.total
	result_text += "   TARGET: %d\n" % Global.opponent_target
	result_text += "═══════════════════\n\n"
	result_text += "Perfect Matches: %d\n" % result.perfect_matches
	result_text += "  (+%d coins)\n\n" % (result.perfect_matches * 5)
	result_text += "Perfect Lines: %d\n" % result.perfect_lines
	if result.perfect_lines > 0:
		result_text += "  (BONUS x4 multiplier!)\n\n"
	result_text += "═══════════════════\n"
	result_text += "Total Earned: %d coins" % result.total
	
	popup.dialog_text = result_text
	popup.size = Vector2(450, 350)
	
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func show_message(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.position = Vector2(450, 35)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", 15, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(label.queue_free)

func advance_round():
	Global.current_round += 1
	if Global.current_round > 3:
		show_message("✨ Encounter Complete! ✨", Color("#ffaa00"))
		await get_tree().create_timer(2.0).timeout
		Global.start_new_encounter()
		get_tree().reload_current_scene()
	else:
		Global.start_new_round()
		update_ui()
