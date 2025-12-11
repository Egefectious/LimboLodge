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
@onready var bench_button = $RightPanel/HBoxContainer/BenchButton
@onready var score_button = $RightPanel/HBoxContainer/ScoreButton
@onready var bench_display = $CenterPanel/BenchPanel/BenchContainer

var cells: Array = []
var current_slab: SlabData = null
var must_place_or_bench: bool = false
var is_animating: bool = false

const GRID_CELL = preload("res://Scenes/grid_cell.tscn")
const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():

	animate_limbo_letters()
	setup_grid()
	update_ui()
	draw_button.pressed.connect(_on_draw_button_pressed)
	bench_button.pressed.connect(_on_bench_button_pressed)
	score_button.pressed.connect(_on_score_button_pressed)

func animate_limbo_letters():
	for i in range(limbo_letters.get_child_count()):
		var panel = limbo_letters.get_child(i)
		var label = panel.get_node("Label")
		
		var start_y = label.position.y
		var tween = create_tween()
		tween.set_loops()
		
		tween.tween_property(label, "position:y", start_y - 4, 1.0 + i * 0.2)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			
		tween.tween_property(label, "position:y", start_y + 4, 1.0 + i * 0.2)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			
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
	update_bench_display()
	
	# Can only draw if: have draws remaining AND (no current slab OR haven't placed/benched yet)
	draw_button.disabled = Global.draws_remaining <= 0 or (not current_slab == null and must_place_or_bench)
	bench_button.disabled = current_slab == null or not must_place_or_bench or Global.benched_slabs.size() >= Global.max_bench_slots
	score_button.disabled = false

func update_current_slab_display():
	for child in current_slab_display.get_children():
		child.queue_free()
	
	if current_slab == null:
		var label = Label.new()
		label.text = "Click Draw"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#666666"))
		current_slab_display.add_child(label)
		return
	
	create_slab_visual(current_slab_display, SlabData, Vector2(120, 100))

func update_bench_display():
	for child in bench_display.get_children():
		child.queue_free()
	
	# Show bench slots (max 5)
	for i in range(Global.max_bench_slots):
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(50, 50)
		
		# Style the button as a slot
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.3)
		style_normal.border_color = Color(0.3, 0.3, 0.3, 0.5)
		style_normal.set_border_width_all(2)
		style_normal.set_corner_radius_all(6)
		slot_button.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.15, 0.15, 0.15, 0.5)
		style_hover.border_color = Color(0.5, 0.5, 0.5, 0.7)
		style_hover.set_border_width_all(2)
		style_hover.set_corner_radius_all(6)
		slot_button.add_theme_stylebox_override("hover", style_hover)
		
		if i < Global.benched_slabs.size():
			# Slot has a slab - show it
			var slab = Global.benched_slabs[i]
			var container = CenterContainer.new()
			container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			create_slab_visual(container, slab, Vector2(45, 45))
			slot_button.add_child(container)
			slot_button.pressed.connect(func(): _on_benched_slab_clicked(i))
		else:
			# Empty slot - show it's empty
			var empty_label = Label.new()
			empty_label.text = str(i + 1)
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_size_override("font_size", 20)
			empty_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.5))
			empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_label.size = Vector2(50, 50)
			slot_button.add_child(empty_label)
			slot_button.disabled = true
		
		bench_display.add_child(slot_button)

