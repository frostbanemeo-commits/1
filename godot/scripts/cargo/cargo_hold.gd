extends Node
class_name CargoHold

# ═══════════════════════════════════════════════════════════════════
#  Cargo Hold
#
#  The ship's cargo inventory.
#  Attach to the skyship node.
#
#  Fast travel check:
#    Before any teleport, query has_fragile_cargo().
#    If true — warn the player, give them the choice.
#    If they proceed — call shatter_fragile() to destroy fragile items.
#    If they turn back — sail instead.
# ═══════════════════════════════════════════════════════════════════

signal cargo_added(item: CargoItem)
signal cargo_removed(item: CargoItem)
signal fragile_cargo_shattered(items: Array)   # fast travel consequence

const MAX_SLOTS := 20   # total cargo hold capacity

var _items: Array[CargoItem] = []


# ── Cargo management ──────────────────────────────────────────────
func add(item: CargoItem) -> bool:
	if _items.size() >= MAX_SLOTS:
		return false
	_items.append(item)
	cargo_added.emit(item)
	return true


func remove(item: CargoItem) -> void:
	_items.erase(item)
	cargo_removed.emit(item)


func remove_by_id(item_id: String) -> void:
	var found := get_by_id(item_id)
	if found:
		remove(found)


func get_by_id(item_id: String) -> CargoItem:
	for item in _items:
		if item.id == item_id:
			return item
	return null


func all_items() -> Array:
	return _items.duplicate()


func slots_used() -> int:
	return _items.size()


func slots_free() -> int:
	return MAX_SLOTS - _items.size()


# ── Fast travel gate ──────────────────────────────────────────────
func has_fragile_cargo() -> bool:
	for item in _items:
		if item.fragile and not item.is_destroyed():
			return true
	return false


func fragile_items() -> Array:
	return _items.filter(func(i): return i.fragile and not i.is_destroyed())


# Called when player confirms fast travel despite fragile cargo warning.
# Destroys all fragile items and emits the signal for UI/audio/log.
func shatter_fragile() -> void:
	var shattered := []
	for item in _items:
		if item.fragile and not item.is_destroyed():
			item.destroy()
			shattered.append(item)

	# Remove destroyed items from hold
	for item in shattered:
		_items.erase(item)

	if shattered.size() > 0:
		fragile_cargo_shattered.emit(shattered)


# ── Mission cargo helpers ─────────────────────────────────────────
func has_mission_cargo(mission_id: String) -> bool:
	for item in _items:
		if item.mission_id == mission_id:
			return true
	return false


func get_mission_cargo(mission_id: String) -> Array:
	return _items.filter(func(i): return i.mission_id == mission_id)
