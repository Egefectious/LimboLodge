extends Node

# === VISUAL PALETTE (From HTML Redesign) ===
const COLOR_BG_DARK = Color("#0a0612")
const COLOR_ACCENT_PURPLE = Color("#8b4dc9")
const COLOR_TEXT_GOLD = Color("#ffeb3b")  # For Score
const COLOR_TEXT_RED = Color("#ff5252")   # For Target
const COLOR_TEXT_CYAN = Color("#4dd0e1")  # For Draws
const COLOR_TEXT_GREEN = Color("#69f0ae") # For Round
const COLOR_BUTTON_GREEN = Color("#2d5016")

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
# ... (Keep your existing balance constants below) ...
const BASE_TARGET := 100
const TARGET_SCALING := 50
const LETTER_MATCH_BONUS := 10
const PERFECT_MATCH_BONUS := 25
const BASE_LINE_MULTIPLIER := 2
const PERFECT_LINE_BONUS := 1

# === RESOURCES ===
const CUSTOM_FONT := preload("res://Assets/Fonts/Creepster-Regular.ttf")