func create_slab_visual(parent: Node, slab, size: Vector2):
	var slab_base = Control.new()
	slab_base.custom_minimum_size = size
	
	var shadow = Panel.new()
	shadow.position = Vector2(3, 3)
	shadow.size = size
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.6)
	shadow_style.set_corner_radius_all(8)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	slab_base.add_child(shadow)
	
	var slab_panel = Panel.new()
	slab_panel.size = size
	
	var color_map = {
		"L": Color("#ff5555"),
		"I": Color("#ff9955"),
		"M": Color("#ffff55"),
		"B": Color("#55ff55"),
		"O": Color("#aa55ff")
	}
	
	var style = StyleBoxFlat.new()
	style.bg_color = color_map.get(slab.letter, Color.WHITE)
	style.border_color = Color("#ffffff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 2)
	style.shadow_color = Color(0, 0, 0, 0.7)
	slab_panel.add_theme_stylebox_override("panel", style)
	
	var highlight = Panel.new()
	highlight.position = Vector2(3, 3)
	highlight.size = Vector2(size.x - 6, size.y * 0.4)
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 1, 1, 0.25)
	highlight_style.corner_radius_top_left = 6
	highlight_style.corner_radius_top_right = 6
	highlight.add_theme_stylebox_override("panel", highlight_style)
	slab_panel.add_child(highlight)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(0, 0)
	vbox.size = size
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -3)
	
	var letter_label = Label.new()
	letter_label.text = slab.letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_override("font", CUSTOM_FONT)
	letter_label.add_theme_font_size_override("font_size", int(size.y * 0.4))
	letter_label.add_theme_color_override("font_color", Color("#1a1520"))
	letter_label.add_theme_constant_override("outline_size", 4)
	letter_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	
	var number_label = Label.new()
	number_label.text = str(slab.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_override("font", CUSTOM_FONT)
	number_label.add_theme_font_size_override("font_size", int(size.y * 0.28))
	number_label.add_theme_color_override("font_color", Color("#1a1520"))
	number_label.add_theme_constant_override("outline_size", 3)
	number_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	
	slab_base.add_child(slab_panel)
	parent.add_child(slab_base)

func _on_draw_button_pressed():
	if Global.draws_remaining > 0 and (current_slab == null or not must_place_or_bench):
		current_slab = Global.draw_slab()
		must_place_or_bench = true
		AudioManager.play("draw")
		update_ui()
		
		var tween = create_tween()
		tween.tween_property(draw_button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(draw_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_bench_button_pressed():
	if not current_slab == null and must_place_or_bench:
		if Global.benched_slabs.size() >= Global.max_bench_slots:
			AudioManager.play("error")
			show_message("Bench is full! (5 max)", Color("#ff8888"))
			return
		
		Global.benched_slabs.append(current_slab)
		AudioManager.play("slide")
		show_message("Slab benched", Color("#88aaff"))
		SlabData
		must_place_or_bench = false
		update_ui()

func _on_benched_slab_clicked(index: int):
	if not current_slab == null:
		AudioManager.play("error")
		show_message("Place or bench current slab first!", Color("#ff8888"))
		return
	
	current_slab = Global.benched_slabs[index]
	Global.benched_slabs.remove_at(index)
	must_place_or_bench = true
	AudioManager.play("slide")
	show_message("Retrieved from bench", Color("#88aaff"))
	update_ui()

func _on_cell_clicked(cell_index: int):
	if current_slab == null:
		AudioManager.play("error")
		show_message("Draw a slab first!", Color("#ff8888"))
		return
	
	if not must_place_or_bench:
		AudioManager.play("error")
		show_message("Draw a new slab first!", Color("#ff8888"))
		return
	
	if Global.placed_slabs[cell_index] != null:
		AudioManager.play("error")
		show_message("Cell already occupied!", Color("#ff8888"))
		return
	
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	var row = cell_index / 5
	var expected_letter = ["L", "I", "M", "B", "O"][row]
	var is_perfect = (current_slab.letter == expected_letter and current_slab.number == Global.grid_numbers[cell_index])
	var is_letter_correct = (current_slab.letter == expected_letter)
	
	if is_perfect:
		AudioManager.play("place", Vector2(1.1, 1.3))
		show_message("✨ Perfect! +" + str(current_slab.number + 25) + " pts", Color("#ffff00"))
		create_particle_burst(cells[cell_index].global_position + Vector2(37, 37))
	elif is_letter_correct:
		AudioManager.play("place", Vector2(1.0, 1.2))
		show_message("Letter Match! +" + str(current_slab.number + 10) + " pts", Color("#88ff88"))
	else:
		AudioManager.play("place")
		show_message("+" + str(current_slab.number) + " pts", Color("#ffffff"))
	
	SlabData
	must_place_or_bench = false
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
	if is_animating: return
	
	var result = Global.calculate_score()
	
	# Update Global Game State
	Global.current_score = result.total_score
	Global.coins += result.coins_earned
	Global.obols += result.obols_earned # New Currency!
	
	AudioManager.play("win")
	show_score_result(result)
	
	if Global.current_score >= Global.opponent_target:
		# Check for Early Win (Essence)
		if Global.current_round < 3:
			var bonus_essence = (3 - Global.current_round) * 10
			Global.essence += bonus_essence
			show_message("🏆 Early Win! +" + str(bonus_essence) + " Essence", Color("#aa88ff"))
		
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
	result_text += "   SCORE: %d\n" % result.total_score
	result_text += "   TARGET: %d\n" % Global.opponent_target
	result_text += "═══════════════════\n\n"
	result_text += "Matches: %d (+%d Coins)\n" % [result.perfect_matches, result.coins_earned]
	result_text += "Lines: %d (+%d Obols)\n" % [result.perfect_lines, result.obols_earned]
	
	if result.perfect_lines > 0:
		result_text += "  (Line Bonus Active!)\n\n"
	
	popup.dialog_text = result_text
	
	if result.line_details.size() > 0:
		result_text += "LINE BONUSES:\n"
		for detail in result.line_details:
			result_text += "  %s: x%d = +%d\n" % [detail.type, detail.multiplier, detail.bonus]
		result_text += "\n"
	
	result_text += "═══════════════════\n"
	result_text += "Total Earned: %d coins" % result.total
	
	popup.dialog_text = result_text
	popup.size = Vector2(500, 450)
	
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
		must_place_or_bench = false
		update_ui()
