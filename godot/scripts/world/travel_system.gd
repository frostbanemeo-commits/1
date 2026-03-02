extends Node
class_name TravelSystem

# ═══════════════════════════════════════════════════════════════════
#  Travel System
#
#  Three travel abilities — unlocked in sequence:
#
#  TIER 1 — SHIP TRAVEL (always available)
#    The ship physically sails through the world.
#    Required for all UNDISCOVERED cells. No exceptions.
#    Entering a new cell charts it.
#
#  TIER 2 — FLY MODE  (unlocked by story beat)
#    Cinder projects herself to any CHARTED island instantly.
#    She learned to move through space — herself, not the ship.
#    Fragile cargo is destroyed if she teleports with it.
#    Locked until unlock_fly_mode() is called.
#
#  TIER 3 — SHIP SUMMON  (unlocked after fly mode)
#    Cinder whistles. The ship comes to her.
#    The harder skill — projecting something else through space.
#    Only available after fly mode is unlocked.
#    Locked until unlock_ship_summon() is called.
#
#  Unlock order enforced:
#    ship summon requires fly mode — you cannot summon before you fly.
# ═══════════════════════════════════════════════════════════════════

signal fly_mode_unlocked()
signal ship_summon_unlocked()
signal fast_travel_started(destination: WorldGrid.Cell)
signal fast_travel_arrived(destination: WorldGrid.Cell)
signal fast_travel_fragile_warning(fragile_items: Array, destination: WorldGrid.Cell)
signal ship_summoned(to_position: Vector3)
signal cell_discovered(cell: WorldGrid.Cell)

@export var player:     Node3D
@export var ship:       Node3D
@export var world_grid: WorldGrid
@export var cargo_hold: CargoHold

# Unlock state
var _fly_mode_unlocked:    bool = false
var _ship_summon_unlocked: bool = false
var _story_complete:       bool = false


# ── Unlock progression ────────────────────────────────────────────
func unlock_fly_mode() -> void:
	if _fly_mode_unlocked:
		return
	_fly_mode_unlocked = true
	fly_mode_unlocked.emit()


func unlock_ship_summon() -> void:
	if not _fly_mode_unlocked:
		push_warning("TravelSystem: ship summon requires fly mode to be unlocked first.")
		return
	if _ship_summon_unlocked:
		return
	_ship_summon_unlocked = true
	ship_summon_unlocked.emit()


func has_fly_mode() -> bool:
	return _fly_mode_unlocked


func has_ship_summon() -> bool:
	return _ship_summon_unlocked


# ── Tier 2 — Fly mode (fast travel) ──────────────────────────────
func can_fast_travel(cell: WorldGrid.Cell) -> bool:
	if not _fly_mode_unlocked:
		return false
	if not cell:
		return false
	if cell.type == WorldGrid.CellType.EMPTY:
		return false
	if not cell.can_fast_travel():
		return false   # UNDISCOVERED — ship required regardless
	return true


func fragile_cargo_at_risk() -> Array:
	if not cargo_hold:
		return []
	return cargo_hold.fragile_items()


func fast_travel_to(cell: WorldGrid.Cell, shatter_fragile: bool = false) -> void:
	if not can_fast_travel(cell):
		push_warning("TravelSystem: fly mode not unlocked or cell invalid.")
		return

	if cargo_hold and cargo_hold.has_fragile_cargo():
		if not shatter_fragile:
			fast_travel_fragile_warning.emit(cargo_hold.fragile_items(), cell)
			return
		cargo_hold.shatter_fragile()

	fast_travel_started.emit(cell)

	var dest := cell.island_origin() + Vector3(
		WorldGrid.ISLAND_SIZE * 0.5,
		8.0,
		WorldGrid.ISLAND_SIZE * 0.5
	)
	player.global_position = dest

	# Ship stays where it was — player flew, not the ship.
	# Player must summon the ship separately if they need it.

	fast_travel_arrived.emit(cell)


# ── Tier 3 — Ship summon ──────────────────────────────────────────
func can_summon_ship() -> bool:
	return _ship_summon_unlocked and ship != null


func summon_ship() -> void:
	if not can_summon_ship():
		if not _fly_mode_unlocked:
			push_warning("TravelSystem: fly mode not yet unlocked.")
		elif not _ship_summon_unlocked:
			push_warning("TravelSystem: ship summon not yet unlocked.")
		return

	var arrive_at := _ship_summon_position()
	ship.global_position = arrive_at
	ship_summoned.emit(arrive_at)


func _ship_summon_position() -> Vector3:
	if not player:
		return Vector3.ZERO
	var forward := -player.global_transform.basis.z
	return player.global_position - forward * 12.0 + Vector3(6.0, 0.0, 0.0)


# ── Tier 1 — Discovery (always active) ───────────────────────────
func on_ship_entered_cell(cell: WorldGrid.Cell) -> void:
	if not cell:
		return
	if cell.discovery == WorldGrid.DiscoveryState.UNDISCOVERED:
		world_grid.discover(cell.grid_pos.x, cell.grid_pos.y)
		cell_discovered.emit(cell)


func on_player_explored_island(cell: WorldGrid.Cell) -> void:
	if not cell:
		return
	world_grid.explore(cell.grid_pos.x, cell.grid_pos.y)


# ── Story completion ──────────────────────────────────────────────
func complete_main_story() -> void:
	_story_complete = true


func is_story_complete() -> bool:
	return _story_complete


# ── World map data for UI ─────────────────────────────────────────
func get_charted_cells() -> Array:
	return world_grid.charted_cells()


func get_story_cells() -> Array:
	return world_grid.story_cells()
