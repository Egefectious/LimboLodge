# res://Scripts/Data/SlabDefinitions.gd
extends Node

# This dictionary holds all the data for your 54 slabs.
# To balance the game, just edit the numbers here!

const SLABS = {
	# === COMMON SLABS (20) ===
	"bonus_five": {
		"name": "Bonus Five", "rarity": "common", "cost": 20,
		"desc": "All placements +5 points",
		"type": "additive", "val": 5
	},
	"letter_shift": {
		"name": "Letter Shift", "rarity": "common", "cost": 20,
		"desc": "Match adjacent letters (L-I, I-M, etc.)",
		"type": "rule_change", "effect": "adjacent_letters"
	},
	"number_flex": {
		"name": "Number Flex", "rarity": "common", "cost": 20,
		"desc": "Match numbers +/- 1",
		"type": "rule_change", "effect": "flex_numbers"
	},
	"chain_starter": {
		"name": "Chain Starter", "rarity": "common", "cost": 25,
		"desc": "+1, +2, +3... bonus per placement",
		"type": "scaling", "val": 1
	},
	"corner_power": {
		"name": "Corner Power", "rarity": "common", "cost": 15,
		"desc": "Corner placements +4 points",
		"type": "positional", "val": 4, "target": "corner"
	},
	"center_power": {
		"name": "Center Power", "rarity": "common", "cost": 15,
		"desc": "Center placement +7 points",
		"type": "positional", "val": 7, "target": "center"
	},
	"first_strike": {
		"name": "First Strike", "rarity": "common", "cost": 20,
		"desc": "1st placement +8 points",
		"type": "sequential", "val": 8, "index": 0
	},
	"final_push": {
		"name": "Final Push", "rarity": "common", "cost": 20,
		"desc": "8th placement +8 points",
		"type": "sequential", "val": 8, "index": 7
	},
	"neighbor_friend": {
		"name": "Neighbor Friend", "rarity": "common", "cost": 25,
		"desc": "+2 points per filled neighbor",
		"type": "dynamic_add", "effect": "neighbors", "val": 2
	},
	"odd_bonus": {
		"name": "Odd Bonus", "rarity": "common", "cost": 20,
		"desc": "Odd grid numbers +5 points",
		"type": "conditional", "check": "odd", "val": 5
	},
	"even_bonus": {
		"name": "Even Bonus", "rarity": "common", "cost": 20,
		"desc": "Even grid numbers +5 points",
		"type": "conditional", "check": "even", "val": 5
	},
	"salvage": {
		"name": "Salvage", "rarity": "common", "cost": 20,
		"desc": "Mismatches score min 5 points",
		"type": "min_score", "val": 5, "cond": "mismatch"
	},
	"steady_income": {
		"name": "Steady Income", "rarity": "common", "cost": 25,
		"desc": "Gain 1 Coin per placement",
		"type": "economy", "resource": "coins", "val": 1
	},
	"essence_drip": {
		"name": "Essence Drip", "rarity": "common", "cost": 30,
		"desc": "Perfects give +1 Essence",
		"type": "economy_cond", "resource": "essence", "val": 1, "cond": "perfect"
	},
	"line_reward": {
		"name": "Line Reward", "rarity": "common", "cost": 25,
		"desc": "Line completing placement +10",
		"type": "line_finish", "val": 10
	},
	"quick_placement": {
		"name": "Quick Placement", "rarity": "common", "cost": 15,
		"desc": "Minimum 7 points per placement",
		"type": "min_score", "val": 7, "cond": "all"
	},
	"lucky_seven": {
		"name": "Lucky Seven", "rarity": "common", "cost": 25,
		"desc": "Slabs with 7 are always Perfect",
		"type": "rule_change", "effect": "perfect_7"
	},
	"double_digits": {
		"name": "Double Digits", "rarity": "common", "cost": 25,
		"desc": "Numbers 10+ gain +4 points",
		"type": "conditional", "check": "high_num", "val": 4
	},
	"early_advantage": {
		"name": "Early Advantage", "rarity": "common", "cost": 20,
		"desc": "+1 per empty cell in row/col",
		"type": "dynamic_add", "effect": "empty_rc", "val": 1
	},
	"safety_net": {
		"name": "Safety Net", "rarity": "common", "cost": 30,
		"desc": "+50 points if failing (Once/Caller)",
		"type": "trigger", "effect": "save_fail", "val": 50
	},

	# === UNCOMMON SLABS (15) ===
	"small_mult": {
		"name": "Small Mult", "rarity": "uncommon", "cost": 50,
		"desc": "All scores x1.2",
		"type": "mult", "val": 1.2
	},
	"bonus_ten": {
		"name": "Bonus Ten", "rarity": "uncommon", "cost": 40,
		"desc": "All placements +10 points",
		"type": "additive", "val": 10
	},
	"perfect_spread": {
		"name": "Perfect Spread", "rarity": "uncommon", "cost": 60,
		"desc": "Perfects make 1 neighbor Perfect",
		"type": "grid_mod", "effect": "spread_perfect", "range": 1
	},
	"ghost_slab": {
		"name": "Ghost Slab", "rarity": "uncommon", "cost": 55,
		"desc": "Can replace placed slabs",
		"type": "rule_change", "effect": "allow_overwrite"
	},
	"number_swap": {
		"name": "Number Swap", "rarity": "uncommon", "cost": 50,
		"desc": "Swap cell numbers after place",
		"type": "active", "effect": "swap_num"
	},
	"wild_letter": {
		"name": "Wild Letter", "rarity": "uncommon", "cost": 60,
		"desc": "Matches ANY letter",
		"type": "rule_change", "effect": "wild_letter"
	},
	"wild_number": {
		"name": "Wild Number", "rarity": "uncommon", "cost": 60,
		"desc": "Matches ANY number",
		"type": "rule_change", "effect": "wild_number"
	},
	"chain_multiplier": {
		"name": "Chain Multiplier", "rarity": "uncommon", "cost": 55,
		"desc": "+2, +4, +6... bonus per placement",
		"type": "scaling", "val": 2
	},
	"high_risk": {
		"name": "High Risk", "rarity": "uncommon", "cost": 45,
		"desc": "Perfect x1.5, others score 0",
		"type": "special_mult", "effect": "risk_reward", "good": 1.5, "bad": 0.0
	},
	"mirror_play": {
		"name": "Mirror Play", "rarity": "uncommon", "cost": 50,
		"desc": "Copies previous score",
		"type": "score_mod", "effect": "copy_prev"
	},
	"line_shield": {
		"name": "Line Shield", "rarity": "uncommon", "cost": 55,
		"desc": "Row/Col immune to Caller",
		"type": "defense", "val": 1
	},
	"essence_bloom": {
		"name": "Essence Bloom", "rarity": "uncommon", "cost": 50,
		"desc": "Perfects give +2 Essence",
		"type": "economy_cond", "resource": "essence", "val": 2, "cond": "perfect"
	},
	"coin_rush": {
		"name": "Coin Rush", "rarity": "uncommon", "cost": 40,
		"desc": "Gain 3 Coins per placement",
		"type": "economy", "resource": "coins", "val": 3
	},
	"perfect_refund": {
		"name": "Perfect Refund", "rarity": "uncommon", "cost": 55,
		"desc": "Perfect grants +5 to NEXT placement",
		"type": "chain", "val": 5
	},
	"line_boost": {
		"name": "Line Boost", "rarity": "uncommon", "cost": 60,
		"desc": "Line multiplier +1 (x2->x3)",
		"type": "line_mult_add", "val": 1
	},

	# === RARE SLABS (10) ===
	"big_mult": {
		"name": "Big Mult", "rarity": "rare", "cost": 120,
		"desc": "All scores x1.5",
		"type": "mult", "val": 1.5
	},
	"double_line": {
		"name": "Double Line", "rarity": "rare", "cost": 150,
		"desc": "Lines apply multiplier TWICE",
		"type": "line_mod", "effect": "double_proc"
	},
	"perfect_chain": {
		"name": "Perfect Chain", "rarity": "rare", "cost": 130,
		"desc": "Perfects make 2 neighbors Perfect",
		"type": "grid_mod", "effect": "spread_perfect", "range": 2
	},
	"curse_breaker": {
		"name": "Curse Breaker", "rarity": "rare", "cost": 140,
		"desc": "Negates ALL Caller abilities",
		"type": "defense", "val": 999
	},
	"untouchable": {
		"name": "Untouchable", "rarity": "rare", "cost": 135,
		"desc": "Placements can't be interfered",
		"type": "defense", "val": 999
	},
	"all_perfect": {
		"name": "All Perfect", "rarity": "rare", "cost": 150,
		"desc": "5+ Perfects = ALL count as Perfect",
		"type": "trigger", "effect": "convert_all_perfect", "threshold": 5
	},
	"momentum": {
		"name": "Momentum", "rarity": "rare", "cost": 140,
		"desc": "+5, +10, +15... bonus",
		"type": "scaling", "val": 5
	},
	"reversal": {
		"name": "Reversal", "rarity": "rare", "cost": 145,
		"desc": "Caller debuffs become buffs",
		"type": "defense_special", "effect": "reverse"
	},
	"eternal_slab": {
		"name": "Eternal Slab", "rarity": "rare", "cost": 110,
		"desc": "One slab persists to next Caller",
		"type": "meta", "effect": "persist_one"
	},
	"coin_flip": {
		"name": "Coin Flip", "rarity": "rare", "cost": 100,
		"desc": "50/50: x2.5 OR -10 points",
		"type": "gambit", "mult": 2.5, "pen": -10
	},
	
	# ... (You can add the Ultra Rares here following the same pattern)
}

# Helper to pick a random slab key by rarity
func get_random_id(rarity: String) -> String:
	var pool = []
	for id in SLABS:
		if SLABS[id].rarity == rarity:
			pool.append(id)
	if pool.is_empty(): return "bonus_five"
	return pool.pick_random()
