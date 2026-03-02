extends RefCounted

# ─────────────────────────────────────────
#  Voxel Material Definitions
#  Color is the only surface data — no UV textures.
#  Material type drives destruction behaviour and audio.
#
#  Requires: godot-voxel addon (Zylann)
#  Assets:   MagicaVoxel (.vox) for structures
# ─────────────────────────────────────────

enum Type {
	AIR        = 0,
	SOIL       = 1,
	MARBLE     = 2,
	WILDFLOWER = 3,
	RUBY       = 4,
	EMPIRE     = 5,
	WOOD       = 6,
}

# ── Color palette (RGB) ──────────────────
# Each material has 2-4 color variants — chosen randomly on generation
# for natural variation without textures.

const COLORS: Dictionary = {
	Type.SOIL: [
		Color(0.420, 0.259, 0.149),   # #6B4226
		Color(0.478, 0.322, 0.188),   # #7A5230
		Color(0.290, 0.188, 0.094),   # #4A3018
	],
	Type.MARBLE: [
		Color(0.910, 0.894, 0.863),   # #E8E4DC
		Color(0.831, 0.812, 0.776),   # #D4CFC6
		Color(0.784, 0.753, 0.706),   # #C8C0B4
	],
	Type.WILDFLOWER: [
		Color(1.000, 0.267, 0.400),   # #FF4466  rose
		Color(1.000, 0.843, 0.000),   # #FFD700  gold
		Color(0.800, 0.267, 1.000),   # #CC44FF  violet
		Color(0.267, 0.667, 1.000),   # #44AAFF  sky blue
		Color(1.000, 0.533, 0.200),   # #FF8833  amber
	],
	Type.RUBY: [
		Color(0.800, 0.067, 0.133),   # #CC1122
		Color(0.667, 0.000, 0.067),   # #AA0011
		Color(1.000, 0.133, 0.200),   # #FF2233  (brightest, emissive)
	],
	Type.EMPIRE: [
		Color(0.227, 0.227, 0.243),   # #3A3A3E
		Color(0.180, 0.180, 0.196),   # #2E2E32
		Color(0.290, 0.290, 0.314),   # #4A4A50
	],
	Type.WOOD: [
		Color(0.545, 0.412, 0.078),   # #8B6914
		Color(0.478, 0.361, 0.063),   # #7A5C10
	],
}

# ── Material properties ───────────────────
# hardness:      blast power required to destroy (0.0 = instant, 1.0 = max)
# scatter_force: how far destroyed voxels fly
# debris_count:  number of debris pieces spawned on destruction
# emissive:      does this material glow?

const PROPERTIES: Dictionary = {
	Type.SOIL: {
		"hardness":     0.1,
		"scatter_force": 4.0,
		"debris_count": 3,
		"emissive":     false,
		"sound":        "soil_break",
	},
	Type.MARBLE: {
		"hardness":     0.55,
		"scatter_force": 7.0,
		"debris_count": 6,
		"emissive":     false,
		"sound":        "marble_shatter",
	},
	Type.WILDFLOWER: {
		"hardness":     0.0,
		"scatter_force": 6.0,
		"debris_count": 8,
		"emissive":     false,
		"sound":        "foliage_scatter",
	},
	Type.RUBY: {
		"hardness":     0.35,
		"scatter_force": 12.0,
		"debris_count": 10,
		"emissive":     true,
		"emissive_energy": 2.5,
		"sound":        "ruby_burst",
	},
	Type.EMPIRE: {
		"hardness":     0.85,
		"scatter_force": 5.0,
		"debris_count": 4,
		"emissive":     false,
		"sound":        "metal_crack",
	},
	Type.WOOD: {
		"hardness":     0.3,
		"scatter_force": 5.0,
		"debris_count": 5,
		"emissive":     false,
		"sound":        "wood_splinter",
	},
}


# ── Helpers ───────────────────────────────

static func get_color(type: Type) -> Color:
	var palette: Array = COLORS.get(type, [Color.MAGENTA])
	return palette[randi() % palette.size()]


static func get_props(type: Type) -> Dictionary:
	return PROPERTIES.get(type, {})


static func can_destroy(type: Type, blast_power: float) -> bool:
	var props := get_props(type)
	return blast_power >= props.get("hardness", 0.0)


static func is_emissive(type: Type) -> bool:
	return get_props(type).get("emissive", false)
