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
var deck: Array[SlabData] = []
var draw_pile: Array[SlabData] = []
var discard_pile: Array[SlabData] = []

var placed_slabs: Array = [] 
var benched_slabs: Array[SlabData] = []
var max_bench_slots: int = 5

# === GRID ===
var grid_numbers: Array = [] 

# === UPGRADES & META ===
var active_artifacts: Array[String] = []
var artifacts: Array = []
var number_bias: Dictionary = {} # Old system (keep if needed, but we use new buckets now)
var max_artifacts: int = 6

# NEW: Death's Gift System
var rng_bias: String = "NEUTRAL" # NEUTRAL, LOW, MID, HIGH
var perm_base_bonus: int = 0
var perm_mult_bonus: float = 0.0
var reroll_cost: int = 1
var fated_letter: String = "" # For Guaranteed letter gift
var fated_charges: int = 0

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
	
	# Reset Scaling
	perm_base_bonus = 0
	perm_mult_bonus = 0.0
	rng_bias = "NEUTRAL"
	max_artifacts = 6
	
	artifacts.clear()
	number_bias.clear()
	benched_slabs.clear()
	active_artifacts.clear()
	
	create_starting_deck()
	generate_grid_numbers()
	clear_board()
	reset_draw_pile()

func create_starting_deck():
	deck.clear()
	for letter_char in LIMBO_LETTERS:
		for num in range(1, 16):
			var new_slab = SlabData.new(letter_char, num, "common")
			deck.append(new_slab)

# === NEW: PROBABILITY BUCKETS ===

func get_weighted_number() -> int:
	var weights = {
		"NEUTRAL": [33, 33, 34],
		"LOW":     [60, 20, 20], # Death's Gift: Favor 1-5
		"MID":     [20, 60, 20], # Death's Gift: Favor 6-10
		"HIGH":    [20, 20, 60]  # Death's Gift: Favor 11-15
	}
	
	var current = weights.get(rng_bias, weights["NEUTRAL"])
	var roll = randi_range(1, 100)
	
	# Determine Bucket
	var bucket = 1
	if roll <= current[0]: bucket = 1      # 1-5
	elif roll <= current[0] + current[1]: bucket = 2 # 6-10
	else: bucket = 3                       # 11-15
	
	# Return random number from bucket
	if bucket == 1: return randi_range(1, 5)
	elif bucket == 2: return randi_range(6, 10)
	else: return randi_range(11, 15)

func generate_grid_numbers():
	grid_numbers.clear()
	# New Logic: purely weighted random based on Death's Gift
	for i in range(25):
		grid_numbers.append(get_weighted_number())

func clear_board():
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)

# === DRAW SYSTEM ===

func reset_draw_pile():
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	
	# ORACLE GIFT: If we have the Oracle, we might need to sort or prep the pile? 
	# Actually, shuffling is fine, the UI just peeks.

func draw_slab() -> SlabData:
	if draw_pile.is_empty():
		if discard_pile.size() > 0:
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		else:
			draw_pile = deck.duplicate()
			draw_pile.shuffle()
	
	if draw_pile.is_empty(): return null
		
	draws_remaining -= 1
	var slab = draw_pile.pop_front()
	
	# Handle "Extra Pocket" or similar artifacts logic if needed here
	
	discard_pile.append(slab) 
	return slab

# === ROUND/ENCOUNTER PROGRESSION ===

func start_new_round_logic(keep_board: bool):
	current_round += 1
	
	# Base draws
	draws_remaining = max_draws
	# Artifact: Extra Pocket
	if has_effect("extra_draw"):
		draws_remaining += 1
		
	reroll_cost = 1 # Reset shop reroll cost logic here or on shop enter
	
	if not keep_board:
		clear_board()
		benched_slabs.clear()
		reset_draw_pile() 

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	current_score = 0
	
	clear_board()
	benched_slabs.clear()
	generate_grid_numbers()
	
	# PERSISTENCE RULE
	var kept_artifacts = []
	for id in active_artifacts:
		# These are permanent upgrades
		kept_artifacts.append(id)
	
	active_artifacts = kept_artifacts.duplicate()
	
	opponent_target = 100 + (current_encounter * 75)
	
	draws_remaining = max_draws
	if has_effect("extra_draw"): draws_remaining += 1

