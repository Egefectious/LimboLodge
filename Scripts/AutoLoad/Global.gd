
extends Node

var current_encounter: int = 1
var current_round: int = 1
var coins: int = 0
var essence: int = 0
var obols: int = 0

var current_score: int = 0
var opponent_target: int = 100
var draws_remaining: int = 8
var max_draws: int = 8

# Arrays containing SlabData objects
var deck: Array[SlabData] = []
var placed_slabs: Array = [] # Array of SlabData or null
var benched_slabs: Array[SlabData] = []
var max_bench_slots: int = 5

var artifacts: Array = []
var number_bias: Dictionary = {}

var grid_numbers: Array = []

func _ready():
	reset_game()

func reset_game():
	current_encounter = 1
	current_round = 1
	coins = 0
	essence = 0
	obols = 0
	create_starting_deck()
	generate_grid_numbers()
	clear_board()
	benched_slabs.clear()

func create_starting_deck():
	deck.clear()
	var letters = ["L", "I", "M", "B", "O"]
	for letter_char in letters:
		for num in range(1, 16):
			var new_slab = SlabData.new(letter_char, num, "common")
			deck.append(new_slab)
	deck.shuffle()

func generate_grid_numbers():
	grid_numbers.clear()
	# Generate 5 rows, each with unique numbers 1-15 mixed
	for row in range(5):
		var row_numbers = []
		for i in range(1, 16):
			row_numbers.append(i)
		row_numbers.shuffle()
		for col in range(5):
			grid_numbers.append(row_numbers[col])

func clear_board():
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)

func draw_slab() -> SlabData:
	if deck.is_empty():
		create_starting_deck() # reshuffle logic if needed
	draws_remaining -= 1
	return deck.pop_front()

func add_slab_to_deck(slab_data: Dictionary):
	# Helper to convert dict to SlabData if coming from older shop logic
	var new_slab = SlabData.new(slab_data.get("letter", "L"), slab_data.get("number", 1))
	deck.append(new_slab)

func start_new_round_logic(keep_board: bool):
	current_round += 1
	draws_remaining = max_draws
	if not keep_board:
		clear_board()

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	clear_board()
	benched_slabs.clear()
	generate_grid_numbers()
	opponent_target = 100 + (current_encounter * 50)
	current_score = 0
	draws_remaining = max_draws

# --- Scoring Logic ---
func calculate_score() -> Dictionary:
	var single_scores = []
	var total_score = 0
	var perfect_count = 0
	
	for i in range(25):
		if placed_slabs[i] != null:
			var slab = placed_slabs[i]
			var row = i / 5
			var expected_letter = ["L", "I", "M", "B", "O"][row]
			
			var base_score = slab.number
			var is_letter_correct = (slab.letter == expected_letter)
			var is_number_correct = (slab.number == grid_numbers[i])
			var is_perfect = is_letter_correct and is_number_correct
			
			if is_perfect:
				base_score += 25
				perfect_count += 1
			elif is_letter_correct:
				base_score += 10
			
			single_scores.append(base_score)
			total_score += base_score
		else:
			single_scores.append(0)
	
	var line_bonuses = calculate_line_bonuses(single_scores)
	total_score += line_bonuses.total_bonus
	
	var coins_earned = int(total_score / 10)
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
	
	# Helper to check lines
	var check_line = func(indices: Array, name: String):
		var filled = 0
		var score_sum = 0
		var perfects = 0
		for idx in indices:
			if placed_slabs[idx] != null:
				filled += 1
				score_sum += single_scores[idx]
				if is_perfect_match(idx): perfects += 1
		
		if filled == indices.size():
			var multiplier = 2 + max(0, perfects - 2)
			var bonus = score_sum * (multiplier - 1)
			total_bonus += bonus
			details.append({"type": name, "bonus": bonus, "multiplier": multiplier})

	# Rows
	for r in range(5):
		var idxs = []
		for c in range(5): idxs.append(r * 5 + c)
		check_line.call(idxs, "Row " + str(r+1))
		
	# Cols
	for c in range(5):
		var idxs = []
		for r in range(5): idxs.append(r * 5 + c)
		check_line.call(idxs, "Col " + str(c+1))
		
	# Diagonals
	var d1 = [0, 6, 12, 18, 24]
	check_line.call(d1, "Diagonal \\")
	var d2 = [4, 8, 12, 16, 20]
	check_line.call(d2, "Diagonal /")

	return {"total_bonus": total_bonus, "details": details}

func is_perfect_match(idx: int) -> bool:
	if placed_slabs[idx] == null: return false
	var row = idx / 5
	var expected = ["L", "I", "M", "B", "O"][row]
	return placed_slabs[idx].letter == expected and placed_slabs[idx].number == grid_numbers[idx]

# --- Artifact & Weights (Stubbed) ---
func add_artifact(id: String): artifacts.append(id)
func increase_number_weight(num: int, val: int):
	number_bias[num] = number_bias.get(num, 0) + val
func get_weighted_random_number() -> int:
	var pool = []
	for i in range(1, 16):
		var w = 10 + number_bias.get(i, 0)
		for k in range(w): pool.append(i)
	return pool.pick_random()
