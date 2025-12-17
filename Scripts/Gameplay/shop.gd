extends Control

# UI References
var container: VBoxContainer
var message_label: Label
var items_grid: GridContainer
var deck_popup: PopupPanel
var deck_grid_ref: GridContainer
var reroll_btn: Button # New Reference

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	_setup_ui_structure()
	# Reset reroll cost on entry logic is handled in Global.start_new_round, 
	# but we can ensure it here too.
	if Global.current_round == 1 and Global.current_encounter > 1:
		Global.reroll_cost = 1
		
	_populate_shop_for_stage()
	_update_header()

func _setup_ui_structure():
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.08, 0.12, 1)
	add_child(bg)
	
	container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 20)
	container.position = Vector2(50, 20)
	container.size = Vector2(1180, 680)
	add_child(container)
	
	# Header
	message_label = Label.new()
	message_label.add_theme_font_override("font", CUSTOM_FONT)
	message_label.add_theme_font_size_override("font_size", 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.text = "THE FERRYMAN'S MARKET"
	container.add_child(message_label)
	
	# Content Area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	items_grid = GridContainer.new()
	items_grid.columns = 3
	items_grid.add_theme_constant_override("h_separation", 30)
	items_grid.add_theme_constant_override("v_separation", 30)
	items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_grid)
	
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 30)
	container.add_child(bottom_hbox)
	
	# REROLL BUTTON
	reroll_btn = _create_button("REROLL (1g)", Color(0.6, 0.4, 0.2))
	reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_hbox.add_child(reroll_btn)
	
	var deck_btn = _create_button("MANAGE DECK", Color("#554466"))
	deck_btn.pressed.connect(_open_deck_management)
	bottom_hbox.add_child(deck_btn)
	
	var next_btn = _create_button("ENTER LIMBO", Color("#446644"))
	next_btn.pressed.connect(_on_leave_shop)
	bottom_hbox.add_child(next_btn)
	
	_setup_deck_popup()
	_update_reroll_button()

func _update_reroll_button():
	reroll_btn.text = "REROLL (%dg)" % Global.reroll_cost
	if Global.coins < Global.reroll_cost:
		reroll_btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		reroll_btn.modulate = Color.WHITE

func _on_reroll_pressed():
	if Global.coins >= Global.reroll_cost:
		Global.coins -= Global.reroll_cost
		Global.reroll_cost += 1
		AudioManager.play("buy")
		_populate_shop_for_stage() # Refresh Items
		_update_reroll_button()
	else:
		AudioManager.play("error")

func _update_header():
	var txt = "MARKET"
	match Global.current_encounter:
		0: txt = "PRE-LIMBO PREPARATION"
		1, 2, 3: txt = "CALLER 1: REST STOP"
		4, 5, 6: txt = "CALLER 2: THE DEPTHS"
		_: txt = "CALLER 4: THE VOID"
	message_label.text = txt

func _populate_shop_for_stage():
	for c in items_grid.get_children(): c.queue_free()
	
	# 1. ADD NUMBER SLABS (Based on Death's Gift Weights)
	# We offer 2 random slabs every shop visit
	for i in range(2):
		var num = Global.get_weighted_number()
		var letter = Global.LIMBO_LETTERS.pick_random()
		
		# Fated Letter Gift Logic
		if Global.fated_letter != "" and i == 0:
			letter = Global.fated_letter
			
		var slab = SlabData.new(letter, num, "common")
		_add_slab_item(slab, 15) # Base cost 15
	
	# 2. ADD ARTIFACTS
	var stage = Global.current_encounter
	if stage <= 1:
		for i in range(2): _add_shop_item("common")
	elif stage <= 3:
		_add_shop_item("common")
		_add_shop_item("uncommon")
	else:
		_add_shop_item("uncommon")
		_add_shop_item("rare")

func _add_shop_item(rarity: String):
	# 1. Fetch Random Data from Definitions
	var id = SlabDefinitions.get_random_id(rarity)
	var def = SlabDefinitions.SLABS[id]
	var price = def.cost
	if Global.has_effect("discount"):
		price = int(price * 0.75)
	# 2. Create Background Panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 200) # Taller to fit description
	
	panel.mouse_entered.connect(func(): AudioManager.play("hover", Vector2(0.9, 1.0)))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1)
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	# 3. Create Layout Container
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 180)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# 4. Title Label (With Rarity Colors)
	var title = Label.new()
	title.text = def.name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CUSTOM_FONT)
	title.add_theme_font_size_override("font_size", 32)
	
	var title_color = Color.WHITE
	match rarity:
		"common": title_color = Color("#aaddaa") # Pale Green
		"uncommon": title_color = Color("#66ccff") # Sky Blue
		"rare": title_color = Color("#ffaa00") # Gold
		"legendary": title_color = Color("#ff4444") # Red
	title.add_theme_color_override("font_color", title_color)
	vbox.add_child(title)
	
	# 5. Description Label
	var desc = Label.new()
	desc.text = def.desc
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL # Fill available space
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc)
	
	# 6. Buy Button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 40)
	
	# Check if we already own this artifact (prevent duplicates unless allowed)
	if Global.active_artifacts.has(id) and def.get("type") != "consumable":
		btn.text = "OWNED"
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		if def.cost == 0:
			btn.text = "CLAIM FREE"
			btn.modulate = Color.GREEN
		else:
			btn.text = "BUY (%d)" % def.cost
			
		# Connect the buy signal
		btn.pressed.connect(func(): _buy_artifact(id, price, btn))
	
	vbox.add_child(btn)
	
	# 7. Add to the Shop Grid
	items_grid.add_child(panel)
	
