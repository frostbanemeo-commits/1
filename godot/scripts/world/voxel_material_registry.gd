extends RefCounted

# ═══════════════════════════════════════════════════════════════════
#  Voxel Material Registry
#  The authoritative source for every material in the world.
#
#  THE PRIMAL COLOUR — #7B2FBE — Royal Purple
#    Every voxel cluster is born from this colour.
#    The origin voxel of every cluster sparks purple before resolving
#    to its material colour. The primal colour is the base state of
#    all magic — the generative force from which all matter emerges.
#    It is stored in the cluster's soul record and never destroyed.
#    See: VoxelCluster, ClusterSpawner.
#
#  Materials are organized into categories:
#    Natural      — soil, sand, gravel, grass
#    Organic      — wood, bark, leaves, wildflower, vine, root
#    Stone        — limestone, granite, marble, sandstone, basalt
#    Ruby Civ     — ruby sphere, inlay, ancient tile, glowstone
#    Sacred       — INDESTRUCTIBLE materials (ancient temple block, etc.)
#    Empire       — iron, plating, treated wood, glass, explosive barrels
#    Ship         — hull planks, rope, sail, iron fittings
#    Environmental— ice, snow, ash, ember
#
#  Interaction system:
#    Each Force type has a reaction against each Material type.
#    Reactions: IMMUNE / RESISTANT / NORMAL / WEAK / INSTANT / REACTIVE
# ═══════════════════════════════════════════════════════════════════

# The primal colour — origin of all clusters. Never used as a material.
# Referenced here so every system has one source of truth.
const PRIMAL_PURPLE := Color(0.482, 0.184, 0.745)   # #7B2FBE


# ── Material Types ───────────────────────────────────────────────────
enum Type {
	AIR               = 0,

	# Natural
	SOIL              = 1,
	SAND              = 2,
	GRASS             = 3,
	GRAVEL            = 4,

	# Organic
	WOOD              = 10,
	BARK              = 11,
	LEAVES            = 12,
	WILDFLOWER        = 13,
	VINE              = 14,
	ROOT              = 15,

	# Stone
	LIMESTONE         = 20,
	GRANITE           = 21,
	MARBLE            = 22,
	SANDSTONE         = 23,
	BASALT            = 24,

	# Ruby Civilization
	RUBY              = 30,
	RUBY_INLAY        = 31,   # ruby embedded in marble — decorative
	ANCIENT_TILE      = 32,
	ANCIENT_PILLAR    = 33,
	GLOWSTONE         = 34,   # ancient light source, faintly emissive

	# Sacred / Indestructible
	ANCIENT_TEMPLE_BLOCK = 40,  # NOTHING destroys this — ever
	VOID_STONE           = 41,  # empire excavation material — nearly indestructible
	HEART_STONE          = 42,  # lore material — connected to the Holy Stone
	CURSED_IRON          = 43,  # the chains — indestructible by normal means

	# Empire
	EMPIRE_IRON       = 50,
	EMPIRE_PLATING    = 51,   # reinforced armour plate — very hard
	EMPIRE_WOOD       = 52,   # chemically treated — harder than natural wood
	EMPIRE_GLASS      = 53,   # brittle — shatters easily
	BARREL_EXPLOSIVE  = 54,   # detonates on damage — chain reaction possible

	# Ship
	SHIP_PLANK        = 60,
	SHIP_ROPE         = 61,
	SHIP_SAIL         = 62,
	SHIP_IRON         = 63,

	# Environmental
	ICE               = 70,
	SNOW              = 71,
	ASH               = 72,
	EMBER             = 73,   # hot, damages on contact
}


# ── Force Types ───────────────────────────────────────────────────────
# Sources of destruction that interact with materials differently.
enum Force {
	CONE_BLAST    = 0,   # Cinder's primary weapon
	FIRE          = 1,   # burning — spreads
	PHYSICAL      = 2,   # collision / fall impact
	EXPLOSION     = 3,   # barrel blasts, chain reactions
	EMPIRE_WEAPON = 4,   # enemy attacks
	VOID          = 5,   # lore / special — bypasses most immunity
}


