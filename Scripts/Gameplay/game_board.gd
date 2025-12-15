extends Control

# === NODE REFERENCES - PROFESSIONAL LAYOUT ===
@onready var grid_container = $MainContainer/GameLayout/CenterColumn/GridPanel/BoardLayout/GridContainer
@onready var limbo_letters = $MainContainer/GameLayout/CenterColumn/GridPanel/BoardLayout/LimboLetters

# Title & Caller
@onready var game_title = $MainContainer/GameLayout/CenterColumn/TitleBar/Content/GameTitle
@onready var caller_avatar = $MainContainer/GameLayout/CenterColumn/CallerPanel/Content/CallerAvatar/AvatarLabel
@onready var caller_name = $MainContainer/GameLayout/CenterColumn/CallerPanel/Content/DialogueBox/CallerName
@onready var caller_text = $MainContainer/GameLayout/CenterColumn/CallerPanel/Content/DialogueBox/CallerText

# Current Slab
@onready var current_slab_display = $MainContainer/GameLayout/RightSidebar/CurrentSlabPanel/Content/SlabDisplay

# Stats Cards
@onready var score_label = $MainContainer/GameLayout/RightSidebar/StatsGrid/ScoreCard/Content/ScoreLabel
@onready var target_label = $MainContainer/GameLayout/RightSidebar/StatsGrid/TargetCard/Content/TargetLabel
@onready var draws_label = $MainContainer/GameLayout/RightSidebar/StatsGrid/DrawsCard/Content/DrawsLabel
@onready var round_label = $MainContainer/GameLayout/RightSidebar/StatsGrid/RoundCard/Content/RoundLabel


# Buttons
@onready var draw_button = $MainContainer/GameLayout/RightSidebar/ActionButtons/DrawButton
@onready var bench_button = $MainContainer/GameLayout/RightSidebar/ActionButtons/BenchButton
@onready var score_button = $MainContainer/GameLayout/RightSidebar/ActionButtons/ScoreButton

# Bench
@onready var bench_display = $MainContainer/GameLayout/CenterColumn/GridPanel/BoardLayout/BenchSection

