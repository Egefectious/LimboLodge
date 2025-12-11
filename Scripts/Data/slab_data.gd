class_name SlabData
extends Resource

@export var letter: String
@export var number: int
@export var rarity: String = "common"

func _init(p_letter: String = "L", p_number: int = 1, p_rarity: String = "common"):
	letter = p_letter
	number = p_number
	rarity = p_rarity
