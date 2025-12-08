# DeckGenerator.gd
@tool
extends EditorScript

func _run():
	var letters = ["L", "I", "M", "B", "O"]
	var folder_path = "res://Resources/Slabs/"
	
	# Make sure folder exists
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(folder_path):
		dir.make_dir_recursive(folder_path)
		
	for letter in letters:
		for i in range(1, 16):
			var new_slab = SlabStandard.new()
			new_slab.letter = letter
			new_slab.number = i
			new_slab.rarity = "Common"
			
			# Save it as a file like "Slab_L_01.tres"
			var filename = "Slab_%s_%02d.tres" % [letter, i]
			ResourceSaver.save(new_slab, folder_path + filename)
			print("Created: " + filename)
	
	print("Deck Generation Complete!")
