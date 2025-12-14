extends Control

# === NODE REFERENCES ===
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

# === STATE ===
var cells: Array = []
var current_slab: SlabData = null
var must_place_or_bench: bool = false
var is_animating: bool = false
var score_manager: ScoreManager

# === UI ELEMENTS ===
var next_round_button: Button
var deck_popup: PopupPanel
var score_modal: Panel

# === CONSTANTS ===
const GRID_CELL = preload("res://Scenes/grid_cell.tscn")
const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	_initialize_systems()
	_setup_ui()
	_connect_signals()
	_start_music()

# === INITIALIZATION ===

func _initialize_systems():
	score_manager = ScoreManager.new(self, score_label)
	add_child(score_manager)

func _setup_ui():
	animate_limbo_letters()
	setup_grid()
	setup_extra_ui()
	update_ui()

func _connect_signals():
	draw_button.pressed.connect(_on_draw_button_pressed)
	bench_button.pressed.connect(_on_bench_button_pressed)
	score_button.pressed.connect(_on_score_button_pressed)

func _start_music():
	if AudioManager.music_player and not AudioManager.music_player.playing:
		AudioManager.play_music("res://Assets/Audio/music.mp3")

# === UI SETUP ===

func setup_extra_ui():
	_create_next_round_button()
	_create_deck_popup()
	_create_view_deck_button()

func _create_next_round_button():
	next_round_button = Button.new()
	next_round_button.text = "HOLD & CONTINUE"
	next_round_button.custom_minimum_size = Vector2(300, 50)
	next_round_button.add_theme_font_override("font", CUSTOM_FONT)
	next_round_button.add_theme_font_size_override("font_size", 24)
	next_round_button.modulate = Color(0.6, 1.0, 0.6)
	
	var bottom_area = Control.new()
	bottom_area.position = Vector2(680, 500)
	add_child(bottom_area)
	bottom_area.add_child(next_round_button)
	
	next_round_button.pressed.connect(_on_next_round_pressed)
	next_round_button.hide()

func _create_deck_popup():
	deck_popup = PopupPanel.new()
	deck_popup.size = Vector2(800, 600)
	add_child(deck_popup)
	
	var deck_scroll = ScrollContainer.new()
	deck_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_popup.add_child(deck_scroll)
	
	var deck_grid = GridContainer.new()
	deck_grid.columns = 6
	deck_grid.name = "DeckGrid"
	deck_grid.add_theme_constant_override("h_separation", 15)
	deck_grid.add_theme_constant_override("v_separation", 15)
	deck_scroll.add_child(deck_grid)

func _create_view_deck_button():
	var view_deck_btn = Button.new()
	view_deck_btn.text = "Deck"
	view_deck_btn.position = Vector2(1180, 20)
	view_deck_btn.size = Vector2(80, 40)
	view_deck_btn.pressed.connect(_show_deck)
	add_child(view_deck_btn)

func animate_limbo_letters():
	for i in range(limbo_letters.get_child_count()):
		var panel = limbo_letters.get_child(i)
		var label = panel.get_node("Label")
		var start_y = label.position.y
		
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(label, "position:y", start_y - 4, 1.0 + i * 0.2).set_trans(Tween.TRANS_SINE)
		tween.tween_property(label, "position:y", start_y + 4, 1.0 + i * 0.2).set_trans(Tween.TRANS_SINE)

# === GRID SETUP ===

func setup_grid():
	cells.clear()
	for child in grid_container.get_children(): 
		child.queue_free()
	
	for i in range(25):
		var cell = GRID_CELL.instantiate()
		var row = i / 5
		var letter = Global.LIMBO_LETTERS[row]
		cell.setup(i, Global.grid_numbers[i], letter)
		cell.cell_clicked.connect(_on_cell_clicked)
		grid_container.add_child(cell)
		cells.append(cell)
	
	refresh_grid_visuals()

func refresh_grid_visuals():
	for i in range(25):
		cells[i].place_slab(Global.placed_slabs[i])

# === UI UPDATES ===

func update_ui():
	_update_labels()
	_update_current_slab_display()
	_update_bench_display()
	_update_button_states()

