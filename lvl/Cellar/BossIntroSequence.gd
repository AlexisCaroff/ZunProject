extends Node
class_name BossIntroSequence

# ─────────────────────────────────────────────
#  Exports — à remplir dans l'inspecteur
# ─────────────────────────────────────────────

@export var intro_animatic: Animatic
@export var portraits_resource: PortraitsResource

@export var choice_resist_label: String  = "Résister !"
@export var choice_give_in_label: String = "Céder..."

@export var boss_encounter: CombatEncounter
@export var inquisition_encounter: CombatEncounter
## Scène de combat chargée si le joueur résiste (remplace entièrement la scène courante)
@export var resist_combat_scene: PackedScene
## Scène de combat chargée si le joueur cède (remplace entièrement la scène courante)
@export var give_in_combat_scene: PackedScene

@export_file("*.txt") var dialogue_intro_path:   String = "res://dialogues/boss/intro.txt"
@export_file("*.txt") var dialogue_corrupt_path:  String = "res://dialogues/boss/corrupt.txt"
@export_file("*.txt") var dialogue_resist_path:   String = "res://dialogues/boss/resist.txt"
@export_file("*.txt") var dialogue_give_in_path:  String = "res://dialogues/boss/give_in.txt"
@export var no_portrait_speakers: Array[String] = ["Narrator"]
@export var portrait_aliases: Dictionary = {"Hooded figure": "Inquisitor", "Inquisitor.": "Inquisitor"}
## Slots absents du layout initial — entrent dynamiquement quand leur speaker parle.
@export var late_entry_slots: Array[String] = ["Inquisitor"]

## ── Layout custom pour la scène GIVE-IN ──
## Liste des slots du DialogueUI à utiliser (dans l'ordre d'affectation).
## Layout par défaut souhaité : Inquisitor en gauche (slot 0),
## Priestess centre-gauche (slot 1), Broodmother à droite (slot 3).
## Le slot 2 (centre-droite) reste vide.
@export var give_in_slot_layout: Array[int] = [0, 1, 3]

## Mapping speaker → index logique dans give_in_slot_layout.
## Exemple par défaut :
##   "Inquisitor" → 0 (donc slot 0 = gauche)
##   "Priestess"  → 1 (donc slot 1 = centre-gauche)
##   "Broodmother"→ 2 (donc slot 3 = droite, car layout[2] = 3)
@export var give_in_slot_overrides: Dictionary = {
	"Inquisitor": 0,
	"Priestess":  1,
	"Broodmother": 2,
}

@export var debug_force_corrupt: bool = false

# ─────────────────────────────────────────────
#  Internes
# ─────────────────────────────────────────────

var _dm_simple: DialogueManager
var _dm_choice: DialogueManager
var _gm: GameManager
var _canvas: CanvasLayer   # les DM vivent ici pour passer au-dessus du combat UI


func _ready() -> void:
	_gm = get_tree().root.get_node("GameManager") as GameManager
	_build_dialogue_managers()


# ─────────────────────────────────────────────
#  Point d'entrée
# ─────────────────────────────────────────────

func run_sequence(cam: Camera2D) -> Dictionary:

	# 1 ── Animatique d'intro
	if intro_animatic:
		var overlay = _gm.show_Animatic_scene(intro_animatic, cam)
		await overlay.finished

	# 2 ── Dialogue d'introduction
	await _play_simple(dialogue_intro_path)

	# 3 ── Branchement corruption
	if debug_force_corrupt or _has_cursed_items():
		return await _corrupt_branch()
	else:
		return await _resist_branch()


# ─────────────────────────────────────────────
#  Branches
# ─────────────────────────────────────────────

func _corrupt_branch() -> Dictionary:
	_dm_choice.load_dialogue(dialogue_corrupt_path)
	await _gm.sceneTransition.fade_out()
	_dm_choice.start_dialogue()
	await get_tree().create_timer(.2).timeout
	await _gm.sceneTransition.fade_in()
	var choice: int = await _dm_choice.choice_made
	if choice == 0:
		return await _resist_branch()
	else:
		return await _give_in_branch()


func _resist_branch() -> Dictionary:
	await _play_simple(dialogue_resist_path)

	if resist_combat_scene != null:
		_gm.load_scene_direct(resist_combat_scene, boss_encounter)
		return {"encounter": null, "scene": null, "handled": true}

	return {"encounter": boss_encounter, "scene": null}


func _give_in_branch() -> Dictionary:
	# Layout custom : Inquisitor à gauche, Priestess centre-gauche,
	# Broodmother à droite (slot 3, on saute le centre-droite).
	_apply_give_in_layout(_dm_simple)

	await _play_simple(dialogue_give_in_path)
	_gm.teamCorrupted = true

	# Charge directement la scène give_in sans passer par RoomResource
	if give_in_combat_scene != null:
		_gm.load_scene_direct(give_in_combat_scene, inquisition_encounter)
		return {"encounter": null, "scene": null, "handled": true}

	return {"encounter": inquisition_encounter, "scene": give_in_combat_scene}


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

## Configure le DialogueManager pour le layout give-in :
##   - liste de slots visibles
##   - mapping speaker → index logique
##
## ⚠ Requiert que DialogueManager.gd ait deux propriétés :
##   var slot_layout: Array[int]      # passe à DialogueUI.setup_layout_explicit()
##   var slot_overrides: Dictionary   # speaker name → index dans slot_layout
##
## Si tes propriétés s'appellent différemment, adapte les deux lignes
## d'assignation ci-dessous.
func _apply_give_in_layout(dm: DialogueManager) -> void:
	if dm == null:
		return
	if "slot_layout" in dm:
		dm.slot_layout = give_in_slot_layout.duplicate()
	if "slot_overrides" in dm:
		dm.slot_overrides = give_in_slot_overrides.duplicate()


func _play_simple(file_path: String) -> void:
	_dm_simple.load_dialogue(file_path)
	_dm_simple.start_dialogue()
	await _dm_simple.dialogue_finished


func _has_cursed_items() -> bool:
	for chara: CharacterData in _gm.characters:
		for item: Equipment in chara.equipped_items:
			if item.get("isCursed") == true:
				return true
	return false


func _build_dialogue_managers() -> void:
	# CanvasLayer dédié — layer élevé pour passer au-dessus du combat UI
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)

	# DialogueManager simple (intro, résistance, reddition)
	_dm_simple = DialogueManager.new()
	_dm_simple.portraits_resource = portraits_resource
	_dm_simple.no_portrait_speakers = no_portrait_speakers
	_dm_simple.portrait_aliases     = portrait_aliases
	_dm_simple.late_entry_slots     = late_entry_slots
	_canvas.add_child(_dm_simple)

	# DialogueManager avec choix (corruption)
	_dm_choice = DialogueManager.new()
	_dm_choice.portraits_resource = portraits_resource
	_dm_choice.is_Choice    = true
	_dm_choice.text_choice1 = choice_resist_label
	_dm_choice.text_choice2 = choice_give_in_label
	_canvas.add_child(_dm_choice)
