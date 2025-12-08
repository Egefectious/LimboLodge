# SlabData.gd
abstract class_name SlabData extends Resource

# This defines what every single slab in the game has
@export_group("Visuals")
@export var icon: Texture2D
@export var glow_color: Color = Color.CYAN

@export_group("Gameplay")
@export_enum("L", "I", "M", "B", "O") var letter: String = "L"
@export_range(1, 15) var number: int = 1
@export_enum("Common", "Uncommon", "Rare", "Legendary", "Cursed") var rarity: String = "Common"

# This function does nothing now, but specific slabs will override it later
func get_score_bonus(current_score: int) -> int:
	return 0
