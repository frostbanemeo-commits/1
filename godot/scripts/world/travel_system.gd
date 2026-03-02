extends Node
class_name TravelSystem

# ═══════════════════════════════════════════════════════════════════
#  Travel System
#
#  Two travel modes — with a hard gate between them:
#
#  SHIP TRAVEL (discovery)
#    The ship physically moves through the world.
#    Required for all UNDISCOVERED cells.
#    Entering a new cell charts it — unlocks fast travel to it.
#    No shortcuts. You must go there first.
#
#  FAST TRAVEL (revisit)
#    Instant teleport to any CHARTED or EXPLORED island.
#    Only unlocks after physical discovery.
#    Not available during the main story until story is complete.
#    [Post-story: full fast travel freedom.]
#
#  SHIP SUMMON (whistle)
#    Call the ship to Cinder's current position.
#    Works anywhere — on an island or in open sky.
#    Ship arrives instantly (teleport, not travel).
#    The ship is never lost — it always comes when called.
# ═══════════════════════════════════════════════════════════════════

signal fast_travel_started(destination: WorldGrid.Cell)
signal fast_travel_arrived(destination: WorldGrid.Cell)
signal ship_summoned(to_position: Vector3)
signal cell_discovered(cell: WorldGrid.Cell)

@export var player:     Node3D
@export var ship:       Node3D   ## The skyship node
@export var world_grid: WorldGrid

var _story_complete: bool = false


# ── Fast travel ───────────────────────────────────────────────────
func can_fast_travel(cell: WorldGrid.Cell) -> bool:
	if not cell:
		return false
	if cell.type == WorldGrid.CellType.EMPTY:
		return false   # can't fast travel to open sky
	if not cell.can_fast_travel():
		return false   # UNDISCOVERED — ship required
	return true


func fast_travel_to(cell: WorldGrid.Cell) -> void:
	if not can_fast_travel(cell):
		push_warning("TravelSystem: fast travel blocked — cell undiscovered or invalid.")
		return

	fast_travel_started.emit(cell)

	# Teleport player to island landing point
	var dest := cell.island_origin() + Vector3(
		WorldGrid.ISLAND_SIZE * 0.5,
		8.0,   # drop in slightly above surface
		WorldGrid.ISLAND_SIZE * 0.5
	)
	player.global_position = dest

	# Teleport ship nearby — docked beside the island
	if ship:
		ship.global_position = cell.world_centre() + Vector3(
			WorldGrid.ISLAND_SIZE * 0.5 + 10.0,
			0.0,
			0.0
		)

	fast_travel_arrived.emit(cell)


# ── Ship summon ───────────────────────────────────────────────────
# The ship always comes. No conditions. Whistle = ship.
func summon_ship() -> void:
	if not ship:
		return
	var arrive_at := _ship_summon_position()
	ship.global_position = arrive_at
	ship_summoned.emit(arrive_at)


func _ship_summon_position() -> Vector3:
	if not player:
		return Vector3.ZERO
	# Arrive beside and slightly behind the player
	var p       := player.global_position
	var forward := -player.global_transform.basis.z
	return p - forward * 12.0 + Vector3(6.0, 0.0, 0.0)


# ── Discovery gate ────────────────────────────────────────────────
# Called when the ship physically enters a new cell.
func on_ship_entered_cell(cell: WorldGrid.Cell) -> void:
	if not cell:
		return
	if cell.discovery == WorldGrid.DiscoveryState.UNDISCOVERED:
		var gp := cell.grid_pos
		world_grid.discover(gp.x, gp.y)
		cell_discovered.emit(cell)


# Called when Cinder lands and walks an island.
func on_player_explored_island(cell: WorldGrid.Cell) -> void:
	if not cell:
		return
	var gp := cell.grid_pos
	world_grid.explore(gp.x, gp.y)


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
