extends Node
class_name AnimationController

# ═══════════════════════════════════════════════════════════════════
#  Animation Controller
#
#  Two call paths — enforced separately, cannot cross:
#
#    play_cinematic(id)  — called by the narrative/cutscene system.
#                          Validates CINEMATIC tier. Blocks player input.
#
#    play_emote(id)      — called by player input.
#                          Validates EMOTE tier + 3rd person requirement.
#                          Silently refuses in 1st person.
#
#  Gameplay animations (GAMEPLAY tier) are driven by the state machine
#  via play_gameplay(id) — not routed through either above path.
# ═══════════════════════════════════════════════════════════════════

signal animation_started(id: String, tier: int)
signal animation_finished(id: String)

@export var animation_player: AnimationPlayer
@export var perspective_node: Node   ## Assign PerspectiveManager

var _current_id:    String = ""
var _is_in_cutscene: bool  = false


# ── Cinematic path — narrative system only ────────────────────────
func play_cinematic(id: String) -> void:
	if not AnimationRegistry.is_cinematic(id):
		push_warning("AnimationController: '%s' is not a CINEMATIC animation." % id)
		return

	var anim := AnimationRegistry.get_anim(id)
	_play(id, anim)


# ── Emote path — player input only ───────────────────────────────
func play_emote(id: String) -> void:
	# Never available during cutscenes
	if _is_in_cutscene:
		return

	# Must be a registered EMOTE
	if not AnimationRegistry.is_player_callable(id):
		push_warning("AnimationController: '%s' is not player-callable." % id)
		return

	# Emotes are 3rd person only — silently refuse in 1st person
	if perspective_node and perspective_node.has_method("is_first_person"):
		if perspective_node.is_first_person():
			return

	var anim := AnimationRegistry.get_anim(id)
	_play(id, anim)


# ── Gameplay path — state machine only ───────────────────────────
func play_gameplay(id: String) -> void:
	if _is_in_cutscene:
		return
	var anim := AnimationRegistry.get_anim(id)
	if anim.is_empty():
		return
	_play(id, anim)


# ── Shared playback ───────────────────────────────────────────────
func _play(id: String, anim: Dictionary) -> void:
	if not animation_player:
		return

	var anim_path: String = anim.get("anim_path", "")
	if anim_path.is_empty():
		return

	# Interrupt current animation if allowed
	if _current_id != "":
		var current_def := AnimationRegistry.get_anim(_current_id)
		if not current_def.get("interruptible", true):
			return   # current animation refuses to be interrupted

	_current_id = id
	animation_player.play(anim_path)
	animation_started.emit(id, anim.get("tier", -1))

	# Auto-finish signal for fixed-duration animations
	var duration: float = anim.get("duration", 0.0)
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(
			func(): _on_animation_finished(id),
			CONNECT_ONE_SHOT
		)


func _on_animation_finished(id: String) -> void:
	if _current_id == id:
		_current_id = ""
	animation_finished.emit(id)


# ── Cutscene state ────────────────────────────────────────────────
func begin_cutscene() -> void:
	_is_in_cutscene = true


func end_cutscene() -> void:
	_is_in_cutscene = false


func is_in_cutscene() -> bool:
	return _is_in_cutscene


# ── Query ─────────────────────────────────────────────────────────
func current_animation() -> String:
	return _current_id


func is_playing(id: String) -> bool:
	return _current_id == id
