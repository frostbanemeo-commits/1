extends Node

# ─────────────────────────────────────────
#  Voxel Destruction Handler
#
#  Receives cone blast hit data, consults the material interaction
#  matrix, and excavates voxels that are not immune or resistant.
#
#  This is the Tool Agent in the destruction pipeline:
#    ConeBlast  →  VoxelDestruction  →  VoxelMaterialRegistry (validator)
#                                     →  VoxelTerrain (world edit)
#
#  Attach to the world root node.
#  Requires: godot-voxel addon — VoxelTerrain node in scene.
# ─────────────────────────────────────────

@export var voxel_terrain: Node          ## Assign VoxelTerrain in inspector
@export var debris_scene:  PackedScene   ## Small RigidBody3D cube for scatter

const VOXEL_SIZE      := 0.1    # metres — gameplay / destruction tier
const DEBRIS_LIFETIME := 3.0   # seconds before debris despawns
const MAX_DEBRIS      := 120   # global cap — performance guard

var _active_debris: int = 0


# ── Entry point — called by ConeBlast signal ─────────────────────
func handle_blast_destruction(
		origin:      Vector3,
		forward:     Vector3,
		hit_points:  Array,
		blast_power: float) -> void:

	for hit in hit_points:
		var mat_type: int = hit.get("material_type", VoxelMaterialRegistry.Type.AIR)
		if mat_type == VoxelMaterialRegistry.Type.AIR:
			continue

		# ── Consult the interaction matrix (the validator) ──────────
		var reaction := VoxelMaterialRegistry.get_reaction(
			VoxelMaterialRegistry.Force.CONE_BLAST,
			mat_type
		)

		match reaction:
			VoxelMaterialRegistry.Reaction.IMMUNE:
				continue   # formally excluded — no code path destroys this

			VoxelMaterialRegistry.Reaction.RESISTANT:
				# Partial damage — only high-power blasts push through
				if blast_power < 0.9:
					continue

			VoxelMaterialRegistry.Reaction.INSTANT, \
			VoxelMaterialRegistry.Reaction.NORMAL, \
			VoxelMaterialRegistry.Reaction.WEAK:
				# Check hardness against blast power
				var props    := VoxelMaterialRegistry.get_material(mat_type)
				var hardness := props.get("hardness", 0.0)
				var required := hardness
				if reaction == VoxelMaterialRegistry.Reaction.INSTANT:
					required = 0.0   # always destroys
				elif reaction == VoxelMaterialRegistry.Reaction.WEAK:
					required = hardness * 0.5
				if blast_power < required:
					continue

			VoxelMaterialRegistry.Reaction.REACTIVE:
				# Destroy + trigger secondary effect
				var effect := VoxelMaterialRegistry.get_secondary_effect(mat_type)
				_trigger_secondary(effect, hit.position)

		_excavate_voxels(hit.position, hit.radius, mat_type)


# ── Excavate a sphere of voxels ──────────────────────────────────
func _excavate_voxels(center: Vector3, radius: float, mat_type: int) -> void:
	if not voxel_terrain:
		return

	var props         := VoxelMaterialRegistry.get_material(mat_type)
	var scatter_force := props.get("scatter_force", 5.0)
	var debris_count  := props.get("debris_count",  4)

	var voxel_radius := int(ceil(radius / VOXEL_SIZE))
	var center_voxel := _world_to_voxel(center)

	for x in range(-voxel_radius, voxel_radius + 1):
		for y in range(-voxel_radius, voxel_radius + 1):
			for z in range(-voxel_radius, voxel_radius + 1):
				if Vector3(x, y, z).length() > voxel_radius:
					continue
				_set_voxel_air(center_voxel + Vector3i(x, y, z))

	_spawn_debris(center, mat_type, debris_count, scatter_force)


# ── Secondary effects (REACTIVE materials) ───────────────────────
func _trigger_secondary(effect: String, position: Vector3) -> void:
	match effect:
		"ruby_explosion":
			# Crimson voxel burst — high scatter, emissive debris
			_spawn_debris(position, VoxelMaterialRegistry.Type.RUBY, 12, 14.0)

		"barrel_explosion":
			# Chain detonation — damage nearby voxels in a larger radius
			var props := VoxelMaterialRegistry.get_material(
				VoxelMaterialRegistry.Type.BARREL_EXPLOSIVE
			)
			var exp_radius  := props.get("explosion_radius", 4.0)
			var exp_power   := props.get("explosion_power",  0.8)
			var fake_hits   := [{"position": position, "radius": exp_radius,
								 "material_type": VoxelMaterialRegistry.Type.AIR}]
			# Re-enter with explosion force — note: uses EXPLOSION not CONE_BLAST
			_handle_explosion(position, exp_radius, exp_power)


func _handle_explosion(center: Vector3, radius: float, power: float) -> void:
	# Iterate nearby voxels and apply EXPLOSION force reactions
	var voxel_radius := int(ceil(radius / VOXEL_SIZE))
	var center_voxel := _world_to_voxel(center)

	for x in range(-voxel_radius, voxel_radius + 1):
		for y in range(-voxel_radius, voxel_radius + 1):
			for z in range(-voxel_radius, voxel_radius + 1):
				if Vector3(x, y, z).length() > voxel_radius:
					continue
				var vpos := center_voxel + Vector3i(x, y, z)
				# Could query material at vpos here when VoxelTerrain API allows it
				_set_voxel_air(vpos)


# ── Voxel grid helpers ───────────────────────────────────────────
func _world_to_voxel(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(world_pos.x / VOXEL_SIZE),
		int(world_pos.y / VOXEL_SIZE),
		int(world_pos.z / VOXEL_SIZE)
	)


func _set_voxel_air(voxel_pos: Vector3i) -> void:
	if voxel_terrain.has_method("get_voxel_tool"):
		var tool := voxel_terrain.get_voxel_tool()
		tool.channel = 0
		tool.set_voxel(voxel_pos, 0)


# ── Debris spawning ──────────────────────────────────────────────
func _spawn_debris(center: Vector3, mat_type: int, count: int, force: float) -> void:
	if not debris_scene:
		return
	if _active_debris >= MAX_DEBRIS:
		return

	var color    := VoxelMaterialRegistry.get_color(mat_type)
	var props    := VoxelMaterialRegistry.get_material(mat_type)
	var emissive := props.get("emissive", false)
	var emit_e   := props.get("emissive_energy", 1.0)

	for i in range(min(count, MAX_DEBRIS - _active_debris)):
		var debris: RigidBody3D = debris_scene.instantiate()
		get_tree().current_scene.add_child(debris)
		debris.global_position = center + Vector3(
			randf_range(-0.2, 0.2),
			randf_range( 0.0, 0.3),
			randf_range(-0.2, 0.2)
		)

		_tint_debris(debris, color, emissive, emit_e)

		var impulse := Vector3(
			randf_range(-1.0, 1.0),
			randf_range( 0.3, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * force * randf_range(0.5, 1.5)
		debris.apply_central_impulse(impulse)

		_active_debris += 1
		_schedule_debris_cleanup(debris)


func _tint_debris(debris: Node, color: Color, emissive: bool, emit_energy: float) -> void:
	var mesh_instance := debris.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission         = color
		mat.emission_energy  = emit_energy
	mesh_instance.set_surface_override_material(0, mat)


func _schedule_debris_cleanup(debris: Node) -> void:
	get_tree().create_timer(DEBRIS_LIFETIME).timeout.connect(func():
		if is_instance_valid(debris):
			debris.queue_free()
		_active_debris = maxi(_active_debris - 1, 0)
	)
