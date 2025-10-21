extends Node
class_name CombatManager
@onready var ResultScreen_label =$"../ResultScreen"
# characters combat
var heroes: Array[Character] = []
var enemies: Array[Character] = []
var turn_queue: Array[Character] = []
var current_character: Character = null
var ui: Control = null
@export var HERO_START_POS = Vector2(100, 600)
@export var ENEMY_START_POS = Vector2(1200, 600)
@export var SPACING_Y = 250
@export var _pending_skill: Skill = null  

@export_file("*.tscn") var target_scene : String

#save
var saved_data : Array = []

var pending_skill: Skill:
	get:
		#print("GET pending_skill →", _pending_skill)
		return _pending_skill
	set(value):
		#print("SET pending_skill →", value)
		_pending_skill = value

@onready var hero_positions: Array[PositionSlot]=[]
@onready var enemy_positions: Array[PositionSlot] =[]
var HERO_SCENES = [
	preload("res://characters/CharaPriest.tscn"),
	preload("res://characters/CharaHunter.tscn"),
	preload("res://characters/CharaMystic.tscn"),
	preload("res://characters/CharaWarrior.tscn")
]
@export var cristal_texture = preload("res://UI/cristalIcon.png")
@export var encounter: CombatEncounter

#stat combat manager
@onready var audio = $AudioStreamPlayer2D

@onready var SpriteHeros=$"../SpriteHeros"
@onready var SpriteEnnemies=$"../SpriteEnnemies"
enum CombatState {
	IDLE,
	SELECTING_FIRST_TARGET,
	SELECTING_SECOND_TARGET
}
var combat_state: CombatState = CombatState.IDLE
var startcombat = true
var nb_crystaleloot :int = 0
var ennemy_are_ambushed : bool = false
var heroes_are_ambushed : bool = false

func _ready():
	for child in $"../HeroPosition".get_children():
		if child is PositionSlot:
			hero_positions.append(child)
	
	for child in $"../ennemiePosition".get_children():
		if child is PositionSlot:
			enemy_positions.append(child)
			
	if heroes_are_ambushed:
		show_ambush_message("You're ambushed!", Color(1, 0.2, 0.2))
	elif ennemy_are_ambushed:
		show_ambush_message("You surprise your enemies!", Color(0.2, 1, 0.2))
	if startcombat ==true:
		_start()
func show_ambush_message(text: String, color: Color):
	# Crée le Label
	var label = Label.new()
	label.text = text
	label.z_index=21
	label.scale = Vector2(0.1, 0.1)
	label.modulate.a = 0.0
	label.add_theme_font_size_override("font_size", 68)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	var font: FontFile = ResourceLoader.load("res://UI/Euphorigenic.otf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 64)
	label.position = get_viewport().get_visible_rect().size / 3
	add_child(label)
	label.pivot_offset = label.size / 2

	# Animation via Tween
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.0) # temps d’affichage
	tween.parallel().tween_property(label, "scale", Vector2(1.5, 1.5), 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)


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
				chara.current_stamina= chara.max_stamina
				if heroes_are_ambushed:
					chara.surprised()
				chara.update_ui()
		
		# Spawn ennemis
		for i in encounter.enemy_scenes.size():
			var chara = encounter.enemy_scenes[i].instantiate()
			add_child(chara)
			chara.combat_manager = self
			enemies.append(chara)

			var slot_index = i
			var slot = enemy_positions[slot_index]
			move_character_to(chara, slot, 0.0)
			if ennemy_are_ambushed:
				chara.surprised()
			chara.update_ui()
		ui.log("start Combat")
		start_combat()
		
	for char in heroes + enemies:
		char.skill_animation_started.connect(_on_skill_animation_started)
		char.skill_animation_finished.connect(_on_skill_animation_finished)
	
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
		if heroes_are_ambushed:
			hero.surprised()
		hero.update_ui()
		
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
	await get_tree().process_frame
	ui.log(current_character.Charaname +" turn")
	current_character.animate_start_Turn()
	await current_character.skill_animation_finished
	if current_character.current_stamina<=0: # look if tired
		ui.log(current_character.Charaname +" is tired")
		while is_animation_playing():
			await get_tree().process_frame
		turn_queue.append(current_character)
		next_turn()
		return
	if current_character.stun==true:
		current_character.stun=false
		ui.log(current_character.Charaname +" is stun")
		if current_character.exclamation!= null:
			current_character.exclamation.free()
			ui.log(current_character.Charaname +" is surprised")
		
		current_character.sprite.self_modulate=Color(1,1,1,1)
		while is_animation_playing():
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		turn_queue.append(current_character)
		
		next_turn()
		
		return
	
	if current_character.is_player_controlled:
		
		await get_tree().process_frame
		ui.update_ui_for_current_character(current_character)
		current_character.CharaColor =Color(1.8,1.8,1.8,1)
		current_character.sprite.modulate =current_character.CharaColor
	else:
		
		ui.update_ui_for_current_character(current_character)
		await get_tree().create_timer(1.0).timeout
		current_character.play_ai_turn(heroes,enemies)
		await get_tree().create_timer(2.5).timeout
		while is_animation_playing():
			await get_tree().process_frame
		turn_queue.append(current_character)
		next_turn()


