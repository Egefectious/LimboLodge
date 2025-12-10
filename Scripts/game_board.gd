extends Control

# --- UI References ---
@onready var grid_container = $GridContainer
@onready var limbo_letters = $LimboLetters
@onready var current_slab_display = $RightPanel/CurrentSlabPanel/SlabDisplay
@onready var right_panel_container = $RightPanel

# Stats Labels
@onready var score_label = $RightPanel/StatsPanel/VBoxContainer/ScoreLabel
@onready var target_label = $RightPanel/StatsPanel/VBoxContainer/TargetLabel
@onready var draws_label = $RightPanel/StatsPanel/VBoxContainer/DrawsLabel
@onready var round_label = $RightPanel/StatsPanel/VBoxContainer/RoundLabel
@onready var encounter_label = $RightPanel/StatsPanel/VBoxContainer/EncounterLabel

# Buttons
@onready var draw_button = $RightPanel/HBoxContainer/DrawButton
@onready var score_button = $RightPanel/HBoxContainer/ScoreButton

# --- Managers & Logic ---
var audio: AudioManager
var bench: Bench

var cells: Array = []
var current_slab: Dictionary = {}
var is_animating: bool = false 
# [NEW] Track if we are waiting for a play before allowing another draw
var waiting_for_play: bool = false

const GRID_CELL = preload("res://Scenes/grid_cell.tscn")
const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	audio = AudioManager.new()
	add_child(audio)
	
	bench = Bench.new()
	bench.position = Vector2(110, 550)
	bench.slot_clicked.connect(_on_bench_slot_clicked)
	add_child(bench)
	
	animate_limbo_letters()
	setup_grid()
	update_ui()
	
	draw_button.pressed.connect(_on_draw_button_pressed)
	score_button.pressed.connect(_on_score_button_pressed)

func animate_limbo_letters():
	if limbo_letters.get_child_count() == 0: return
	for i in range(limbo_letters.get_child_count()):
		var panel = limbo_letters.get_child(i)
		if not panel.has_node("Label"): continue
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
	bench.update_display()
	
	# [UPDATED] Button logic: Disabled if animating OR waiting for a play
	# Also disabled if hand is full (standard rule) or no draws left
	var can_draw = Global.draws_remaining > 0 and current_slab.is_empty() and not is_animating and not waiting_for_play
	draw_button.disabled = not can_draw
	
	score_button.disabled = is_animating

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
	
	var slab_visual = SlabBuilder.create_visual(current_slab, 1.0)
	current_slab_display.add_child(slab_visual)
	
	var tween = create_tween()
	tween.set_loops()
	var panel = slab_visual.get_child(0)
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_IN_OUT)

func _on_draw_button_pressed():
	if is_animating: return
	# [UPDATED] Check waiting_for_play
	if Global.draws_remaining > 0 and current_slab.is_empty() and not waiting_for_play:
		audio.play("draw", Vector2(0.9, 1.1))
		current_slab = Global.draw_slab()
		
		# Lock drawing until this slab (or one from bench) is played
		waiting_for_play = true
		
		update_ui()
		
		var tween = create_tween()
		tween.tween_property(draw_button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(draw_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_bench_slot_clicked(index: int):
	if is_animating: return
	
	var benched_slab = Global.bench[index]
	var hand_pos = current_slab_display.global_position + (current_slab_display.size / 2)
	var bench_pos = bench.get_slot_global_position(index)
	
	# Case 1: Pick up from Bench (Move to Hand)
	if current_slab.is_empty() and benched_slab != null:
		animate_transfer(bench_pos, hand_pos, benched_slab, 0.55, 1.0, func():
			current_slab = benched_slab
			Global.bench[index] = null
			audio.play("draw")
			update_ui()
		)
		
	# Case 2: Place on Bench (Move to Slot)
	elif not current_slab.is_empty() and benched_slab == null:
		var hand_data = current_slab
		current_slab = {}
		update_current_slab_display() # Clear visual immediately
		
		animate_transfer(hand_pos, bench_pos, hand_data, 1.0, 0.55, func():
			Global.bench[index] = hand_data
			audio.play("place")
			
			# [FIX] This line allows you to draw again after benching!
			waiting_for_play = false 
			
			update_ui()
		)
		
	# Case 3: Error (Slot full)
	elif not current_slab.is_empty() and benched_slab != null:
		audio.play("error")
		show_message("Slot occupied!", Color("#ff8888"))

func _on_cell_clicked(cell_index: int):
	if is_animating: return
	
	if current_slab.is_empty():
		audio.play("error")
		show_message("Draw a slab first!", Color("#ff8888"))
		return
	
	if Global.placed_slabs[cell_index] != null:
		audio.play("error")
		show_message("Cell already occupied!", Color("#ff8888"))
		return
	
	# Place slab logic
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	audio.play("place")
	
	# [UPDATED] Unlock drawing! The player has fulfilled their turn obligation.
	waiting_for_play = false
	
	var row = cell_index / 5
	var expected_letter = ["L", "I", "M", "B", "O"][row]
	var is_perfect = (current_slab.letter == expected_letter and current_slab.number == Global.grid_numbers[cell_index])
	
	if is_perfect:
		audio.play("win")
		show_message("✨ Perfect Match! +5 coins", Color("#ffff00"))
		create_particle_burst(cells[cell_index].global_position + Vector2(37, 37))
	
	current_slab = {}
	update_ui()

func _on_score_button_pressed():
	if is_animating: return
	
	var result = Global.calculate_score()
	Global.current_score = result.total
	Global.total_coins += result.total
	
	audio.play("win")
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

# --- Helper Functions ---

func animate_transfer(start_pos: Vector2, target_pos: Vector2, data: Dictionary, start_scale: float, end_scale: float, on_complete: Callable):
	is_animating = true
	audio.play("slide")
	
	var floater = SlabBuilder.create_visual(data, 1.0)
	add_child(floater)
	floater.scale = Vector2(start_scale, start_scale)
	floater.position = start_pos - (floater.custom_minimum_size * start_scale / 2)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	var final_pos = target_pos - (floater.custom_minimum_size * end_scale / 2)
	tween.tween_property(floater, "position", final_pos, 0.3)
	tween.tween_property(floater, "scale", Vector2(end_scale, end_scale), 0.3)
	
	tween.chain().tween_callback(func():
		floater.queue_free()
		on_complete.call()
		is_animating = false
	)

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

func advance_round():
	Global.current_round += 1
	# Reset local state
	waiting_for_play = false
	
	if Global.current_round > 3:
		audio.play("win")
		show_message("✨ Encounter Complete! ✨", Color("#ffaa00"))
		await get_tree().create_timer(2.0).timeout
		Global.start_new_encounter()
		get_tree().reload_current_scene()
	else:
		Global.start_new_round()
		update_ui()
