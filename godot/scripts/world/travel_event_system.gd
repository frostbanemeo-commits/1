extends Node
class_name TravelEventSystem

# ═══════════════════════════════════════════════════════════════════
#  Travel Event System
#
#  While the player travels through EMPTY cells on their skyship,
#  random events can trigger. These are the moments in the open sky —
#  the forced reset between islands. Time to breathe, to think,
#  to be surprised.
#
#  Events fire at most once per crossing of an empty cell.
#  Probability scales with zone — deeper zones have more frequent
#  and more dangerous events.
#
#  Event types:
#    DEBRIS_FIELD     — floating wreckage, lootable
#    EMPIRE_PATROL    — empire ships crossing your path
#    PIRATE_SIGNAL    — distress signal or ambush
#    WEATHER          — storm, fog, thermals (affect ship handling)
#    ANOMALY          — unexplained phenomenon (lore, mystery)
#    MERCHANT         — wandering trader ship
#    SILENCE          — nothing. just sky. intentional.
# ═══════════════════════════════════════════════════════════════════

signal event_triggered(event: Dictionary)
signal event_cleared()

enum EventType {
	DEBRIS_FIELD,
	EMPIRE_PATROL,
	PIRATE_SIGNAL,
	WEATHER,
	ANOMALY,
	MERCHANT,
	SILENCE,      # a rest — the open sky is just the open sky
}

# [zone 0..3] → Array of {type, weight} — higher weight = more likely
const EVENT_TABLES: Array = [
	# Zone 0 — outer, early, gentle
	[
		{"type": EventType.DEBRIS_FIELD,  "weight": 20},
		{"type": EventType.PIRATE_SIGNAL, "weight": 10},
		{"type": EventType.WEATHER,       "weight": 15},
		{"type": EventType.MERCHANT,      "weight": 15},
		{"type": EventType.ANOMALY,       "weight": 10},
		{"type": EventType.SILENCE,       "weight": 30},   # most common — open sky
	],
	# Zone 1
	[
		{"type": EventType.DEBRIS_FIELD,  "weight": 20},
		{"type": EventType.EMPIRE_PATROL, "weight": 15},
		{"type": EventType.PIRATE_SIGNAL, "weight": 15},
		{"type": EventType.WEATHER,       "weight": 15},
		{"type": EventType.MERCHANT,      "weight": 10},
		{"type": EventType.ANOMALY,       "weight": 10},
		{"type": EventType.SILENCE,       "weight": 15},
	],
	# Zone 2
	[
		{"type": EventType.EMPIRE_PATROL, "weight": 30},
		{"type": EventType.DEBRIS_FIELD,  "weight": 15},
		{"type": EventType.PIRATE_SIGNAL, "weight": 10},
		{"type": EventType.WEATHER,       "weight": 20},
		{"type": EventType.ANOMALY,       "weight": 15},
		{"type": EventType.MERCHANT,      "weight": 5},
		{"type": EventType.SILENCE,       "weight": 5},
	],
	# Zone 3 — centre, empire heart, dangerous
	[
		{"type": EventType.EMPIRE_PATROL, "weight": 45},
		{"type": EventType.WEATHER,       "weight": 20},
		{"type": EventType.ANOMALY,       "weight": 20},
		{"type": EventType.DEBRIS_FIELD,  "weight": 10},
		{"type": EventType.SILENCE,       "weight": 5},
	],
]

# Base probability that ANY event fires when entering an empty cell
const EVENT_CHANCE: Array = [0.35, 0.50, 0.65, 0.80]

var _rng          := RandomNumberGenerator.new()
var _active_event: Dictionary = {}
var _cells_this_session: Array = []   # cells visited this session (no repeat events)


# ── Called when player enters an empty cell ───────────────────────
func on_enter_empty_cell(cell: WorldGrid.Cell) -> void:
	var cell_key := cell.grid_pos

	# Each cell fires at most one event per session
	if cell_key in _cells_this_session:
		return
	_cells_this_session.append(cell_key)

	var zone   := cell.zone
	var chance := EVENT_CHANCE[clampi(zone, 0, 3)]

	_rng.seed = int(Time.get_unix_time_from_system()) ^ (cell.grid_pos.x * 999983 + cell.grid_pos.y)
	if _rng.randf() > chance:
		# No event this crossing — open sky, peace
		return

	var event_type := _roll_event(zone)
	_fire_event(event_type, cell)


func _roll_event(zone: int) -> EventType:
	var table: Array = EVENT_TABLES[clampi(zone, 0, 3)]
	var total_weight := 0
	for entry in table:
		total_weight += entry["weight"]

	var roll := _rng.randi_range(0, total_weight - 1)
	var acc  := 0
	for entry in table:
		acc += entry["weight"]
		if roll < acc:
			return entry["type"]

	return EventType.SILENCE


func _fire_event(type: EventType, cell: WorldGrid.Cell) -> void:
	_active_event = {
		"type":     type,
		"zone":     cell.zone,
		"cell":     cell.grid_pos,
		"resolved": false,
	}

	match type:
		EventType.SILENCE:
			# No notification — the sky is just the sky
			_active_event = {}
			return
		EventType.DEBRIS_FIELD:
			_active_event["label"]       = "Debris Field"
			_active_event["description"] = "Wreckage drifts past — something didn't survive the crossing."
		EventType.EMPIRE_PATROL:
			_active_event["label"]       = "Empire Patrol"
			_active_event["description"] = "An empire ship on a heading. They may not have seen you yet."
		EventType.PIRATE_SIGNAL:
			_active_event["label"]       = "Signal"
			_active_event["description"] = "A light in the distance. Hard to tell if it's a call for help or a lure."
		EventType.WEATHER:
			_active_event["label"]       = "Weather"
			_active_event["description"] = "The sky changes. The ship feels it before you do."
		EventType.ANOMALY:
			_active_event["label"]       = "Anomaly"
			_active_event["description"] = "Something in the sky that has no name. It does not appear on any chart."
		EventType.MERCHANT:
			_active_event["label"]       = "Merchant"
			_active_event["description"] = "A trade ship running quiet. Flags neutral. They're open for business."

	event_triggered.emit(_active_event)


func resolve_event() -> void:
	if _active_event.is_empty():
		return
	_active_event["resolved"] = true
	_active_event = {}
	event_cleared.emit()


func has_active_event() -> bool:
	return not _active_event.is_empty()
