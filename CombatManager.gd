extends Node
class_name CombatManager
var heroes: Array[Character] = []
var enemies: Array[Character] = []
var turn_queue: Array[Character] = []
var current_character: Character = null
var ui: Control = null
@export var HERO_START_POS = Vector2(100, 600)
@export var ENEMY_START_POS = Vector2(1200, 600)
@export var SPACING_Y = 250
@export var _pending_skill: Skill = null  # Stockage interne
@export var exploration_scene: PackedScene 
@onready var imageAction :TextureRect= $"../ImageAction"
#save
var saved_data : Array = []
# Propriété publique avec accesseurs
var pending_skill: Skill:
	get:
		#print("GET pending_skill →", _pending_skill)
		return _pending_skill
	set(value):
		#print("SET pending_skill →", value)
		_pending_skill = value


@onready var ResultScreen_label= $"../ResultScreen"
@onready var hero_positions: Array[PositionSlot]=[
		$"../HeroPosition/position1",
		$"../HeroPosition/position2",
		$"../HeroPosition/position3",
		$"../HeroPosition/position4"
	
]
@onready var enemy_positions: Array[PositionSlot] =[

]
var HERO_SCENES = [
	preload("res://characters/CharacterTestHero1.tscn"),
	preload("res://characters/CharacterTestHero2.tscn"),
	preload("res://characters/CharacterTestHero3.tscn"),
	preload("res://characters/CharacterTestHero4.tscn")
]

@export var ENEMY_SCENES = [
	preload("res://characters/CharacterTestEnemy1.tscn"),
	preload("res://characters/CharacterTestEnemy2.tscn"),
	preload("res://characters/CharacterTestEnemy3.tscn"),
	preload("res://characters/CharacterTestEnemy4.tscn")
]
@onready var audio = $AudioStreamPlayer2D
enum CombatState {
	IDLE,
	SELECTING_FIRST_TARGET,
	SELECTING_SECOND_TARGET
}

var combat_state: CombatState = CombatState.IDLE
var startcombat = true

func _ready():
	if startcombat ==true:
		_start()
func _start():
	if GameState.current_phase == GameStat.GamePhase.COMBAT:
		ui = get_parent()
		enemy_positions=[
			$"../ennemiePosition/position1",
			$"../ennemiePosition/position2",
			$"../ennemiePosition/position3",
			$"../ennemiePosition/position4",]

		# Spawn héros
		if not GameState.saved_heroes_data.is_empty():
			print("Chargement des héros sauvegardés...")
			load_saved_heroes_into_slots(hero_positions)
		else:
			print("Aucune sauvegarde -> Spawn des héros par défaut")
			for i in HERO_SCENES.size():
				var chara_scene = HERO_SCENES[i]
				var chara: Character = chara_scene.instantiate()
				
				chara.Chara_position = i
				add_child(chara)
				chara.combat_manager = self
				heroes.append(chara)

				var slot_index = clamp(chara.Chara_position, 0, hero_positions.size() - 1)
				var slot = hero_positions[slot_index]
				move_character_to(chara, slot, 0.0)
		
		# Spawn ennemis
		for i in ENEMY_SCENES.size():
			var chara = ENEMY_SCENES[i].instantiate()
			add_child(chara)
			chara.combat_manager = self
			enemies.append(chara)
			
			var slot_index = i
			var slot = enemy_positions[slot_index]
			move_character_to(chara, slot,0.0)
		ui.log("start Combat")
		start_combat()
		
	
func load_saved_heroes_into_slots(slots: Array[PositionSlot]):
	for hero_data in GameState.saved_heroes_data:
		var scene = load(hero_data["scene_path"])
		var hero: Character = scene.instantiate()
		hero.Charaname = hero_data["name"]
		hero.current_stamina = hero_data["stamina"]
		hero.current_stress = hero_data["stress"]
		hero.current_horniness = hero_data["horniness"]
		hero.dead = hero_data["dead"]
		hero.skill_resources = hero_data["skills"]
		hero._updateSkills(hero.skill_resources)
		hero.update_ui()

		add_child(hero)
		hero.combat_manager = self
		heroes.append(hero)

		
		var pos_index = hero_data.get("position", -1)
		if pos_index >= 0 and pos_index < slots.size():
			slots[pos_index].assign_character(hero, 0.0)
	
func start_combat():
	combat_state = CombatState.IDLE
	var all_characters: Array[Character] = []
	all_characters.append_array(heroes)
	all_characters.append_array(enemies)
	turn_queue = build_turn_queue(all_characters)
	ui.update_turn_queue_ui(turn_queue)
	next_turn()

func build_turn_queue(characters: Array[Character]) -> Array[Character]:
	var queue: Array[Character] = characters.duplicate()  
	queue.sort_custom(func(a: Character, b: Character) -> bool:
		return a.initiative > b.initiative
	)
	return queue

