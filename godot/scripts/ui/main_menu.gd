extends Control
class_name MainMenu

# ═══════════════════════════════════════════════════════════════════
#  Main Menu
#
#  Screen order:
#    Title screen → fade in → main options
#    Continue      → slot picker (if multiple saves exist)
#    New Game      → slot picker → world gen → character creation
#    Settings      → options panel
#    Quit          → confirm → exit
#
#  Visual: dark sky, slow atmospheric drift, title in white/purple.
#  No flashy animations — quiet and heavy, like the world.
# ═══════════════════════════════════════════════════════════════════

signal new_game_requested(slot: int, world_seed: int)
signal continue_requested(slot: int, data: SaveData)

@onready var _title_screen:  Control = $TitleScreen
@onready var _main_panel:    Control = $MainPanel
@onready var _slot_panel:    Control = $SlotPanel
@onready var _settings_panel: Control = $SettingsPanel
@onready var _confirm_panel: Control = $ConfirmPanel

@onready var _btn_continue:  Button = $MainPanel/BtnContinue
@onready var _btn_new_game:  Button = $MainPanel/BtnNewGame
@onready var _btn_settings:  Button = $MainPanel/BtnSettings
@onready var _btn_quit:      Button = $MainPanel/BtnQuit

@onready var _slot_buttons:  Array  = [
	$SlotPanel/Slot0,
	$SlotPanel/Slot1,
	$SlotPanel/Slot2,
]

@onready var _save_system:   SaveSystem = $SaveSystem

var _pending_action: String = ""   # "new_game" or "continue"


func _ready() -> void:
	InputSchema.register_all()
	_show_only(_title_screen)
	_setup_buttons()
	_refresh_slots()

	# Fade from black into title
	_title_screen.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_title_screen, "modulate:a", 1.0, 1.8)
	tween.tween_callback(_on_title_ready)


func _on_title_ready() -> void:
	# Brief hold on title, then reveal main panel
	await get_tree().create_timer(0.8).timeout
	_show_only(_main_panel)


# ── Button setup ──────────────────────────────────────────────────
func _setup_buttons() -> void:
	_btn_continue.pressed.connect(_on_continue)
	_btn_new_game.pressed.connect(_on_new_game)
	_btn_settings.pressed.connect(_on_settings)
	_btn_quit.pressed.connect(_on_quit)

	for i in _slot_buttons.size():
		var btn: Button = _slot_buttons[i]
		btn.pressed.connect(_on_slot_selected.bind(i))


func _refresh_slots() -> void:
	var any_save := false
	for i in SaveSystem.SLOTS:
		var meta: Dictionary = _save_system.slot_meta()[i]
		var btn:  Button     = _slot_buttons[i]

		if meta["exists"]:
			any_save = true
			var pt   := int(meta["play_time"] / 60)
			btn.text  = "Slot %d — %s  (%d min)" % [i + 1, meta["timestamp"], pt]
		else:
			btn.text  = "Slot %d — Empty" % (i + 1)

	_btn_continue.disabled = not any_save


# ── Button handlers ───────────────────────────────────────────────
func _on_continue() -> void:
	_pending_action = "continue"
	_show_only(_slot_panel)
	# Only show occupied slots
	for i in SaveSystem.SLOTS:
		_slot_buttons[i].visible = _save_system.slot_exists(i)


func _on_new_game() -> void:
	_pending_action = "new_game"
	_show_only(_slot_panel)
	for btn in _slot_buttons:
		btn.visible = true


func _on_slot_selected(slot: int) -> void:
	if _pending_action == "continue":
		var data := _save_system.load_slot(slot)
		if data:
			continue_requested.emit(slot, data)

	elif _pending_action == "new_game":
		if _save_system.slot_exists(slot):
			_confirm_overwrite(slot)
		else:
			_start_new_game(slot)


func _confirm_overwrite(slot: int) -> void:
	_show_only(_confirm_panel)
	var btn_yes: Button = _confirm_panel.get_node("BtnYes")
	var btn_no:  Button = _confirm_panel.get_node("BtnNo")
	btn_yes.pressed.connect(func(): _start_new_game(slot), CONNECT_ONE_SHOT)
	btn_no.pressed.connect(func(): _show_only(_slot_panel),  CONNECT_ONE_SHOT)


func _start_new_game(slot: int) -> void:
	var seed := _generate_world_seed()
	new_game_requested.emit(slot, seed)


func _on_settings() -> void:
	_show_only(_settings_panel)


func _on_quit() -> void:
	_show_only(_confirm_panel)
	_confirm_panel.get_node("Label").text = "Quit to desktop?"
	var btn_yes: Button = _confirm_panel.get_node("BtnYes")
	var btn_no:  Button = _confirm_panel.get_node("BtnNo")
	btn_yes.pressed.connect(func(): get_tree().quit(), CONNECT_ONE_SHOT)
	btn_no.pressed.connect(func(): _show_only(_main_panel), CONNECT_ONE_SHOT)


# ── Helpers ───────────────────────────────────────────────────────
func _show_only(panel: Control) -> void:
	for child in get_children():
		if child is Control:
			child.visible = (child == panel)


func _generate_world_seed() -> int:
	return randi()   # random each new game — deterministic from that point
