extends Area3D

# ─────────────────────────────────────────
#  Strength Fragment
#  Collectible — grants the player +1 mid-air jump permanently.
#  Lore: shards of the ancient ruby civilization, still holding power.
# ─────────────────────────────────────────

## Emitted when collected. Connected to any listening systems (UI, save, audio).
signal collected(fragment: StrengthFragment)

@export var pulse_speed: float  = 1.4   # glow pulse rate
@export var bob_speed: float    = 0.9   # vertical float rate
@export var bob_height: float   = 0.18  # float amplitude

var _base_y: float
var _time:   float = 0.0

@onready var _mesh:           MeshInstance3D = $MeshInstance3D
@onready var _glow_material:  ShaderMaterial = $MeshInstance3D.get_surface_override_material(0)
@onready var _collect_sound:  AudioStreamPlayer3D = $CollectSound
@onready var _particles:      GPUParticles3D = $CollectParticles


func _ready() -> void:
	_base_y = global_position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	# Float bob
	global_position.y = _base_y + sin(_time * bob_speed) * bob_height
	# Glow pulse via shader param (material must expose "pulse_intensity")
	if _glow_material:
		_glow_material.set_shader_parameter(
			"pulse_intensity",
			0.6 + sin(_time * pulse_speed) * 0.4
		)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_collect(body)


func _collect(player: Node3D) -> void:
	# Grant the jump upgrade
	if player.has_method("collect_strength_fragment"):
		player.collect_strength_fragment()

	collected.emit(self)
	_play_collect_fx()
	# Hide mesh immediately, destroy after particles finish
	_mesh.visible = false
	set_deferred("monitoring", false)
	await get_tree().create_timer(1.2).timeout
	queue_free()


func _play_collect_fx() -> void:
	if _collect_sound:
		_collect_sound.play()
	if _particles:
		_particles.emitting = true