func next_turn():
	_check_victory()
	_check_defeat()
	if turn_queue.is_empty():
		turn_queue = build_turn_queue(heroes + enemies)
		ui.update_turn_queue_ui(turn_queue)
	ui.update_turn_queue_ui(turn_queue)
	current_character = turn_queue.pop_front()
	
		
	if current_character.is_dead():
		next_turn()
		return
	if current_character.stun==true:
		current_character.stun=false
		current_character.sprite.self_modulate=Color(1,1,1,1)
		next_turn()
		
		return
	if current_character.is_player_controlled:
		await get_tree().process_frame
		ui.update_ui_for_current_character(current_character)
	else:
		ui.log("Enemie's turn")
		var random_index = randi() % heroes.size()
		ui.update_ui_for_current_character(current_character)
		await get_tree().create_timer(1.0).timeout
		current_character.play_ai_turn(heroes,enemies)
		await get_tree().create_timer(0.5).timeout
		next_turn()
func _check_victory():
	for enemy in enemies:
		if not enemy.dead:
			return 
	
	_show_victory()
	
func _check_defeat():
	for ally in heroes:
		if not ally.dead:
			return 
	_show_defeat()
	
func _show_defeat():
	ResultScreen_label.text = "Defeat !"
	ResultScreen_label.modulate = Color(1, 1, 1, 1)
	
func _show_victory():
	ResultScreen_label.text = "Victoire !"
	ResultScreen_label.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(2.0).timeout

	# --- Sauvegarder l'équipe avant de changer de scène
	GameState.save_party_from_nodes(heroes)
	GameState.current_phase = GameStat.GamePhase.EXPLORATION

	call_deferred("change_to_exploration_scene")



func change_to_exploration_scene():
	if get_tree():
		get_tree().change_scene_to_packed(exploration_scene)
	else:
		print("Erreur : get_tree() est null.")
	
	
	
func use_skill(index: int):
	var skill = current_character.get_skill(index)
	pending_skill=skill
	combat_state = CombatState.SELECTING_FIRST_TARGET
	if skill.can_use():
		
		pending_skill = skill
		start_target_selection(skill)
		
func get_current_character() -> Character:
	return current_character
	
	
func start_target_selection(skill: Skill):
	match combat_state: 
		CombatState.SELECTING_FIRST_TARGET :
			print("selecting first target")
			skill.select_targets(self)
		CombatState.SELECTING_SECOND_TARGET :
			print("selecting second target")
			skill.select_second_target(self)
			
		
func _on_target_selected(targets: Array[PositionSlot]):
	match combat_state: 
		CombatState.SELECTING_FIRST_TARGET :
			if !pending_skill.two_target_Type:
				if pending_skill.name != "move":
					await current_character.animate_attack(targets[0].occupant)  # anime sur la première cible
				if pending_skill.attack_sound != null:
					audio.stream= pending_skill.attack_sound
					audio.pitch_scale = randf_range(0.3, 0.5)
					audio.play()
				ui.log(pending_skill.name)

				for target in targets:
					pending_skill.use(target)
					print(target.occupant.Charaname)
					target.occupant.update_ui()

				pending_skill.end_turn(self)
				stop_target_selection()
			else:
				pending_skill.target1 = targets
				combat_state = CombatState.SELECTING_SECOND_TARGET
				start_target_selection(pending_skill)

		CombatState.SELECTING_SECOND_TARGET :
			if pending_skill.name != "move":
				await current_character.animate_attack(pending_skill.target1[0].occupant)  # anime sur la première cible
			if pending_skill.attack_sound != null:
				audio.stream= pending_skill.attack_sound
				audio.pitch_scale = randf_range(0.3, 0.5)
				audio.play()
			ui.log(pending_skill.name)

			for target in pending_skill.target1:
				pending_skill.use(target)
				print(target.occupant.Charaname)
				target.occupant.update_ui()
			for target2 in targets:
				pending_skill.use(target2,true)
				print(target2.occupant.Charaname)
				target2.occupant.update_ui()
			pending_skill.end_turn(self)
			stop_target_selection()
			




	

func stop_target_selection():
	pending_skill=null
	for enemy in enemies:
		enemy.set_targetable(false)
		enemy.resetVisuel()
		if enemy.target_selected.is_connected(_on_target_selected):
			enemy.target_selected.disconnect(_on_target_selected)
		
	for ally in heroes:
		ally.set_targetable(false)
		ally.resetVisuel()
		if ally.target_selected.is_connected(_on_target_selected):
			ally.target_selected.disconnect(_on_target_selected)
			
func get_positions(is_playercontroled: bool) -> Array[PositionSlot]:
	return hero_positions if is_playercontroled else enemy_positions

func move_character_to(character: Character, slot: PositionSlot, movetime: int):
	if slot.occupant == character:
		return  

	slot.assign_character(character,movetime)
		
func swap_characters(slot_a: PositionSlot, slot_b: PositionSlot,movetime: int):
	var char_a = slot_a.occupant
	var char_b = slot_b.occupant

	if char_a != null:
		slot_b.assign_character(char_a,movetime)
	if char_b != null:
		slot_a.assign_character(char_b,movetime)
