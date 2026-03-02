extends RefCounted
class_name IslandGenerator

# ═══════════════════════════════════════════════════════════════════
#  Island Generator
#  Produces the voxel fill map for a single floating island.
#
#  Dimensions: 64 × 64 (X/Z),  Y from -48 to +64  (112 total)
#  Shape     : teardrop — wide in the upper third, tapers to a
#              single point at the base tip.
#
#  Output    : 3D Array[bool] — true = solid voxel
#              indexed as [x][y_offset][z] where y_offset = y + 48
# ═══════════════════════════════════════════════════════════════════

const SIZE_X  := 64
const SIZE_Z  := 64
const Y_MIN   := -48
const Y_MAX   :=  64
const Y_TOTAL := Y_MAX - Y_MIN          # 112

# Centre of the footprint
const CX := SIZE_X * 0.5
const CZ := SIZE_Z * 0.5

# ── Tunable shape parameters ──────────────────────────────────────
# Widest cross-section radius (in voxels) — sits at TOP_BAND_Y
const MAX_RADIUS        := 26.0
const TOP_BAND_Y        := 28.0    # y value of widest point
const TOP_TAPER_RATE    :=  0.06   # how fast radius shrinks going UP from widest
const BOTTOM_TAPER_EXP  :=  1.7   # power curve — higher = sharper bottom point

# Surface noise (top terrain)
const SURFACE_NOISE_AMP :=  8.0   # max height variation on surface
const SURFACE_NOISE_SCL :=  0.08  # frequency

# Underbelly pocket noise (caves and overhangs on the underside)
const BELLY_NOISE_AMP   :=  6.0
const BELLY_NOISE_SCL   :=  0.12

# ─────────────────────────────────────────────────────────────────

var _noise_surface := FastNoiseLite.new()
var _noise_belly   := FastNoiseLite.new()
var _seed: int


func _init(seed_value: int = 0) -> void:
	_seed = seed_value
	_noise_surface.seed           = seed_value
	_noise_surface.noise_type     = FastNoiseLite.TYPE_PERLIN
	_noise_surface.frequency      = SURFACE_NOISE_SCL
	_noise_belly.seed             = seed_value + 1337
	_noise_belly.noise_type       = FastNoiseLite.TYPE_PERLIN
	_noise_belly.frequency        = BELLY_NOISE_SCL


# ── Main generation entry ─────────────────────────────────────────
func generate() -> Array:
	# [x][y_offset][z] → bool (true = solid)
	var grid := []
	grid.resize(SIZE_X)
	for x in SIZE_X:
		grid[x] = []
		grid[x].resize(Y_TOTAL)
		for yi in Y_TOTAL:
			grid[x][yi] = []
			grid[x][yi].resize(SIZE_Z)
			grid[x][yi].fill(false)

	for x in SIZE_X:
		for z in SIZE_Z:
			var dx := float(x) - CX
			var dz := float(z) - CZ
			var h_dist := sqrt(dx * dx + dz * dz)   # horizontal distance from axis

			# Surface height at this (x,z) column
			var surface_n := _noise_surface.get_noise_2d(float(x), float(z))
			var surface_y := Y_MAX - 4.0 + surface_n * SURFACE_NOISE_AMP

			for y in range(Y_MIN, Y_MAX):
				var yi := y - Y_MIN   # array index
				if _is_solid(x, y, z, h_dist, surface_y):
					grid[x][yi][z] = true

	return grid


# ── Per-voxel SDF test ────────────────────────────────────────────
func _is_solid(x: int, y: int, z: int, h_dist: float, surface_y: float) -> bool:
	# Voxels above the noisy surface are always air
	if float(y) > surface_y:
		return false

	# Radius of the island cross-section at this y
	var allowed_r := _radius_at(float(y))

	# Apply underbelly pocket noise (carves cave-like overhangs on the bottom)
	if float(y) < 0.0:
		var belly_n := _noise_belly.get_noise_3d(float(x), float(y), float(z))
		allowed_r += belly_n * BELLY_NOISE_AMP

	return h_dist <= allowed_r


# ── Teardrop radius function ──────────────────────────────────────
# r(y):
#   y >= TOP_BAND_Y  → shrinks gently upward  (terrain top)
#   y <  TOP_BAND_Y  → shrinks on power curve toward tip at Y_MIN
func _radius_at(y: float) -> float:
	if y >= TOP_BAND_Y:
		# Above widest point — gentle taper upward
		var t := (y - TOP_BAND_Y) / float(Y_MAX - TOP_BAND_Y)
		return MAX_RADIUS * (1.0 - t * t * TOP_TAPER_RATE * (Y_MAX - TOP_BAND_Y))
	else:
		# Below widest point — power curve down to tip
		var t := (TOP_BAND_Y - y) / (TOP_BAND_Y - float(Y_MIN))  # 0 at widest, 1 at tip
		return MAX_RADIUS * (1.0 - pow(t, BOTTOM_TAPER_EXP))


# ── Material assignment pass ──────────────────────────────────────
# Returns a parallel grid of VoxelMaterialRegistry.Type values.
# Called after generate() — only fills cells that are solid.
func assign_materials(solid_grid: Array, rng: RandomNumberGenerator) -> Array:
	var mat_grid := []
	mat_grid.resize(SIZE_X)
	for x in SIZE_X:
		mat_grid[x] = []
		mat_grid[x].resize(Y_TOTAL)
		for yi in Y_TOTAL:
			mat_grid[x][yi] = []
			mat_grid[x][yi].resize(SIZE_Z)
			mat_grid[x][yi].fill(0)   # 0 = AIR

	for x in SIZE_X:
		for z in SIZE_Z:
			# Find topmost solid voxel in this column
			var top_yi := -1
			for yi in range(Y_TOTAL - 1, -1, -1):
				if solid_grid[x][yi][z]:
					top_yi = yi
					break
			if top_yi < 0:
				continue

			for yi in Y_TOTAL:
				if not solid_grid[x][yi][z]:
					continue
				var y := yi + Y_MIN
				var depth := top_yi - yi   # 0 = surface, higher = deeper

				mat_grid[x][yi][z] = _material_for(y, depth, rng)

	return mat_grid


func _material_for(y: int, depth: int, rng: RandomNumberGenerator) -> int:
	# Deep core — stone
	if depth > 12:
		var r := rng.randf()
		if r < 0.6:  return VoxelMaterialRegistry.Type.LIMESTONE
		if r < 0.85: return VoxelMaterialRegistry.Type.GRANITE
		return          VoxelMaterialRegistry.Type.MARBLE

	# Mid layer — mixed stone with occasional soil
	if depth > 4:
		var r := rng.randf()
		if r < 0.5:  return VoxelMaterialRegistry.Type.LIMESTONE
		if r < 0.75: return VoxelMaterialRegistry.Type.SOIL
		return          VoxelMaterialRegistry.Type.SANDSTONE

	# Surface (depth 0–4) — soil / grass
	if depth == 0:
		return VoxelMaterialRegistry.Type.GRASS
	return VoxelMaterialRegistry.Type.SOIL
