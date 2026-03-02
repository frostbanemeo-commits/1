extends RefCounted
class_name CargoItem

# ═══════════════════════════════════════════════════════════════════
#  Cargo Item
#
#  Any object that can be carried in the ship's hold.
#
#  FRAGILE items are destroyed by fast travel (teleportation).
#  Teleportation skips the physical journey through space —
#  fragile cargo requires that continuous physical path to survive.
#
#  Lore basis:
#    Ruby artifacts and primal cluster objects are bound to the
#    physical space they move through. Teleportation severs that
#    thread. The cluster's soul record loses its spatial continuity
#    and the item collapses — the purple origin disconnects.
#
#  Fragile cargo = the game's instruction to sail this leg.
#  You CAN teleport with fragile cargo. You will lose it.
# ═══════════════════════════════════════════════════════════════════

enum Category {
	GENERAL,      # tools, resources, goods — survives teleport
	FRAGILE,      # destroyed by fast travel
	LIVING,       # creatures, plants — fragile + time-sensitive
	CONTRABAND,   # empire-restricted — risky to carry
	MISSION,      # quest item — may or may not be fragile
}

var id:           String      # unique item type id
var display_name: String
var category:     Category
var fragile:      bool        # true = destroyed by fast travel
var fragile_reason: String    # shown in the fast travel warning
var quantity:     int = 1
var mission_id:   String = "" # which mission this belongs to (if any)
var condition:    float = 1.0 # 1.0 = perfect, 0.0 = destroyed


func _init(
		item_id:   String,
		name:      String,
		cat:       Category,
		is_fragile: bool = false,
		reason:    String = "") -> void:
	id             = item_id
	display_name   = name
	category       = cat
	fragile        = is_fragile
	fragile_reason = reason if reason != "" else _default_reason(cat)


func is_destroyed() -> bool:
	return condition <= 0.0


func destroy() -> void:
	condition = 0.0


static func _default_reason(cat: Category) -> String:
	match cat:
		Category.FRAGILE:
			return "Teleportation severs the spatial thread this object requires."
		Category.LIVING:
			return "Living cargo cannot survive the discontinuity of teleportation."
		_:
			return "This item cannot survive fast travel."
