extends Control

# --- UI Containers ---
var currency_panel: Panel
var tab_container: TabContainer
var deck_popup: PopupPanel
var deck_grid: GridContainer

# --- Constants ---
const CUSTOM_FONT = preload("res://Assets/Fonts/Creepster-Regular.ttf")

func _ready():
	# Build the entire UI from code so you don't have to setup nodes manually
	setup_background()
	setup_currency_display()
	setup_navigation_buttons()
	setup_shop_tabs()
	setup_deck_view()
	
	update_currency_labels()

# --- UI BUILDER ---

func setup_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.15, 0.1, 0.2, 1) # Dark purple/void background
	add_child(bg)
	
	var title = Label.new()
	title.text = "THE FERRYMAN'S MARKET"
	title.position = Vector2(0, 20)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CUSTOM_FONT)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#aa88ff"))
	add_child(title)

func setup_currency_display():
	currency_panel = Panel.new()
	currency_panel.position = Vector2(40, 100)
	currency_panel.size = Vector2(1200, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(8)
	currency_panel.add_theme_stylebox_override("panel", style)
	add_child(currency_panel)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 100)
	currency_panel.add_child(hbox)
	
	# Create 3 Labels for Currencies
	create_currency_label(hbox, "coins", "Charon's Coins", Color("#ffffaa"))
	create_currency_label(hbox, "essence", "Vitality Essence", Color("#dd88ff"))
	create_currency_label(hbox, "obols", "Grim Obols", Color("#88ff88"))

func create_currency_label(parent, name, title, color):
	var label = Label.new()
	label.name = name
	label.text = title + ": 0"
	label.add_theme_font_override("font", CUSTOM_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func setup_navigation_buttons():
	# View Deck Button
	var deck_btn = create_button("VIEW DECK", Vector2(1050, 650), Color("#444455"))
	deck_btn.pressed.connect(_on_view_deck_pressed)
	add_child(deck_btn)
	
	# Next Encounter Button
	var next_btn = create_button("DEPART", Vector2(1050, 580), Color("#446644"))
	next_btn.pressed.connect(_on_depart_pressed)
	add_child(next_btn)

func setup_shop_tabs():
	tab_container = TabContainer.new()
	tab_container.position = Vector2(40, 180)
	tab_container.size = Vector2(980, 500)
	add_child(tab_container)
	
	# 1. SLAB MARKET (Coins)
	var slab_tab = create_tab("Slab Market")
	populate_slabs(slab_tab)
	
	# 2. ARTIFACTS (Essence)
	var art_tab = create_tab("Artifacts")
	populate_artifacts(art_tab)
	
	# 3. DEATH'S GIFTS (Obols)
	var gift_tab = create_tab("Death's Gifts")
	populate_gifts(gift_tab)

func create_tab(name: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.name = name
	tab_container.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	
	return scroll

# --- POPULATE ITEMS ---

func populate_slabs(scroll_container):
	var grid = scroll_container.get_child(0)
	# Example Slabs
	add_shop_item(grid, "Simple Slab", "Adds a random basic slab.", 10, "coins", func():
		var letters = ["L", "I", "M", "B", "O"]
		var slab = {"letter": letters.pick_random(), "number": randi_range(1, 15)}
		Global.add_slab_to_deck(slab)
	)
	
	add_shop_item(grid, "The Joker", "L-Wild (Matches any L)", 50, "coins", func():
		# '0' represents a wild number in logic later
		Global.add_slab_to_deck({"letter": "L", "number": 0}) 
	)

func populate_artifacts(scroll_container):
	var grid = scroll_container.get_child(0)
	
	add_shop_item(grid, "Midas Skull", "+2 Coins per match.", 30, "essence", func():
		Global.add_artifact("midas_skull")
	)
	
	add_shop_item(grid, "Bone Ledger", "Line bingos worth x6 score.", 50, "essence", func():
		Global.add_artifact("bone_ledger")
	)

func populate_gifts(scroll_container):
	var grid = scroll_container.get_child(0)
	
	add_shop_item(grid, "Favored Seven", "Number 7 appears 5x more often.", 5, "obols", func():
		Global.increase_number_weight(7, 40) # +40 weight
	)
	
	add_shop_item(grid, "Even Tide", "Even numbers appear more often.", 10, "obols", func():
		for i in [2,4,6,8,10,12,14]:
			Global.increase_number_weight(i, 5)
	)

# --- ITEM FACTORY ---

func add_shop_item(parent_grid, name, desc, cost, currency_type, effect_callback: Callable):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 120)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.18, 0.22, 1)
	style.border_color = Color(0.4, 0.35, 0.45, 1)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 100)
	panel.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_color_override("font_color", Color("#ffddaa"))
	name_lbl.add_theme_font_override("font", CUSTOM_FONT)
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.custom_minimum_size.y = 40
	desc_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.text = "Buy (%d %s)" % [cost, currency_type.capitalize()]
	btn.pressed.connect(func(): _try_buy(cost, currency_type, effect_callback, btn))
	vbox.add_child(btn)
	
	parent_grid.add_child(panel)

# --- LOGIC ---

func _try_buy(cost: int, currency: String, effect: Callable, button: Button):
	var can_afford = false
	if currency == "coins" and Global.coins >= cost:
		Global.coins -= cost
		can_afford = true
	elif currency == "essence" and Global.essence >= cost:
		Global.essence -= cost
		can_afford = true
	elif currency == "obols" and Global.obols >= cost:
		Global.obols -= cost
		can_afford = true
		
	if can_afford:
		effect.call()
		update_currency_labels()
		button.text = "PURCHASED"
		button.disabled = true
	else:
		# Flash red (Simple feedback)
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color.RED, 0.1)
		tween.tween_property(button, "modulate", Color.WHITE, 0.1)

func update_currency_labels():
	var hbox = currency_panel.get_child(0)
	hbox.get_node("coins").text = "Charon's Coins: " + str(Global.coins)
	hbox.get_node("essence").text = "Vitality Essence: " + str(Global.essence)
	hbox.get_node("obols").text = "Grim Obols: " + str(Global.obols)

func _on_depart_pressed():
	# Go to next level
	get_tree().change_scene_to_file("res://Scenes/game_board.tscn")

# --- DECK VIEWER (Reused Logic) ---

func setup_deck_view():
	deck_popup = PopupPanel.new()
	deck_popup.size = Vector2(700, 500)
	deck_popup.position = Vector2(
		(get_viewport_rect().size.x - 700) / 2,
		(get_viewport_rect().size.y - 500) / 2
	)
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_popup.add_child(scroll)
	
	deck_grid = GridContainer.new()
	deck_grid.columns = 8
	deck_grid.add_theme_constant_override("h_separation", 10)
	deck_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(deck_grid)
	add_child(deck_popup)

func _on_view_deck_pressed():
	for child in deck_grid.get_children():
		child.queue_free()
		
	var view_deck = Global.deck.duplicate()
	view_deck.sort_custom(func(a, b): 
		if a.letter != b.letter: return a.letter < b.letter
		return a.number < b.number
	)
	
	for slab_data in view_deck:
		# Using the SlabBuilder utility we made earlier
		var visual = SlabBuilder.create_visual(slab_data, 0.45)
		deck_grid.add_child(visual)
	
	deck_popup.title = "Current Deck (%d Slabs)" % Global.deck.size()
	deck_popup.popup_centered()

# Helper for main buttons
func create_button(text, pos, color):
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(180, 60)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_override("font", CUSTOM_FONT)
	btn.add_theme_font_size_override("font_size", 24)
	return btn
