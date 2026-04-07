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
#  Point d'entrée — appelé en tout début de _start() dans CombatManager,
#  AVANT le spawn des ennemis.
#  Retourne l'encounter à utiliser.
# ─────────────────────────────────────────────

## Retourne {encounter: CombatEncounter|null, scene: PackedScene|null}
## Si scene != null, CombatManager doit charger cette scène au lieu de spawner.
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
	var choice: int = await _dm_choice.choice_made  # 0 résister / 1 céder
	if choice == 0:
		return await _resist_branch()
	else:
		return await _give_in_branch()


func _resist_branch() -> Dictionary:
	await _play_simple(dialogue_resist_path)
	return {"encounter": boss_encounter, "scene": null}


func _give_in_branch() -> Dictionary:
	await _play_simple(dialogue_give_in_path)
	_gm.teamCorrupted = true

	# Charge directement la scène give_in sans passer par la logique du RoomResource
	if give_in_combat_scene != null:
		_gm.load_scene_direct(give_in_combat_scene, inquisition_encounter)
		# On retourne un signal "scène déjà chargée" pour que CombatManager s'arrête
		return {"encounter": null, "scene": null, "handled": true}

	return {"encounter": inquisition_encounter, "scene": give_in_combat_scene}


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

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
