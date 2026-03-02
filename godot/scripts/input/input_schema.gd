extends RefCounted
class_name InputSchema

# ═══════════════════════════════════════════════════════════════════
#  Input Schema
#  All game actions defined in one place.
#  Register these in Godot's InputMap (Project Settings → Input Map)
#  or call InputSchema.register_all() at startup.
#
#  Keyboard/Mouse (PC primary)
#  Controller (Xbox/PS layout labelled by function)
# ═══════════════════════════════════════════════════════════════════

# Action name → default bindings
const ACTIONS: Dictionary = {

	# ── Movement ──────────────────────────────────────────────────
	"move_forward":  {"key": KEY_W,      "pad": JOY_AXIS_LEFT_Y,  "pad_dir": -1},
	"move_back":     {"key": KEY_S,      "pad": JOY_AXIS_LEFT_Y,  "pad_dir":  1},
	"move_left":     {"key": KEY_A,      "pad": JOY_AXIS_LEFT_X,  "pad_dir": -1},
	"move_right":    {"key": KEY_D,      "pad": JOY_AXIS_LEFT_X,  "pad_dir":  1},

	# ── Jump / glide ──────────────────────────────────────────────
	# Tap: jump. Hold after all jumps spent: glide.
	"jump":          {"key": KEY_SPACE,  "pad": JOY_BUTTON_A},

	# ── Cone blast ────────────────────────────────────────────────
	"blast":         {"mouse": MOUSE_BUTTON_LEFT, "pad": JOY_BUTTON_RIGHT_SHOULDER},

	# ── Interaction ───────────────────────────────────────────────
	"interact":      {"key": KEY_E,      "pad": JOY_BUTTON_X},

	# ── Ship controls ─────────────────────────────────────────────
	"ship_forward":  {"key": KEY_W,      "pad": JOY_AXIS_LEFT_Y,  "pad_dir": -1},   # same as move (context-sensitive)
	"ship_back":     {"key": KEY_S,      "pad": JOY_AXIS_LEFT_Y,  "pad_dir":  1},
	"ship_left":     {"key": KEY_A,      "pad": JOY_AXIS_LEFT_X,  "pad_dir": -1},
	"ship_right":    {"key": KEY_D,      "pad": JOY_AXIS_LEFT_X,  "pad_dir":  1},
	"ship_ascend":   {"key": KEY_SPACE,  "pad": JOY_BUTTON_A},
	"ship_descend":  {"key": KEY_C,      "pad": JOY_BUTTON_B},

	# ── Travel ────────────────────────────────────────────────────
	# Fly mode: open fast travel map
	"open_map":      {"key": KEY_M,      "pad": JOY_BUTTON_BACK},
	# Ship summon: whistle (hold briefly)
	"summon_ship":   {"key": KEY_F,      "pad": JOY_BUTTON_LEFT_SHOULDER},

	# ── Emote ─────────────────────────────────────────────────────
	# Opens emote wheel (3rd person only)
	"emote_wheel":   {"key": KEY_T,      "pad": JOY_BUTTON_Y},

	# ── Camera ────────────────────────────────────────────────────
	"cam_toggle":    {"key": KEY_V,      "pad": JOY_BUTTON_RIGHT_STICK},

	# ── Menus ─────────────────────────────────────────────────────
	"pause":         {"key": KEY_ESCAPE, "pad": JOY_BUTTON_START},

	# ── Debug (stripped in release builds) ───────────────────────
	"debug_toggle":  {"key": KEY_QUOTELEFT},   # backtick
}


# ── Register all actions into Godot's InputMap ────────────────────
static func register_all() -> void:
	for action_name in ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		var binding: Dictionary = ACTIONS[action_name]

		if binding.has("key"):
			var ev        := InputEventKey.new()
			ev.keycode     = binding["key"]
			InputMap.action_add_event(action_name, ev)

		if binding.has("mouse"):
			var ev        := InputEventMouseButton.new()
			ev.button_index = binding["mouse"]
			InputMap.action_add_event(action_name, ev)

		if binding.has("pad") and not binding.has("pad_dir"):
			var ev        := InputEventJoypadButton.new()
			ev.button_index = binding["pad"]
			InputMap.action_add_event(action_name, ev)

		if binding.has("pad") and binding.has("pad_dir"):
			var ev        := InputEventJoypadMotion.new()
			ev.axis        = binding["pad"]
			ev.axis_value  = binding["pad_dir"]
			InputMap.action_add_event(action_name, ev)
