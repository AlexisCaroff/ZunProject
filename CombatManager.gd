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
@export var turnNumber : int =0
@export_file("*.tscn") var target_scene : String
@onready var ShadowBackground: Sprite2D = $"../Gradiant"
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
var combatChara = 	preload("res://characters/CombatChara.tscn")

@export var cristal_texture = preload("res://UI/cristalIcon.png")
@export var encounter: CombatEncounter

#stat combat manager
@onready var audio = $AudioStreamPlayer2D
@onready var canvas =$"../CanvasLayer"

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
const SELECTOR_TEX = preload("res://UI/selectorCombatChara.png")
var selectorChara : Sprite2D
var gm: GameManager
var combatEnd: bool = false

func _ready():
	gm= get_tree().root.get_node("GameManager") as GameManager
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

func show_ambush_message(text: String, _color: Color):
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
	label.position = get_viewport().get_visible_rect().size / 3.2
	label.position.y -= 100
	add_child(label)
	label.pivot_offset = label.size / 2

	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.0)
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

		print("Aucune sauvegarde -> Spawn des héros par défaut")
		for i in gm.characters.size():
			var charaData = gm.characters[i] 
			
			var chara : Character= combatChara.instantiate()
			chara.characterData = charaData
			chara.characterData.Chara_position = i
			add_child(chara)
			chara.combat_manager = self
			heroes.append(chara)
			print ("spawn " + chara.characterData.Charaname)

			# place in slot
			var slot_index = clamp(chara.characterData.Chara_position, 0, hero_positions.size() - 1)
			var slot = hero_positions[slot_index]
			move_character_to(chara, slot, 0)

				# initialise les stats runtime depuis la ressource (si besoin)
			chara.update_stats()
			chara.characterData.current_stamina = chara.characterData.max_stamina
			chara.characterData.current_stress = clamp(chara.characterData.current_stress, 0, chara.characterData.max_stress)
			chara.characterData.current_horniness = clamp(chara.characterData.current_horniness, 0, chara.characterData.max_horniness)
			chara.ShadowBackground = ShadowBackground

			if heroes_are_ambushed:
				chara.surprised()
			chara.update_ui()
		
		# Spawn ennemis
		for i in encounter.enemy_scenes.size():
			var chara :Character = encounter.enemy_scenes[i].instantiate()
			chara.characterData = chara.characterData.duplicate()
			add_child(chara)
			chara.combat_manager = self
			enemies.append(chara)
			chara.ShadowBackground = ShadowBackground
			var slot_index = i
			var slot = enemy_positions[slot_index]
			move_character_to(chara, slot, 0)

			# initialise stats runtime si la ressource existe
			if chara.characterData:
				chara.update_stats()
				chara.characterData.current_stamina = chara.characterData.max_stamina
				chara.characterData.current_stress = clamp(chara.characterData.current_stress, 0, chara.characterData.max_stress)
				chara.characterData.current_horniness = clamp(chara.characterData.current_horniness, 0, chara.characterData.max_horniness)

			if ennemy_are_ambushed:
				chara.surprised()
			
			chara.update_ui()
			
		
		ui.set_MenuPerso(gm.characters)
		
		start_combat()
		
	for chara in heroes + enemies:
		chara.skill_animation_started.connect(_on_skill_animation_started)
		chara.skill_animation_finished.connect(_on_skill_animation_finished)
	
	
func start_combat():
	combat_state = CombatState.IDLE
	var all_characters: Array[Character] = []
	all_characters.append_array(heroes)
	all_characters.append_array(enemies)
	turn_queue = build_turn_queue(all_characters)
	ui.update_turn_queue_ui(turn_queue)
	create_selector_sprite()
	next_turn()

func build_turn_queue(characters: Array[Character]) -> Array[Character]:
	var queue: Array[Character] = characters.duplicate()  
	queue.sort_custom(func(a: Character, b: Character) -> bool:
		# compare via characterData.initiative
		return a.characterData.initiative > b.characterData.initiative
	)
	return queue

