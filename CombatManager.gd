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
@export var turnNumber : int = 0
var round_number : int = 1
## Effets appliqués à tous les héros au début de chaque round (buff passif, allié invisible…)
@export var round_effects : Array[SkillEffect] = []
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
	SELECTING_SECOND_TARGET,
	TURN_START,
	TURN_PRE_EFFECTS,
	TURN_ACTION_SELECTION,
	TURN_ACTION_EXECUTION,
	TURN_POST_EFFECTS,
	TURN_END
}
var combat_state: CombatState = CombatState.IDLE
var startcombat = true
var nb_crystaleloot :int = 0
var ennemy_are_ambushed : bool = false
var heroes_are_ambushed : bool = false
const SELECTOR_TEX = preload("res://UI/UI boxes/UI_combat_selector.png")
var selectorChara : Sprite2D
var gm: GameManager
var combatEnd: bool = false
@onready var ScreenLooseChara= $"../CanvasLayer/BadEnd"
var cam : Camera
var pause: bool = false
@onready var passButton=$"../CanvasLayer/ActionPass"
var endTurn_affinity_reaction_queue: Array[Callable] = []
var startSkills_affinity_reaction_queue: Array[Callable]=[]
@onready var hero_skillP:  Node2D = $HeroSkillP
@onready var hero_skillP2: Node2D = $HeroSkillP2
@onready var hero_skillP3: Node2D = $HeroSkillP3
@onready var enemy_skillP: Node2D = $EnemySkillP
@onready var enemy_skillP2: Node2D = $EnemySkillP2
@onready var enemy_skillP3: Node2D = $EnemySkillP3



func _ready():
	gm= get_tree().root.get_node("GameManager") as GameManager
	cam = get_viewport().get_camera_2d()
	for child in $"../HeroPosition".get_children():
		if child is PositionSlot:
			hero_positions.append(child)
	
	for child in $"../ennemiePosition".get_children():
		if child is PositionSlot:
			enemy_positions.append(child)
			
	if heroes_are_ambushed:
		show_ambush_message("heroes surprised!", Color(1, 0.2, 0.2))
	elif ennemy_are_ambushed:
		show_ambush_message("ennemies are surprised ", Color(0.2, 1, 0.2))
	if startcombat ==true:
		_start()
	passButton.connect("button_down",PassButtonDown)