func _update_labels():
	score_label.text = "\n Score: " + str(Global.current_score)
	target_label.text = " Target: " + str(Global.opponent_target)
	draws_label.text = " Draws: " + str(Global.draws_remaining) + "/" + str(Global.max_draws)
	round_label.text = " Round: " + str(Global.current_round) + "/3"
	encounter_label.text = " Encounter " + str(Global.current_encounter)

func _update_button_states():
	var has_slab = (current_slab != null)
	var out_of_draws = (Global.draws_remaining <= 0)
	var is_round_end = out_of_draws
	
	draw_button.disabled = out_of_draws or has_slab
	bench_button.disabled = not has_slab or not must_place_or_bench or Global.benched_slabs.size() >= Global.max_bench_slots
	
	# Next Round / Score Logic
	if is_round_end and Global.current_round < 3:
		next_round_button.show()
		score_button.text = "CASH IN"
		score_button.modulate = Color(1, 0.8, 0.4)
	else:
		next_round_button.hide()
		score_button.text = "SCORE"
		score_button.modulate = Color.WHITE
	
	# Force Score attention if R3 end
	if is_round_end and Global.current_round >= 3:
		score_button.text = "FINISH!"
		score_button.modulate = Color(1, 0.5, 0.5)

func _update_current_slab_display():
	for child in current_slab_display.get_children(): 
		child.queue_free()
	
	if current_slab == null:
		var label = Label.new()
		label.text = "Click Draw"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.GRAY)
		current_slab_display.add_child(label)
	else:
		var visual = SlabBuilder.create_visual(current_slab, 1.2)
		current_slab_display.add_child(visual)

func _update_bench_display():
	for child in bench_display.get_children(): 
		child.queue_free()
	
	for i in range(Global.max_bench_slots):
		var slot_btn = _create_bench_slot(i)
		bench_display.add_child(slot_btn)

func _create_bench_slot(index: int) -> Button:
	var slot_btn = Button.new()
	slot_btn.custom_minimum_size = Vector2(50, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
	style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	slot_btn.add_theme_stylebox_override("normal", style)
	
	if index < Global.benched_slabs.size():
		var slab = Global.benched_slabs[index]
		var container = CenterContainer.new()
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var vis = SlabBuilder.create_visual(slab, 0.4)
		container.add_child(vis)
		slot_btn.add_child(container)
		slot_btn.pressed.connect(_on_benched_slab_clicked.bind(index))
	else:
		slot_btn.disabled = true
	
	return slot_btn

# === BUTTON ACTIONS ===

func _on_draw_button_pressed():
	if Global.draws_remaining > 0 and current_slab == null:
		current_slab = Global.draw_slab()
		must_place_or_bench = true
		AudioManager.play("draw")
		update_ui()

func _on_bench_button_pressed():
	if current_slab and Global.benched_slabs.size() < Global.max_bench_slots:
		Global.benched_slabs.append(current_slab)
		current_slab = null
		must_place_or_bench = false
		AudioManager.play("slide")
		update_ui()
	else:
		AudioManager.play("error")

func _on_benched_slab_clicked(index: int):
	if current_slab != null:
		AudioManager.play("error")
		show_message("Place current slab first!", Color.RED)
		return
	
	current_slab = Global.benched_slabs[index]
	Global.benched_slabs.remove_at(index)
	must_place_or_bench = true
	AudioManager.play("slide")
	show_message("Equipped from bench", Color.CYAN)
	update_ui()

func _on_cell_clicked(cell_index: int):
	if current_slab == null: 
		return
	if Global.placed_slabs[cell_index] != null:
		AudioManager.play("error")
		return
	
	# Place slab
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	# Feedback
	var is_perfect = (current_slab.letter == cells[cell_index].letter and 
					  current_slab.number == cells[cell_index].grid_number)
	if is_perfect:
		AudioManager.play("place", Vector2(1.1, 1.3))
		create_particle_burst(cells[cell_index].global_position + Vector2(37, 37))
	else:
		AudioManager.play("place")
	
	current_slab = null
	must_place_or_bench = false
	update_ui()

func _on_next_round_pressed():
	Global.start_new_round_logic(true)
	AudioManager.play("draw")
	show_message("Draws Refilled! Combo continues...", Color.GREEN)
	update_ui()

# === SCORING ===

func _on_score_button_pressed():
	if is_animating: 
		return
	
	is_animating = true
	_disable_all_buttons()
	
	score_label.text = "SCORE: 0"
	var result = Global.calculate_score()
	
	await score_manager.run_score_sequence(result, cells)
	
	Global.current_score += result.total_score
	Global.coins += result.coins_earned
	Global.obols += result.obols_earned
	
	show_nice_score_screen(result)

func _disable_all_buttons():
	draw_button.disabled = true
	bench_button.disabled = true
	score_button.disabled = true

func show_nice_score_screen(result: Dictionary):
	score_modal = Panel.new()
	score_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	score_modal.add_theme_stylebox_override("panel", style)
	add_child(score_modal)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	score_modal.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 300)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	_add_score_header(vbox)
	_add_score_total(vbox, result)
	_add_score_details(vbox, result)
	_add_score_rewards(vbox, result)
	_add_continue_button(vbox)

