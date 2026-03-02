extends CharacterBody3D

# ─────────────────────────────────────────
#  Player Movement — Cinder
#  Handles: movement, jumping, hover, strength fragment upgrades
# ─────────────────────────────────────────

const MOVE_SPEED        := 6.0
const JUMP_VELOCITY     := 9.0
const GRAVITY           := 20.0

# ── Jump system ──────────────────────────
# Base: 1 jump (ground only). Strength fragments add mid-air jumps.
var max_air_jumps: int   = 0   # 0 = only ground jump. Each fragment adds 1.
var air_jumps_left: int  = 0   # resets to max_air_jumps on landing

var _was_on_floor: bool  = false

# ── Hover system (placeholder values — tuning pass later) ──
const HOVER_DURATION     := 1.8   # seconds of hover available
const HOVER_RECHARGE_RATE := 0.4  # per second, recharges on ground only
var hover_energy: float  = HOVER_DURATION
var is_hovering: bool    = false

# ── References ───────────────────────────
@onready var _ui: Node = get_tree().get_first_node_in_group("hud")


func _physics_process(delta: float) -> void:
	_handle_landing()
	_apply_gravity(delta)
	_handle_jump()
	_handle_hover(delta)
	_handle_movement()
	move_and_slide()


# ── Landing detection ────────────────────
func _handle_landing() -> void:
	if is_on_floor() and not _was_on_floor:
		air_jumps_left = max_air_jumps   # reset mid-air jumps on landing
	_was_on_floor = is_on_floor()


# ── Gravity ──────────────────────────────
func _apply_gravity(delta: float) -> void:
	if is_hovering:
		# Hovering cancels gravity — slow downward drift only
		velocity.y = move_toward(velocity.y, -0.5, GRAVITY * delta * 0.15)
	elif not is_on_floor():
		velocity.y -= GRAVITY * delta


# ── Jump ─────────────────────────────────
func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		# Ground jump — always available
		_do_jump()
	elif air_jumps_left > 0:
		# Mid-air jump — requires strength fragment upgrades
		_do_jump()
		air_jumps_left -= 1


func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	is_hovering = false   # jumping cancels hover


# ── Hover ────────────────────────────────
func _handle_hover(delta: float) -> void:
	if is_on_floor():
		is_hovering = false
		hover_energy = minf(hover_energy + HOVER_RECHARGE_RATE * delta, HOVER_DURATION)
		return

	if Input.is_action_pressed("hover") and hover_energy > 0.0 and velocity.y < 0.0:
		is_hovering = true
		hover_energy -= delta
		if hover_energy <= 0.0:
			hover_energy = 0.0
			is_hovering = false
	else:
		is_hovering = false

	_emit_hover_ui_update()


# ── Horizontal movement ──────────────────
func _handle_movement() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis  := _get_camera_basis()
	var direction  := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED


func _get_camera_basis() -> Basis:
	var cam := get_viewport().get_camera_3d()
	if cam:
		return cam.global_transform.basis
	return Basis.IDENTITY


# ── Strength fragment pickup ─────────────
## Called by StrengthFragment when collected.
func collect_strength_fragment() -> void:
	max_air_jumps   += 1
	air_jumps_left   = max_air_jumps   # immediately usable
	_emit_jump_ui_update()


# ── UI signals (emits if HUD exists) ─────
func _emit_hover_ui_update() -> void:
	if _ui and _ui.has_method("update_hover"):
		_ui.update_hover(hover_energy, HOVER_DURATION)


func _emit_jump_ui_update() -> void:
	if _ui and _ui.has_method("update_jumps"):
		_ui.update_jumps(air_jumps_left, max_air_jumps)


# ── Getters (for HUD / other systems) ────
func get_hover_percent() -> float:
	return hover_energy / HOVER_DURATION


func get_jump_state() -> Dictionary:
	return {
		"max_air_jumps":  max_air_jumps,
		"air_jumps_left": air_jumps_left,
		"on_floor":       is_on_floor(),
	}
