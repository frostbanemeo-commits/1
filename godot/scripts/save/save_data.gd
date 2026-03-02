extends RefCounted
class_name SaveData

# ═══════════════════════════════════════════════════════════════════
#  Save Data
#  The full serializable state of a single save slot.
#  Serializes to / deserializes from JSON.
# ═══════════════════════════════════════════════════════════════════

const SAVE_VERSION := 1

# ── Identity ──────────────────────────────────────────────────────
var save_version:    int    = SAVE_VERSION
var slot:            int    = 0
var save_timestamp:  String = ""
var play_time:       float  = 0.0   # seconds

# ── World ─────────────────────────────────────────────────────────
var world_seed:      int    = 0
var current_cell:    Vector2i = Vector2i(5, 5)   # starter cell
var player_position: Vector3  = Vector3.ZERO

# ── Discovery ─────────────────────────────────────────────────────
# Stored as Array of [x, z, discovery_state_int]
var cell_states:     Array = []

# ── Story ─────────────────────────────────────────────────────────
var story_progress:  int   = -1    # index of last completed story beat
var story_complete:  bool  = false

# ── Abilities ─────────────────────────────────────────────────────
var fly_mode_unlocked:    bool = false
var ship_summon_unlocked: bool = false

# ── Player progression ────────────────────────────────────────────
var strength_fragments:   int  = 0   # 0–4

# ── Character customization ───────────────────────────────────────
var character:  Dictionary = {}   # populated by character creation

# ── Cargo hold ────────────────────────────────────────────────────
var cargo:  Array = []   # Array of serialized CargoItem dicts

# ── Options (persisted per save) ─────────────────────────────────
var options:  Dictionary = {}


# ── Serialization ─────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"save_version":         save_version,
		"slot":                 slot,
		"save_timestamp":       save_timestamp,
		"play_time":            play_time,
		"world_seed":           world_seed,
		"current_cell":         [current_cell.x, current_cell.y],
		"player_position":      [player_position.x, player_position.y, player_position.z],
		"cell_states":          cell_states,
		"story_progress":       story_progress,
		"story_complete":       story_complete,
		"fly_mode_unlocked":    fly_mode_unlocked,
		"ship_summon_unlocked": ship_summon_unlocked,
		"strength_fragments":   strength_fragments,
		"character":            character,
		"cargo":                cargo,
		"options":              options,
	}


static func from_dict(d: Dictionary) -> SaveData:
	var s                    := SaveData.new()
	s.save_version            = d.get("save_version",    SAVE_VERSION)
	s.slot                    = d.get("slot",             0)
	s.save_timestamp          = d.get("save_timestamp",  "")
	s.play_time               = d.get("play_time",       0.0)
	s.world_seed              = d.get("world_seed",      0)
	var cp: Array             = d.get("current_cell",    [5, 5])
	s.current_cell            = Vector2i(cp[0], cp[1])
	var pp: Array             = d.get("player_position", [0.0, 0.0, 0.0])
	s.player_position         = Vector3(pp[0], pp[1], pp[2])
	s.cell_states             = d.get("cell_states",     [])
	s.story_progress          = d.get("story_progress",  -1)
	s.story_complete          = d.get("story_complete",  false)
	s.fly_mode_unlocked       = d.get("fly_mode_unlocked",    false)
	s.ship_summon_unlocked    = d.get("ship_summon_unlocked", false)
	s.strength_fragments      = d.get("strength_fragments",   0)
	s.character               = d.get("character",       {})
	s.cargo                   = d.get("cargo",           [])
	s.options                 = d.get("options",         {})
	return s
