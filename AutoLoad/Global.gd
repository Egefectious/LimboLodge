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
var bench: Array = []

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
	
	setup_bench()

func create_starting_deck():
	deck.clear()
	var letters = ["L", "I", "M", "B", "O"]
	for letter in letters:
		for num in range(1, 16):
			deck.append({"letter": letter, "number": num, "rarity": "common"})
	deck.shuffle()

func generate_grid_numbers():
	grid_numbers.clear()
	
	# 1. Create a pool of numbers 1-15
	var number_pool = []
	for i in range(1, 16):
		number_pool.append(i)
	
	number_pool.shuffle()
	
	# 2. Use the first 15 unique numbers
	for i in range(15):
		grid_numbers.append(number_pool[i])
	
	# 3. Fill the last 10 spots randomly (SAFE: No while loop)
	for i in range(10):
		grid_numbers.append(randi_range(1, 15))
	
	grid_numbers.shuffle()

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
	generate_grid_numbers()
	opponent_target = 100 + (current_encounter * 50)
	setup_bench()


func calculate_score() -> Dictionary:
	var perfect_matches = 0
	var perfect_lines = 0
	var base_coins = 0
	
	for i in range(25):
		if placed_slabs[i] != null:
			var slab = placed_slabs[i]
			var row = i / 5
			var expected_letter = ["L", "I", "M", "B", "O"][row]
			
			if slab.letter == expected_letter and slab.number == grid_numbers[i]:
				perfect_matches += 1
				base_coins += 5
	
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
	
	var line_bonus = 0
	if perfect_lines > 0:
		line_bonus = perfect_lines * 5 * 5 * 4
	
	var total = base_coins + line_bonus
	
	return {
		"total": total,
		"perfect_matches": perfect_matches,
		"perfect_lines": perfect_lines,
		"base_coins": base_coins
	}

func setup_bench():
	bench.clear()
	bench.resize(5)
	bench.fill(null)
