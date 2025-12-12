extends Control

# UI References
var container: VBoxContainer
var message_label: Label
var items_grid: GridContainer
var deck_popup: PopupPanel
var deck_grid_ref: GridContainer # <--- NEW: Store direct reference here

const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	_setup_ui_structure()
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
	
	# Bottom Bar
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 50)
	container.add_child(bottom_hbox)
	
	var deck_btn = _create_button("MANAGE DECK (Delete)", Color("#554466"))
	deck_btn.pressed.connect(_open_deck_management)
	bottom_hbox.add_child(deck_btn)
	
	var next_btn = _create_button("ENTER LIMBO", Color("#446644"))
	next_btn.pressed.connect(_on_leave_shop)
	bottom_hbox.add_child(next_btn)
	
	_setup_deck_popup()

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
	
	var stage = Global.current_encounter
	
	if stage == 0:
		_add_slab_item("Starter Gift", "common", 0)
	elif stage == 1 or stage == 2:
		for i in range(3): _add_slab_item("Standard Slab", "common", 15)
	elif stage == 3:
		_add_slab_item("Special Gift", "uncommon", 0)
		for i in range(3): _add_slab_item("Enhanced Slab", "uncommon", 40)
	elif stage >= 4 and stage <= 6:
		for i in range(2): _add_slab_item("Standard Slab", "common", 20)
		for i in range(2): _add_slab_item("Enhanced Slab", "uncommon", 45)
	elif stage == 7:
		_add_slab_item("Rare Relic", "rare", 0)
		_add_slab_item("Rare Slab", "rare", 100)
		_add_slab_item("Enhanced Slab", "uncommon", 50)
	else:
		_add_slab_item("Common Slab", "common", 25)
		_add_slab_item("Uncommon Slab", "uncommon", 55)
		_add_slab_item("Rare Slab", "rare", 120)
		_add_slab_item("Mystery Box", "random", 75)

func _add_slab_item(title: String, rarity: String, cost: int):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 150)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1)
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 130)
	panel.add_child(vbox)
	
	var slab_data
	if rarity == "random": slab_data = Global.generate_random_slab()
	else: slab_data = Global.generate_random_slab(rarity)
	
	var visual = SlabBuilder.create_visual(slab_data, 0.4)
	visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(visual)
	
	var info = Label.new()
	info.text = "%s %d" % [slab_data.letter, slab_data.number]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)
	
	var btn = Button.new()
	if cost == 0:
		btn.text = "CLAIM FREE"
		btn.modulate = Color.GREEN
	else:
		btn.text = "BUY (%d)" % cost
	
	btn.pressed.connect(func(): _buy_slab(slab_data, cost, btn))
	vbox.add_child(btn)
	
	items_grid.add_child(panel)

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
	Global.start_next_encounter()

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
	
	# Create Grid and save reference immediately
	deck_grid_ref = GridContainer.new()
	deck_grid_ref.columns = 6
	deck_grid_ref.add_theme_constant_override("h_separation", 15)
	deck_grid_ref.add_theme_constant_override("v_separation", 15)
	scroll.add_child(deck_grid_ref)

func _open_deck_management():
	# Use the saved reference, no more get_node error!
	for c in deck_grid_ref.get_children(): c.queue_free()
	
	for slab in Global.deck:
		var btn = TextureButton.new()
		var visual = SlabBuilder.create_visual(slab, 0.6)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.custom_minimum_size = Vector2(80, 70)
		btn.add_child(visual)
		
		btn.pressed.connect(func(): _delete_slab(slab))
		deck_grid_ref.add_child(btn)
		
	deck_popup.popup_centered()

func _delete_slab(slab):
	Global.remove_slab_from_deck(slab)
	AudioManager.play("error")
	deck_popup.hide()

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
