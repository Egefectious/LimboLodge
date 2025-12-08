# SlabStandard.gd
class_name SlabStandard extends SlabData

func get_score_bonus(current_score: int) -> int:
	# Standard slabs just give flat points if matched correctly
	return 10
