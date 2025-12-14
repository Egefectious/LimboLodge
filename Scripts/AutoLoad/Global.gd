extends Node

# === GAME STATE ===
var current_encounter: int = 1
var current_round: int = 1
var current_score: int = 0

# === CURRENCIES ===
var coins: int = 0
var essence: int = 0
var obols: int = 0

# === DRAWS SYSTEM ===
var draws_remaining: int = 8
var max_draws: int = 8

# === TARGETS ===
var opponent_target: int = 100

# === DECK & BOARD ===
# 'deck' is your PERMANENT collection (Master Deck)
var deck: Array[SlabData] = []
# 'draw_pile' is the temporary stack you draw from during gameplay
var draw_pile: Array[SlabData] = []
# 'discard_pile' holds cards that have been recycled (if we add discard logic later)
var discard_pile: Array[SlabData] = []

var placed_slabs: Array = [] # Array of SlabData or null (size 25)
var benched_slabs: Array[SlabData] = []
var max_bench_slots: int = 5

# === GRID ===
var grid_numbers: Array = [] # The random numbers on each grid cell

# === UPGRADES ===
var active_artifacts: Array[String] = []
var artifacts: Array = []
var number_bias: Dictionary = {}

# === CONSTANTS ===
const LIMBO_LETTERS := ["L", "I", "M", "B", "O"]
const LETTER_MATCH_BONUS := 10
const PERFECT_MATCH_BONUS := 25

func _ready():
	reset_game()

# === INITIALIZATION ===

func reset_game():
	current_encounter = 1
	current_round = 1
	coins = 0
	essence = 0
	obols = 0
	current_score = 0
	opponent_target = 100
	
	artifacts.clear()
	number_bias.clear()
	benched_slabs.clear()
	
	create_starting_deck()
	generate_grid_numbers()
	clear_board()
	
	# Initialize the draw pile for the first game
	reset_draw_pile()

func create_starting_deck():
	deck.clear()
	for letter_char in LIMBO_LETTERS:
		for num in range(1, 16):
			var new_slab = SlabData.new(letter_char, num, "common")
			deck.append(new_slab)
	# We do NOT shuffle the master deck; we shuffle the draw pile

func generate_grid_numbers():
	grid_numbers.clear()
	# Generate 5 rows, each with unique numbers 1-15 mixed
	for row in range(5):
		var row_numbers = range(1, 16)
		row_numbers.shuffle()
		for col in range(5):
			grid_numbers.append(row_numbers[col])

func clear_board():
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)

# === DRAW SYSTEM ===

func reset_draw_pile():
	# Create a fresh copy of the Master Deck for the new round/encounter
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	print("Draw Pile Reset. Total Cards: ", draw_pile.size())

func draw_slab() -> SlabData:
	# If pile is empty, recycle from discard or emergency refill from master
	if draw_pile.is_empty():
		if discard_pile.size() > 0:
			print("Draw pile empty. Reshuffling discard pile...")
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		else:
			print("Draw & Discard empty! Emergency refill from Master Deck.")
			draw_pile = deck.duplicate()
			draw_pile.shuffle()
	
	if draw_pile.is_empty():
		# This should only happen if the player deleted their whole deck
		print("CRITICAL: Deck is empty!")
		return null
		
	draws_remaining -= 1
	var slab = draw_pile.pop_front()
	
	# In a future update, when board is cleared, we should add those to 'discard_pile'
	# For now, we assume drawn cards are effectively 'out' until the round resets
	discard_pile.append(slab) 
	
	return slab

# === ROUND/ENCOUNTER PROGRESSION ===

func start_new_round_logic(keep_board: bool):
	current_round += 1
	draws_remaining = max_draws
	
	if not keep_board:
		clear_board()
		benched_slabs.clear()
		# Standard Roguelike Logic: Reshuffle everything at start of round
		reset_draw_pile() 

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	current_score = 0
	
	clear_board()
	benched_slabs.clear()
	generate_grid_numbers()
	
	# PERSISTENCE RULE: Clear artifacts unless "Infinite Reuse" or "Eternal"
	var kept_artifacts = []
	for id in active_artifacts:
		if id == "infinite_reuse" or id == "eternal_slab":
			kept_artifacts.append(id)
			# Only keep one eternal if multiple? Logic says "This slab persists"
	
	active_artifacts = kept_artifacts.duplicate()
	
	opponent_target = 100 + (current_encounter * 50)
	draws_remaining = draws_remaining # Reset to max

# === SCORING SYSTEM (Unchanged for now) ===

func calculate_score() -> Dictionary:
	var total_score = 0
	var single_scores = []
	var perfect_count = 0
	var placement_count = 0 # For scaling effects
	
	# 1. Base Score + Additive Bonuses
	for i in range(25):
		if placed_slabs[i] != null:
			placement_count += 1
			var slab = placed_slabs[i]
			var raw_score = 0
			
			# Check match type using new logic
			if is_perfect_match(i):
				raw_score = 10 + PERFECT_MATCH_BONUS # 10 base + 25
				perfect_count += 1
			elif slab.letter == get_letter_for_row(i / 5): # Basic letter match
				raw_score = 10 + LETTER_MATCH_BONUS
			else:
				# Mismatch
				raw_score = slab.number
				# Salvage Effect
				if has_effect("salvage") and raw_score < 5: raw_score = 5
				if has_effect("quick_placement") and raw_score < 7: raw_score = 7

			# Apply Additive Bonuses (Bonus Five, Bonus Ten)
			raw_score += get_stat_sum("additive")
			
			# Conditionals
			if (i % 2 != 0) and has_effect("odd_bonus"): raw_score += 5 # Odd index isn't exactly odd number, check grid_numbers[i] % 2
			
			# Scaling (Chain Starter)
			if has_effect("chain_starter"):
				raw_score += placement_count # +1 for 1st, +2 for 2nd... (approximate logic)

			single_scores.append(raw_score)
			total_score += raw_score
		else:
			single_scores.append(0)
	

	var line_bonuses = calculate_line_bonuses(single_scores)
	total_score += line_bonuses.total_bonus
	
	var coins_earned = int(total_score / 10.0)
	var obols_earned = line_bonuses.details.size()
	
	var global_mult = get_multipliers()
	total_score = total_score * global_mult
	
	return {
		"total_score": total_score,
		"coins_earned": coins_earned,
		"obols_earned": obols_earned,
		"perfect_matches": perfect_count,
		"perfect_lines": line_bonuses.details.size(),
		"line_details": line_bonuses.details
	}

