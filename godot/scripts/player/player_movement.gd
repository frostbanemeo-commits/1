extends CharacterBody3D

# ─────────────────────────────────────────
#  Player Movement — Cinder
#
#  Jump progression (strength fragments):
#    Base:         1 jump → GLIDE
#    +1 fragment:  2 jumps → GLIDE
#    +2 fragments: 3 jumps → GLIDE
#    +3 fragments: 4 jumps → GLIDE
#    +4 fragments: 5 jumps → GLIDE  (MAX)
#
#  Glide: hold jump after all jumps spent.
#  Gravity is the only limiter — no bar, no energy.
# ─────────────────────────────────────────

const MOVE_SPEED    := 6.0
const JUMP_VELOCITY := 9.0
const GRAVITY       := 20.0

# ── Jump system ──────────────────────────
const MAX_AIR_JUMPS  := 4       # 4 fragments = 5 total jumps, hard cap
var max_air_jumps: int  = 0
var air_jumps_left: int = 0

var _was_on_floor: bool = false

# ── Glide system ─────────────────────────
# Glide = hold jump after all jumps spent.
# Natural gravity descent is the limiter — no energy bar.
const GLIDE_GRAVITY     := 2.2   # weak downward pull while gliding
const GLIDE_SPEED_BOOST := 1.2   # slight horizontal boost while gliding
var is_gliding: bool = false

# ── References ───────────────────────────
@onready var _ui: Node = get_tree().get_first_node_in_group("hud")


func _physics_process(delta: float) -> void:
	_handle_landing()
	_apply_gravity(delta)
	_handle_jump()
	_handle_glide_release()
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
		# Glide — slow sink, player still descends
		velocity.y = move_toward(velocity.y, -1.5, GLIDE_GRAVITY * delta)
	else:
		velocity.y -= GRAVITY * delta


# ── Jump ─────────────────────────────────
func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		_do_jump()
	elif air_jumps_left > 0:
		_do_jump()
		air_jumps_left -= 1
	elif not is_gliding:
		# All jumps spent — begin glide
		_start_glide()


# ── Glide release ─────────────────────────
func _handle_glide_release() -> void:
	if is_gliding and not Input.is_action_pressed("jump"):
		is_gliding = false


# ── Jump / glide helpers ─────────────────
func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	is_gliding = false


func _start_glide() -> void:
	is_gliding = true
	velocity.y = minf(velocity.y, 0.0)   # glide always starts descending


# ── Horizontal movement ──────────────────
func _handle_movement() -> void:
	var speed     := MOVE_SPEED * (GLIDE_SPEED_BOOST if is_gliding else 1.0)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := _get_camera_basis()
	var direction := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _get_camera_basis() -> Basis:
	var cam := get_viewport().get_camera_3d()
	return cam.global_transform.basis if cam else Basis.IDENTITY


# ── Strength fragment pickup ─────────────
func collect_strength_fragment() -> void:
	if max_air_jumps >= MAX_AIR_JUMPS:
		return
	max_air_jumps  += 1
	air_jumps_left  = max_air_jumps
	if _ui and _ui.has_method("update_jumps"):
		_ui.update_jumps(air_jumps_left, max_air_jumps)


# ── Getters ──────────────────────────────
func get_jump_state() -> Dictionary:
	return {
		"max_air_jumps":  max_air_jumps,
		"air_jumps_left": air_jumps_left,
		"is_gliding":     is_gliding,
		"on_floor":       is_on_floor(),
	}
