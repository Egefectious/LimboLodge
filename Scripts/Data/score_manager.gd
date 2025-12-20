class_name ScoreManager extends Node

var game_board: Control
var total_score_label: Label
var score_accumulated: int = 0
var base_points_paid: Dictionary = {} 

func _init(board: Control, label: Label):
	game_board = board
	total_score_label = label

func run_score_sequence(result: Dictionary, cells: Array):
	score_accumulated = 0
	base_points_paid.clear()
	AudioManager.reset_pitch()
	
	# --- 1. IDENTIFY ORPHANS (Cells not in any line) ---
	var line_indices = {}
	for line in result.line_details:
		var indices = _get_indices_from_name(line.type)
		for idx in indices:
			line_indices[idx] = true
			
	# --- 2. SCORE ORPHANS ---
	for i in range(25):
		if Global.placed_slabs[i] != null and not line_indices.has(i):
			await _play_cell_score(i, cells[i])
			await game_board.get_tree().create_timer(0.05).timeout

	# --- 3. SCORE LINES ---
	# Sort lines: smaller wins first, big wins last
	var lines = result.line_details.duplicate()
	lines.sort_custom(func(a, b): return a.bonus < b.bonus)
	
	for line in lines:
		var indices = _get_indices_from_name(line.type)
		
		# === NEW VISUAL: DRAW THE CONNECTION ===
		# Cyan for small hits, Gold for big hits
		var line_color = Color.CYAN if line.multiplier < 1.5 else Color.GOLD
		_draw_combo_line(indices, cells, line_color)
		
		var line_base_sum = 0
		
		# A. Animate each slab in the line (Pop visuals)
		for idx in indices:
			if Global.placed_slabs[idx] != null:
				var slab_points = _get_slab_points(idx)
				line_base_sum += slab_points
				
				_spawn_visual_for_cell(idx, cells[idx], slab_points)
				
				if not base_points_paid.has(idx):
					_add_to_total(slab_points)
					base_points_paid[idx] = true
				
				await game_board.get_tree().create_timer(0.05).timeout
		
		# B. Show Line Summary 
		var center = _get_center_pos(indices, cells)
		
		# Shake screen based on multiplier power
		_shake_screen(2.0 * line.multiplier)
		
		# Show Base Sum
		var txt_sum = _spawn_text("Base: " + str(line_base_sum), center, Color.WHITE, FloatingText.Type.NORMAL)
		AudioManager.play("slide")
		await txt_sum.finished
		
		# Show Multiplier
		var txt_mult = _spawn_text("x" + str(line.multiplier), center, line_color, FloatingText.Type.MULT)
		AudioManager.play("win") 
		await game_board.get_tree().create_timer(0.4).timeout 
		
		# Add Bonus to Total
		var bonus = line.bonus
		_rapid_score_add(bonus) 
		
		# Show Floating Total
		_spawn_text("+" + str(bonus), center + Vector2(0, 40), Color.GOLD, FloatingText.Type.LINE_TOTAL)
		
		await game_board.get_tree().create_timer(0.2).timeout

	await game_board.get_tree().create_timer(0.5).timeout

# --- SCORING HELPERS ---

func _play_cell_score(idx: int, cell: Control):
	var points = _get_slab_points(idx)
	_spawn_visual_for_cell(idx, cell, points)
	
	if Global.is_perfect_match(idx):
		if Global.has_effect("scale_base"):
			Global.perm_base_bonus += 1
			_spawn_text("+1 Base Perm!", cell.global_position + Vector2(0, -30), Color.CYAN, FloatingText.Type.NORMAL)
		if Global.has_effect("scale_mult"):
			Global.perm_mult_bonus += 0.1
			_spawn_text("+0.1 Mult Perm!", cell.global_position + Vector2(0, -50), Color.MAGENTA, FloatingText.Type.NORMAL)

	_add_to_total(points)
	base_points_paid[idx] = true
	
	await game_board.get_tree().create_timer(0.1).timeout

