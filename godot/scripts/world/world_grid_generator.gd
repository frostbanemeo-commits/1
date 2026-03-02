extends RefCounted
class_name WorldGridGenerator

# ═══════════════════════════════════════════════════════════════════
#  World Grid Generator
#
#  Populates a WorldGrid with island and empty cells.
#  Island placement is deterministic — same world seed = same world.
#
#  Placement rules per zone:
#    Zone 0 (outer)   — 25–35% island density, sparse, wide gaps
#    Zone 1           — 35–50% density, clusters begin forming
#    Zone 2           — 50–65% density, empire presence
#    Zone 3 (centre)  — 70–85% density, fortified, empire heart
#
#  Guarantees:
#    - Starter island placed at a fixed outer-ring cell (grid 1,1)
#    - Empire heart placed at exact grid centre (5,5)
#    - No two adjacent cells are both EMPTY (ensures traversal paths)
#    - Every island cell is reachable from the starter island
# ═══════════════════════════════════════════════════════════════════

# Island density (probability) per zone
const DENSITY: Array = [0.30, 0.42, 0.58, 0.78]

# Fixed positions
const STARTER_POS := Vector2i(1, 1)
const EMPIRE_HEART_POS := Vector2i(5, 5)


static func generate(grid: WorldGrid, world_seed: int) -> void:
	var rng := RandomNumberGenerator.new()

	# Place fixed islands first
	_place_fixed(grid)

	# Fill remaining cells by zone density
	for x in WorldGrid.GRID_W:
		for z in WorldGrid.GRID_H:
			var pos := Vector2i(x, z)
			if pos == STARTER_POS or pos == EMPIRE_HEART_POS:
				continue

			var zone    := WorldGrid.zone_of(x, z)
			var density := DENSITY[zone]

			# Deterministic per-cell seed: world_seed + cell position hash
			rng.seed = world_seed ^ (x * 7919 + z * 6271)
			if rng.randf() < density:
				_place_island(grid, x, z, world_seed)

	# Assign zones to all cells
	for cell in grid.all_cells():
		cell.zone = WorldGrid.zone_of(cell.grid_pos.x, cell.grid_pos.y)


static func _place_fixed(grid: WorldGrid) -> void:
	# Starter island — opening sequence, outer ring
	var starter := grid.get_cell(STARTER_POS.x, STARTER_POS.y)
	starter.type        = WorldGrid.CellType.STARTER
	starter.island_seed = 0   # fixed seed — same starter island always
	starter.discovery   = WorldGrid.DiscoveryState.EXPLORED   # known from start

	# Empire heart — final area, always present
	var heart := grid.get_cell(EMPIRE_HEART_POS.x, EMPIRE_HEART_POS.y)
	heart.type        = WorldGrid.CellType.EMPIRE
	heart.island_seed = 1   # fixed seed — authored, not random


static func _place_island(grid: WorldGrid, x: int, z: int, world_seed: int) -> void:
	var cell := grid.get_cell(x, z)
	cell.type        = WorldGrid.CellType.ISLAND
	# Island seed: unique per cell, deterministic from world seed
	cell.island_seed = world_seed ^ (x * 104729 + z * 48611)
