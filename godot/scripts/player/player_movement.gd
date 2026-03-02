extends CharacterBody3D

# ─────────────────────────────────────────
#  Player Movement — Cinder
#  Handles: movement, jumping, hover, glide, strength fragment upgrades
#
#  Jump progression:
#    Base:        1 jump (ground only)
#    +1 fragment: 2 total
#    +2 fragments: 3 total
#    +3 fragments: 4 total
#    +4 fragments: 5 total (MAX) → pressing jump again activates GLIDE
# ─────────────────────────────────────────

const MOVE_SPEED        := 6.0
const JUMP_VELOCITY     := 9.0
const GRAVITY           := 20.0

# ── Jump system ──────────────────────────
const MAX_AIR_JUMPS     := 4        # 4 fragments = 5 total jumps, hard cap
var   max_air_jumps: int = 0        # grows with fragments, never exceeds MAX_AIR_JUMPS
var   air_jumps_left: int = 0       # resets to max_air_jumps on landing

var _was_on_floor: bool  = false

# ── Glide system ─────────────────────────
# Unlocked when max_air_jumps == MAX_AIR_JUMPS (all 4 fragments collected).
# Activated by pressing jump after all jumps are spent while still airborne.
const GLIDE_GRAVITY     := 1.8      # much weaker than normal gravity
const GLIDE_SPEED_BOOST := 1.25     # slight horizontal speed increase while gliding
var   is_gliding: bool   = false

# ── Hover system ─────────────────────────
# Hover: hold jump while falling — slows descent, drains energy.
# Recharges only on the ground.
const HOVER_DURATION     := 1.8
const HOVER_RECHARGE_RATE := 0.4
var   hover_energy: float = HOVER_DURATION
var   is_hovering: bool   = false

# ── References ───────────────────────────
@onready var _ui: Node = get_tree().get_first_node_in_group("hud")


func _physics_process(delta: float) -> void:
	_handle_landing()
	_apply_gravity(delta)
	_handle_jump()
	_handle_hover(delta)
	_handle_movement()
	move_and_slide()


# ── Landing ──────────────────────────────
func _handle_landing() -> void:
	if is_on_floor() and not _was_on_floor:
		air_jumps_left = max_air_jumps
		is_gliding     = false
	_was_on_floor = is_on_floor()


# ── Gravity ──────────────────────────────
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if is_gliding:
		# Glide — very slow sink, horizontal speed preserved
		velocity.y = move_toward(velocity.y, -1.0, GLIDE_GRAVITY * delta)
	elif is_hovering:
		# Hover — gentle drift down, energy draining
		velocity.y = move_toward(velocity.y, -0.5, GRAVITY * delta * 0.15)
	else:
		velocity.y -= GRAVITY * delta


# ── Jump & Glide ─────────────────────────
func _handle_jump() -> void:
	# Glide — cancel on button release
	if is_gliding and not Input.is_action_pressed("jump"):
		is_gliding = false

	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		_do_jump()
		return

	if air_jumps_left > 0:
		# Mid-air jump — costs one air jump
		_do_jump()
		air_jumps_left -= 1
		return

	# All jumps spent — glide is always available as the final action
	if not is_gliding:
		_start_glide()


func _do_jump() -> void:
	velocity.y  = JUMP_VELOCITY
	is_gliding  = false
	is_hovering = false


func _start_glide() -> void:
	is_gliding  = true
	is_hovering = false
	# Clamp any upward velocity so glide always begins descending
	velocity.y  = minf(velocity.y, 0.0)


# ── Hover ────────────────────────────────
func _handle_hover(delta: float) -> void:
	if is_on_floor():
		is_hovering   = false
		hover_energy  = minf(hover_energy + HOVER_RECHARGE_RATE * delta, HOVER_DURATION)
		return

	# Glide overrides hover — don't run hover while gliding
	if is_gliding:
		is_hovering = false
		return

	if Input.is_action_pressed("hover") and hover_energy > 0.0 and velocity.y < 0.0:
		is_hovering   = true
		hover_energy -= delta
		hover_energy  = maxf(hover_energy, 0.0)
		if hover_energy <= 0.0:
			is_hovering = false
	else:
		is_hovering = false

	_emit_hover_ui_update()


# ── Horizontal movement ──────────────────
func _handle_movement() -> void:
	var speed      := MOVE_SPEED * (GLIDE_SPEED_BOOST if is_gliding else 1.0)
	var input_dir  := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis  := _get_camera_basis()
	var direction  := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x     = direction.x * speed
	velocity.z     = direction.z * speed


func _get_camera_basis() -> Basis:
	var cam := get_viewport().get_camera_3d()
	if cam:
		return cam.global_transform.basis
	return Basis.IDENTITY


# ── Strength fragment pickup ─────────────
## Called by StrengthFragment when collected.
func collect_strength_fragment() -> void:
	if max_air_jumps >= MAX_AIR_JUMPS:
		return   # already at cap
	max_air_jumps  += 1
	air_jumps_left  = max_air_jumps   # immediately usable
	_emit_jump_ui_update()


# ── UI callbacks ─────────────────────────
func _emit_hover_ui_update() -> void:
	if _ui and _ui.has_method("update_hover"):
		_ui.update_hover(hover_energy, HOVER_DURATION)


func _emit_jump_ui_update() -> void:
	if _ui and _ui.has_method("update_jumps"):
		_ui.update_jumps(air_jumps_left, max_air_jumps)


# ── Getters ──────────────────────────────
func get_hover_percent() -> float:
	return hover_energy / HOVER_DURATION


func get_jump_state() -> Dictionary:
	return {
		"max_air_jumps":   max_air_jumps,
		"air_jumps_left":  air_jumps_left,
		"is_gliding":      is_gliding,
		"is_hovering":     is_hovering,
		"on_floor":        is_on_floor(),
	}
