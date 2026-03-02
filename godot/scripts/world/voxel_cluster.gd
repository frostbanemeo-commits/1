extends RefCounted
class_name VoxelCluster

# ═══════════════════════════════════════════════════════════════════
#  Voxel Cluster
#
#  A cluster is a group of voxels that share a material identity
#  and a single origin — the spark that generated the cluster.
#
#  THE ORIGIN VOXEL:
#    Every cluster has exactly one origin voxel.
#    It is the first voxel placed. It leads.
#    It is born PRIMAL — royal purple (#7B2FBE).
#    It then resolves to the cluster's assigned material colour.
#    The primal colour is never destroyed — it is stored in the
#    cluster's soul record even after resolution.
#
#  THE PRIMAL COLOUR:
#    Royal purple. The base state of all magic in this world.
#    All matter emerged from it. All clusters begin with it.
#    The ruby civilisation channelled it into red.
#    The Emperor's chains were purple before they were cursed iron.
#    Cinder's blast carries a trace of it — the cone is born purple
#    at its origin point before expanding outward.
#
#  CLUSTER SOUL:
#    origin_position  — world-space Vector3i of the origin voxel
#    material_type    — VoxelMaterialRegistry.Type
#    primal_colour    — always PRIMAL_PURPLE (stored, never lost)
#    resolved_colour  — the actual colour after material assignment
#    cluster_id       — unique identifier for this cluster instance
# ═══════════════════════════════════════════════════════════════════

# Royal purple — the primal state. Born before material identity.
const PRIMAL_PURPLE := Color(0.482, 0.184, 0.745)   # #7B2FBE

# How long the origin voxel holds the primal colour before resolving
const PRIMAL_HOLD_SECONDS := 0.12   # brief flash — a spark, not a glow

var cluster_id:       int
var origin_position:  Vector3i
var material_type:    int          # VoxelMaterialRegistry.Type
var primal_colour:    Color        # always PRIMAL_PURPLE — the record of birth
var resolved_colour:  Color        # the material colour after resolution
var voxel_positions:  Array        # Array[Vector3i] — all voxels in this cluster
var is_resolved:      bool = false # false during the primal flash, true after

static var _id_counter: int = 0


func _init(
		origin:   Vector3i,
		mat_type: int,
		mat_colour: Color) -> void:

	_id_counter    += 1
	cluster_id      = _id_counter
	origin_position = origin
	material_type   = mat_type
	primal_colour   = PRIMAL_PURPLE
	resolved_colour = mat_colour
	voxel_positions = [origin]
	is_resolved     = false


# ── Voxel membership ─────────────────────────────────────────────
func add_voxel(pos: Vector3i) -> void:
	if pos not in voxel_positions:
		voxel_positions.append(pos)


func contains(pos: Vector3i) -> bool:
	return pos in voxel_positions


func size() -> int:
	return voxel_positions.size()


# ── Soul record ───────────────────────────────────────────────────
# The primal colour is never overwritten — it is the birth record.
# resolved_colour is what the world sees after the spark.

func resolve() -> void:
	is_resolved = true


func get_display_colour() -> Color:
	return resolved_colour if is_resolved else primal_colour


func soul() -> Dictionary:
	return {
		"cluster_id":      cluster_id,
		"origin":          origin_position,
		"material":        material_type,
		"primal_colour":   primal_colour,
		"resolved_colour": resolved_colour,
		"voxel_count":     voxel_positions.size(),
		"is_resolved":     is_resolved,
	}
