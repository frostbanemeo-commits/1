extends Control
class_name StoryGuideMarker

# ═══════════════════════════════════════════════════════════════════
#  Story Guide Marker
#
#  A directional compass indicator — always points toward the next
#  main story waypoint. Visible at all times during the main story.
#  Disappears permanently when the story is complete.
#
#  Sits at the top-centre of the screen.
#  Rotates to show the horizontal direction to the objective.
#  Shows distance in whole kilometres.
#
#  Does NOT show if the objective is the current island
#  (you're already there — the story beat will trigger).
# ═══════════════════════════════════════════════════════════════════

@export var player:       Node3D
@export var travel_system: TravelSystem
@export var world_grid:   WorldGrid

@onready var _arrow:    TextureRect = $Arrow
@onready var _distance: Label       = $Distance

var _current_story_cell: WorldGrid.Cell = null
var _story_complete:      bool = false


func _ready() -> void:
	visible = true


func _process(_delta: float) -> void:
	if _story_complete or not player or not world_grid:
		visible = false
		return

	_update_target()

	if not _current_story_cell:
		visible = false
		return

	visible = true
	_update_arrow()
	_update_distance()


# ── Find next uncompleted story cell ─────────────────────────────
func _update_target() -> void:
	var story_cells := world_grid.story_cells()
	# Sort by story_index — find the first one not yet explored
	story_cells.sort_custom(func(a, b): return a.story_index < b.story_index)
	_current_story_cell = null
	for cell in story_cells:
		if cell.discovery != WorldGrid.DiscoveryState.EXPLORED:
			_current_story_cell = cell
			break


# ── Rotate arrow toward objective ─────────────────────────────────
func _update_arrow() -> void:
	if not _current_story_cell:
		return
	var player_xz := Vector2(player.global_position.x, player.global_position.z)
	var target    := _current_story_cell.world_centre()
	var target_xz := Vector2(target.x, target.z)
	var dir       := (target_xz - player_xz).normalized()
	var angle     := atan2(dir.x, -dir.y)   # screen-space rotation
	_arrow.rotation = angle


# ── Distance label ────────────────────────────────────────────────
func _update_distance() -> void:
	if not _current_story_cell:
		_distance.text = ""
		return
	var dist_m := player.global_position.distance_to(_current_story_cell.world_centre())
	if dist_m < 1000.0:
		_distance.text = "%d m" % int(dist_m)
	else:
		_distance.text = "%.1f km" % (dist_m / 1000.0)


# ── Called when story completes ────────────────────────────────────
func on_story_complete() -> void:
	_story_complete = true
	visible         = false