func show_ambush_message(text: String, _color: Color):
	var label = $"../CanvasLayer/AmbushLabel"
	label.text = text
	label.z_index=21
	label.scale = Vector2(0.1, 0.1)
	label.modulate.a = 0.0
	label.visible=true


	
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
		enemy_positions = [
			$"../ennemiePosition/position1",
			$"../ennemiePosition/position2",
			$"../ennemiePosition/position3",
			$"../ennemiePosition/position4",
			$"../ennemiePosition/position5",
		]
 
		# ── Séquence d'intro boss AVANT le spawn ─────────────────────────
		var boss_intro := get_parent().get_parent().get_node_or_null("BossIntroSequence") as BossIntroSequence
		if boss_intro:
			await get_tree().process_frame
			var result: Dictionary = await boss_intro.run_sequence(cam)
 
			var chosen_scene: PackedScene = result.get("scene", null)
			if chosen_scene != null:
				# Le joueur a cédé → on quitte cette scène et on en charge une autre.
				# On met à jour l'encounter dans le RoomResource avant de partir
				# pour que la nouvelle scène le récupère si besoin.
				var chosen_encounter: CombatEncounter = result.get("encounter", null)
				if chosen_encounter != null:
					gm.current_room_Ressource.encounter = chosen_encounter
				gm._enter_scene_in_current_room(chosen_scene)
				return   # ← stoppe _start(), rien ne se spawne ici
 
			# Branche normale (résistance) : on change juste l'encounter
			var chosen_encounter: CombatEncounter = result.get("encounter", null)
			if chosen_encounter != null:
				encounter = chosen_encounter
		# ─────────────────────────────────────────────────────────────────
 
		# Spawn héros
		print("Aucune sauvegarde -> Spawn des héros par défaut")
		for i in gm.characters.size():
			var charaData = gm.characters[i]
			var chara: Character = combatChara.instantiate()
			chara.characterData = charaData
			chara.characterData.Chara_position = i
			add_child(chara)
			chara.combat_manager = self
			heroes.append(chara)
			print("spawn " + chara.characterData.Charaname)
			if gm.teamCorrupted:
				chara.sprite.flip_h=true
				chara.Selector.flip_h=true
				chara.pivot.position.x += -150 
			var slot_index = clamp(chara.characterData.Chara_position, 0, hero_positions.size() - 1)
			var slot = hero_positions[slot_index]
			move_character_to(chara, slot, 0)
 
			chara.update_stats()
			chara.characterData.current_stamina = chara.characterData.max_stamina
			chara.characterData.current_stress = clamp(chara.characterData.current_stress, 0, chara.characterData.max_stress)
			chara.characterData.current_horniness = clamp(chara.characterData.current_horniness, 0, chara.characterData.max_horniness)
			chara.ShadowBackground = ShadowBackground
 
			if heroes_are_ambushed:
				chara.surprised()
			chara.update_ui()
 
		# Spawn ennemis (encounter est maintenant le bon)
		for i in encounter.enemy_scenes.size():
			var chara: Character = encounter.enemy_scenes[i].instantiate()
			chara.characterData = chara.characterData.duplicate()
			add_child(chara)
			chara.combat_manager = self
			enemies.append(chara)
			chara.ShadowBackground = ShadowBackground
			var slot_index = i
			var slot = enemy_positions[slot_index]
			move_character_to(chara, slot, 0)
			if chara.characterData.Charaname == "Mommy":
				enemy_positions[slot_index + 1].occupant = chara
			if chara.characterData:
				chara.update_stats()
				chara.characterData.current_stamina = chara.characterData.max_stamina
				chara.characterData.current_stress = clamp(chara.characterData.current_stress, 0, chara.characterData.max_stress)
				chara.characterData.current_horniness = clamp(chara.characterData.current_horniness, 0, chara.characterData.max_horniness)
 
			if ennemy_are_ambushed:
				chara.surprised()
			chara.update_ui()
 
		ui.set_MenuPerso(gm.characters)
		_start_combat_flow()
 
	for chara in heroes + enemies:
		chara.skill_animation_started.connect(_on_skill_animation_started)
		chara.skill_animation_finished.connect(_on_skill_animation_finished)

func _start_combat_flow() -> void:
	if ui:
		ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 
	# Animatique et histoire pré-combat (système existant)
	if gm.current_room_Ressource.before_combat_scene_History:
		var overlay = gm.show_history_scene(gm.current_room_Ressource.before_combat_scene_History)
		await overlay.history_finished
	if gm.current_room_Ressource.before_combat_Animatic_scene:
		var overlay = gm.show_Animatic_scene(gm.current_room_Ressource.before_combat_Animatic_scene, cam)
		await overlay.Animatic_finished

 
	if ui:
		ui.mouse_filter = Control.MOUSE_FILTER_STOP
 
	start_combat()
	
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
func is_pause() -> bool:
	return pause
	
	
