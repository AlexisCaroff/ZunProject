extends Node
class_name BossSceneController

# --- Animatic ---
@export var animatic: Animatic

# --- Dialogues (fichiers .txt) ---
@export_file("*.txt") var dialogue_intro_path: String = ""
@export_file("*.txt") var dialogue_corrupt_path: String = ""
@export_file("*.txt") var dialogue_resist_path: String = ""
@export_file("*.txt") var dialogue_give_in_path: String = ""

# --- Portraits pour le DialogueManager ---
@export var portraits_resource: PortraitsResource

# --- Combats ---
@export var boss_encounter: CombatEncounter
@export var inquisition_encounter: CombatEncounter

# --- Seuil de corruption (moyenne du groupe) ---
@export var corruption_threshold: int = 30

# --- Références internes ---
var _combat_manager: Node  # ton CombatManager existant
var _animatic_player: AnimaticPlayer
var _dialogue_manager: DialogueManager

func _ready() -> void:
	_combat_manager = get_parent().find_child("CombatManager", true, false)
	if _combat_manager == null:
		push_error("BossSceneController : CombatManager introuvable")
		return
	_start_sequence()

# -------------------------------------------------------
# SÉQUENCE PRINCIPALE
# -------------------------------------------------------

func _start_sequence() -> void:
	await _play_animatic()
	if _is_party_corrupt():
		await _run_corrupt_path()
	else:
		await _run_normal_path()

func _is_party_corrupt() -> bool:
	var gm := _get_game_manager()
	if gm == null or gm.characters.is_empty():
		return false
	var total := 0
	for c: CharacterData in gm.characters:
		total += c.corruption
	return (total / gm.characters.size()) >= corruption_threshold

# -------------------------------------------------------
# CHEMINS NARRATIFS
# -------------------------------------------------------

func _run_normal_path() -> void:
	await _play_dialogue(dialogue_intro_path, false)
	_start_combat(boss_encounter, false, false)

func _run_corrupt_path() -> void:
	# Dialogue intro + extension corrompue enchaînés
	await _play_dialogue(dialogue_intro_path, false)
	
	var gave_in := await _play_dialogue_with_choice(dialogue_corrupt_path)
	
	if gave_in:
		await _play_dialogue(dialogue_give_in_path, false)
		var gm := _get_game_manager()
		for chara in gm.characters:
			chara.corrupted=true
		_start_combat(inquisition_encounter, true, false)  # héros embusqués par l'inquisition
	else:
		await _play_dialogue(dialogue_resist_path, false)
		_start_combat(boss_encounter, false, false)

# -------------------------------------------------------
# ANIMATIC
# -------------------------------------------------------

func _play_animatic() -> void:
	var animatic_scene := preload("res://animatic/animatic_scene.tscn")
	_animatic_player = animatic_scene.instantiate()
	_animatic_player.animatic = animatic
	get_tree().current_scene.add_child(_animatic_player)
	await _animatic_player.finished

# -------------------------------------------------------
# DIALOGUE
# -------------------------------------------------------

func _play_dialogue(path: String, has_choice: bool) -> void:
	if path.is_empty():
		return
	_dialogue_manager = _create_dialogue_manager(has_choice)
	_dialogue_manager.load_dialogue(path)
	_dialogue_manager.start_dialogue()
	await _dialogue_manager.dialogue_finished
	_dialogue_manager.queue_free()
	_dialogue_manager = null

## Retourne true si le joueur a choisi "rejoindre" (index 1), false pour "résister" (index 0)
func _play_dialogue_with_choice(path: String) -> bool:
	if path.is_empty():
		return false
	_dialogue_manager = _create_dialogue_manager(true)
	_dialogue_manager.load_dialogue(path)
	_dialogue_manager.start_dialogue()

	var choice_index := -1
	_dialogue_manager.choice_made.connect(func(i): choice_index = i)
	await _dialogue_manager.choice_made
	_dialogue_manager.queue_free()
	_dialogue_manager = null
	return choice_index == 1

func _create_dialogue_manager(has_choice: bool) -> DialogueManager:
	var dm := DialogueManager.new()
	dm.portraits_resource = portraits_resource
	dm.is_Choice = has_choice
	if has_choice:
		dm.text_choice1 = "Nous vous résistons !"       # index 0 → résister
		dm.text_choice2 = "Oui… Maman…"                # index 1 → rejoindre
	get_tree().current_scene.add_child(dm)
	return dm

# -------------------------------------------------------
# COMBAT
# -------------------------------------------------------

func _start_combat(encounter: CombatEncounter, heroes_ambushed: bool, enemies_ambushed: bool) -> void:
	if _combat_manager == null:
		push_error("BossSceneController : impossible de démarrer le combat, CombatManager manquant")
		return
	_combat_manager.encounter = encounter
	_combat_manager.heroes_are_ambushed = heroes_ambushed
	_combat_manager.ennemy_are_ambushed = enemies_ambushed
	# Appelle la méthode de démarrage de ton CombatManager
	if _combat_manager.has_method("begin"):
		_combat_manager.begin()

# -------------------------------------------------------
# UTILITAIRE
# -------------------------------------------------------

func _get_game_manager() -> GameManager:
	return get_tree().get_root().get_child(0) as GameManager
