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
<<<<<<< Updated upstream
@export var pending_skill: Skill = null
=======
@export var _pending_skill: Skill = null  # Stockage interne
@export var next_scene_path: String = "res://scenes/WorldMap.tscn"  # Exemple
@export var transition_delay: float = 2.0
# Propriété publique avec accesseurs
var pending_skill: Skill:
	get:
		#print("GET pending_skill →", _pending_skill)
		return _pending_skill
	set(value):
		#print("SET pending_skill →", value)
		_pending_skill = value


>>>>>>> Stashed changes
@onready var ResultScreen_label= $"../ResultScreen"
@onready var hero_positions: Array[PositionSlot]=[
		$"../HeroPosition/position1",
		$"../HeroPosition/position2",
		$"../HeroPosition/position3",
		$"../HeroPosition/position4"
	
]
@onready var enemy_positions: Array[PositionSlot] =[
		$"../ennemiePosition/position1",
		$"../ennemiePosition/position2",
		$"../ennemiePosition/position3",
		$"../ennemiePosition/position4",
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

func _ready():
	ui = get_parent()

	if Game_Manager.surviving_heroes.size() > 0:
		load_surviving_heroes()
	else:
		spawn_default_heroes() 


<<<<<<< Updated upstream
		# Place dans la bonne PositionSlot
		var slot_index = clamp(chara.Chara_position, 0, hero_positions.size() )
		var slot = hero_positions[slot_index]
		move_character_to(chara, slot,2.0)
	
	
=======
>>>>>>> Stashed changes
	# Spawn ennemis
	for i in ENEMY_SCENES.size():
		var chara = ENEMY_SCENES[i].instantiate()
		add_child(chara)
		chara.combat_manager = self
		enemies.append(chara)
		
		var slot_index = i
		var slot = enemy_positions[slot_index]
		move_character_to(chara, slot,2.0)
	ui.log("start Combat")
	start_combat()
	
func spawn_default_heroes() :
	for i in HERO_SCENES.size():
		var packed_scene = HERO_SCENES[i]
		var chara = packed_scene.instantiate()
		chara.set_meta("scene_file_path", packed_scene.resource_path)  # 🔧 AJOUT ICI !
		add_child(chara)
		chara.combat_manager = self
		heroes.append(chara)

		# Place dans la bonne PositionSlot
		var slot_index = clamp(chara.Chara_position, 0, hero_positions.size() )
		var slot = hero_positions[slot_index]
		move_character_to(chara, slot,0.0)
		
func load_surviving_heroes():
	heroes.clear()
	for saved_data in Game_Manager.surviving_heroes:
		if saved_data.resource_path == "":
			push_warning("Chemin de scène vide pour " + saved_data.chara_name)
			continue

		var packed_scene = load(saved_data.resource_path)
		if packed_scene == null:
			push_error("Impossible de charger : " + saved_data.resource_path)
			continue

		var hero: Character = packed_scene.instantiate()
		hero.set_meta("scene_file_path", saved_data.resource_path)
		hero.Charaname = saved_data.chara_name
		hero.current_stamina = saved_data.current_stamina
		hero.current_stress = saved_data.current_stress
		hero.current_horniness = saved_data.current_horniness
		hero.Chara_position = saved_data.position_index
		hero.combat_manager = self
		add_child(hero)
		heroes.append(hero)

		if saved_data.position_index < hero_positions.size():
			var slot = hero_positions[saved_data.position_index]
			move_character_to(hero, slot, 0.0)
	
func start_combat():
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
func save_surviving_heroes():
	Game_Manager.surviving_heroes.clear()
	for hero in heroes:
		if not hero.is_dead():
			var save_data = Game_Manager.CharacterSaveData.new(hero)
			Game_Manager.surviving_heroes.append(save_data)
			
			
func _show_victory():
	ResultScreen_label.text = "Victoire !"
	ResultScreen_label.modulate = Color(1, 1, 1, 1)
	print("Tous les ennemis sont vaincus.")

	await get_tree().create_timer(transition_delay).timeout
	save_surviving_heroes()
	transition_to_next_scene()
	
func transition_to_next_scene():
	if next_scene_path == "":
		push_error("Aucune scène suivante définie pour la transition.")
		return

	var transition := preload("res://scene_transition_fade.tscn").instantiate()
	get_tree().current_scene.add_child(transition)
	await transition.fade_out() 
	 # Nécessite une méthode fade_out() dans ton node

	get_tree().change_scene_to_file(next_scene_path)

func use_skill(index: int):
	var skill = current_character.get_skill(index)
	pending_skill=skill
	if skill.can_use():
		if skill.needtarget:
			pending_skill = skill
			start_target_selection(skill)
		else:
			skill.use()
			ui.log("%s utilise %s" % [current_character.name, skill.name])
			next_turn()
func get_current_character() -> Character:
	return current_character
	
	
func start_target_selection(skill: Skill):
	skill.select_targets(self)
		
func _on_target_selected(target: Character):
	if pending_skill.name != "move":
		await current_character.animate_attack(target)
	ui.log(pending_skill.name)
	pending_skill.use(target)
	
	target.update_ui()
	if pending_skill.two_target_Type:
		pending_skill.select_second_target(self)
	else:
		pending_skill.end_turn(self)
	

	stop_target_selection()
	
func _on_second_target_selected(target: Character):
	#await current_character.animate_attack(target)
	ui.log(pending_skill.name)
	pending_skill._apply_second_effect(target)
	pending_skill.end_turn(self)
	target.update_ui()
	stop_target_selection()

func stop_target_selection():
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