func next_turn():
	while is_animation_playing():
		await get_tree().process_frame
 
	_check_victory()
	_check_defeat()
 
	while is_pause():
		await get_tree().process_frame
	while GameState.Pause:
		await get_tree().process_frame
 
	if combatEnd:
		return
 
	turnNumber += 1
 
	# ── Compteur de round ─────────────────────────────────────────────
	if not turn_queue.is_empty() and turnNumber > turn_queue.size():
		round_number += 1
		turnNumber = 1
		print("⚔️ Round ", round_number, " !")
		await _trigger_round_effects()
 
	if turn_queue.is_empty():
		turn_queue = build_turn_queue(heroes + enemies)
		ui.update_turn_queue_ui(turn_queue)
	ui.update_turn_queue_ui(turn_queue)
	current_character = turn_queue.pop_front()
 
	for char in turn_queue:
		char.resetVisuel()
 
	if current_character.characterData.acte_twice:
		current_character.characterData.acte_twice = false
		turn_queue.push_front(current_character)
		print("Hunter Acte_twice")
	await get_tree().process_frame
 
	for position in enemy_positions:
		if position.occupant == null:
			position.CharaUI.visible = false
 
	ui.hide_Panel_action()
 
	selectorChara.position = current_character._current_slot.CharaUI.global_position if current_character._current_slot else Vector2.ZERO
	selectorChara.position.y += 45
	if current_character.characterData.is_player_controlled:
		selectorChara.modulate = Color(0.9, 0.95, 0.7)
	else:
		selectorChara.modulate = Color(0.1, 0.1, 0.1)
 
	current_character.start_turn()
 
	for chara in turn_queue:
		chara.update_ui()
 
	# ══════════════════════════════════════════════════════════════════
	#  CHECKS D'INCAPACITÉ — TOUT EN HAUT, avant tout affichage UI
	# ══════════════════════════════════════════════════════════════════
 
	# ── Stamina épuisée ──
	if current_character.characterData.current_stamina <= 0:
		print("🚫 SKIP (tired): ", current_character.characterData.Charaname)
		ui.log(current_character.characterData.Charaname + " is tired")
		await end_currentChara_Turn()
		return
 
	# ── Horniness max ──
	if current_character.characterData.current_horniness >= 100:
		print("🚫 SKIP (horny): ", current_character.characterData.Charaname)
		current_character.characterData.current_horniness = 100
		ui.log(current_character.characterData.Charaname + " is too horny to fight")
		# Disable les boutons même pour un héros (cohérence visuelle)
		if current_character.characterData.is_player_controlled:
			for button: Button in ui.skill_buttons:
				button.disabled = true
		await get_tree().create_timer(1.5).timeout
		await end_currentChara_Turn()
		return
 
	# ── Grab (boss capture) ──
	if current_character.characterData.grab == true:
		print("🚫 SKIP (grabbed): ", current_character.characterData.Charaname)
		ui.log(current_character.characterData.Charaname + " is grabbed")
		if current_character.characterData.is_player_controlled:
			for button: Button in ui.skill_buttons:
				button.disabled = true
		await end_currentChara_Turn()
		return
 
	# ── Stun / Surprise ──
	# IMPORTANT : on traite le stun AVANT d'afficher le menu joueur,
	# sinon l'UI flash brièvement pour rien.
	if current_character.characterData.stun == true:
		print("🚫 SKIP (stun): ", current_character.characterData.Charaname)
		ui.log(current_character.characterData.Charaname + " is stuned")
		if current_character.exclamation != null:
			current_character.exclamation.free()
			ui.log(current_character.characterData.Charaname + " is surprised")
		if current_character.characterData.is_player_controlled:
			for button: Button in ui.skill_buttons:
				button.disabled = true
		current_character.characterData.stun = false
		await end_currentChara_Turn()
		return
 
	# ══════════════════════════════════════════════════════════════════
	#  Le perso peut jouer : décision joueur vs IA
	# ══════════════════════════════════════════════════════════════════
 
	if current_character.characterData.is_player_controlled:
		ui.MenuPerso.select_character(current_character.characterData)
		await get_tree().process_frame
		current_character.sprite.modulate = current_character.CharaColor
	else:
		await get_tree().create_timer(1.5).timeout
		current_character.play_ai_turn(heroes, enemies)
		await end_currentChara_Turn()
		
		
