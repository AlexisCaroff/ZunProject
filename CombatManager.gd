extends Node
#combat manager
var heroes: Array[Character] = []
var enemies: Array[Character] = []
var turn_queue: Array[Character] = []
var combat_manager: Node = null 
var current_character: Character = null
var ui: Control = null
@export var HERO_START_POS = Vector2(100, 600)
@export var ENEMY_START_POS = Vector2(1200, 600)
@export var SPACING_Y = 250
var pending_skill: Skill = null
@onready var ResultScreen_label= $"../ResultScreen"

const HERO_SCENES = [
	preload("res://characters/CharacterTestHero1.tscn"),
	preload("res://characters/CharacterTestHero2.tscn"),
	preload("res://characters/CharacterTestHero3.tscn"),
	preload("res://characters/CharacterTestHero4.tscn")
]

const ENEMY_SCENES = [
	preload("res://characters/CharacterTestEnemy1.tscn"),
	preload("res://characters/CharacterTestEnemy2.tscn"),
	preload("res://characters/CharacterTestEnemy3.tscn"),
	
]

func _ready():
	ui = get_parent()
	
	# Spawn héros
	for i in HERO_SCENES.size():
		var chara = HERO_SCENES[i].instantiate()
		print(chara)
		add_child(chara)
		chara.position = HERO_START_POS + Vector2(i * SPACING_Y,0)
		chara.combat_manager= self
		heroes.append(chara)
	
	# Spawn ennemis
	for i in ENEMY_SCENES.size():
		var chara = ENEMY_SCENES[i].instantiate()
		print(chara)
		add_child(chara)
		chara.position = ENEMY_START_POS + Vector2(i * SPACING_Y,0)
		chara.combat_manager= self
		enemies.append(chara)
	
	start_combat()

func start_combat():
	var all_characters: Array[Character] = []
	all_characters.append_array(heroes)
	all_characters.append_array(enemies)
	turn_queue = build_turn_queue(all_characters)
	ui.update_turn_queue_ui(turn_queue)
	next_turn()

func build_turn_queue(characters: Array[Character]) -> Array[Character]:
	var queue: Array[Character] = characters.duplicate()  # Duplique le tableau pour ne pas modifier l'original
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
		var random_index = randi() % heroes.size()
		ui.update_ui_for_current_character(current_character)
		await get_tree().create_timer(1.0).timeout
		current_character.play_ai_turn(heroes,enemies)
		
		next_turn()
func _check_victory():
	for enemy in enemies:
		if not enemy.dead:
			return # au moins un ennemi vivant, on sort
	# Tous les ennemis sont morts
	_show_victory()
	
func _show_victory():
	ResultScreen_label.text = "Victoire !"
	ResultScreen_label.modulate = Color(1,1,1,1)
	print("Tous les ennemis sont vaincus.")
	

func use_skill(index: int):
	var skill = current_character.get_skill(index)
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
	ui.log("Sélectionnez une cible pour %s" % skill.name)
	if skill.the_target_type == skill.target_type.ENNEMY:
		for enemy in enemies:
			enemy.set_targetable(true)
			# Déconnecte si déjà connecté
			if enemy.target_selected.is_connected(self._on_target_selected):
				enemy.target_selected.disconnect(self._on_target_selected)
			enemy.target_selected.connect(_on_target_selected)
		for ally in heroes:
			ally.set_targetable(false)
	
	elif skill.the_target_type == skill.target_type.All_ENNEMY:
		for enemy in enemies:
			await current_character.animate_attack(enemy)
			pending_skill.use(enemy)
			enemy.update_ui()
			ui.log("%s utilise %s sur %s" % [current_character.name, pending_skill.name, enemy.name])
		pending_skill = null
		next_turn()
	
	
	elif skill.the_target_type == skill.target_type.ALLY:
		for ally in heroes:
			ally.set_targetable(true)
		
		# Déconnecte si déjà connecté
			if ally.target_selected.is_connected(self._on_target_selected):
				ally.target_selected.disconnect(self._on_target_selected)
			ally.target_selected.connect(_on_target_selected)
		for enemy in enemies:
			enemy.set_targetable(false)

	
	elif skill.the_target_type == skill.target_type.ALL_ALLY:
		for ally in heroes:
			await current_character.animate_attack(ally)
			pending_skill.use(ally)
			ally.update_ui()
			ui.log("%s utilise %s sur %s" % [current_character.name, pending_skill.name, ally.name])
		pending_skill = null
		next_turn()
	
	elif skill.the_target_type == skill.target_type.SELF:
		pending_skill.use(current_character)
		current_character.update_ui()
		current_character.resetVisuel()
		ui.log("%s utilise %s sur %s" % [current_character.name, pending_skill.name, current_character.name])
		pending_skill = null
		
		next_turn()
		
func _on_target_selected(target: Character):
	await current_character.animate_attack(target)

	pending_skill.use(target)
	target.update_ui()
	ui.log("%s utilise %s sur %s" % [current_character.name, pending_skill.name, target.name])
	pending_skill = null
	next_turn()
	stop_target_selection()


func stop_target_selection():
	for enemy in enemies:
		enemy.set_targetable(true)
		enemy.resetVisuel()
		if enemy.target_selected.is_connected(_on_target_selected):
			enemy.target_selected.disconnect(_on_target_selected)
		
	for ally in heroes:
		ally.set_targetable(true)
		ally.resetVisuel()
		if ally.target_selected.is_connected(_on_target_selected):
			ally.target_selected.disconnect(_on_target_selected)
		