func next_turn():
	while is_animation_playing():
			await get_tree().process_frame

	_check_victory()
	_check_defeat()
	if combatEnd:
		return
	turnNumber += 1
	if turn_queue.is_empty():
		turn_queue = build_turn_queue(heroes + enemies)
		ui.update_turn_queue_ui(turn_queue)
	ui.update_turn_queue_ui(turn_queue)
	current_character = turn_queue.pop_front()
	for char in turn_queue:
		char.resetVisuel()
	if current_character.acte_twice:
		current_character.acte_twice=false
		turn_queue.push_front(current_character)
	await get_tree().process_frame
	for position in enemy_positions:
		if position.occupant==null :
			position.CharaUI.visible=false

	ui.hide_Panel_action()
	
	selectorChara.position= current_character._current_slot.CharaUI.global_position if current_character._current_slot else Vector2.ZERO
	if current_character.characterData.is_player_controlled:
		selectorChara.modulate = Color(0.9,0.95,0.7)
	else:
		selectorChara.modulate = Color(0.1,0.1,0.1)
	current_character.start_turn()
	
	for chara in turn_queue:
		chara.update_ui()
	
	

	if current_character.characterData.current_stamina <= 0:
		ui.log(current_character.characterData.Charaname +" is tired")
		current_character.update_buffs()
		while is_animation_playing():
			await get_tree().process_frame
		turn_queue.append(current_character)
		next_turn()
		return
	if current_character.characterData.current_horniness >= 100: 
		current_character.characterData.current_horniness =100
		print (current_character.characterData.Charaname + "is too horny to fight")
		ui.log(current_character.characterData.Charaname +" is too horny to fight")
		current_character.update_buffs()
		for button:Button in ui.skill_buttons :
			button.disabled = true
		while is_animation_playing():
			print ("-----")
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		turn_queue.append(current_character)
		next_turn()
		return
	if current_character.characterData.stun == true:
		current_character.characterData.stun = false
		ui.log(current_character.characterData.Charaname +" is stun")
		if current_character.exclamation != null:
			current_character.exclamation.free()
			ui.log(current_character.characterData.Charaname +" is surprised")
		for button:Button in ui.skill_buttons :
			button.disabled = true
		current_character.update_buffs()
		current_character.sprite.self_modulate=Color(1,1,1,1)
		while is_animation_playing():
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		turn_queue.append(current_character)
		next_turn()
		return
	
	if current_character.characterData.is_player_controlled:

		ui.MenuPerso.select_character(current_character.characterData)
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

func create_selector_sprite():
	var sprite := Sprite2D.new()
	sprite.texture = SELECTOR_TEX
	add_child(sprite)
	selectorChara=sprite
	selectorChara.scale= Vector2(0.9,1.1)
	selectorChara.offset.y =-4.0
	selectorChara.z_index = 3


func _on_skill_animation_started():
	active_animations += 1
	print("-_-_-_-_  "+ str(active_animations) )
func _on_skill_animation_finished():
	active_animations -= 1

func is_animation_playing() -> bool:
	return active_animations > 0

func _check_victory():
	for enemy in enemies.duplicate():
		if enemy.dead:
			turn_queue.erase(enemy)
			if enemy._current_slot:
				enemy._current_slot.remove_character()
			enemies.erase(enemy)
			enemy.queue_free()
	if enemies.is_empty():
		_show_victory()
	
func _check_defeat():
	for ally in heroes.duplicate():
		if !ally.dead && ally.characterData.current_horniness<100:
			return 
		if ally.dead:
			turn_queue.erase(ally)
			if ally._current_slot:
				ally._current_slot.remove_character()
			heroes.erase(ally)
			ally.queue_free()
	combatEnd=true
	_show_defeat()
	
func _show_defeat():
	ResultScreen_label.text = "Defeat !"
	ResultScreen_label.visible=true
	ResultScreen_label.modulate = Color(1, 1, 1, 1)
	
	
	