# Artifacts
@onready var artifact_grid = $MainContainer/GameLayout/RightSidebar/ArtifactsPanel/Content/ArtifactGrid

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
	next_round_button.custom_minimum_size = Vector2(340, 54)
	next_round_button.add_theme_font_override("font", CUSTOM_FONT)
	next_round_button.add_theme_font_size_override("font_size", 24)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.137255, 0.27451, 0.0666667, 1)
	style.border_color = Color(0.247059, 0.490196, 0.117647, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	next_round_button.add_theme_stylebox_override("normal", style)
	
	var bottom_area = Control.new()
	bottom_area.position = Vector2(470, 600)
	add_child(bottom_area)
	bottom_area.add_child(next_round_button)
	
	next_round_button.pressed.connect(_on_next_round_pressed)
	next_round_button.hide()

func _create_deck_popup():
	deck_popup = PopupPanel.new()
	deck_popup.size = Vector2(900, 650)
	add_child(deck_popup)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	deck_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "YOUR DECK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CUSTOM_FONT)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.788235, 0.639216, 0.964706, 1))
	vbox.add_child(title)
	
	var deck_scroll = ScrollContainer.new()
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(deck_scroll)
	
	var deck_grid = GridContainer.new()
	deck_grid.columns = 7
	deck_grid.name = "DeckGrid"
	deck_grid.add_theme_constant_override("h_separation", 15)
	deck_grid.add_theme_constant_override("v_separation", 15)
	deck_scroll.add_child(deck_grid)

func _create_view_deck_button():
	var view_deck_btn = Button.new()
	view_deck_btn.text = "VIEW DECK"
	view_deck_btn.position = Vector2(1100, 24)
	view_deck_btn.custom_minimum_size = Vector2(150, 45)
	view_deck_btn.add_theme_font_override("font", CUSTOM_FONT)
	view_deck_btn.add_theme_font_size_override("font_size", 18)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0392157, 0.121569, 0.9)
	style.border_color = Color(0.415686, 0.105882, 0.603922, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	view_deck_btn.add_theme_stylebox_override("normal", style)
	
	view_deck_btn.pressed.connect(_show_deck)
	add_child(view_deck_btn)

func animate_limbo_letters():
	for i in range(limbo_letters.get_child_count()):
		var panel = limbo_letters.get_child(i)
# Instead of animating 'panel', we animate the 'label' inside it.
		var label = panel.get_node("Label")
	
	# Ensure label can be moved (Control nodes inside Panels usually allow manual positioning)
		var start_y = label.position.y 
	
		var tween = create_tween()
		tween.set_loops()
	
	# Float the LABEL, not the PANEL
		tween.tween_property(label, "position:y", start_y - 6, 1.5).set_trans(Tween.TRANS_SINE).set_delay(i * 0.1)
		tween.tween_property(label, "position:y", start_y, 1.5).set_trans

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
	_update_artifacts_display()
	_update_caller_dialogue()

func _update_labels():
	score_label.text = str(Global.current_score)
	target_label.text = str(Global.opponent_target)
	draws_label.text = "%d/%d" % [Global.draws_remaining, Global.max_draws]
	round_label.text = "%d/3" % Global.current_round


func _update_caller_dialogue():
	# Update caller based on encounter
	var caller_data = _get_caller_for_encounter(Global.current_encounter)
	caller_avatar.text = caller_data.avatar
	caller_name.text = caller_data.name
	caller_text.text = caller_data.dialogue

func _get_caller_for_encounter(encounter: int) -> Dictionary:
	match encounter:
		1:
			return {
				"avatar": "🎩",
				"name": "THE FERRYMAN",
				"dialogue": "\"Welcome to Limbo Lodge, wanderer. Place your slabs wisely...\""
			}
		2:
			return {
				"avatar": "👤",
				"name": "THE BARBER",
				"dialogue": "\"A closer shave with fate, I see. Let's make this interesting...\""
			}
		3:
			return {
				"avatar": "🔮",
				"name": "THE FORTUNE TELLER",
				"dialogue": "\"I see your future... but can you place it correctly?\""
			}
		_:
			return {
				"avatar": "💀",
				"name": "THE REAPER",
				"dialogue": "\"Your time grows short. Prove yourself worthy.\""
			}

func _update_button_states():
	var has_slab = (current_slab != null)
	var out_of_draws = (Global.draws_remaining <= 0)
	var is_round_end = out_of_draws
	
	draw_button.disabled = out_of_draws or has_slab
	bench_button.disabled = not has_slab or not must_place_or_bench or Global.benched_slabs.size() >= Global.max_bench_slots
	
	if is_round_end and Global.current_round < 3:
		next_round_button.show()
		score_button.text = "CASH IN"
		var style = score_button.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color(0.27451, 0.2, 0.0666667, 1)
		style.border_color = Color(0.490196, 0.356863, 0.117647, 1)
		score_button.add_theme_stylebox_override("normal", style)
	else:
		next_round_button.hide()
		score_button.text = "SCORE"
		var style = score_button.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color(0.231373, 0.0666667, 0.27451, 1)
		style.border_color = Color(0.411765, 0.117647, 0.490196, 1)
		score_button.add_theme_stylebox_override("normal", style)
	
	if is_round_end and Global.current_round >= 3:
		score_button.text = "FINISH!"
		var style = score_button.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color(0.4, 0.05, 0.05, 1)
		style.border_color = Color(0.8, 0.1, 0.1, 1)
		score_button.add_theme_stylebox_override("normal", style)

func _update_current_slab_display():
	for child in current_slab_display.get_children(): 
		child.queue_free()
	
	if current_slab == null:
		var label = Label.new()
		label.text = "Click DRAW"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", CUSTOM_FONT)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6, 1))
		current_slab_display.add_child(label)
	else:
		var visual = SlabBuilder.create_visual(current_slab, 1.3)
		current_slab_display.add_child(visual)

func _update_bench_display():
	for child in bench_display.get_children(): 
		child.queue_free()
	
	for i in range(Global.max_bench_slots):
		var slot_btn = _create_bench_slot(i)
		bench_display.add_child(slot_btn)

func _create_bench_slot(index: int) -> Button:
	var slot_btn = Button.new()
	slot_btn.custom_minimum_size = Vector2(95, 95)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.039216, 0.019608, 0.078431, 0.7)
	style.border_color = Color(0.239216, 0.12549, 0.345098, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.5)
	slot_btn.add_theme_stylebox_override("normal", style)
	
	if index < Global.benched_slabs.size():
		var slab = Global.benched_slabs[index]
		var container = CenterContainer.new()
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var vis = SlabBuilder.create_visual(slab, 0.75)
		container.add_child(vis)
		slot_btn.add_child(container)
		slot_btn.pressed.connect(_on_benched_slab_clicked.bind(index))
		
		# Hover effect
		var hover_style = style.duplicate()
		hover_style.border_color = Color(0.545098, 0.301961, 0.788235, 1)
		hover_style.shadow_size = 15
		slot_btn.add_theme_stylebox_override("hover", hover_style)
	else:
		slot_btn.disabled = true
		style.bg_color = Color(0.02, 0.01, 0.04, 0.5)
		style.border_color = Color(0.15, 0.08, 0.2, 1)
	
	return slot_btn

