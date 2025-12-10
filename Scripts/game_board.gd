extends Control

@onready var grid_container = $GridContainer
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

const GRID_CELL = preload("res://scenes/grid_cell.tscn")

func _ready():
	setup_grid()
	update_ui()
	draw_button.pressed.connect(_on_draw_button_pressed)
	score_button.pressed.connect(_on_score_button_pressed)

func setup_grid():
	cells.clear()
	
	# Create 5x5 grid
	for i in range(25):
		var cell = GRID_CELL.instantiate()
		var row = i / 5
		var col = i % 5
		var letter = ["L", "I", "M", "B", "O"][row]
		
		cell.setup(i, Global.grid_numbers[i], letter)
		cell.cell_clicked.connect(_on_cell_clicked)
		
		grid_container.add_child(cell)
		cells.append(cell)
	
	# Restore placed slabs if any
	for i in range(25):
		if Global.placed_slabs[i] != null:
			cells[i].place_slab(Global.placed_slabs[i])

func update_ui():
	score_label.text = "Score: " + str(Global.current_score)
	target_label.text = "Target: " + str(Global.opponent_target)
	draws_label.text = "Draws: " + str(Global.draws_remaining) + "/" + str(Global.max_draws)
	round_label.text = "Round: " + str(Global.current_round) + "/3"
	encounter_label.text = "Encounter: " + str(Global.current_encounter) + "/8"
	
	update_current_slab_display()
	
	draw_button.disabled = Global.draws_remaining <= 0 or not current_slab.is_empty()
	score_button.disabled = false

func update_current_slab_display():
	# Clear existing
	for child in current_slab_display.get_children():
		child.queue_free()
	
	if current_slab.is_empty():
		var label = Label.new()
		label.text = "Click Draw"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("#888888"))
		current_slab_display.add_child(label)
		return
	
	# Show current slab
	var slab_panel = Panel.new()
	slab_panel.custom_minimum_size = Vector2(100, 80)
	
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
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.6)
	slab_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var letter_label = Label.new()
	letter_label.text = current_slab.letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 36)
	letter_label.add_theme_color_override("font_color", Color.BLACK)
	letter_label.add_theme_constant_override("outline_size", 3)
	letter_label.add_theme_color_override("font_outline_color", Color.WHITE)
	
	var number_label = Label.new()
	number_label.text = str(current_slab.number)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 24)
	number_label.add_theme_color_override("font_color", Color.BLACK)
	number_label.add_theme_constant_override("outline_size", 2)
	number_label.add_theme_color_override("font_outline_color", Color.WHITE)
	
	vbox.add_child(letter_label)
	vbox.add_child(number_label)
	slab_panel.add_child(vbox)
	current_slab_display.add_child(slab_panel)

func _on_draw_button_pressed():
	if Global.draws_remaining > 0 and current_slab.is_empty():
		current_slab = Global.draw_slab()
		update_ui()

func _on_cell_clicked(cell_index: int):
	if current_slab.is_empty():
		# Show feedback
		show_message("Draw a slab first!")
		return
	
	if Global.placed_slabs[cell_index] != null:
		# Show feedback
		show_message("Cell already occupied!")
		return
	
	# Place slab
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	# Check if perfect match
	var row = cell_index / 5
	var expected_letter = ["L", "I", "M", "B", "O"][row]
	var is_perfect = (current_slab.letter == expected_letter and current_slab.number == Global.grid_numbers[cell_index])
	
	if is_perfect:
		show_message("Perfect Match! +5 coins", Color.GOLD)
	
	current_slab = {}
	update_ui()

func _on_score_button_pressed():
	var result = Global.calculate_score()
	Global.current_score = result.total
	Global.total_coins += result.total
	
	# Show result popup
	show_score_result(result)
	
	# Check win/loss
	if Global.current_score >= Global.opponent_target:
		# Win round
		if Global.current_round < 3:
			# Early win bonus
			var bonus_essence = (3 - Global.current_round) * 10
			Global.essence += bonus_essence
			show_message("Won Round! +" + str(bonus_essence) + " Essence Bonus", Color.GREEN)
		advance_round()
	else:
		# Lost round
		if Global.current_round >= 3:
			# Lost encounter
			show_message("Lost Encounter!", Color.RED)
			await get_tree().create_timer(2.0).timeout
			get_tree().reload_current_scene()
		else:
			show_message("Didn't reach target. Try again!", Color.YELLOW)
			advance_round()

func show_score_result(result: Dictionary):
	var popup = AcceptDialog.new()
	popup.title = "Round Score"
	
	var result_text = "Score: %d\nTarget: %d\n\n" % [result.total, Global.opponent_target]
	result_text += "Perfect Matches: %d (+%d coins)\n" % [result.perfect_matches, result.perfect_matches * 5]
	result_text += "Perfect Lines: %d\n" % result.perfect_lines
	result_text += "\nTotal Coins Earned: %d" % result.total
	
	popup.dialog_text = result_text
	popup.size = Vector2(400, 300)
	
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func show_message(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.position = Vector2(400, 40)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func advance_round():
	Global.current_round += 1
	if Global.current_round > 3:
		# Encounter complete
		show_message("Encounter Complete! Going to shop...", Color.GOLD)
		await get_tree().create_timer(2.0).timeout
		# TODO: Go to shop scene
		print("Going to shop (not implemented yet)")
		Global.start_new_encounter()
		get_tree().reload_current_scene()
	else:
		Global.start_new_round()
		update_ui()
