extends Node

var current_encounter: int = 1
var current_round: int = 1
var total_coins: int = 0
var essence: int = 0

var current_score: int = 0
var opponent_target: int = 100
var draws_remaining: int = 8
var max_draws: int = 8

var deck: Array = []
var placed_slabs: Array = []
var benched_slabs: Array = []
var max_bench_slots: int = 5

var artifacts: Array = []
var number_bias: Dictionary = {}
var letter_bias: Array = []

var grid_numbers: Array = []

func _ready():
	reset_game()

func reset_game():
	current_encounter = 1
	current_round = 1
	total_coins = 0
	essence = 0
	create_starting_deck()
	generate_grid_numbers()
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)
	benched_slabs.clear()

func create_starting_deck():
	deck.clear()
	var letters = ["L", "I", "M", "B", "O"]
	for letter in letters:
		for num in range(1, 16):
			deck.append({"letter": letter, "number": num, "rarity": "common"})
	deck.shuffle()

func generate_grid_numbers():
	grid_numbers.clear()
	
	# Generate 5 rows, each with unique numbers 1-15
	for row in range(5):
		var row_numbers = []
		for i in range(1, 16):
			row_numbers.append(i)
		row_numbers.shuffle()
		
		# Take first 5 numbers from shuffled pool for this row
		for col in range(5):
			grid_numbers.append(row_numbers[col])

func draw_slab() -> Dictionary:
	if deck.is_empty():
		create_starting_deck()
	draws_remaining -= 1
	return deck.pop_front()

func start_new_round():
	current_score = 0
	draws_remaining = max_draws

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)
	benched_slabs.clear()
	generate_grid_numbers()
	opponent_target = 100 + (current_encounter * 50)

func calculate_score() -> Dictionary:
	var single_scores = []
	var total_score = 0
	var perfect_count = 0
	var letter_correct_count = 0
	
	# Calculate single slab scores
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
				letter_correct_count += 1
			
			single_scores.append(base_score)
			total_score += base_score
		else:
			single_scores.append(0)
	
	# Calculate line bonuses
	var line_bonuses = calculate_line_bonuses(single_scores)
	
	total_score += line_bonuses.total_bonus
	
	return {
		"total": total_score,
		"base_score": total_score - line_bonuses.total_bonus,
		"line_bonus": line_bonuses.total_bonus,
		"perfect_count": perfect_count,
		"letter_correct_count": letter_correct_count,
		"line_details": line_bonuses.details
	}