func _update_artifacts_display():
	for child in artifact_grid.get_children():
		child.queue_free()
	
	# Always show 6 slots (3x2 grid)
	var max_slots = 6
	for i in range(max_slots):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(110, 110)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.039216, 0.019608, 0.078431, 0.7)
		style.border_color = Color(0.239216, 0.12549, 0.345098, 1)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.shadow_size = 8
		slot.add_theme_stylebox_override("panel", style)
		
		# If we have an artifact for this slot, show it
		if i < Global.active_artifacts.size():
			var artifact_id = Global.active_artifacts[i]
			var label = Label.new()
			label.text = _get_artifact_icon(artifact_id)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			label.add_theme_font_size_override("font_size", 42)
			slot.add_child(label)
		
		artifact_grid.add_child(slot)

func _get_artifact_icon(id: String) -> String:
	match id:
		"infinite_reuse": return "🔮"
		"eternal_slab": return "⚱️"
		"bonus_five": return "✨"
		"coin_rush": return "💰"
		"wild_letter": return "🎭"
		"wild_number": return "🎲"
		_: return "📦"

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
	
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	var is_perfect = (current_slab.letter == cells[cell_index].letter and 
					  current_slab.number == cells[cell_index].grid_number)
	if is_perfect:
		AudioManager.play("place", Vector2(1.1, 1.3))
		create_particle_burst(cells[cell_index].global_position + Vector2(43, 43))
	else:
		AudioManager.play("place")
	
	current_slab = null
	must_place_or_bench = false
	update_ui()

func _on_next_round_pressed():
	Global.start_new_round_logic(true)
	AudioManager.play("draw")
	show_message("Draws Refilled! Combo continues...", Color(0.411765, 0.941176, 0.682353, 1))
	update_ui()

# === SCORING ===

