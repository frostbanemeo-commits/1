extends RefCounted
class_name IslandGenerator

# ═══════════════════════════════════════════════════════════════════
#  Island Generator
#
#  PHILOSOPHY:
#    The world is defined in metres at real scale.
#    Voxels are the pixelation — a rendering resolution choice.
#    Change voxel_size to change detail level; the island stays 64 m wide.
#
#  Island dimensions (metres, real scale):
#    Width      : 64 m × 64 m
#    Height     : -48 m (bottom tip) → +64 m (peak)  =  112 m total
#    Widest band:  +28 m elevation,  radius 26 m
#
#  Default voxel sizes:
#    0.1 m  — gameplay / destruction tier  (10 cm cubes)
#    0.001 m — visual / colour tier        (1 mm, surface detail only)
# ═══════════════════════════════════════════════════════════════════

# ── Island definition — metres, real scale ────────────────────────
const ISLAND_W  := 64.0    # metres
const ISLAND_D  := 64.0    # metres
const Y_BOTTOM  := -48.0   # metres  (tip)
const Y_TOP     :=  64.0   # metres  (peak surface)

# Shape
const MAX_RADIUS       := 26.0   # metres, widest cross-section
const WIDE_BAND_Y      := 28.0   # metres, elevation of widest point
const TOP_TAPER_RATE   :=  0.06
const BOTTOM_TAPER_EXP :=  1.7   # higher = sharper tip

# Surface noise
const SURFACE_AMP := 8.0    # ± metres height variation on top
const SURFACE_FRQ := 0.08

# Underbelly noise
const BELLY_AMP   := 6.0    # ± metres carved from underside
const BELLY_FRQ   := 0.12

# ─────────────────────────────────────────────────────────────────

var _noise_surface := FastNoiseLite.new()
var _noise_belly   := FastNoiseLite.new()
var _seed:       int
var _voxel_size: float   # metres per voxel edge

# Derived grid dimensions (computed in _init)
var _gx: int   # voxels along X
var _gz: int   # voxels along Z
var _gy: int   # voxels along Y


func _init(seed_value: int = 0, voxel_size: float = 0.1) -> void:
	_seed       = seed_value
	_voxel_size = voxel_size

	# Grid size = real dimension / voxel size
	_gx = int(ISLAND_W  / _voxel_size)
	_gz = int(ISLAND_D  / _voxel_size)
	_gy = int((Y_TOP - Y_BOTTOM) / _voxel_size)

	_noise_surface.seed       = seed_value
	_noise_surface.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise_surface.frequency  = SURFACE_FRQ

	_noise_belly.seed         = seed_value + 1337
	_noise_belly.noise_type   = FastNoiseLite.TYPE_PERLIN
	_noise_belly.frequency    = BELLY_FRQ


# ── Main generation ───────────────────────────────────────────────
# Returns [x][yi][z] → bool  (true = solid)
# yi is the Y array index; real y = Y_BOTTOM + yi * voxel_size
func generate() -> Array:
	var grid := _empty_grid(false)
	var cx := _gx * 0.5
	var cz := _gz * 0.5

	for xi in _gx:
		for zi in _gz:
			var dx := float(xi) - cx
			var dz := float(zi) - cz
			var h_dist := sqrt(dx * dx + dz * dz) * _voxel_size  # convert to metres

			# World-space X/Z for noise sampling (metres)
			var wx := float(xi) * _voxel_size
			var wz := float(zi) * _voxel_size

			var surface_n := _noise_surface.get_noise_2d(wx, wz)
			var surface_y := Y_TOP - (4.0 * _voxel_size) + surface_n * SURFACE_AMP

			for yi in _gy:
				var wy := Y_BOTTOM + yi * _voxel_size   # real y in metres
				if _is_solid(wx, wy, wz, h_dist, surface_y):
					grid[xi][yi][zi] = true

	return grid


func _is_solid(wx: float, wy: float, wz: float, h_dist: float, surface_y: float) -> bool:
	if wy > surface_y:
		return false

	var allowed_r := _radius_at(wy)

	if wy < 0.0:
		var bn := _noise_belly.get_noise_3d(wx, wy, wz)
		allowed_r += bn * BELLY_AMP

	return h_dist <= allowed_r


# ── Teardrop radius at a given real y (metres) ────────────────────
func _radius_at(y: float) -> float:
	if y >= WIDE_BAND_Y:
		var t := (y - WIDE_BAND_Y) / (Y_TOP - WIDE_BAND_Y)
		return MAX_RADIUS * (1.0 - t * t * TOP_TAPER_RATE * (Y_TOP - WIDE_BAND_Y))
	else:
		var t := (WIDE_BAND_Y - y) / (WIDE_BAND_Y - Y_BOTTOM)
		return MAX_RADIUS * (1.0 - pow(t, BOTTOM_TAPER_EXP))


# ── Material assignment ───────────────────────────────────────────
func assign_materials(solid_grid: Array, rng: RandomNumberGenerator) -> Array:
	var mat_grid := _empty_grid(0)

	for xi in _gx:
		for zi in _gz:
			var top_yi := -1
			for yi in range(_gy - 1, -1, -1):
				if solid_grid[xi][yi][zi]:
					top_yi = yi
					break
			if top_yi < 0:
				continue

			for yi in _gy:
				if not solid_grid[xi][yi][zi]:
					continue
				var depth_m := float(top_yi - yi) * _voxel_size  # metres below surface
				mat_grid[xi][yi][zi] = _material_for(depth_m, rng)

	return mat_grid


func _material_for(depth_m: float, rng: RandomNumberGenerator) -> int:
	if depth_m > 12.0:   # solid stone core
		var r := rng.randf()
		if r < 0.60: return VoxelMaterialRegistry.Type.LIMESTONE
		if r < 0.85: return VoxelMaterialRegistry.Type.GRANITE
		return              VoxelMaterialRegistry.Type.MARBLE

	if depth_m > 4.0:    # transition layer
		var r := rng.randf()
		if r < 0.50: return VoxelMaterialRegistry.Type.LIMESTONE
		if r < 0.75: return VoxelMaterialRegistry.Type.SOIL
		return              VoxelMaterialRegistry.Type.SANDSTONE

	if depth_m == 0.0:   return VoxelMaterialRegistry.Type.GRASS
	return                      VoxelMaterialRegistry.Type.SOIL


# ── Helpers ───────────────────────────────────────────────────────
func _empty_grid(fill_value) -> Array:
	var g := []
	g.resize(_gx)
	for xi in _gx:
		g[xi] = []
		g[xi].resize(_gy)
		for yi in _gy:
			g[xi][yi] = []
			g[xi][yi].resize(_gz)
			g[xi][yi].fill(fill_value)
	return g


func grid_size() -> Vector3i:
	return Vector3i(_gx, _gy, _gz)


func voxel_size() -> float:
	return _voxel_size