func _show_victory():

	var victory_ui_scene = preload("res://UI/victory.tscn")
	var victory_ui = victory_ui_scene.instantiate()
	var cristal_item := Equipment.new()
	
	cristal_item.name = (str(nb_crystaleloot)+" Cristal")
	cristal_item.icon = cristal_texture
	cristal_item.number = nb_crystaleloot
	cristal_item.description = "Un cristal précieux obtenu en combat."
	if nb_crystaleloot >0:
		encounter.loots.append(cristal_item)
	gm = get_tree().root.get_node("GameManager") as GameManager
	victory_ui.showLoot(encounter.loots, gm)
	
	gm.current_room_Ressource.ennemikilled=true
	
	canvas.add_child(victory_ui)


	
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
	stop_target_selection()
	match combat_state: 
		CombatState.SELECTING_FIRST_TARGET :
			if !pending_skill.two_target_Type:
				if pending_skill.name != "move" : #&& pending_skill.name != "ChangeMask" :
					var slot
					var occupied_slots = targets.filter(func(slot): return slot.occupant != null)
					
					if occupied_slots.size() > 0:
						slot = occupied_slots[0] 
					current_character.sprite.texture = current_character.current_skill.ImageSkill
					await current_character.animate_attack(slot.occupant,current_character.current_skill.duration)
				
				for target in targets:
					if target.occupant != null:
						pending_skill.use(target)
						print(target.occupant.characterData.Charaname)
						target.occupant.update_ui()
						ui.update_ui_for_current_character(current_character)
				if pending_skill.attack_sound != null:
					audio.stream= pending_skill.attack_sound
					audio.pitch_scale = randf_range(0.3, 0.5)
					audio.play()
				
				ui.log(pending_skill.name)
				pending_skill.end_turn(self)
				
				pending_skill=null
			else:
				pending_skill.target1 = targets
				combat_state = CombatState.SELECTING_SECOND_TARGET
				start_target_selection(pending_skill)
		CombatState.SELECTING_SECOND_TARGET :
			if pending_skill.name != "move" :# && pending_skill.name != "ChangeMask" :
				
				await current_character.animate_attack(pending_skill.target1[0].occupant)
			if pending_skill.attack_sound != null:
				audio.stream= pending_skill.attack_sound
				audio.pitch_scale = randf_range(0.3, 0.5)
				audio.play()
			ui.log(pending_skill.name)
			stop_target_selection()
			for target in pending_skill.target1:
				pending_skill.use(target)
				print(target.occupant.characterData.Charaname)
				target.occupant.update_ui()
			for target2 in targets:
				pending_skill.use(target2,true)
				print(target2.occupant.characterData.Charaname)
				target2.occupant.update_ui()
			pending_skill.end_turn(self)
			pending_skill=null
			

func stop_target_selection():
	for enemy in enemies:
		enemy.set_targetable(false)
		enemy.resetVisuel()
		if enemy.target_selected.is_connected(_on_target_selected):
			enemy.target_selected.disconnect(_on_target_selected)
		
	for ally in heroes:
		ally.set_targetable(false)
		if ally != current_character:
			ally.resetVisuel()
		if ally.target_selected.is_connected(_on_target_selected):
			ally.target_selected.disconnect(_on_target_selected)
			
func get_positions(is_playercontroled: bool) -> Array[PositionSlot]:
	return hero_positions if is_playercontroled else enemy_positions

func move_character_to(character: Character, slot: PositionSlot, movetime: int):
	if slot == null:
		return
	var currentslot = character._current_slot

	slot.Set_CharaUI()
	slot.CharaUI.visible=true

	slot.assign_character(character,movetime)
	
	character._current_slot = slot
	character.update_ui()
		
func swap_characters(slot_a: PositionSlot, slot_b: PositionSlot,movetime: int):
	var char_a = slot_a.occupant
	var char_b = slot_b.occupant

	if char_a != null:
		slot_b.assign_character(char_a,movetime)
	if char_b != null:
		slot_a.assign_character(char_b,movetime)

	if char_a:
		char_a.update_ui()
	if char_b:
		char_b.update_ui()