func _on_score_button_pressed():
	if is_animating: 
		return
	
	is_animating = true
	_disable_all_buttons()
	
	score_label.text = "0"
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
	style.bg_color = Color(0, 0, 0, 0.92)
	score_modal.add_theme_stylebox_override("panel", style)
	add_child(score_modal)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	score_modal.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(600, 400)
	vbox.add_theme_constant_override("separation", 25)
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
	header.add_theme_font_size_override("font_size", 68)
	header.add_theme_color_override("font_color", Color.GOLD)
	header.pivot_offset = Vector2(300, 34)
	vbox.add_child(header)
	
	var t = create_tween().set_loops()
	t.tween_property(header, "scale", Vector2(1.05, 1.05), 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(header, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)

func _add_score_total(vbox: VBoxContainer, result: Dictionary):
	var score_txt = Label.new()
	score_txt.text = str(result.total_score)
	score_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_txt.add_theme_font_override("font", CUSTOM_FONT)
	score_txt.add_theme_font_size_override("font_size", 110)
	score_txt.add_theme_color_override("font_color", Color.WHITE)
	score_txt.add_theme_color_override("font_shadow_color", Color(1, 0.921569, 0.231373, 0.6))
	score_txt.add_theme_constant_override("shadow_outline_size", 20)
	vbox.add_child(score_txt)

func _add_score_details(vbox: VBoxContainer, result: Dictionary):
	var details = Label.new()
	details.text = "Perfect Matches: %d  |  Line Bonuses: %d" % [result.perfect_matches, result.perfect_lines]
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_font_size_override("font_size", 18)
	details.add_theme_color_override("font_color", Color(0.815686, 0.721569, 0.909804, 1))
	vbox.add_child(details)

func _add_score_rewards(vbox: VBoxContainer, result: Dictionary):
	var rewards = Label.new()
	rewards.text = "+%d Coins   +%d Obols" % [result.coins_earned, result.obols_earned]
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	rewards.add_theme_font_size_override("font_size", 28)
	vbox.add_child(rewards)

func _add_continue_button(vbox: VBoxContainer):
	var btn = Button.new()
	btn.text = "CONTINUE"
	btn.custom_minimum_size = Vector2(0, 65)
	btn.add_theme_font_override("font", CUSTOM_FONT)
	btn.add_theme_font_size_override("font_size", 36)
	btn.pressed.connect(_on_score_confirmed)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.137255, 0.27451, 0.0666667, 1)
	btn_style.border_color = Color(0.247059, 0.490196, 0.117647, 1)
	btn_style.set_border_width_all(3)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	
	vbox.add_child(btn)
	
	btn.modulate.a = 0
	create_tween().tween_property(btn, "modulate:a", 1.0, 0.5).set_delay(0.6)

func _on_score_confirmed():
	score_modal.queue_free()
	is_animating = false
	
	Global.clear_board()
	refresh_grid_visuals()
	
	if Global.current_score >= Global.opponent_target:
		show_message("ENCOUNTER COMPLETE!", Color.GOLD)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Scenes/shop.tscn")
	elif Global.current_round >= 3:
		show_message("GAME OVER", Color.RED)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		Global.start_new_round_logic(false)
		update_ui()

# === DECK VIEWER ===

func _show_deck():
	var actual_grid = deck_popup.get_child(0).get_child(0).get_child(1).get_child(0)
	for c in actual_grid.get_children(): 
		c.queue_free()
	
	var sorted_deck = Global.deck.duplicate()
	sorted_deck.sort_custom(func(a, b): 
		if a.letter != b.letter: return a.letter < b.letter
		return a.number < b.number
	)
	
	for slab in sorted_deck:
		var visual = SlabBuilder.create_visual(slab, 0.55)
		actual_grid.add_child(visual)
	
	deck_popup.popup_centered()

# === VISUAL EFFECTS ===

func show_message(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.position = Vector2(640, 60)
	label.pivot_offset = Vector2(label.size.x / 2, 0)
	label.add_theme_font_override("font", CUSTOM_FONT)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	
	label.modulate.a = 0
	label.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_interval(1.5)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

func create_particle_burst(pos: Vector2):
	for i in range(15):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(1, 0.921569, 0.231373, 1)
		p.position = pos
		add_child(p)
		
		var angle = (TAU / 15) * i
		var dist = randf_range(40, 70)
		var dest = pos + Vector2(cos(angle), sin(angle)) * dist
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(p, "position", dest, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0, 0.5).set_delay(0.1)
		tween.tween_property(p, "scale", Vector2.ZERO, 0.5).set_delay(0.2)
		tween.chain().tween_callback(p.queue_free)
