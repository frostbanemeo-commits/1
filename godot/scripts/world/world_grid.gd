extends RefCounted
class_name WorldGrid

# ═══════════════════════════════════════════════════════════════════
#  World Grid
#
#  10×10 grid of cells, each 1000 m × 1000 m.
#  CENTERED on world origin (0, 0, 0).
#  Grid runs from -5000 m to +5000 m on X and Z.
#
#  (0,0,0) is where the pirate ship sits during character creation.
#  It is the literal origin of Cinder's journey — the first moment
#  she chooses who she is. Everything radiates outward from here.
#
#  Zone rings radiate outward from (0,0):
#    Zone 0  — near origin,  early game, weak empire
#    Zone 1  — mid distance, moderate density, first patrols
#    Zone 2  — far,          dense, blockades, mid game
#    Zone 3  — outermost,    empire heart territory, late game
#
#  Discovery gate:
#    UNDISCOVERED cells cannot be fast-travelled to.
#    The ship is required to enter a new cell for the first time.
#    Fast travel and ship summon only work on CHARTED/EXPLORED cells.
# ═══════════════════════════════════════════════════════════════════

const GRID_W    := 10        # cells across X
const GRID_H    := 10        # cells across Z
const CELL_SIZE := 1000.0    # metres per cell edge
const HALF_W    := GRID_W * CELL_SIZE * 0.5   # 5000 m — half-extent
const HALF_H    := GRID_H * CELL_SIZE * 0.5

const ISLAND_SIZE := 64.0   # metres — centred within its cell

enum CellType {
	EMPTY         = 0,   # open sky — traversable, event-eligible
	ISLAND        = 1,   # procedural island
	STARTER       = 2,   # fixed — pirate ship origin, character creation
	STORY         = 3,   # fixed story waypoint — always guide-marked
	EMPIRE_HEART  = 4,   # final area — the Emperor's seat
}

enum DiscoveryState {
	UNDISCOVERED = 0,   # blank on map — ship has not entered this cell
	CHARTED      = 1,   # ship entered — visible on map, fast travel unlocked
	EXPLORED     = 2,   # player landed and walked the island
}

class Cell:
	var grid_pos:    Vector2i
	var type:        CellType
	var discovery:   DiscoveryState
	var island_seed: int
	var zone:        int        # 0 = near origin (easy), 3 = far (hard)
	var story_index: int = -1   # if STORY type: which story beat (-1 = none)

	func _init(gx: int, gz: int) -> void:
		grid_pos    = Vector2i(gx, gz)
		type        = CellType.EMPTY
		discovery   = DiscoveryState.UNDISCOVERED
		island_seed = 0
		zone        = 0

	# World-space centre of this cell
	# Grid (0,0) → world (-4500, 0, -4500)  (bottom-left corner)
	# Grid (5,5) → world (  500, 0,   500)  (near origin)
	func world_centre() -> Vector3:
		return Vector3(
			(grid_pos.x - WorldGrid.GRID_W * 0.5 + 0.5) * WorldGrid.CELL_SIZE,
			0.0,
			(grid_pos.y - WorldGrid.GRID_H * 0.5 + 0.5) * WorldGrid.CELL_SIZE
		)

	func island_origin() -> Vector3:
		var c    := world_centre()
		var half := WorldGrid.ISLAND_SIZE * 0.5
		return Vector3(c.x - half, 0.0, c.z - half)

	func can_fast_travel() -> bool:
		return discovery != DiscoveryState.UNDISCOVERED

	func requires_ship() -> bool:
		return discovery == DiscoveryState.UNDISCOVERED


# ── Grid storage ──────────────────────────────────────────────────
var _cells:      Array
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


# Convert world position to grid cell
func get_cell_at_world(world_pos: Vector3) -> Cell:
	var gx := int((world_pos.x + HALF_W) / CELL_SIZE)
	var gz := int((world_pos.z + HALF_H) / CELL_SIZE)
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


func charted_cells() -> Array:
	return all_cells().filter(func(c): return c.can_fast_travel())


func story_cells() -> Array:
	return all_cells().filter(func(c): return c.type == CellType.STORY)


# Zone = Chebyshev distance from grid centre (5,5)
# Capped to 0–3 to match density table indices
static func zone_of(gx: int, gz: int) -> int:
	var cx   := GRID_W / 2
	var cz   := GRID_H / 2
	var dist := maxi(absi(gx - cx), absi(gz - cz))
	return clampi(dist - 1, 0, 3)   # centre cells = zone 0
