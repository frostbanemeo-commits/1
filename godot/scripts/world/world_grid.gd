extends RefCounted
class_name WorldGrid

# ═══════════════════════════════════════════════════════════════════
#  World Grid
#
#  The sky world is a 10×10 grid of cells.
#  Each cell is 1000 m × 1000 m of open sky.
#  A cell either contains an island (64 m × 64 m, centred)
#  or is empty — open sky, traversable, event-eligible.
#
#  Reference: Legend of Zelda — Wind Waker ocean grid.
#  Fog of war: cells are UNDISCOVERED until the player enters them.
#  Travel between cells takes real time — intentional pacing.
#
#  Zone rings (from outer edge inward):
#    Ring 0  outer edge   — sparse, early game, weak empire
#    Ring 1               — moderate density, first patrols
#    Ring 2               — dense, empire blockades, mid game
#    Ring 3  centre 2×2   — empire heart, late game, final area
# ═══════════════════════════════════════════════════════════════════

const GRID_W      := 10       # cells across X
const GRID_H      := 10       # cells across Z
const CELL_SIZE   := 1000.0   # metres per cell edge
const ISLAND_SIZE :=   64.0   # metres — island occupies centre of cell

enum CellType {
	EMPTY   = 0,   # open sky — traversable, event-eligible
	ISLAND  = 1,   # contains a procedural island
	STARTER = 2,   # the opening island — fixed position
	EMPIRE  = 3,   # empire-controlled island — structured, not random
}

enum DiscoveryState {
	UNDISCOVERED = 0,   # blank on world map — player has not entered this cell
	CHARTED      = 1,   # player entered — island/empty visible on map
	EXPLORED     = 2,   # player landed and walked the island
}

# Per-cell data
class Cell:
	var grid_pos:   Vector2i
	var type:       CellType
	var discovery:  DiscoveryState
	var island_seed: int          # 0 if EMPTY — deterministic from world seed
	var zone:       int           # 0 = outer, 3 = centre

	func _init(gx: int, gz: int) -> void:
		grid_pos    = Vector2i(gx, gz)
		type        = CellType.EMPTY
		discovery   = DiscoveryState.UNDISCOVERED
		island_seed = 0
		zone        = 0

	func world_centre() -> Vector3:
		# World-space centre of this cell (Y = 0 baseline)
		return Vector3(
			(grid_pos.x + 0.5) * WorldGrid.CELL_SIZE,
			0.0,
			(grid_pos.y + 0.5) * WorldGrid.CELL_SIZE
		)

	func island_origin() -> Vector3:
		# Where the island's (0,0) corner sits in world space
		var c := world_centre()
		var half := WorldGrid.ISLAND_SIZE * 0.5
		return Vector3(c.x - half, 0.0, c.z - half)


# ── Grid storage ──────────────────────────────────────────────────
var _cells:      Array          # [x][z] → Cell
var _world_seed: int


func _init(world_seed: int) -> void:
	_world_seed = world_seed
	_cells = []
	_cells.resize(GRID_W)
	for x in GRID_W:
		_cells[x] = []
		_cells[x].resize(GRID_H)
		for z in GRID_H:
			_cells[x][z] = Cell.new(x, z)


# ── Accessors ─────────────────────────────────────────────────────
func get_cell(gx: int, gz: int) -> Cell:
	if gx < 0 or gx >= GRID_W or gz < 0 or gz >= GRID_H:
		return null
	return _cells[gx][gz]


func get_cell_at_world(world_pos: Vector3) -> Cell:
	var gx := int(world_pos.x / CELL_SIZE)
	var gz := int(world_pos.z / CELL_SIZE)
	return get_cell(gx, gz)


func discover(gx: int, gz: int) -> void:
	var cell := get_cell(gx, gz)
	if cell and cell.discovery == DiscoveryState.UNDISCOVERED:
		cell.discovery = DiscoveryState.CHARTED


func explore(gx: int, gz: int) -> void:
	var cell := get_cell(gx, gz)
	if cell:
		cell.discovery = DiscoveryState.EXPLORED


func all_cells() -> Array:
	var result := []
	for x in GRID_W:
		for z in GRID_H:
			result.append(_cells[x][z])
	return result


func island_cells() -> Array:
	return all_cells().filter(func(c): return c.type != CellType.EMPTY)


# ── Zone helper ───────────────────────────────────────────────────
# Zone = Chebyshev distance from the centre of the grid
static func zone_of(gx: int, gz: int) -> int:
	var cx := int(GRID_W / 2)
	var cz := int(GRID_H / 2)
	var dist := maxi(absi(gx - cx), absi(gz - cz))
	# Map distance to zone 0 (outer) → 3 (centre)
	if dist >= 4:   return 0
	if dist >= 3:   return 1
	if dist >= 2:   return 2
	return 3
