extends Node
class_name ClusterSpawner

# ═══════════════════════════════════════════════════════════════════
#  Cluster Spawner
#
#  Handles the visual birth sequence of a VoxelCluster:
#
#    1. Origin voxel placed at PRIMAL_PURPLE
#    2. Hold for PRIMAL_HOLD_SECONDS (the spark moment)
#    3. Sweep outward — each subsequent voxel resolves from purple
#       to material colour as the cluster grows from its origin
#    4. Cluster marked resolved — primal colour stored in soul record
#
#  The sweep radiates outward from origin_position.
#  Closer voxels resolve first. The origin is always first and last
#  to fully commit — it leads and anchors the cluster.
# ═══════════════════════════════════════════════════════════════════

signal cluster_resolved(cluster: VoxelCluster)

@export var voxel_terrain: Node   ## Assign VoxelTerrain

# Time between voxel resolution steps during the sweep
const SWEEP_STEP_SECONDS := 0.008   # fast — feels like a materialising wave

var _active_spawns: Array = []   # Array of in-progress cluster spawns


# ── Spawn a cluster ───────────────────────────────────────────────
func spawn_cluster(cluster: VoxelCluster) -> void:
	_active_spawns.append(cluster)
	_begin_spawn(cluster)


func _begin_spawn(cluster: VoxelCluster) -> void:
	# Step 1 — place origin voxel in primal purple
	_set_voxel_colour(cluster.origin_position, VoxelCluster.PRIMAL_PURPLE)

	# Step 2 — hold the primal flash, then sweep outward
	get_tree().create_timer(VoxelCluster.PRIMAL_HOLD_SECONDS).timeout.connect(
		func(): _sweep_resolve(cluster),
		CONNECT_ONE_SHOT
	)


func _sweep_resolve(cluster: VoxelCluster) -> void:
	# Sort voxels by distance from origin — closest resolve first
	var origin_f := Vector3(cluster.origin_position)
	var sorted   := cluster.voxel_positions.duplicate()
	sorted.sort_custom(func(a, b):
		var da := Vector3(a).distance_to(origin_f)
		var db := Vector3(b).distance_to(origin_f)
		return da < db
	)

	# Sweep with staggered delay
	for i in sorted.size():
		var pos: Vector3i = sorted[i]
		var delay := i * SWEEP_STEP_SECONDS

		get_tree().create_timer(delay).timeout.connect(
			func(): _resolve_voxel(pos, cluster),
			CONNECT_ONE_SHOT
		)

	# Mark fully resolved after sweep completes
	var total_time := sorted.size() * SWEEP_STEP_SECONDS
	get_tree().create_timer(total_time + 0.05).timeout.connect(
		func(): _finish_cluster(cluster),
		CONNECT_ONE_SHOT
	)


func _resolve_voxel(pos: Vector3i, cluster: VoxelCluster) -> void:
	# Brief purple flash on each voxel, then snap to material colour
	_set_voxel_colour(pos, VoxelCluster.PRIMAL_PURPLE)

	get_tree().create_timer(VoxelCluster.PRIMAL_HOLD_SECONDS * 0.5).timeout.connect(
		func(): _set_voxel_colour(pos, cluster.resolved_colour),
		CONNECT_ONE_SHOT
	)


func _finish_cluster(cluster: VoxelCluster) -> void:
	cluster.resolve()
	_active_spawns.erase(cluster)
	cluster_resolved.emit(cluster)


# ── Voxel colour write ────────────────────────────────────────────
func _set_voxel_colour(pos: Vector3i, colour: Color) -> void:
	if not voxel_terrain:
		return
	if not voxel_terrain.has_method("get_voxel_tool"):
		return
	var tool := voxel_terrain.get_voxel_tool()
	tool.channel = 1   # COLOUR channel (godot-voxel channel 1)
	# Encode colour as 16-bit RGB565 or 32-bit depending on voxel format
	# Placeholder — exact encoding depends on VoxelBuffer format in use
	tool.set_voxel(pos, _colour_to_voxel_int(colour))


func _colour_to_voxel_int(c: Color) -> int:
	# Simple 8-bit per channel packing: RRGGBB in 24 bits
	var r := int(c.r * 255) & 0xFF
	var g := int(c.g * 255) & 0xFF
	var b := int(c.b * 255) & 0xFF
	return (r << 16) | (g << 8) | b
