extends Control

# === NODE REFERENCES (Linked to your new Editor Layout) ===
@onready var grid_container = $LayoutMargin/MainColumns/MidCol/GridWrapper/GridContainer
@onready var limbo_letters = $LayoutMargin/MainColumns/MidCol/LimboLetters

# Left Col
@onready var artifact_grid = $LayoutMargin/MainColumns/LeftCol/ArtifactsPanel/ArtifactGrid
@onready var notification_area = $LayoutMargin/MainColumns/LeftCol/CallerPanel/NotificationArea

# Mid Col
@onready var bench_section = $LayoutMargin/MainColumns/MidCol/BenchSection
@onready var current_slab_display = $LayoutMargin/MainColumns/MidCol/HandPanel/CurrentSlabDisplay

# Right Col (Info)
@onready var opponent_name = $LayoutMargin/MainColumns/RightCol/OpponentInfo/InfoBox/OpponentName
@onready var target_label = $LayoutMargin/MainColumns/RightCol/OpponentInfo/InfoBox/TargetLabel
@onready var encounter_label = $LayoutMargin/MainColumns/RightCol/OpponentInfo/InfoBox/EncounterLabel
@onready var score_label = $LayoutMargin/MainColumns/RightCol/ScoreLabel

# Right Col (Buttons)
@onready var draw_button = $LayoutMargin/MainColumns/RightCol/ActionButtons/DrawButton
@onready var bench_button = $LayoutMargin/MainColumns/RightCol/ActionButtons/BenchButton
@onready var deck_button = $LayoutMargin/MainColumns/RightCol/ActionButtons/DeckButton
@onready var score_button = $LayoutMargin/MainColumns/RightCol/ActionButtons/ScoreButton

# Right Col (Stats)
@onready var round_label = $LayoutMargin/MainColumns/RightCol/StatsGrid/RoundPanel/RoundLabel
@onready var draws_label = $LayoutMargin/MainColumns/RightCol/StatsGrid/DrawsPanel/DrawsLabel
@onready var coins_label = $LayoutMargin/MainColumns/RightCol/StatsGrid/CoinsPanel/CoinsLabel
@onready var obols_label = $LayoutMargin/MainColumns/RightCol/StatsGrid/ObolsPanel/ObolsLabel

# === STATE ===
var cells: Array = []
var current_slab: SlabData = null
var must_place_or_bench: bool = false
var is_animating: bool = false
var score_manager: ScoreManager

# === UI ELEMENTS (Created dynamically) ===
var next_round_button: Button
var deck_popup: PopupPanel
var score_modal: Panel

const GRID_CELL = preload("res://Scenes/grid_cell.tscn")
const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	_initialize_systems()
	setup_grid()
	
	# Initial UI Setup
	_connect_signals()
	_start_music()
	_setup_ambience()
	
	# Create popup helpers that don't need to be in the main layout
	_create_deck_popup()
	_create_next_round_button()
	
	update_ui()

func _process(_delta):
	var light = get_node_or_null("MouseLight")
	if light: light.global_position = get_global_mouse_position()

func _initialize_systems():
	score_manager = ScoreManager.new(self, score_label)
	add_child(score_manager)

func _connect_signals():
	draw_button.pressed.connect(_on_draw_button_pressed)
	bench_button.pressed.connect(_on_bench_button_pressed)
	deck_button.pressed.connect(_show_deck)
	score_button.pressed.connect(_on_score_button_pressed)

# ... (Keep _start_music and _setup_ambience as they were) ...
func _start_music():
	if Global.current_encounter == 1:
		AudioManager.play_music("res://Assets/Audio/music.mp3")
	else:
		AudioManager.stop_music()

func _setup_ambience():
	# (Paste the Ambience/Glow/Dust code from the previous step here)
	pass

# === VISUAL UPDATES ===

func update_ui():
	# Labels
	score_label.text = str(Global.current_score)
	target_label.text = "Target: " + str(Global.opponent_target)
	draws_label.text = str(Global.draws_remaining)
	round_label.text = str(Global.current_round)
	coins_label.text = str(Global.coins)
	obols_label.text = str(Global.obols)
	
	var sub_encounter = ((Global.current_encounter - 1) % 3) + 1
	encounter_label.text = "Encounter %d/3" % sub_encounter
	
	var caller = _get_caller_data(Global.current_encounter)
	opponent_name.text = caller.name

	_update_current_slab_display()
	_update_bench_display()
	_update_button_states()
	_update_artifacts_display()

func _get_caller_data(encounter: int) -> Dictionary:
	match encounter:
		1: return {"name": "THE FERRYMAN"}
		2: return {"name": "THE BARBER"}
		3: return {"name": "FORTUNE TELLER"}
		_: return {"name": "THE REAPER"}

func _update_button_states():
	var has_slab = (current_slab != null)
	var out_of_draws = (Global.draws_remaining <= 0)
	var is_round_end = out_of_draws
	
	draw_button.disabled = out_of_draws or has_slab
	bench_button.disabled = not has_slab or not must_place_or_bench or Global.benched_slabs.size() >= Global.max_bench_slots
	
	if is_round_end and Global.current_round < 3:
		if next_round_button: next_round_button.show()
		score_button.text = "CASH IN"
	else:
		if next_round_button: next_round_button.hide()
		score_button.text = "SCORE"
	
	if is_round_end and Global.current_round >= 3:
		score_button.text = "FINISH!"