# Helper function to handle the purchase logic

func _add_slab_item(slab: SlabData, base_cost: int):
	var price = base_cost
	if Global.has_effect("discount"): price = int(price * 0.75)
	
	var desc = "Add a %s-%d to your deck." % [slab.letter, slab.number]
	_create_shop_visual("Slab " + slab.letter + str(slab.number), desc, "common", price, func(btn): _buy_slab(slab, price, btn))

# Helper to avoid code duplication
func _create_shop_visual(title_txt, desc_txt, rarity, price, buy_callback):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 200)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1)
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 180)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = title_txt
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CUSTOM_FONT)
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = desc_txt
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)
	
	var btn = Button.new()
	btn.text = "BUY (%d)" % price
	btn.pressed.connect(func(): buy_callback.call(btn))
	vbox.add_child(btn)
	
	items_grid.add_child(panel)

func _buy_artifact(id: String, cost: int, btn: Button):
	if Global.coins >= cost:
		Global.coins -= cost
		Global.active_artifacts.append(id)
		
		btn.text = "ACQUIRED"
		btn.disabled = true
		btn.modulate = Color.GRAY
		
		AudioManager.play("buy")
		
		# Optional: Refresh UI or Message if needed
		# _update_coin_display() 
	else:
		# Feedback: Not enough money
		var original_text = btn.text
		var original_modulate = btn.modulate
		
		btn.text = "NEED COINS"
		btn.modulate = Color.RED
		
		# Reset button after 0.5 seconds
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(btn):
			btn.text = original_text
			btn.modulate = original_modulate

func _buy_slab(slab: SlabData, cost: int, btn: Button):
	if cost > 0 and Global.coins < cost:
		btn.text = "NEED COINS"
		btn.modulate = Color.RED
		await get_tree().create_timer(0.5).timeout
		btn.text = "BUY (%d)" % cost
		btn.modulate = Color.WHITE
		return
		
	if cost > 0: Global.coins -= cost
	
	Global.add_slab_to_deck(slab)
	btn.text = "ACQUIRED"
	btn.disabled = true
	btn.modulate = Color.GRAY
	AudioManager.play("draw")
	

func _on_leave_shop():
	# Update Global state to start the next encounter
	Global.start_new_encounter() 
	
	# Actually change scene back to the game!
	get_tree().change_scene_to_file("res://Scenes/game_board.tscn")

func _setup_deck_popup():
	deck_popup = PopupPanel.new()
	deck_popup.size = Vector2(800, 600)
	add_child(deck_popup)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_popup.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "CLICK A SLAB TO BANISH IT (DELETE)"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(lbl)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	deck_grid_ref = GridContainer.new()
	deck_grid_ref.columns = 6
	deck_grid_ref.add_theme_constant_override("h_separation", 15)
	deck_grid_ref.add_theme_constant_override("v_separation", 15)
	scroll.add_child(deck_grid_ref)

func _open_deck_management():
	for c in deck_grid_ref.get_children(): c.queue_free()
	
	for slab in Global.deck:
		var btn = TextureButton.new()
		# Wrap visual in a container that doesn't block mouse
		var container = Control.new()
		container.custom_minimum_size = Vector2(80, 70)
		container.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var visual = SlabBuilder.create_visual(slab, 0.6)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE # Important!
		container.add_child(visual)
		
		btn.custom_minimum_size = Vector2(80, 70)
		btn.add_child(container)
		
		# Pass the slab object to delete
		btn.pressed.connect(func(): _delete_slab(slab))
		deck_grid_ref.add_child(btn)
		
	deck_popup.popup_centered()

func _delete_slab(slab):
	Global.remove_slab_from_deck(slab)
	AudioManager.play("error")
	deck_popup.hide()
	# Re-open to show updated list
	_open_deck_management()

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 60)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_override("font", CUSTOM_FONT)
	btn.add_theme_font_size_override("font_size", 24)
	return btn
