extends Node

# ─────────────────────────────────────────
#  Voxel Destruction Handler
#  Receives cone blast hit data and excavates voxels
#  from the world volume, spawning debris.
#
#  Attach to the world root node.
#  Requires: godot-voxel addon — VoxelTerrain node in scene.
# ─────────────────────────────────────────

@export var voxel_terrain: Node          ## Assign VoxelTerrain in inspector
@export var debris_scene: PackedScene    ## Small RigidBody3D cube for scatter

const VOXEL_SIZE       := 0.1           # metres per voxel edge
const DEBRIS_LIFETIME  := 3.0           # seconds before debris despawns
const MAX_DEBRIS       := 120           # global cap — performance guard

var _active_debris: int = 0


# ── Called by ConeBlast after each cast ──
## origin:     world position blast started
## forward:    normalised direction
## hit_points: Array of {position, distance, material_type}
func handle_blast_destruction(
		origin:     Vector3,
		forward:    Vector3,
		hit_points: Array,
		blast_power: float) -> void:

	for hit in hit_points:
		var mat_type: int = hit.get("material_type", VoxelMaterials.Type.AIR)
		if mat_type == VoxelMaterials.Type.AIR:
			continue
		if not VoxelMaterials.can_destroy(mat_type, blast_power):
			continue

		_excavate_voxels(hit.position, hit.radius, mat_type)


# ── Excavate a sphere of voxels ───────────
func _excavate_voxels(center: Vector3, radius: float, mat_type: int) -> void:
	if not voxel_terrain:
		return

	var props         := VoxelMaterials.get_props(mat_type)
	var scatter_force := props.get("scatter_force", 5.0)
	var debris_count  := props.get("debris_count", 4)

	var voxel_radius := int(ceil(radius / VOXEL_SIZE))
	var center_voxel := _world_to_voxel(center)

	# Iterate voxel sphere and set to AIR
	for x in range(-voxel_radius, voxel_radius + 1):
		for y in range(-voxel_radius, voxel_radius + 1):
			for z in range(-voxel_radius, voxel_radius + 1):
				if Vector3(x, y, z).length() > voxel_radius:
					continue
				var vpos := center_voxel + Vector3i(x, y, z)
				_set_voxel_air(vpos)

	# Spawn scatter debris
	_spawn_debris(center, mat_type, debris_count, scatter_force)


# ── Voxel grid helpers ───────────────────
func _world_to_voxel(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(world_pos.x / VOXEL_SIZE),
		int(world_pos.y / VOXEL_SIZE),
		int(world_pos.z / VOXEL_SIZE)
	)


func _set_voxel_air(voxel_pos: Vector3i) -> void:
	# godot-voxel API: VoxelTool.set_voxel(pos, value)
	# Value 0 = AIR in default channel
	if voxel_terrain.has_method("get_voxel_tool"):
		var tool = voxel_terrain.get_voxel_tool()
		tool.channel = 0   # TYPE channel
		tool.set_voxel(voxel_pos, 0)


# ── Debris spawning ──────────────────────
func _spawn_debris(center: Vector3, mat_type: int, count: int, force: float) -> void:
	if not debris_scene:
		return
	if _active_debris >= MAX_DEBRIS:
		return

	var color := VoxelMaterials.get_color(mat_type)
	var emit  := VoxelMaterials.is_emissive(mat_type)

	for i in range(min(count, MAX_DEBRIS - _active_debris)):
		var debris: RigidBody3D = debris_scene.instantiate()
		get_tree().current_scene.add_child(debris)
		debris.global_position = center + Vector3(
			randf_range(-0.2, 0.2),
			randf_range( 0.0, 0.3),
			randf_range(-0.2, 0.2)
		)

		# Tint the debris mesh to match material color
		_tint_debris(debris, color, emit)

		# Random outward impulse
		var impulse := Vector3(
			randf_range(-1.0, 1.0),
			randf_range( 0.3, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * force * randf_range(0.5, 1.5)
		debris.apply_central_impulse(impulse)

		_active_debris += 1
		_schedule_debris_cleanup(debris)


func _tint_debris(debris: Node, color: Color, emissive: bool) -> void:
	var mesh_instance := debris.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission          = color
		mat.emission_energy   = 2.5
	mesh_instance.set_surface_override_material(0, mat)


func _schedule_debris_cleanup(debris: Node) -> void:
	get_tree().create_timer(DEBRIS_LIFETIME).timeout.connect(func():
		if is_instance_valid(debris):
			debris.queue_free()
		_active_debris = maxi(_active_debris - 1, 0)
	)