func calculate_line_bonuses(single_scores: Array) -> Dictionary:
	var total_bonus = 0
	var details = []
	
	var check_line = func(indices: Array, name: String):
		var filled = 0
		var score_sum = 0
		var perfects = 0
		
		for idx in indices:
			if placed_slabs[idx] != null:
				filled += 1
				score_sum += single_scores[idx]
				if is_perfect_match(idx): 
					perfects += 1
		
		if filled == indices.size():
			var multiplier = 2 + max(0, perfects - 2)
			var bonus = score_sum * (multiplier - 1)
			total_bonus += bonus
			details.append({
				"type": name, 
				"bonus": bonus, 
				"multiplier": multiplier,
				"perfects": perfects
			})
	
	for r in range(5):
		var indices = []
		for c in range(5): indices.append(r * 5 + c)
		check_line.call(indices, "Row " + str(r + 1))
	
	for c in range(5):
		var indices = []
		for r in range(5): indices.append(r * 5 + c)
		check_line.call(indices, "Col " + str(c + 1))
	
	check_line.call([0, 6, 12, 18, 24], "Diagonal \\")
	check_line.call([4, 8, 12, 16, 20], "Diagonal /")
	
	return {"total_bonus": total_bonus, "details": details}

func is_perfect_match(idx: int) -> bool:
	if placed_slabs[idx] == null: return false
	
	var row = idx / 5
	var expected_letter = LIMBO_LETTERS[row]
	var slab = placed_slabs[idx]
	var grid_num = grid_numbers[idx]
	
	# NEW: Wildcards and Rules
	var letter_match = (slab.letter == expected_letter) or has_effect("wild_letter")
	
	# Letter Shift (Adjacent match)
	if not letter_match and has_effect("adjacent_letters"):
		var l_idx = LIMBO_LETTERS.find(slab.letter)
		var t_idx = LIMBO_LETTERS.find(expected_letter)
		if abs(l_idx - t_idx) <= 1: letter_match = true

	var num_match = (slab.number == grid_num) or has_effect("wild_number")
	
	# Number Flex (+/- 1)
	if not num_match and has_effect("flex_numbers"):
		if abs(slab.number - grid_num) <= 1: num_match = true
		
	# Lucky Seven
	if has_effect("perfect_7") and slab.number == 7:
		return true
		
	return letter_match and num_match
# === SHOP & DECK MANAGEMENT ===

func add_slab_to_deck(slab_data_input):
	var new_slab: SlabData
	
	# Now this check is valid because slab_data_input isn't forced to be a Dictionary
	if slab_data_input is SlabData:
		new_slab = slab_data_input
	else:
		# Assume it's a Dictionary and create a new SlabData from it
		new_slab = SlabData.new(
			slab_data_input.get("letter", "L"), 
			slab_data_input.get("number", 1),
			slab_data_input.get("rarity", "common")
		)
	
	# Add to Master Deck
	deck.append(new_slab)
	print("Added to Deck: ", new_slab.letter, new_slab.number)

# This function was missing!
func remove_slab_from_deck(slab: SlabData):
	if slab in deck:
		deck.erase(slab)
		print("Removed from Deck: ", slab.letter, slab.number)
	else:
		print("Warning: Tried to remove slab not in deck")

func add_artifact(artifact_id: String):
	if artifact_id not in artifacts:
		artifacts.append(artifact_id)
		print("Artifact acquired: ", artifact_id)

func has_artifact(artifact_id: String) -> bool:
	return artifact_id in artifacts

# === NUMBER WEIGHTING SYSTEM ===

func increase_number_weight(num: int, weight: int):
	number_bias[num] = number_bias.get(num, 0) + weight

func get_weighted_random_number() -> int:
	var pool = []
	for i in range(1, 16):
		var weight = 10 + number_bias.get(i, 0)
		for k in range(weight): 
			pool.append(i)
	return pool.pick_random()

# === UTILITY ===

func get_letter_for_row(row: int) -> String:
	return LIMBO_LETTERS[row] if row < LIMBO_LETTERS.size() else "L"

func get_row_col(index: int) -> Vector2i:
	return Vector2i(index % 5, index / 5)

func has_effect(effect_name: String) -> bool:
	for id in active_artifacts:
		var def = SlabDefinitions.SLABS.get(id, {})
		if def.get("effect") == effect_name: return true
	return false

func get_stat_sum(stat_type: String) -> float:
	var total = 0.0
	for id in active_artifacts:
		var def = SlabDefinitions.SLABS.get(id, {})
		if def.get("type") == stat_type:
			total += def.get("val", 0)
	return total

func get_multipliers() -> float:
	var mult = 1.0
	for id in active_artifacts:
		var def = SlabDefinitions.SLABS.get(id, {})
		if def.get("type") == "mult":
			mult *= def.get("val", 1.0)
	return mult