# === SCORING SYSTEM ===

func calculate_score() -> Dictionary:
	var total_score = 0
	var single_scores = []
	var perfect_count = 0
	var placement_count = 0 
	
	for i in range(25):
		if placed_slabs[i] != null:
			placement_count += 1
			var slab = placed_slabs[i]
			var raw_score = 0
			
			if is_perfect_match(i):
				raw_score = 10 + PERFECT_MATCH_BONUS # 35
				perfect_count += 1
			elif slab.letter == get_letter_for_row(i / 5): 
				raw_score = 10 + LETTER_MATCH_BONUS
			else:
				raw_score = slab.number
				if has_effect("salvage") and raw_score < 5: raw_score = 5

			# === APPLY ARTIFACT SCALING ===
			# "Gem of Precision" logic: Add the permanent bonus we've earned
			raw_score += perm_base_bonus
			
			# Additive Bonuses
			raw_score += get_stat_sum("additive")
			
			# Conditional Bonuses
			if (i % 2 != 0) and has_effect("odd_bonus"): raw_score += 5 
			
			single_scores.append(raw_score)
			total_score += raw_score
		else:
			single_scores.append(0)

	var line_bonuses = calculate_line_bonuses(single_scores)
	total_score += line_bonuses.total_bonus
	
	# === ECONOMY ===
	var coins_earned = int(total_score / 10.0)
	var obols_earned = line_bonuses.details.size()
	
	# Midas Touch Logic
	if has_effect("double_gold"):
		coins_earned *= 2
	
	# === MULTIPLIERS ===
	var global_mult = get_multipliers()
	# "Prism of Focus" logic: Add the permanent mult bonus
	global_mult += perm_mult_bonus
	
	total_score = total_score * global_mult
	
	return {
		"total_score": int(total_score),
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
	
	var letter_match = (slab.letter == expected_letter) or has_effect("wild_letter")
	
	if not letter_match and has_effect("adjacent_letters"):
		var l_idx = LIMBO_LETTERS.find(slab.letter)
		var t_idx = LIMBO_LETTERS.find(expected_letter)
		if abs(l_idx - t_idx) <= 1: letter_match = true

	var num_match = (slab.number == grid_num) or has_effect("wild_number")
	
	if not num_match and has_effect("flex_numbers"):
		if abs(slab.number - grid_num) <= 1: num_match = true
		
	if has_effect("perfect_7") and slab.number == 7:
		return true
		
	return letter_match and num_match

# === ARTIFACT/DECK MANAGEMENT ===

func add_slab_to_deck(slab_data_input):
	var new_slab: SlabData
	if slab_data_input is SlabData:
		new_slab = slab_data_input
	else:
		new_slab = SlabData.new(
			slab_data_input.get("letter", "L"), 
			slab_data_input.get("number", 1),
			slab_data_input.get("rarity", "common")
		)
	deck.append(new_slab)

func remove_slab_from_deck(slab: SlabData):
	if slab in deck:
		deck.erase(slab)

func add_artifact(artifact_id: String):
	if active_artifacts.size() < max_artifacts:
		if artifact_id not in active_artifacts:
			active_artifacts.append(artifact_id)
			
			# Immediate Effects on Pickup
			var def = SlabDefinitions.SLABS.get(artifact_id, {})
			if def.get("type") == "utility_immediate":
				if def.get("effect") == "max_bench":
					max_bench_slots += 1
				elif def.get("effect") == "max_artifact_slot":
					max_artifacts += 1

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

# === HELPERS ===
func get_letter_for_row(row: int) -> String:
	return LIMBO_LETTERS[row] if row < LIMBO_LETTERS.size() else "L"