func _add_score_header(vbox: VBoxContainer):
	var header = Label.new()
	header.text = "ROUND COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", CUSTOM_FONT)
	header.add_theme_font_size_override("font_size", 64)
	header.add_theme_color_override("font_color", Color.GOLD)
	header.pivot_offset = Vector2(250, 32)
	vbox.add_child(header)
	
	var t = create_tween().set_loops()
	t.tween_property(header, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(header, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

func _add_score_total(vbox: VBoxContainer, result: Dictionary):
	var score_txt = Label.new()
	score_txt.text = str(result.total_score)
	score_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_txt.add_theme_font_override("font", CUSTOM_FONT)
	score_txt.add_theme_font_size_override("font_size", 96)
	score_txt.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(score_txt)

func _add_score_details(vbox: VBoxContainer, result: Dictionary):
	var details = Label.new()
	details.text = "Perfect Matches: %d  | Line Bonuses: %d" % [result.perfect_matches, result.perfect_lines]
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(details)

func _add_score_rewards(vbox: VBoxContainer, result: Dictionary):
	var rewards = Label.new()
	rewards.text = "+%d Coins   +%d Obols" % [result.coins_earned, result.obols_earned]
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	rewards.add_theme_font_size_override("font_size", 24)
	vbox.add_child(rewards)

func _add_continue_button(vbox: VBoxContainer):
	var btn = Button.new()
	btn.text = "CONTINUE"
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_override("font", CUSTOM_FONT)
	btn.add_theme_font_size_override("font_size", 32)
	btn.pressed.connect(_on_score_confirmed)
	vbox.add_child(btn)
	
	btn.modulate.a = 0
	create_tween().tween_property(btn, "modulate:a", 1.0, 0.5).set_delay(0.5)

# === GAME END LOGIC ===

func _on_score_confirmed():
	score_modal.queue_free()
	is_animating = false
	
	Global.clear_board()
	refresh_grid_visuals()
	
	if Global.current_score >= Global.opponent_target:
		show_message("ENCOUNTER COMPLETE!", Color.GOLD)
		await get_tree().create_timer(1.5).timeout
		
		# CHANGE: Go to Shop instead of reloading game directly!
		# We do NOT call Global.start_new_encounter() yet, 
		# we let the Shop handle that transition.
		get_tree().change_scene_to_file("res://Scenes/shop.tscn")
		
	elif Global.current_round >= 3:
		show_message("GAME OVER", Color.RED)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		Global.start_new_round_logic(false)
		update_ui()

# === VISUAL EFFECTS ===

func show_message(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.position = Vector2(450, 50)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", 20, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func create_particle_burst(pos: Vector2):
	for i in range(10):
		var p = ColorRect.new()
		p.size = Vector2(5, 5)
		p.color = Color.GOLD
		p.position = pos
		add_child(p)
		
		var dest = pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var tween = create_tween()
		tween.tween_property(p, "position", dest, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0, 0.4)
		tween.tween_callback(p.queue_free)

# DECK VIEWER
func _show_deck():
	var actual_grid = deck_popup.get_child(0).get_child(0)
	for c in actual_grid.get_children(): c.queue_free()
	var sorted_deck = Global.deck.duplicate()
	sorted_deck.sort_custom(func(a, b): 
		if a.letter != b.letter: return a.letter < b.letter
		return a.number < b.number
	)
	for slab in sorted_deck:
		var visual = SlabBuilder.create_visual(slab, 0.5)
		actual_grid.add_child(visual)
	deck_popup.popup_centered()