func calculate_line_bonuses(single_scores: Array) -> Dictionary:
	var total_bonus = 0
	var details = []
	
	# Horizontal lines (5 lines)
	for row in range(5):
		var line_score = 0
		var perfect_in_line = 0
		var cells_filled = 0
		
		for col in range(5):
			var idx = row * 5 + col
			if placed_slabs[idx] != null:
				cells_filled += 1
				line_score += single_scores[idx]
				if is_perfect_match(idx):
					perfect_in_line += 1
		
		if cells_filled == 5:
			var multiplier = 2 + max(0, perfect_in_line - 2)  # 2x base, +1 for each perfect after 2
			var bonus = line_score * (multiplier - 1)
			total_bonus += bonus
			details.append({"type": "Horizontal Line " + str(row + 1), "bonus": bonus, "multiplier": multiplier})
	
	# Vertical lines (5 lines)
	for col in range(5):
		var line_score = 0
		var perfect_in_line = 0
		var cells_filled = 0
		
		for row in range(5):
			var idx = row * 5 + col
			if placed_slabs[idx] != null:
				cells_filled += 1
				line_score += single_scores[idx]
				if is_perfect_match(idx):
					perfect_in_line += 1
		
		if cells_filled == 5:
			var multiplier = 2 + max(0, perfect_in_line - 2)
			var bonus = line_score * (multiplier - 1)
			total_bonus += bonus
			details.append({"type": "Vertical Line " + str(col + 1), "bonus": bonus, "multiplier": multiplier})
	
	# Diagonal lines (2 lines)
	# Top-left to bottom-right
	var diag1_score = 0
	var diag1_perfect = 0
	var diag1_filled = 0
	for i in range(5):
		var idx = i * 5 + i
		if placed_slabs[idx] != null:
			diag1_filled += 1
			diag1_score += single_scores[idx]
			if is_perfect_match(idx):
				diag1_perfect += 1
	
	if diag1_filled == 5:
		var multiplier = 2 + max(0, diag1_perfect - 2)
		var bonus = diag1_score * (multiplier - 1)
		total_bonus += bonus
		details.append({"type": "Diagonal \\", "bonus": bonus, "multiplier": multiplier})
	
	# Top-right to bottom-left
	var diag2_score = 0
	var diag2_perfect = 0
	var diag2_filled = 0
	for i in range(5):
		var idx = i * 5 + (4 - i)
		if placed_slabs[idx] != null:
			diag2_filled += 1
			diag2_score += single_scores[idx]
			if is_perfect_match(idx):
				diag2_perfect += 1
	
	if diag2_filled == 5:
		var multiplier = 2 + max(0, diag2_perfect - 2)
		var bonus = diag2_score * (multiplier - 1)
		total_bonus += bonus
		details.append({"type": "Diagonal /", "bonus": bonus, "multiplier": multiplier})
	
	# Four Corners (only if all 4 are perfect)
	var corners = [0, 4, 20, 24]
	var corners_perfect = true
	var corners_score = 0
	for idx in corners:
		if placed_slabs[idx] == null or not is_perfect_match(idx):
			corners_perfect = false
			break
		corners_score += single_scores[idx]
	
	if corners_perfect:
		var bonus = corners_score * 4
		total_bonus += bonus
		details.append({"type": "Four Corners", "bonus": bonus, "multiplier": 5})
	
	# X Pattern (both diagonals - 9 cells, need 7-9 perfect)
	var x_cells = [0, 4, 6, 8, 12, 16, 18, 20, 24]
	var x_perfect = 0
	var x_score = 0
	var x_filled = 0
	for idx in x_cells:
		if placed_slabs[idx] != null:
			x_filled += 1
			x_score += single_scores[idx]
			if is_perfect_match(idx):
				x_perfect += 1
	
	if x_filled == 9 and x_perfect >= 7:
		var multiplier = 4 + (x_perfect - 7)  # 7=x4, 8=x5, 9=x6
		var bonus = x_score * (multiplier - 1)
		total_bonus += bonus
		details.append({"type": "X Pattern", "bonus": bonus, "multiplier": multiplier, "perfects": x_perfect})
	
	# H Pattern (left column + middle column + right column - 13 cells, need 10-13 perfect)
	var h_cells = [0, 5, 10, 15, 20, 2, 7, 12, 17, 22, 4, 9, 14, 19, 24]
	var h_perfect = 0
	var h_score = 0
	var h_filled = 0
	for idx in h_cells:
		if placed_slabs[idx] != null:
			h_filled += 1
			h_score += single_scores[idx]
			if is_perfect_match(idx):
				h_perfect += 1
	
	if h_filled == 13 and h_perfect >= 10:
		var multiplier = 8 + (h_perfect - 10)  # 10=x8, 11=x9, 12=x10, 13=x15
		if h_perfect == 13:
			multiplier = 15
		var bonus = h_score * (multiplier - 1)
		total_bonus += bonus
		details.append({"type": "H Pattern", "bonus": bonus, "multiplier": multiplier, "perfects": h_perfect})
	
	# Full Board Bonus (based on percentage of perfects)
	var total_placed = 0
	var total_perfect = 0
	for i in range(25):
		if placed_slabs[i] != null:
			total_placed += 1
			if is_perfect_match(i):
				total_perfect += 1
	
	if total_placed == 25:
		var perfect_percent = (total_perfect * 100) / 25
		var board_multiplier = 0
		
		if perfect_percent >= 100:
			board_multiplier = 50
		elif perfect_percent >= 90:
			board_multiplier = 15
		elif perfect_percent >= 80:
			board_multiplier = 12
		elif perfect_percent >= 70:
			board_multiplier = 8
		elif perfect_percent >= 60:
			board_multiplier = 6
		elif perfect_percent >= 50:
			board_multiplier = 4
		
		if board_multiplier > 0:
			var board_score = 0
			for score in single_scores:
				board_score += score
			var bonus = board_score * (board_multiplier - 1)
			total_bonus += bonus
			details.append({"type": "Full Board", "bonus": bonus, "multiplier": board_multiplier, "percent": perfect_percent})
	
	return {
		"total_bonus": total_bonus,
		"details": details
	}

func is_perfect_match(idx: int) -> bool:
	if placed_slabs[idx] == null:
		return false
	
	var slab = placed_slabs[idx]
	var row = idx / 5
	var expected_letter = ["L", "I", "M", "B", "O"][row]
	
	return slab.letter == expected_letter and slab.number == grid_numbers[idx]