func _spawn_visual_for_cell(idx: int, cell: Control, points: int):
	var is_perfect = Global.is_perfect_match(idx)
	# Adjust position to center of cell (assuming 75x75 cell)
	var pos = cell.global_position + Vector2(37, 10)
	
	if is_perfect:
		_spawn_text("Perfect! +" + str(points), pos, Color("#ffff00"), FloatingText.Type.PERFECT)
		AudioManager.play_sequential("place", 0.1)
		_flash_cell(cell, Color.YELLOW)
	else:
		_spawn_text(str(points), pos, Color.WHITE, FloatingText.Type.NORMAL)
		AudioManager.play_sequential("place", 0.05)
		_flash_cell(cell, Color.WHITE)

func _rapid_score_add(amount: int):
	var steps = 5
	var step_val = amount / steps
	for i in range(steps):
		score_accumulated += step_val
		total_score_label.text = "SCORE: " + str(score_accumulated)
		AudioManager.play("place", Vector2(1.5 + (i*0.1), 1.5 + (i*0.1)))
		_pulse_label()
		await game_board.get_tree().create_timer(0.05).timeout
	
	score_accumulated += (amount % steps)
	total_score_label.text = "SCORE: " + str(score_accumulated)

# --- UTILITIES ---

func _get_slab_points(idx: int) -> int:
	var slab = Global.placed_slabs[idx]
	var points = slab.number
	var row = idx / 5
	var is_letter = (slab.letter == Global.LIMBO_LETTERS[row])
	
	if Global.is_perfect_match(idx): points += 25
	elif is_letter: points += 10
	return points

func _spawn_text(val: String, pos: Vector2, col: Color, type) -> FloatingText:
	var txt = FloatingText.new()
	game_board.add_child(txt)
	txt.setup(val, pos, col, type)
	return txt

func _add_to_total(amount: int):
	score_accumulated += amount
	total_score_label.text = "SCORE: " + str(score_accumulated)
	_pulse_label()

func _pulse_label():
	var t = game_board.create_tween()
	t.tween_property(total_score_label, "scale", Vector2(1.2, 1.2), 0.05)
	t.tween_property(total_score_label, "scale", Vector2(1.0, 1.0), 0.05)

func _flash_cell(cell, color):
	var bg = cell.get_node_or_null("Background")
	if bg:
		var t = game_board.create_tween()
		t.tween_property(bg, "modulate", color, 0.1)
		t.tween_property(bg, "modulate", Color.WHITE, 0.2)

func _get_indices_from_name(name: String) -> Array:
	var indices = []
	if name.begins_with("Row"):
		var r = int(name.split(" ")[1]) - 1
		for c in range(5): indices.append(r * 5 + c)
	elif name.begins_with("Col"):
		var c = int(name.split(" ")[1]) - 1
		for r in range(5): indices.append(r * 5 + c)
	elif "Diagonal \\" in name: indices = [0, 6, 12, 18, 24]
	elif "Diagonal /" in name: indices = [4, 8, 12, 16, 20]
	return indices

func _get_center_pos(indices: Array, cells: Array) -> Vector2:
	if indices.is_empty(): return Vector2(640, 360)
	var sum = Vector2.ZERO
	for idx in indices: sum += cells[idx].global_position
	return (sum / indices.size()) + Vector2(37, 37)

# --- NEW VISUAL HELPERS ---

func _draw_combo_line(indices: Array, cells: Array, color: Color):
	if indices.size() < 2: return
	
	var line = Line2D.new()
	line.width = 0
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	for idx in indices:
		# Offset to center of cell
		line.add_point(cells[idx].global_position + Vector2(37, 37))
	
	game_board.add_child(line)
	
	var t = game_board.create_tween()
	t.tween_property(line, "width", 12.0, 0.2).set_trans(Tween.TRANS_ELASTIC)
	t.tween_property(line, "modulate:a", 0.0, 0.5).set_delay(0.5)
	t.tween_callback(line.queue_free)

func _shake_screen(intensity: float):
	if not game_board: return
	var initial_pos = game_board.position
	var tween = game_board.create_tween()
	for i in range(8):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(game_board, "position", initial_pos + offset, 0.05)
	tween.tween_property(game_board, "position", initial_pos, 0.05)
