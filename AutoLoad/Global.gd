extends Node

# Game State
var current_encounter: int = 1
var current_round: int = 1
var total_coins: int = 0
var essence: int = 0

# Current Game
var current_score: int = 0
var opponent_target: int = 100
var draws_remaining: int = 8
var max_draws: int = 8

# Deck Management
var deck: Array = []
var placed_slabs: Array = [] # Stays for encounter (25 slots for 5x5)

# Artifacts and Modifiers
var artifacts: Array = []
var number_bias: Dictionary = {} # e.g., {"min": 1, "max": 5}
var letter_bias: Array = [] # e.g., ["L", "I"]

# Grid numbers (generated per encounter)
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

func create_starting_deck():
	deck.clear()
	var letters = ["L", "I", "M", "B", "O"]
	for letter in letters:
		for num in range(1, 16): # 1-15
			deck.append({"letter": letter, "number": num, "rarity": "common"})
	deck.shuffle()

func generate_grid_numbers():
	grid_numbers.clear()
	for i in range(25): # 5x5 = 25 cells
		grid_numbers.append(randi_range(1, 15))

func draw_slab() -> Dictionary:
	if deck.is_empty():
		create_starting_deck() # Reshuffle if empty
	draws_remaining -= 1
	return deck.pop_front()

func start_new_round():
	current_score = 0
	draws_remaining = max_draws
	# Board persists across rounds in same encounter

func start_new_encounter():
	current_round = 1
	current_encounter += 1
	placed_slabs.clear()
	placed_slabs.resize(25)
	placed_slabs.fill(null)
	generate_grid_numbers()
	opponent_target = 100 + (current_encounter * 50)

func calculate_score() -> Dictionary:
	var perfect_matches = 0
	var perfect_lines = 0
	var base_coins = 0
	
	# Check each placed slab for perfect match
	for i in range(25):
		if placed_slabs[i] != null:
			var slab = placed_slabs[i]
			var row = i / 5
			var expected_letter = ["L", "I", "M", "B", "O"][row]
			
			if slab.letter == expected_letter and slab.number == grid_numbers[i]:
				perfect_matches += 1
				base_coins += 5
	
	# Check for perfect lines (horizontal)
	for row in range(5):
		var line_perfect = true
		for col in range(5):
			var idx = row * 5 + col
			if placed_slabs[idx] == null:
				line_perfect = false
				break
			var slab = placed_slabs[idx]
			var expected_letter = ["L", "I", "M", "B", "O"][row]
			if slab.letter != expected_letter or slab.number != grid_numbers[idx]:
				line_perfect = false
				break
		
		if line_perfect:
			perfect_lines += 1
	
	# Calculate total with multipliers
	var line_bonus = 0
	if perfect_lines > 0:
		# Each perfect line gives 4x the coins from that line's perfect matches
		line_bonus = perfect_lines * 5 * 5 * 4 # 5 cells * 5 coins * 4x
	
	var total = base_coins + line_bonus
	
	return {
		"total": total,
		"perfect_matches": perfect_matches,
		"perfect_lines": perfect_lines,
		"base_coins": base_coins
	}
