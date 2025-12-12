# Scripts/AutoLoad/constants.gd
# Create this as an autoload singleton
extends Node

# === VISUAL CONSTANTS ===
const LETTER_COLORS := {
	"L": Color("#ff5555"),
	"I": Color("#ff9955"),
	"M": Color("#ffff55"),
	"B": Color("#55ff55"),
	"O": Color("#aa55ff")
}

const LIMBO_LETTERS := ["L", "I", "M", "B", "O"]

# === GAME BALANCE ===
const STARTING_DRAWS := 8
const MAX_BENCH_SLOTS := 5
const GRID_SIZE := 25
const GRID_COLS := 5
const GRID_ROWS := 5

const BASE_TARGET := 100
const TARGET_SCALING := 50

# === SCORING ===
const LETTER_MATCH_BONUS := 10
const PERFECT_MATCH_BONUS := 25
const BASE_LINE_MULTIPLIER := 2
const PERFECT_LINE_BONUS := 1  # +1 multiplier per perfect after 2

# === PATHS ===
const CUSTOM_FONT := preload("res://Assets/Fonts/Creepster-Regular.ttf")
const GRID_CELL_SCENE := preload("res://Scenes/grid_cell.tscn")

# === AUDIO ===
const AUDIO_PATHS := {
	"draw": "res://Assets/Audio/draw.wav",
	"place": "res://Assets/Audio/place.wav",
	"slide": "res://Assets/Audio/slide.wav",
	"error": "res://Assets/Audio/error.wav",
	"win": "res://Assets/Audio/win.mp3",
	"music": "res://Assets/Audio/music.mp3"
}

# === UTILITY FUNCTIONS ===
static func get_letter_for_row(row: int) -> String:
	return LIMBO_LETTERS[row] if row < LIMBO_LETTERS.size() else "L"

static func get_cell_index(row: int, col: int) -> int:
	return row * GRID_COLS + col

static func get_row_from_index(idx: int) -> int:
	return idx / GRID_COLS

static func get_col_from_index(idx: int) -> int:
	return idx % GRID_COLS