# ── Reaction Types ────────────────────────────────────────────────────
enum Reaction {
	IMMUNE    = 0,   # zero effect — not even a scratch
	RESISTANT = 1,   # partial damage, cannot fully destroy
	NORMAL    = 2,   # standard destruction at rated hardness
	WEAK      = 3,   # extra vulnerable — destroyed at low power
	INSTANT   = 4,   # destroyed immediately, power irrelevant
	REACTIVE  = 5,   # special: triggers secondary effect on hit
}


# ── Material Definitions ──────────────────────────────────────────────
# hardness:      0.0–1.0 — blast power needed for NORMAL destruction
# scatter_force: how far debris flies
# debris_count:  pieces spawned
# emissive:      glows?
# category:      for grouping and audio bank selection

const MATERIALS: Dictionary = {

	# ── Natural ───────────────────────────────────────────────────────
	Type.SOIL: {
		"name": "Soil", "category": "natural",
		"hardness": 0.05, "scatter_force": 3.0, "debris_count": 4,
		"emissive": false,
		"colors": ["#6B4226", "#7A5230", "#4A3018"],
		"sound": "soil_break",
	},
	Type.SAND: {
		"name": "Sand", "category": "natural",
		"hardness": 0.02, "scatter_force": 2.0, "debris_count": 6,
		"emissive": false,
		"colors": ["#C2A05A", "#B8944A", "#D4B06A"],
		"sound": "sand_scatter",
	},
	Type.GRASS: {
		"name": "Grass", "category": "natural",
		"hardness": 0.02, "scatter_force": 2.5, "debris_count": 5,
		"emissive": false,
		"colors": ["#4A7A2E", "#3E6624", "#5A8A38"],
		"sound": "foliage_scatter",
	},
	Type.GRAVEL: {
		"name": "Gravel", "category": "natural",
		"hardness": 0.15, "scatter_force": 5.0, "debris_count": 8,
		"emissive": false,
		"colors": ["#888880", "#787870", "#989890"],
		"sound": "gravel_break",
	},

	# ── Organic ───────────────────────────────────────────────────────
	Type.WOOD: {
		"name": "Wood", "category": "organic",
		"hardness": 0.2, "scatter_force": 6.0, "debris_count": 6,
		"emissive": false,
		"colors": ["#8B6914", "#7A5C10", "#9C7820"],
		"sound": "wood_splinter",
		"flammable": true,
	},
	Type.BARK: {
		"name": "Bark", "category": "organic",
		"hardness": 0.15, "scatter_force": 4.0, "debris_count": 5,
		"emissive": false,
		"colors": ["#5C3D11", "#4A2E0A", "#6E4A18"],
		"sound": "wood_splinter",
		"flammable": true,
	},
	Type.LEAVES: {
		"name": "Leaves", "category": "organic",
		"hardness": 0.0, "scatter_force": 3.0, "debris_count": 8,
		"emissive": false,
		"colors": ["#2D6E1A", "#3A8A22", "#247014"],
		"sound": "foliage_scatter",
		"flammable": true,
	},
	Type.WILDFLOWER: {
		"name": "Wildflower", "category": "organic",
		"hardness": 0.0, "scatter_force": 6.0, "debris_count": 10,
		"emissive": false,
		"colors": ["#FF4466", "#FFD700", "#CC44FF", "#44AAFF", "#FF8833"],
		"sound": "foliage_scatter",
	},
	Type.VINE: {
		"name": "Vine", "category": "organic",
		"hardness": 0.05, "scatter_force": 3.0, "debris_count": 4,
		"emissive": false,
		"colors": ["#2A5C14", "#1E480E", "#347018"],
		"sound": "foliage_scatter",
		"flammable": true,
	},
	Type.ROOT: {
		"name": "Root", "category": "organic",
		"hardness": 0.25, "scatter_force": 4.0, "debris_count": 4,
		"emissive": false,
		"colors": ["#6B4A1A", "#5A3A10", "#7C5A24"],
		"sound": "wood_splinter",
	},

	# ── Stone ─────────────────────────────────────────────────────────
	Type.LIMESTONE: {
		"name": "Limestone", "category": "stone",
		"hardness": 0.45, "scatter_force": 6.0, "debris_count": 5,
		"emissive": false,
		"colors": ["#C8C0A8", "#D4CAB0", "#BEB6A0"],
		"sound": "stone_crack",
	},
	Type.GRANITE: {
		"name": "Granite", "category": "stone",
		"hardness": 0.75, "scatter_force": 7.0, "debris_count": 4,
		"emissive": false,
		"colors": ["#888884", "#787880", "#989894"],
		"sound": "stone_crack",
	},
	Type.MARBLE: {
		"name": "Marble", "category": "stone",
		"hardness": 0.55, "scatter_force": 7.0, "debris_count": 6,
		"emissive": false,
		"colors": ["#E8E4DC", "#D4CFC6", "#C8C0B4"],
		"sound": "marble_shatter",
	},
	Type.SANDSTONE: {
		"name": "Sandstone", "category": "stone",
		"hardness": 0.35, "scatter_force": 5.0, "debris_count": 5,
		"emissive": false,
		"colors": ["#C8A464", "#B8944A", "#D4B478"],
		"sound": "stone_crack",
	},
	Type.BASALT: {
		"name": "Basalt", "category": "stone",
		"hardness": 0.85, "scatter_force": 6.0, "debris_count": 3,
		"emissive": false,
		"colors": ["#2A2A2E", "#1E1E22", "#363638"],
		"sound": "stone_crack",
	},

	# ── Ruby Civilization ─────────────────────────────────────────────
	Type.RUBY: {
		"name": "Ruby Sphere", "category": "ruby_civ",
		"hardness": 0.35, "scatter_force": 14.0, "debris_count": 12,
		"emissive": true, "emissive_energy": 2.5,
		"colors": ["#CC1122", "#AA0011", "#FF2233"],
		"sound": "ruby_burst",
		"on_destroy": "ruby_explosion",   # secondary effect
	},
	Type.RUBY_INLAY: {
		"name": "Ruby Inlay", "category": "ruby_civ",
		"hardness": 0.3, "scatter_force": 10.0, "debris_count": 8,
		"emissive": true, "emissive_energy": 1.5,
		"colors": ["#CC1122", "#FF2233"],
		"sound": "ruby_burst",
	},
	Type.ANCIENT_TILE: {
		"name": "Ancient Tile", "category": "ruby_civ",
		"hardness": 0.5, "scatter_force": 6.0, "debris_count": 5,
		"emissive": false,
		"colors": ["#8A7A6A", "#9A8A7A", "#7A6A5A"],
		"sound": "marble_shatter",
	},
	Type.ANCIENT_PILLAR: {
		"name": "Ancient Pillar", "category": "ruby_civ",
		"hardness": 0.65, "scatter_force": 8.0, "debris_count": 6,
		"emissive": false,
		"colors": ["#C0B8A8", "#D0C8B8", "#B0A898"],
		"sound": "marble_shatter",
	},
	Type.GLOWSTONE: {
		"name": "Glowstone", "category": "ruby_civ",
		"hardness": 0.4, "scatter_force": 8.0, "debris_count": 8,
		"emissive": true, "emissive_energy": 3.5,
		"colors": ["#FFD080", "#FFC060", "#FFE0A0"],
		"sound": "ruby_burst",
	},

	# ── Sacred / Indestructible ───────────────────────────────────────
	Type.ANCIENT_TEMPLE_BLOCK: {
		"name": "Ancient Temple Block", "category": "sacred",
		"hardness": 999.0,   # effectively infinite
		"scatter_force": 0.0, "debris_count": 0,
		"emissive": false,
		"colors": ["#4A4040", "#3A3030", "#5A5050"],
		"sound": "stone_thud",
		"indestructible": true,   # flag — interaction matrix ignores all forces
		"lore": "These blocks predate the ruby civilization. Nothing made by mortal hands breaks them.",
	},
	Type.VOID_STONE: {
		"name": "Void Stone", "category": "sacred",
		"hardness": 0.95, "scatter_force": 2.0, "debris_count": 2,
		"emissive": false,
		"colors": ["#1A1A2A", "#0E0E1E", "#262636"],
		"sound": "metal_crack",
		"lore": "The empire quarried this from deep below. Even their weapons struggle with it.",
	},
	Type.HEART_STONE: {
		"name": "Heart Stone", "category": "sacred",
		"hardness": 999.0,
		"scatter_force": 0.0, "debris_count": 0,
		"emissive": true, "emissive_energy": 4.0,
		"colors": ["#8B0000", "#A00010", "#CC0020"],
		"sound": "stone_thud",
		"indestructible": true,
		"lore": "Pulses like a heartbeat. Connected to the Holy Stone. The empire cannot break it — they carry it instead.",
	},
	Type.CURSED_IRON: {
		"name": "Cursed Iron", "category": "sacred",
		"hardness": 999.0,
		"scatter_force": 0.0, "debris_count": 0,
		"emissive": true, "emissive_energy": 0.8,
		"colors": ["#1A1A1A", "#2A1A2A"],
		"sound": "metal_crack",
		"indestructible": true,
		"lore": "The chains that held Cinder. Imbued with the Emperor's curse. No blast, no fire, no blade breaks them — they must be unlocked.",
	},

	# ── Empire ────────────────────────────────────────────────────────
	Type.EMPIRE_IRON: {
		"name": "Empire Iron", "category": "empire",
		"hardness": 0.80, "scatter_force": 4.0, "debris_count": 3,
		"emissive": false,
		"colors": ["#3A3A3E", "#2E2E32", "#4A4A50"],
		"sound": "metal_crack",
	},
	Type.EMPIRE_PLATING: {
		"name": "Empire Reinforced Plating", "category": "empire",
		"hardness": 0.92, "scatter_force": 3.0, "debris_count": 2,
		"emissive": false,
		"colors": ["#28282C", "#222226", "#343438"],
		"sound": "metal_crack",
	},
	Type.EMPIRE_WOOD: {
		"name": "Empire Treated Wood", "category": "empire",
		"hardness": 0.45, "scatter_force": 5.0, "debris_count": 5,
		"emissive": false,
		"colors": ["#5C4A2A", "#4A3818", "#6E5C3A"],
		"sound": "wood_splinter",
		"flammable": false,   # chemically treated — fire resistant
	},
	Type.EMPIRE_GLASS: {
		"name": "Empire Glass", "category": "empire",
		"hardness": 0.05, "scatter_force": 9.0, "debris_count": 12,
		"emissive": false,
		"colors": ["#88CCCC", "#6AACAC", "#AADEEE"],
		"sound": "glass_shatter",
	},
	Type.BARREL_EXPLOSIVE: {
		"name": "Explosive Barrel", "category": "empire",
		"hardness": 0.1, "scatter_force": 0.0, "debris_count": 0,
		"emissive": false,
		"colors": ["#8B2222", "#6B1A1A", "#AA2A2A"],
		"sound": "explosion",
		"on_destroy": "barrel_explosion",   # chain reaction
		"explosion_radius": 4.0,
		"explosion_power":  0.8,
	},

	# ── Ship ──────────────────────────────────────────────────────────
	Type.SHIP_PLANK: {
		"name": "Ship Hull Plank", "category": "ship",
		"hardness": 0.3, "scatter_force": 6.0, "debris_count": 6,
		"emissive": false,
		"colors": ["#7A5C2A", "#6A4C1A", "#8A6C3A"],
		"sound": "wood_splinter",
		"flammable": true,
	},
	Type.SHIP_ROPE: {
		"name": "Ship Rope", "category": "ship",
		"hardness": 0.0, "scatter_force": 2.0, "debris_count": 3,
		"emissive": false,
		"colors": ["#C8A87A", "#B8986A", "#D8B88A"],
		"sound": "rope_snap",
		"flammable": true,
	},
	Type.SHIP_SAIL: {
		"name": "Ship Sail", "category": "ship",
		"hardness": 0.0, "scatter_force": 4.0, "debris_count": 4,
		"emissive": false,
		"colors": ["#E8E0CC", "#D8D0BC", "#F0E8D8"],
		"sound": "cloth_tear",
		"flammable": true,
	},
	Type.SHIP_IRON: {
		"name": "Ship Iron Fitting", "category": "ship",
		"hardness": 0.65, "scatter_force": 4.0, "debris_count": 3,
		"emissive": false,
		"colors": ["#484848", "#3A3A3A", "#585858"],
		"sound": "metal_crack",
	},

	# ── Environmental ─────────────────────────────────────────────────
	Type.ICE: {
		"name": "Ice", "category": "environmental",
		"hardness": 0.1, "scatter_force": 7.0, "debris_count": 8,
		"emissive": false,
		"colors": ["#A8D8E8", "#B8E8F8", "#98C8D8"],
		"sound": "ice_crack",
		"slippery": true,
	},
	Type.SNOW: {
		"name": "Snow", "category": "environmental",
		"hardness": 0.0, "scatter_force": 1.5, "debris_count": 4,
		"emissive": false,
		"colors": ["#F0F0F8", "#E8E8F0", "#F8F8FF"],
		"sound": "snow_puff",
	},
	Type.ASH: {
		"name": "Ash", "category": "environmental",
		"hardness": 0.0, "scatter_force": 1.0, "debris_count": 3,
		"emissive": false,
		"colors": ["#A0A0A0", "#909090", "#B0B0B0"],
		"sound": "ash_scatter",
	},
	Type.EMBER: {
		"name": "Ember", "category": "environmental",
		"hardness": 0.0, "scatter_force": 3.0, "debris_count": 6,
		"emissive": true, "emissive_energy": 2.0,
		"colors": ["#FF6600", "#FF4400", "#FF8800"],
		"sound": "ember_hiss",
		"damages_on_contact": true,
		"contact_damage": 5.0,
	},
}


