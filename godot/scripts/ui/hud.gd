extends Control
class_name HUD

# ═══════════════════════════════════════════════════════════════════
#  HUD — Heads Up Display
#
#  Layout (all anchored, resolution-independent):
#
#  ┌─────────────────────────────────────────────────┐
#  │  [STORY GUIDE ▲ 2.4 km]          [MINIMAP 32px] │  ← top
#  │                                                   │
#  │                    [CROSSHAIR]                    │  ← centre
#  │                                                   │
#  │  [JUMP PIPS ○●●]   [BLAST ████░]  [FRAGILE ⚠]   │  ← bottom
#  └─────────────────────────────────────────────────┘
#
#  Elements:
#    Story guide marker  top-centre    (StoryGuideMarker — already built)
#    Island minimap      top-right     (IslandMinimap — already built)
#    Crosshair           screen-centre (simple dot, hidden in 3rd person)
#    Jump pips           bottom-left   (pip per available jump, grey when spent)
#    Blast cooldown bar  bottom-centre (fills as cooldown recovers)
#    Fragile cargo icon  bottom-right  (warning icon if fragile in hold)
#    Ship summon hint    bottom-right  (F / LB — visible when summon available)
# ═══════════════════════════════════════════════════════════════════

@export var player_movement: Node    ## PlayerMovement
@export var cone_blast:      Node    ## ConeBlast
@export var travel_system:   TravelSystem
@export var cargo_hold:      CargoHold

@onready var _crosshair:        Control   = $Crosshair
@onready var _jump_pips:        HBoxContainer = $BottomLeft/JumpPips
@onready var _blast_bar:        ProgressBar   = $BottomCentre/BlastCooldown
@onready var _fragile_icon:     TextureRect   = $BottomRight/FragileIcon
@onready var _summon_hint:      Label         = $BottomRight/SummonHint
@onready var _fly_mode_hint:    Label         = $BottomRight/FlyModeHint

const PIP_ON_COLOUR  := Color(1.0,  1.0,  1.0, 1.0)
const PIP_OFF_COLOUR := Color(0.3,  0.3,  0.3, 0.6)
const PRIMAL_PURPLE  := Color(0.482, 0.184, 0.745, 1.0)   # #7B2FBE

var _pip_nodes: Array = []


func _ready() -> void:
	_build_jump_pips()
	_fragile_icon.visible  = false
	_summon_hint.visible   = false
	_fly_mode_hint.visible = false


func _process(_delta: float) -> void:
	_update_jumps()
	_update_blast()
	_update_fragile()
	_update_travel_hints()


# ── Jump pips ─────────────────────────────────────────────────────
# One pip per max jump. Lit = available. Dark = spent.
# Always shows at least 1 pip (the ground jump).
func _build_jump_pips() -> void:
	for child in _jump_pips.get_children():
		child.queue_free()
	_pip_nodes.clear()

	for _i in 5:   # max possible jumps
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10, 10)
		pip.color               = PIP_OFF_COLOUR
		_jump_pips.add_child(pip)
		_pip_nodes.append(pip)
		pip.visible = false


func _update_jumps() -> void:
	if not player_movement:
		return
	var state      := player_movement.get_jump_state()
	var max_j      := state["max_air_jumps"] + 1   # +1 for ground jump
	var left       := state["air_jumps_left"] + (1 if state["on_floor"] else 0)
	var is_gliding := state["is_gliding"]

	for i in _pip_nodes.size():
		var pip: ColorRect = _pip_nodes[i]
		pip.visible = (i < max_j)
		if is_gliding:
			pip.color = PRIMAL_PURPLE   # gliding = primal trace
		elif i < left:
			pip.color = PIP_ON_COLOUR
		else:
			pip.color = PIP_OFF_COLOUR


# ── Blast cooldown ────────────────────────────────────────────────
func _update_blast() -> void:
	if not cone_blast:
		return
	_blast_bar.value = cone_blast.get_cooldown_percent() * 100.0


# ── Fragile cargo warning ─────────────────────────────────────────
func _update_fragile() -> void:
	if not cargo_hold:
		_fragile_icon.visible = false
		return
	_fragile_icon.visible = cargo_hold.has_fragile_cargo()


# ── Travel ability hints ──────────────────────────────────────────
func _update_travel_hints() -> void:
	if not travel_system:
		return
	_summon_hint.visible  = travel_system.has_ship_summon()
	_fly_mode_hint.visible = travel_system.has_fly_mode() and not travel_system.has_ship_summon()


# ── Crosshair ─────────────────────────────────────────────────────
func set_first_person(is_first_person: bool) -> void:
	_crosshair.visible = is_first_person


# ── Called by PlayerMovement on fragment collect ──────────────────
func update_jumps(jumps_left: int, max_jumps: int) -> void:
	pass   # handled in _update_jumps() via get_jump_state() each frame