# ─────────────────────────────────────────────────────────────────────
#  Effets de début de round (allié passif non ciblable)
#  Applique chaque SkillEffect de round_effects sur tous les héros vivants.
#  Pour ajouter un effet : créer une ressource SkillEffect dans l'inspecteur
#  et l'ajouter au tableau round_effects du CombatManager.
# ─────────────────────────────────────────────────────────────────────
func _trigger_round_effects() -> void:
	if round_effects.is_empty():
		return

	
	var caster: Character = null
	for hero in heroes:
		if is_instance_valid(hero) and not hero.is_dead():
			caster = hero
			break

	if caster == null:
		return

	for hero in heroes:
		if not is_instance_valid(hero) or hero.is_dead():
			continue
		if hero._current_slot == null:
			continue
		for effect: SkillEffect in round_effects:
			effect.apply(caster, hero._current_slot)
		hero.update_ui()


func end_currentChara_Turn():
	if current_character.characterData.current_stamina >= 0:
		print("🚫 SKIP TURN: ", current_character.characterData.Charaname,
		" stamina=", current_character.characterData.current_stamina,
		" stun=", current_character.characterData.stun,
		" grab=", current_character.characterData.grab,
		" horny=", current_character.characterData.current_horniness)
	await get_tree().create_timer(1.5).timeout
	current_character.end_turn()
	while is_animation_playing():
		await get_tree().process_frame
	
	turn_queue.append(current_character)
	await flush_endTurn_affinity_reactions()
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
	#print("-_-_-_-_  "+ str(active_animations) )
func _on_skill_animation_finished():
	active_animations -= 1

func is_animation_playing() -> bool:
	return active_animations > 0
	
func _is_incapacitated(c: Character) -> bool:
	if not is_instance_valid(c) or c.characterData == null:
		return true
	if c.is_dead():
		return true
	if c.characterData.current_stamina <= 0:
		return true
	if c.characterData.current_horniness >= c.characterData.max_horniness:
		return true
	if c.characterData.grab:
		return true
	return false
	

func _check_victory():
	# ── 1. Nettoyage des ennemis MORTS (libère grabs, slots, queue_free) ──
	for enemy: Character in enemies.duplicate():
		if enemy.dead:
			turn_queue.erase(enemy)
			if enemy.CharaGrab != null:
				enemy.CharaGrab._current_slot.remove_character()
				enemy.CharaGrab.characterData.grab = false
				enemy.CharaGrab.visible = true
				for pos: PositionSlot in hero_positions:
					if not pos.is_occupied():
						pos.assign_character(enemy.CharaGrab, 0.3)
			if enemy._current_slot:
				enemy._current_slot.remove_character()
			enemies.erase(enemy)
			enemy.queue_free()
 
	# ── 2. Victoire : aucun ennemi en état de combattre ──
	var any_active_enemy := false
	for enemy: Character in enemies:
		if not _is_incapacitated(enemy):
			any_active_enemy = true
			break
 
	if not any_active_enemy:
		# Bonus cristaux : chaque démon encore présent (vivant mais incapacité)
		# en donne 1. Les démons morts par magie ont déjà été comptés dans
		# Character.take_damage().
		for enemy: Character in enemies:
			if is_instance_valid(enemy) \
					and enemy.characterData \
					and enemy.characterData.IsDemon \
					and not enemy.is_dead():
				nb_crystaleloot += 1
				print("💎 +1 cristal (démon incapacité : ", enemy.characterData.Charaname, ")")
		_show_victory()
 
 
