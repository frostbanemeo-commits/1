extends Node3D

# ─────────────────────────────────────────
#  Cone Blast — Cinder's primary weapon
#
#  Fires forward from screen center.
#  Pierces as a tight point at origin,
#  expands as a cone over distance,
#  full falloff at 60 metres.
#
#  Shape at distance d (0..MAX_RANGE):
#    radius(d) = BASE_RADIUS * (1.0 + GROWTH_RATE * (d / MAX_RANGE))
#    where GROWTH_RATE = 0.15  →  15% size increase over full range
#    and BASE_RADIUS uses π as the spread unit base (≈ 3.14m at origin,
#    scaling to ≈ 3.61m at 60m — tight near, wider far)
#
#  Segments: the 60m range is sampled in slices.
#  Each slice casts a sphere of the appropriate radius.
#  Hits are deduplicated — a body is damaged at most once per blast.
# ─────────────────────────────────────────

signal blast_fired(origin: Vector3, direction: Vector3)

# ── Tuning ───────────────────────────────
const MAX_RANGE    := 60.0          # metres — hard falloff
const BASE_RADIUS  := PI * 0.1     # ≈ 0.314m at origin (tight pierce)
const GROWTH_RATE  := 0.15         # 15% radius increase over full range
const SEGMENTS     := 20           # sphere samples along the cone
const COOLDOWN     := 1.2          # seconds between blasts

const DAMAGE_NEAR  := 80.0         # damage at origin
const DAMAGE_FAR   := 20.0         # damage at 60m (linear falloff)
const KNOCKBACK    := 18.0         # impulse force magnitude

# ── State ────────────────────────────────
var _cooldown_timer: float = 0.0
var _camera: Camera3D

@export var blast_layer: int = 1   # physics layer to hit


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	# Keep camera reference fresh (handles perspective switches)
	_camera = get_viewport().get_camera_3d()


# ── Fire ─────────────────────────────────
func fire() -> void:
	if _cooldown_timer > 0.0:
		return
	if not _camera:
		return

	_cooldown_timer = COOLDOWN

	var origin    := _camera.global_position
	var forward   := -_camera.global_transform.basis.z   # camera looks down -Z

	blast_fired.emit(origin, forward)
	_cast_cone(origin, forward)


func _cast_cone(origin: Vector3, forward: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state
	var hit_bodies  := {}   # deduplicate: body → closest distance hit

	for i in range(1, SEGMENTS + 1):
		var t      := float(i) / float(SEGMENTS)
		var dist   := t * MAX_RANGE
		var radius := BASE_RADIUS * (1.0 + GROWTH_RATE * t)
		var center := origin + forward * dist

		var params := PhysicsShapeQueryParameters3D.new()
		params.shape            = SphereShape3D.new()
		params.shape.radius     = radius
		params.transform        = Transform3D(Basis.IDENTITY, center)
		params.collision_mask   = blast_layer
		params.exclude          = [get_parent()]   # don't hit self

		var results := space_state.intersect_shape(params, 16)
		for result in results:
			var body: Object = result.get("collider")
			if body and body not in hit_bodies:
				hit_bodies[body] = dist

	_apply_hits(hit_bodies, origin, forward)


func _apply_hits(hit_bodies: Dictionary, origin: Vector3, forward: Vector3) -> void:
	for body in hit_bodies:
		var dist: float = hit_bodies[body]
		var t           := clampf(dist / MAX_RANGE, 0.0, 1.0)
		var damage      := lerpf(DAMAGE_NEAR, DAMAGE_FAR, t)
		var knockback   := forward * KNOCKBACK * (1.0 - t * 0.6)

		# Damage
		if body.has_method("take_damage"):
			body.take_damage(damage, knockback)

		# Physics impulse for rigid bodies
		if body is RigidBody3D:
			body.apply_central_impulse(knockback)


# ── Query ────────────────────────────────
func is_ready() -> bool:
	return _cooldown_timer <= 0.0


func get_cooldown_percent() -> float:
	return clampf(1.0 - (_cooldown_timer / COOLDOWN), 0.0, 1.0)
