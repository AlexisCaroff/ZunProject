extends CanvasLayer
class_name SaveMenu
# ════════════════════════════════════════════════════════════════════
#  ÉCRAN DE SAUVEGARDE / CHARGEMENT
# ════════════════════════════════════════════════════════════════════
#  Instancié une fois dans game_manager.tscn, il sert les deux usages :
#    • Mode.SAVE — ouvert par le bouton du GameManager, propose les 3 slots
#      manuels (le slot automatique est en lecture seule).
#    • Mode.LOAD — ouvert depuis le menu principal, propose les 4 slots.
#
#  Les lignes de slot sont construites par code : la mise en page ne dépend
#  que du nombre de slots déclaré dans SaveManager.
# ════════════════════════════════════════════════════════════════════

enum Mode { SAVE, LOAD }

@onready var panel: Panel            = $Panel
@onready var title: Label            = $Panel/Margin/VBox/Title
@onready var slot_list: VBoxContainer = $Panel/Margin/VBox/SlotList
@onready var status: Label           = $Panel/Margin/VBox/Status
@onready var close_button: Button    = $Panel/Margin/VBox/ButtonClose

var gm: GameManager
var _mode: int = Mode.SAVE
## Slot occupé attendant une seconde confirmation avant écrasement.
var _armed_slot: int = -1
var _slot_buttons: Array[Button] = []
## Valeur de GameState.Pause avant ouverture, pour ne pas relancer un combat
## qui était déjà en pause pour une autre raison.
var _pause_before: bool = false


func _ready() -> void:
	gm = get_parent() as GameManager
	close_button.pressed.connect(hide_menu)
	_build_slot_buttons()
	visible = false


func _build_slot_buttons() -> void:
	for child in slot_list.get_children():
		child.queue_free()
	_slot_buttons.clear()

	for slot in SaveManager.SLOT_COUNT:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 92)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_on_slot_pressed.bind(slot))
		slot_list.add_child(b)
		_slot_buttons.append(b)


# ════════════════════════════════════════════════════════════════════
#  OUVERTURE / FERMETURE
# ════════════════════════════════════════════════════════════════════

func open(mode: int) -> void:
	_mode = mode
	_armed_slot = -1
	title.text = "Save Game" if mode == Mode.SAVE else "Load Game"
	status.text = ""
	_refresh()
	visible = true
	# Gèle la boucle de combat et l'exploration pendant que le menu est ouvert.
	_pause_before = GameState.Pause
	GameState.Pause = true


func hide_menu() -> void:
	visible = false
	_armed_slot = -1
	GameState.Pause = _pause_before


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_menu()
		get_viewport().set_input_as_handled()


# ════════════════════════════════════════════════════════════════════
#  AFFICHAGE
# ════════════════════════════════════════════════════════════════════

func _refresh() -> void:
	for slot in _slot_buttons.size():
		var button := _slot_buttons[slot]
		var info: Dictionary = SaveManager.get_slot_info(slot)
		button.text = _slot_text(slot, info)
		button.disabled = _slot_disabled(slot, info)
		button.modulate.a = 0.45 if button.disabled else 1.0


func _slot_disabled(slot: int, info: Dictionary) -> bool:
	if SaveManager.is_busy():
		return true
	if _mode == Mode.LOAD:
		return info.is_empty()          # rien à charger
	return not SaveManager.is_manual_slot(slot)   # l'autosave n'est pas écrasable à la main


func _slot_text(slot: int, info: Dictionary) -> String:
	var label: String = "Auto" if slot == SaveManager.AUTO_SLOT else "Slot %d" % slot
	if info.is_empty():
		return "%s  —  empty" % label
	if slot == _armed_slot:
		return "%s  —  overwrite? click again" % label

	var room := str(info.get("room_id", "?"))
	var kind := _kind_label(str(info.get("scene_kind", "")))
	var date := str(info.get("date", ""))
	var line := "%s  —  %s · %s · %s" % [label, room, kind, date]

	var party := []
	for p in info.get("party", []):
		party.append("%s %d/%d" % [
			str(p.get("name", "?")),
			int(p.get("stamina", 0)),
			int(p.get("max_stamina", 0)),
		])
	if not party.is_empty():
		line += "\n" + "   ".join(party)
	return line


func _kind_label(kind: String) -> String:
	if kind == SaveManager.SCENE_DOOR:
		return "Door"
	if kind == SaveManager.SCENE_COMBAT:
		return "Combat"
	if kind == SaveManager.SCENE_CAMP:
		return "Camp"
	return "Exploration"


# ════════════════════════════════════════════════════════════════════
#  ACTIONS
# ════════════════════════════════════════════════════════════════════

func _on_slot_pressed(slot: int) -> void:
	if gm == null or SaveManager.is_busy():
		return

	if _mode == Mode.LOAD:
		status.text = "Loading…"
		hide_menu()
		gm.load_game(slot)
		return

	# Sauvegarde : un slot déjà occupé demande une seconde confirmation.
	if not SaveManager.get_slot_info(slot).is_empty() and _armed_slot != slot:
		_armed_slot = slot
		_refresh()
		status.text = "This slot already holds a save."
		return

	_armed_slot = -1
	var ok: bool = gm.save_to_slot(slot)
	status.text = ("Saved to slot %d." % slot) if ok else "Save failed."
	_refresh()