func _check_defeat():
	# ── 1. Nettoyage des héros morts ──
	for ally: Character in heroes.duplicate():
		if ally.dead:
			turn_queue.erase(ally)
			if ally._current_slot:
				ally._current_slot.remove_character()
			ScreenLooseChara.visible = true
			pause = true
			heroes.erase(ally)
			ally.queue_free()
 
	# ── 2. Défaite : aucun héros en état de combattre ──
	var any_active_hero := false
	for ally: Character in heroes:
		if not _is_incapacitated(ally):
			any_active_hero = true
			break
 
	if not any_active_hero:
		combatEnd = true
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
	if is_animation_playing():
		return
	var skill = current_character.get_skill(index)
	pending_skill = skill
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
 
		# ── Premier groupe de cibles ──────────────────────────────────
		CombatState.SELECTING_FIRST_TARGET:
			if pending_skill.two_target_Type:
				pending_skill.target1 = targets
				combat_state = CombatState.SELECTING_SECOND_TARGET
				start_target_selection(pending_skill)
				return
 
			# ── 1. Animation d'abord ──────────────────────────────────
			if pending_skill.name != "move":
				var target_chars := _slots_to_characters(targets)
				if not target_chars.is_empty():
					await current_character.animate_attack(target_chars, pending_skill)
 
			# ── 2. Effets après ───────────────────────────────────────
			for slot in targets:
				if slot.occupant != null:
					await pending_skill.use(slot)
					if slot.occupant != null:
						slot.occupant.update_ui()
					ui.update_ui_for_current_character(current_character)
 
			await flush_startSkills_affinity_reaction()
			_play_skill_sound(pending_skill)
			ui.log(pending_skill.name)
			pending_skill.end_turn(self)
			pending_skill = null
 
		# ── Deuxième groupe de cibles ─────────────────────────────────
		CombatState.SELECTING_SECOND_TARGET:
 
			# ── 1. Animation d'abord ──────────────────────────────────
			if pending_skill.name != "move":
				var target_chars := _slots_to_characters(pending_skill.target1)
				if not target_chars.is_empty():
					await current_character.animate_attack(target_chars, pending_skill)
 
			# ── 2. Effets après ───────────────────────────────────────
			for slot in pending_skill.target1:
				if slot.occupant != null:
					await pending_skill.use(slot)
					slot.occupant.update_ui()
 
			for slot in targets:
				if slot.occupant != null:
					await pending_skill.use(slot, true)
					slot.occupant.update_ui()
 
			await flush_startSkills_affinity_reaction()
			_play_skill_sound(pending_skill)
			ui.log(pending_skill.name)
			pending_skill.end_turn(self)
			pending_skill = null

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
func move_character_to_async(character: Character, slot: PositionSlot, movetime: float) -> void:
	if slot == null or not is_instance_valid(character):
		return
 
	slot.Set_CharaUI()
	if slot.CharaUI != null:
		slot.CharaUI.visible = true
 
	await slot.assign_character(character, movetime)
 
	if not is_instance_valid(character):
		return
	character._current_slot = slot
	character.update_ui()
 

func swap_characters(slot_a: PositionSlot, slot_b: PositionSlot,movetime: float):
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
func get_hero_by_name(chara_name: String) -> Character:
	for hero in heroes:
		if hero.characterData.Charaname == chara_name:
			return hero
	return null
func queue_endTurn_affinity_reaction(reaction: Callable) -> void:
	endTurn_affinity_reaction_queue.append(reaction)

func queue_startSkills_affinity_reaction (reaction: Callable) -> void:
	startSkills_affinity_reaction_queue.append(reaction)
	
func flush_startSkills_affinity_reaction()->void:
	for reaction in startSkills_affinity_reaction_queue:
		await reaction.call()
		
	startSkills_affinity_reaction_queue.clear()
	
func flush_endTurn_affinity_reactions() -> void:
	for reaction in endTurn_affinity_reaction_queue:
		await reaction.call()
	endTurn_affinity_reaction_queue.clear()
	
func PassButtonDown():
	if current_character and current_character.characterData.is_player_controlled:
		await end_currentChara_Turn()
		
## Retourne les Character occupant les slots (filtre les slots vides)
func _slots_to_characters(slots: Array[PositionSlot]) -> Array[Character]:
	var result: Array[Character] = []
	for slot in slots:
		if slot.occupant != null:
			result.append(slot.occupant)
	return result
 
 
## Joue le son de la skill si présent
func _play_skill_sound(skill: Skill) -> void:
	if skill.attack_sound != null:
		audio.stream = skill.attack_sound
		audio.pitch_scale = randf_range(0.9, 1.0)
		audio.play()
