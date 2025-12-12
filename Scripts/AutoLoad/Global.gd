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
var placed_slabs: Array = [] # Array of SlabData or null (size 25)
var benched_slabs: Array[SlabData] = []
var max_bench_slots: int = 5

# === GRID ===
var grid_numbers: Array = [] # The random numbers on each grid cell

# === UPGRADES ===
var artifacts: Array = []
var number_bias: Dictionary = {} # For weighted random number generation

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

func create_starting_deck():
	deck.clear()
	for letter_char in LIMBO_LETTERS:
		for num in range(1, 16):
			var new_slab = SlabData.new(letter_char, num, "common")
			deck.append(new_slab)
	deck.shuffle()

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

func draw_slab() -> SlabData:
	if deck.is_empty():
		print("Deck empty! Reshuffling...")
		create_starting_deck()
	
	draws_remaining -= 1
	return deck.pop_front()

# === ROUND/ENCOUNTER PROGRESSION ===

func start_new_round_logic(keep_board: bool):
	current_round += 1
	draws_remaining = max_draws
	
	if not keep_board:
		clear_board()
		benched_slabs.clear()

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	current_score = 0
	
	clear_board()
	benched_slabs.clear()
	generate_grid_numbers()
	
	# Scale difficulty
	opponent_target = 100 + (current_encounter * 50)
	draws_remaining = max_draws

# === SCORING SYSTEM ===

func calculate_score() -> Dictionary:
	var single_scores = []
	var total_score = 0
	var perfect_count = 0
	
	# Calculate base scores for each cell
	for i in range(25):
		if placed_slabs[i] != null:
			var slab = placed_slabs[i]
			var row = i / 5
			var expected_letter = LIMBO_LETTERS[row]
			
			var base_score = slab.number
			var is_letter_correct = (slab.letter == expected_letter)
			var is_number_correct = (slab.number == grid_numbers[i])
			var is_perfect = is_letter_correct and is_number_correct
			
			if is_perfect:
				base_score += PERFECT_MATCH_BONUS
				perfect_count += 1
			elif is_letter_correct:
				base_score += LETTER_MATCH_BONUS
			
			single_scores.append(base_score)
			total_score += base_score
		else:
			single_scores.append(0)
	
	# Calculate line bonuses
	var line_bonuses = calculate_line_bonuses(single_scores)
	total_score += line_bonuses.total_bonus
	
	# Calculate rewards
	var coins_earned = int(total_score / 10.0)
	var obols_earned = line_bonuses.details.size()
	
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
	
	# Helper function to check if a line is complete and calculate bonus
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
		
		# Line must be completely filled
		if filled == indices.size():
			# Base multiplier is 2x, +1 for each perfect after the first 2
			var multiplier = 2 + max(0, perfects - 2)
			var bonus = score_sum * (multiplier - 1)
			total_bonus += bonus
			details.append({
				"type": name, 
				"bonus": bonus, 
				"multiplier": multiplier,
				"perfects": perfects
			})
	
	# Check all rows
	for r in range(5):
		var indices = []
		for c in range(5): 
			indices.append(r * 5 + c)
		check_line.call(indices, "Row " + str(r + 1))
	
	# Check all columns
	for c in range(5):
		var indices = []
		for r in range(5): 
			indices.append(r * 5 + c)
		check_line.call(indices, "Col " + str(c + 1))
	
	# Check diagonals
	var diagonal_1 = [0, 6, 12, 18, 24]
	check_line.call(diagonal_1, "Diagonal \\")
	
	var diagonal_2 = [4, 8, 12, 16, 20]
	check_line.call(diagonal_2, "Diagonal /")
	
	return {"total_bonus": total_bonus, "details": details}

func is_perfect_match(idx: int) -> bool:
	if placed_slabs[idx] == null: 
		return false
		
	var row = idx / 5
	var expected_letter = LIMBO_LETTERS[row]
	var slab = placed_slabs[idx]
	
	return slab.letter == expected_letter and slab.number == grid_numbers[idx]

# === SHOP SYSTEM ===

func add_slab_to_deck(slab_data: Dictionary):
	# Helper to convert dict to SlabData (for shop compatibility)
	var new_slab = SlabData.new(
		slab_data.get("letter", "L"), 
		slab_data.get("number", 1),
		slab_data.get("rarity", "common")
	)
	deck.append(new_slab)

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

# === UTILITY FUNCTIONS ===

func get_letter_for_row(row: int) -> String:
	return LIMBO_LETTERS[row] if row < LIMBO_LETTERS.size() else "L"

func get_row_col(index: int) -> Vector2i:
	return Vector2i(index % 5, index / 5)
