class_name SlabData extends Resource

@export var letter: String = "L"
@export var number: int = 1
@export var rarity: String = "Common"
@export_multiline var description: String = ""

# FIX: Added 'rare' as the 3rd argument
static func create(ltr: String, num: int, rare: String = "Common") -> SlabData:
	var s = SlabData.new()
	s.letter = ltr
	s.number = num
	s.rarity = rare
	return s
