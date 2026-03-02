extends Node
class_name SaveSystem

# ═══════════════════════════════════════════════════════════════════
#  Save System
#  3 save slots. JSON files in user://saves/.
#  Auto-save triggers on island landing and story beats.
# ═══════════════════════════════════════════════════════════════════

signal saved(slot: int)
signal loaded(slot: int, data: SaveData)
signal save_failed(slot: int, reason: String)

const SAVE_DIR  := "user://saves/"
const SLOTS     := 3

# In-memory slot metadata (timestamps, play times) for the main menu
var _slot_meta: Array = []   # Array of {slot, exists, timestamp, play_time, character}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_refresh_slot_meta()


# ── Save ──────────────────────────────────────────────────────────
func save(slot: int, data: SaveData) -> void:
	if slot < 0 or slot >= SLOTS:
		save_failed.emit(slot, "Invalid slot.")
		return

	data.slot           = slot
	data.save_timestamp = Time.get_datetime_string_from_system()
	var path            := _slot_path(slot)
	var json            := JSON.stringify(data.to_dict(), "\t")
	var file            := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		save_failed.emit(slot, "Could not open file for writing.")
		return

	file.store_string(json)
	file.close()
	_refresh_slot_meta()
	saved.emit(slot)


# ── Load ──────────────────────────────────────────────────────────
func load_slot(slot: int) -> SaveData:
	if slot < 0 or slot >= SLOTS:
		return null

	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var json_text := file.get_as_text()
	file.close()

	var parsed := JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	var data := SaveData.from_dict(parsed)
	loaded.emit(slot, data)
	return data


# ── Delete ────────────────────────────────────────────────────────
func delete_slot(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_refresh_slot_meta()


# ── Slot metadata for main menu display ───────────────────────────
func slot_meta() -> Array:
	return _slot_meta


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func _refresh_slot_meta() -> void:
	_slot_meta = []
	for i in SLOTS:
		var meta := {"slot": i, "exists": false, "timestamp": "", "play_time": 0.0, "character": {}}
		if slot_exists(i):
			var data := load_slot(i)
			if data:
				meta["exists"]     = true
				meta["timestamp"]  = data.save_timestamp
				meta["play_time"]  = data.play_time
				meta["character"]  = data.character
		_slot_meta.append(meta)


# ── Auto-save ─────────────────────────────────────────────────────
func auto_save(slot: int, data: SaveData) -> void:
	save(slot, data)   # same as manual — no distinction in file format


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot
