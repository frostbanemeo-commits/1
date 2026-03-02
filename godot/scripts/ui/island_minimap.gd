extends Control
class_name IslandMinimap

# ═══════════════════════════════════════════════════════════════════
#  Island Minimap
#
#  32 × 32 pixel display. Top-right corner. Always on.
#  Each pixel = 2 metres of island space (64 m island / 32 px).
#
#  Built from the island's material grid at load time — a top-down
#  view of the topmost solid voxel in each 2 m column.
#  Colours are the resolved material colours (not primal).
#
#  Cinder's position overlaid as a 1×1 white dot, updated every frame.
#  Void (no solid voxel in column) = transparent / black.
#
#  Does NOT update on individual voxel destruction — at 2 m/px
#  resolution, single-voxel changes are invisible. A significant
#  collapse (many metres) would shift the topmost voxel sample.
# ═══════════════════════════════════════════════════════════════════

const MAP_PX      := 32       # minimap pixel dimensions
const ISLAND_M    := 64.0     # island width in metres
const M_PER_PIXEL := ISLAND_M / MAP_PX   # 2.0 m per pixel

const VOID_COLOUR   := Color(0.0,  0.0,  0.0,  0.85)   # unmapped columns
const PLAYER_COLOUR := Color(1.0,  1.0,  1.0,  1.0)    # Cinder dot
const BORDER_COLOUR := Color(0.15, 0.05, 0.30, 0.9)    # subtle purple border

@export var player: Node3D   ## Assign Cinder's CharacterBody3D

var _map_image:   Image
var _map_texture: ImageTexture
var _player_vp:   Vector2i = Vector2i(-1, -1)   # last player pixel

@onready var _map_rect:    TextureRect = $MapRect
@onready var _border_rect: Panel       = $BorderRect


func _ready() -> void:
	# Fixed 32×32 — anchored top-right in the parent Control
	custom_minimum_size = Vector2(MAP_PX, MAP_PX)
	_map_image = Image.create(MAP_PX, MAP_PX, false, Image.FORMAT_RGBA8)
	_map_image.fill(VOID_COLOUR)
	_map_texture = ImageTexture.create_from_image(_map_image)
	_map_rect.texture = _map_texture


# ── Call once after the island is generated ───────────────────────
# solid_grid:  [x][yi][z] → bool  (from IslandGenerator.generate())
# mat_grid:    [x][yi][z] → VoxelMaterialRegistry.Type
# y_min:       the Y_MIN constant used during generation (-48)
func build_from_island(solid_grid: Array, mat_grid: Array, y_min: int) -> void:
	_map_image.fill(VOID_COLOUR)

	for px in MAP_PX:
		for pz in MAP_PX:
			# Each minimap pixel samples a 2 m × 2 m column
			# Take the centre of that cell in voxel space
			var vx := int(px * M_PER_PIXEL + M_PER_PIXEL * 0.5)
			var vz := int(pz * M_PER_PIXEL + M_PER_PIXEL * 0.5)
			vx = clampi(vx, 0, solid_grid.size() - 1)

			# Find topmost solid voxel in this column
			var top_colour := VOID_COLOUR
			var col: Array = solid_grid[vx]
			vz = clampi(vz, 0, col[0].size() - 1)
			for yi in range(col.size() - 1, -1, -1):
				if col[yi][vz]:
					var mat_type: int = mat_grid[vx][yi][vz]
					top_colour = VoxelMaterialRegistry.get_color(mat_type)
					top_colour.a = 1.0
					break

			_map_image.set_pixel(px, pz, top_colour)

	_map_texture.update(_map_image)


# ── Per-frame player dot ──────────────────────────────────────────
func _process(_delta: float) -> void:
	if not player:
		return

	# Erase old dot
	if _player_vp.x >= 0:
		_restore_pixel(_player_vp)

	# New dot position
	var world_x := player.global_position.x
	var world_z := player.global_position.z
	var px := clampi(int(world_x / M_PER_PIXEL), 0, MAP_PX - 1)
	var pz := clampi(int(world_z / M_PER_PIXEL), 0, MAP_PX - 1)
	_player_vp = Vector2i(px, pz)

	_map_image.set_pixel(px, pz, PLAYER_COLOUR)
	_map_texture.update(_map_image)


# ── Restore a pixel to its baked terrain colour ───────────────────
# Stored separately so the player dot can be erased cleanly.
var _baked: Image   # copy of the terrain-only image, no player dot

func _restore_pixel(vp: Vector2i) -> void:
	if _baked:
		_map_image.set_pixel(vp.x, vp.y, _baked.get_pixel(vp.x, vp.y))


func _bake_terrain_snapshot() -> void:
	_baked = _map_image.duplicate()


# ── Called after build_from_island completes ──────────────────────
func finalise() -> void:
	_bake_terrain_snapshot()
	_map_texture.update(_map_image)
