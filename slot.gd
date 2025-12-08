extends Node3D

var grid_x: int
var grid_y: int
var assigned_letter: String
var assigned_number: int

@onready var label = $Label3D

func setup(x, y, letter, number):
	grid_x = x
	grid_y = y
	assigned_letter = letter
	assigned_number = number
	label.text = "%s\n%d" % [letter, number]