# ── Interaction Matrix ────────────────────────────────────────────────
# [Force][Material] → Reaction
# Only non-NORMAL entries need to be listed — NORMAL is the default.
# Indestructible materials override everything.

const INTERACTIONS: Dictionary = {

	Force.CONE_BLAST: {
		# Organic — blast destroys all wood completely
		Type.WOOD:              Reaction.INSTANT,
		Type.BARK:              Reaction.INSTANT,
		Type.LEAVES:            Reaction.INSTANT,
		Type.WILDFLOWER:        Reaction.INSTANT,
		Type.VINE:              Reaction.INSTANT,
		Type.ROOT:              Reaction.WEAK,
		# Stone — blast is resistant against dense stone
		Type.GRANITE:           Reaction.RESISTANT,
		Type.BASALT:            Reaction.RESISTANT,
		# Ruby — normal destruction + reactive scatter
		Type.RUBY:              Reaction.REACTIVE,
		Type.RUBY_INLAY:        Reaction.REACTIVE,
		Type.GLOWSTONE:         Reaction.REACTIVE,
		# Sacred — immune
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.IMMUNE,
		Type.HEART_STONE:          Reaction.IMMUNE,
		Type.CURSED_IRON:          Reaction.IMMUNE,
		Type.VOID_STONE:           Reaction.RESISTANT,
		# Empire
		Type.EMPIRE_GLASS:      Reaction.INSTANT,
		Type.EMPIRE_PLATING:    Reaction.RESISTANT,
		Type.BARREL_EXPLOSIVE:  Reaction.REACTIVE,
		# Ship
		Type.SHIP_SAIL:         Reaction.INSTANT,
		Type.SHIP_ROPE:         Reaction.INSTANT,
		# Environmental
		Type.SNOW:              Reaction.INSTANT,
		Type.ASH:               Reaction.INSTANT,
		Type.EMBER:             Reaction.INSTANT,
		Type.ICE:               Reaction.WEAK,
	},

	Force.FIRE: {
		# Organics burn
		Type.WOOD:              Reaction.REACTIVE,   # burns and spreads
		Type.BARK:              Reaction.REACTIVE,
		Type.LEAVES:            Reaction.INSTANT,
		Type.WILDFLOWER:        Reaction.INSTANT,
		Type.VINE:              Reaction.REACTIVE,
		# Ship materials burn
		Type.SHIP_PLANK:        Reaction.REACTIVE,
		Type.SHIP_ROPE:         Reaction.INSTANT,
		Type.SHIP_SAIL:         Reaction.INSTANT,
		# Stone — fire resistant
		Type.GRANITE:           Reaction.IMMUNE,
		Type.BASALT:            Reaction.IMMUNE,
		Type.MARBLE:            Reaction.RESISTANT,
		# Empire treated wood is fire resistant
		Type.EMPIRE_WOOD:       Reaction.RESISTANT,
		# Sacred
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.IMMUNE,
		Type.HEART_STONE:          Reaction.IMMUNE,
		Type.CURSED_IRON:          Reaction.IMMUNE,
		# Barrel reacts
		Type.BARREL_EXPLOSIVE:  Reaction.REACTIVE,
	},

	Force.EXPLOSION: {
		# Explosion is powerful — overcomes most resistance
		Type.GRANITE:           Reaction.NORMAL,     # explosion breaks what blast can't
		Type.BASALT:            Reaction.NORMAL,
		Type.EMPIRE_PLATING:    Reaction.NORMAL,
		Type.VOID_STONE:        Reaction.RESISTANT,
		# Sacred stays immune
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.IMMUNE,
		Type.HEART_STONE:          Reaction.IMMUNE,
		Type.CURSED_IRON:          Reaction.IMMUNE,
		# Chain reactions
		Type.BARREL_EXPLOSIVE:  Reaction.REACTIVE,
		Type.RUBY:              Reaction.REACTIVE,
	},

	Force.PHYSICAL: {
		# Physical impact — weak against hard materials
		Type.GRANITE:           Reaction.RESISTANT,
		Type.BASALT:            Reaction.IMMUNE,
		Type.EMPIRE_PLATING:    Reaction.IMMUNE,
		Type.EMPIRE_IRON:       Reaction.RESISTANT,
		Type.SHIP_IRON:         Reaction.RESISTANT,
		# Sacred
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.IMMUNE,
		Type.HEART_STONE:          Reaction.IMMUNE,
		Type.CURSED_IRON:          Reaction.IMMUNE,
		# Glass shatters on contact
		Type.EMPIRE_GLASS:      Reaction.INSTANT,
		Type.ICE:               Reaction.WEAK,
	},

	Force.EMPIRE_WEAPON: {
		# Empire weapons are engineered — bypass some resistances
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.IMMUNE,  # still can't touch this
		Type.HEART_STONE:          Reaction.IMMUNE,
		Type.CURSED_IRON:          Reaction.IMMUNE,  # their own chain — still immune
		Type.GRANITE:              Reaction.NORMAL,
		Type.BASALT:               Reaction.NORMAL,
	},

	Force.VOID: {
		# Void force — lore/special. Bypasses almost everything.
		# Only the most ancient sacred materials resist it.
		Type.ANCIENT_TEMPLE_BLOCK: Reaction.RESISTANT,  # even void struggles
		Type.HEART_STONE:          Reaction.IMMUNE,       # absolute
		Type.CURSED_IRON:          Reaction.NORMAL,       # void can break the curse
	},
}


