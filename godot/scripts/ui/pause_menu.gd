extends Control
class_name PauseMenu

# ═══════════════════════════════════════════════════════════════════
#  Pause Menu
#  Opened by "pause" action (Escape / Start).
#  Pauses the game tree. Resumes on close.
#
#  Options:
#    Resume
#    Save Game       → saves to current slot, shows confirmation
#    Settings        → inline options panel
#    Return to Menu  → confirm → main menu (unsaved progress lost)
#    Quit to Desktop → confirm → exit
# ═══════════════════════════════════════════════════════════════════

signal save_requested()
signal return_to_menu_requested()

@onready var _main_panel:     Control = $MainPanel
@onready var _settings_panel: Control = $SettingsPanel
@onready var _confirm_panel:  Control = $ConfirmPanel
@onready var _save_confirm:   Label   = $SaveConfirmLabel   # "Saved." flash

@onready var _btn_resume:     Button = $MainPanel/BtnResume
@onready var _btn_save:       Button = $MainPanel/BtnSave
@onready var _btn_settings:   Button = $MainPanel/BtnSettings
@onready var _btn_menu:       Button = $MainPanel/BtnReturnToMenu
@onready var _btn_quit:       Button = $MainPanel/BtnQuit


func _ready() -> void:
	visible = false
	_btn_resume.pressed.connect(close)
	_btn_save.pressed.connect(_on_save)
	_btn_settings.pressed.connect(_on_settings)
	_btn_menu.pressed.connect(_on_return_to_menu)
	_btn_quit.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		if visible:
			close()
		else:
			open()


# ── Open / close ──────────────────────────────────────────────────
func open() -> void:
	visible = true
	get_tree().paused = true
	_show_only(_main_panel)
	_btn_resume.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


# ── Handlers ──────────────────────────────────────────────────────
func _on_save() -> void:
	save_requested.emit()
	_flash_save_confirm()


func _flash_save_confirm() -> void:
	_save_confirm.visible = true
	_save_confirm.text    = "Game saved."
	await get_tree().create_timer(1.5).timeout
	_save_confirm.visible = false


func _on_settings() -> void:
	_show_only(_settings_panel)


func _on_return_to_menu() -> void:
	_show_only(_confirm_panel)
	_confirm_panel.get_node("Label").text = "Return to main menu?\nUnsaved progress will be lost."
	var btn_yes: Button = _confirm_panel.get_node("BtnYes")
	var btn_no:  Button = _confirm_panel.get_node("BtnNo")
	btn_yes.pressed.connect(
		func():
			get_tree().paused = false
			return_to_menu_requested.emit(),
		CONNECT_ONE_SHOT
	)
	btn_no.pressed.connect(func(): _show_only(_main_panel), CONNECT_ONE_SHOT)


func _on_quit() -> void:
	_show_only(_confirm_panel)
	_confirm_panel.get_node("Label").text = "Quit to desktop?\nUnsaved progress will be lost."
	var btn_yes: Button = _confirm_panel.get_node("BtnYes")
	var btn_no:  Button = _confirm_panel.get_node("BtnNo")
	btn_yes.pressed.connect(func(): get_tree().quit(), CONNECT_ONE_SHOT)
	btn_no.pressed.connect(func(): _show_only(_main_panel), CONNECT_ONE_SHOT)


func _show_only(panel: Control) -> void:
	for child in get_children():
		if child is Control and child != _save_confirm:
			child.visible = (child == panel)