var active_animations := 0

func _on_skill_animation_started():
	active_animations += 1

func _on_skill_animation_finished():
	active_animations -= 1

func is_animation_playing() -> bool:
	return active_animations > 0

func _check_victory():
	for enemy in enemies:
		if enemy.dead:
			#print(enemy.Charaname+ " not dead")

			#print(enemy.Charaname+ " dead")
			turn_queue.erase(enemy)
			enemy.current_slot.remove_character()
			enemies.erase(enemy)
			enemy.queue_free()
	if enemies.is_empty():
		_show_victory()
	
func _check_defeat():
	for ally in heroes:
		if not ally.dead:
			return 
		else:
			turn_queue.erase(ally)
			ally.current_slot.remove_character()
			heroes.erase(ally)
			ally .queue_free()
	_show_defeat()
	
func _show_defeat():
	ResultScreen_label.text = "Defeat !"
	ResultScreen_label.modulate = Color(1, 1, 1, 1)
	
func _show_victory():

	var victory_ui_scene = preload("res://UI/victory.tscn")
	var victory_ui = victory_ui_scene.instantiate()
	var cristal_item := Item.new()
	
	cristal_item.name = (str(nb_crystaleloot)+" Cristal")
	cristal_item.icon = cristal_texture
	cristal_item.quantity = nb_crystaleloot
	cristal_item.description = "Un cristal précieux obtenu en combat."
	if nb_crystaleloot >0:
		encounter.loots.append(cristal_item)
	victory_ui.showLoot(encounter.loots)  # Passer les loots récupérés au Victory UI
	
	# Ajouter Victory UI à la scène et le faire apparaître
	get_parent().add_child(victory_ui)
	
	await get_tree().create_timer(1.0).timeout

	# --- Sauvegarder l'équipe avant de changer de scène
	GameState.save_party_from_nodes(heroes)
	



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
				for target in targets:
					if target.occupant != null:
						
						pending_skill.use(target)
						print(target.occupant.Charaname)
						target.occupant.update_ui()
						ui.update_cooldown(current_character)
				if pending_skill.attack_sound != null:
					audio.stream= pending_skill.attack_sound
					audio.pitch_scale = randf_range(0.3, 0.5)
					audio.play()
				if pending_skill.name != "move" && pending_skill.name != "ChangeMask" :
					
					var occupied_slots = targets.filter(func(slot): return slot.occupant != null)
					var slot
					if occupied_slots.size() > 0:
						slot = occupied_slots[0] 
			
					await current_character.animate_attack(slot.occupant)  # anime sur la première cible
				
				ui.log(pending_skill.name)

				

				pending_skill.end_turn(self)
				stop_target_selection()
				pending_skill=null
			else:
				pending_skill.target1 = targets
				combat_state = CombatState.SELECTING_SECOND_TARGET
				start_target_selection(pending_skill)
				

		CombatState.SELECTING_SECOND_TARGET :
			if pending_skill.name != "move" && pending_skill.name != "ChangeMask" :
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
			pending_skill=null
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