# ── API ───────────────────────────────────────────────────────────────

static func get_reaction(force: Force, material: Type) -> Reaction:
	var mat_data: Dictionary = MATERIALS.get(material, {})
	if mat_data.get("indestructible", false):
		# Void force can still interact with indestructible materials if defined
		if force == Force.VOID:
			var void_map: Dictionary = INTERACTIONS.get(Force.VOID, {})
			if material in void_map:
				return void_map[material]
		return Reaction.IMMUNE

	var force_map: Dictionary = INTERACTIONS.get(force, {})
	return force_map.get(material, Reaction.NORMAL)


static func get_material(type: Type) -> Dictionary:
	return MATERIALS.get(type, {})


static func is_indestructible(type: Type) -> bool:
	return MATERIALS.get(type, {}).get("indestructible", false)


static func get_secondary_effect(type: Type) -> String:
	return MATERIALS.get(type, {}).get("on_destroy", "")


static func get_color(type: Type) -> Color:
	var palette: Array = MATERIALS.get(type, {}).get("colors", ["#FF00FF"])
	var hex: String    = palette[randi() % palette.size()]
	return Color(hex)


static func get_all_of_category(category: String) -> Array:
	var result := []
	for mat_type in MATERIALS:
		if MATERIALS[mat_type].get("category", "") == category:
			result.append(mat_type)
	return result