func _update_current_slab_display():
	for child in current_slab_display.get_children(): child.queue_free()
	if current_slab:
		var visual = SlabBuilder.create_visual(current_slab, 0.8)
		# Center it
		visual.position = Vector2(10, 10) 
		current_slab_display.add_child(visual)

func _update_bench_display():
	for child in bench_section.get_children(): child.queue_free()
	
	# Recreate the horizontal container for the bench buttons
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	bench_section.add_child(container)
	
	for i in range(Global.max_bench_slots):
		var slot_btn = _create_bench_slot(i)
		container.add_child(slot_btn)

func _create_bench_slot(index: int) -> Button:
	var slot_btn = Button.new()
	slot_btn.custom_minimum_size = Vector2(75, 75)
	
	# Default Style
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.05, 0.15, 0.8)
	s.border_color = Color(0.3, 0.2, 0.4, 1)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	slot_btn.add_theme_stylebox_override("normal", s)
	
	# Bench Text (B-E-N-C-H)
	var letters = ["B", "E", "N", "C", "H"]
	if index < letters.size():
		var l = Label.new()
		l.text = letters[index]
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color(1,1,1,0.2))
		slot_btn.add_child(l)

	# Content
	if index < Global.benched_slabs.size():
		var vis = SlabBuilder.create_visual(Global.benched_slabs[index], 0.6)
		# Center visually
		var c = CenterContainer.new()
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(vis)
		slot_btn.add_child(c)
		slot_btn.pressed.connect(_on_benched_slab_clicked.bind(index))
	else:
		slot_btn.disabled = true
	
	return slot_btn

func _update_artifacts_display():
	for child in artifact_grid.get_children(): child.queue_free()
	# Just create visuals here, layout is handled by GridContainer in editor
	for i in range(Global.active_artifacts.size()):
		var lbl = Label.new()
		lbl.text = _get_artifact_icon(Global.active_artifacts[i])
		artifact_grid.add_child(lbl)

func _get_artifact_icon(id: String) -> String:
	match id:
		"infinite_reuse": return "🔮"
		"eternal_slab": return "⚱️"
		"bonus_five": return "✨"
		"coin_rush": return "💰"
		"wild_letter": return "🎭"
		"wild_number": return "🎲"
		_: return "📦"

# === GAME LOGIC (Unchanged) ===

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
		AudioManager.play("click")
		update_ui()
	else:
		AudioManager.play("error")

func _on_benched_slab_clicked(index: int):
	if current_slab != null:
		_spawn_notification("Place current slab first!", Color.RED)
		return
	current_slab = Global.benched_slabs[index]
	Global.benched_slabs.remove_at(index)
	must_place_or_bench = true
	AudioManager.play("slide")
	update_ui()

func setup_grid():
	cells.clear()
	for child in grid_container.get_children(): child.queue_free()
	
	for i in range(25):
		var cell = GRID_CELL.instantiate()
		var row = i / 5
		cell.setup(i, Global.grid_numbers[i], Global.LIMBO_LETTERS[row])
		cell.cell_clicked.connect(_on_cell_clicked)
		grid_container.add_child(cell)
		cells.append(cell)
	refresh_grid_visuals()

func refresh_grid_visuals():
	for i in range(25):
		if i < cells.size():
			cells[i].place_slab(Global.placed_slabs[i])

func _on_cell_clicked(cell_index: int):
	if current_slab == null: return
	if Global.placed_slabs[cell_index] != null: return
	
	Global.placed_slabs[cell_index] = current_slab
	cells[cell_index].place_slab(current_slab)
	
	if current_slab.letter == cells[cell_index].letter and current_slab.number == cells[cell_index].grid_number:
		AudioManager.play("chime")
		_spawn_notification("Perfect!", Color.GOLD)
	else:
		AudioManager.play("place")
	
	current_slab = null
	must_place_or_bench = false
	update_ui()

# === EXTRAS (Popups/Notifications) ===

func _spawn_notification(text: String, color: Color):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 24)
	notification_area.add_child(lbl)
	lbl.position = Vector2(10, 10)
	
	var t = create_tween()
	t.tween_property(lbl, "position:y", -30.0, 1.0).as_relative()
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	t.tween_callback(lbl.queue_free)

func _create_next_round_button():
	next_round_button = Button.new()
	next_round_button.text = "CONTINUE"
	next_round_button.hide()
	next_round_button.pressed.connect(_on_next_round_pressed)
	# Add to Notification Area or somewhere central
	notification_area.add_child(next_round_button)

func _on_next_round_pressed():
	Global.start_new_round_logic(true)
	AudioManager.play("draw")
	update_ui()

func _create_deck_popup():
	deck_popup = PopupPanel.new()
	add_child(deck_popup)
	var m = MarginContainer.new()
	deck_popup.add_child(m)
	var g = GridContainer.new()
	g.columns = 6
	g.name = "DeckGrid"
	m.add_child(g)

func _show_deck():
	var g = deck_popup.get_node("MarginContainer/DeckGrid")
	for c in g.get_children(): c.queue_free()
	for s in Global.deck:
		g.add_child(SlabBuilder.create_visual(s, 0.5))
	deck_popup.popup_centered()

func _on_score_button_pressed():
	if is_animating: return
	is_animating = true
	# Scoring logic here (same as previous scripts)
	var result = Global.calculate_score()
	await score_manager.run_score_sequence(result, cells)
	Global.current_score += result.total_score
	is_animating = false
	update_ui()
