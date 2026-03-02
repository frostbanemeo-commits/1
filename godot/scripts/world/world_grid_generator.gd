extends RefCounted
class_name WorldGridGenerator

# ═══════════════════════════════════════════════════════════════════
#  World Grid Generator
#
#  Places islands and story waypoints on the WorldGrid.
#  Everything is deterministic — same world_seed = same world.
#
#  Layout:
#    (5,5) — STARTER cell, world position near (0,0,0)
#             Pirate ship. Character creation. Journey origin.
#
#    Story waypoints — fixed grid positions along a narrative path
#    that spirals loosely outward from the starter cell toward the
#    empire heart. Always visible on the guide marker.
#
#    Empire heart — far corner of the grid, always present.
#
#  Island density per zone (radiating outward from origin):
#    Zone 0 (near centre) — 30%   sparse, learning the world
#    Zone 1               — 42%
#    Zone 2               — 58%
#    Zone 3 (far edge)    — 75%   empire clusters, late game
# ═══════════════════════════════════════════════════════════════════

# Island fill density per zone
const DENSITY: Array = [0.30, 0.42, 0.58, 0.75]

# Fixed cell positions (grid coordinates)
const STARTER_POS     := Vector2i(5, 5)   # near world (0,0,0)
const EMPIRE_HEART_POS := Vector2i(1, 1)  # far corner — the long journey

# Story waypoints in order — the main narrative path
# Fixed grid positions, authored, deterministic
const STORY_WAYPOINTS: Array = [
	{"grid": Vector2i(5, 6), "index": 0},   # first island after escape
	{"grid": Vector2i(6, 6), "index": 1},   # pirates' base
	{"grid": Vector2i(6, 4), "index": 2},   # first empire contact
	{"grid": Vector2i(7, 3), "index": 3},   # Baron's territory begins
	{"grid": Vector2i(8, 2), "index": 4},   # mid-game turn
	{"grid": Vector2i(6, 1), "index": 5},   # deep empire
	{"grid": Vector2i(3, 1), "index": 6},   # approach
	{"grid": Vector2i(1, 1), "index": 7},   # empire heart — final
]


static func generate(grid: WorldGrid, world_seed: int) -> void:
	_place_starter(grid)
	_place_story_waypoints(grid, world_seed)
	_place_empire_heart(grid)
	_fill_random_islands(grid, world_seed)
	_assign_zones(grid)


static func _place_starter(grid: WorldGrid) -> void:
	var cell         := grid.get_cell(STARTER_POS.x, STARTER_POS.y)
	cell.type        = WorldGrid.CellType.STARTER
	cell.island_seed = 0
	cell.discovery   = WorldGrid.DiscoveryState.EXPLORED   # known from start


static func _place_story_waypoints(grid: WorldGrid, world_seed: int) -> void:
	for wp in STORY_WAYPOINTS:
		var gp: Vector2i = wp["grid"]
		if gp == STARTER_POS:
			continue
		var cell         := grid.get_cell(gp.x, gp.y)
		cell.type        = WorldGrid.CellType.STORY
		cell.story_index = wp["index"]
		cell.island_seed = world_seed ^ (gp.x * 48611 + gp.y * 104729 + wp["index"])


static func _place_empire_heart(grid: WorldGrid) -> void:
	var cell         := grid.get_cell(EMPIRE_HEART_POS.x, EMPIRE_HEART_POS.y)
	cell.type        = WorldGrid.CellType.EMPIRE_HEART
	cell.island_seed = 1   # authored, fixed


static func _fill_random_islands(grid: WorldGrid, world_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	var reserved := _reserved_positions()

	for x in WorldGrid.GRID_W:
		for z in WorldGrid.GRID_H:
			if Vector2i(x, z) in reserved:
				continue

			var zone    := WorldGrid.zone_of(x, z)
			var density := DENSITY[clampi(zone, 0, 3)]

			rng.seed = world_seed ^ (x * 7919 + z * 6271)
			if rng.randf() < density:
				var cell         := grid.get_cell(x, z)
				cell.type        = WorldGrid.CellType.ISLAND
				cell.island_seed = world_seed ^ (x * 999983 + z * 998244353)


static func _assign_zones(grid: WorldGrid) -> void:
	for cell in grid.all_cells():
		cell.zone = WorldGrid.zone_of(cell.grid_pos.x, cell.grid_pos.y)


static func _reserved_positions() -> Array:
	var positions := [STARTER_POS, EMPIRE_HEART_POS]
	for wp in STORY_WAYPOINTS:
		positions.append(wp["grid"])
	return positions
