extends Node2D
class_name Character

# --- Données visuelles
@onready var name_label = $name
@onready var sprite : TextureRect = $pivot/HerosTexture1
var hp_Jauge
var hornyJauge
const MAX_EQUIPMENT = 2

@onready var Selector:TextureRect =$pivot/Selector

# état
var taunted_by: Character = null
var taunt_duration: int = 0
var buffs: Array[Buff] = []
var _current_slot: PositionSlot = null


var CharaScale:Vector2 = Vector2(1.0, 1.0)

var dead: bool = false

var buff_icons: Array = []

# --- Compétences
var skills: Array[Skill] = []


# --- Tags (type, classe, etc.)

# combat
var combat_manager: CombatManager = null 
# --- Contrôle

const HornyEffectScene := preload("res://actions/damageEffect/charmed-particules.tscn")
const DamageEffectScene := preload("res://actions/damageEffect/HitVFX.tscn")
const healEffectScene := preload("res://actions/damageEffect/HealVFX.tscn")
const MissEffectScene:= preload("res://actions/damageEffect/miss_vfx.tscn")
const DebuffEffectScene:= preload("res://actions/damageEffect/debuffVfx.tscn")
const BonkEffectScene:= preload("res://actions/damageEffect/bonkVFX.tscn")
const buffui:= preload("res://UI/buffUi.tscn")
signal target_selected()
var is_targetable: bool = false
@onready var arrow = $Arrow
@onready var buff_bar=$HBoxContainer
@onready var dotsActions : Array[TextureRect]  

var exclamation :TextureRect
var CharaColor =Color(1.0,1.0,1.0,1.0)
var acte_twice : bool = false
var exibBonusAtt = 0

var current_bark: Bark = null
@export var characterData : CharacterData
var current_skill: Skill = null
var cam : Camera

var ShadowBackground: Sprite2D
var getattacked:bool=false
var attacking: bool = false

func set_current_slot(value):
	_current_slot = value

func get_current_slot():
	return _current_slot

func _ready():
	cam = get_viewport().get_camera_2d()

	
	arrow.visible=false
	if characterData:
		name_label.text = characterData.Charaname
		sprite.texture = characterData.portrait_texture
		Selector.texture = characterData.portrait_texture
		_updateSkills(characterData.skill_resources)
	else:
		push_warning("CharacterData non assignée pour %s" % name)
	if characterData.is_player_controlled==false :
		sprite.flip_h=true
		Selector.flip_h=true
func _updateSkills(updated_skills: Array[Resource] ):
	skills.clear()
	for s in updated_skills:
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst= s.duplicate()
		inst.owner = self
		var base_cd = inst.cooldown
		var reduced_cd = base_cd - get_equipement_cooldown_reduction_for(inst)
		reduced_cd = max(0, reduced_cd)
		inst.cooldown = reduced_cd
		skills.append(inst)

func update_stats():
	if not characterData:
		return

	characterData.max_stamina = characterData.base_max_stamina
	characterData.max_horniness = characterData.base_max_horniness
	characterData.max_stress = characterData.base_max_stress

	characterData.attack = characterData.base_attack
	characterData.defense = characterData.base_defense
	characterData.initiative = characterData.base_initiative
	characterData.willpower = characterData.base_willpower
	characterData.evasion = characterData.base_evasion

	for tag in characterData.tags:
		if tag == "sadist":
			characterData.attack += 2
		elif tag == "maso":
			characterData.evasion = max(0, characterData.evasion - 2)
	for buff in characterData.buffs:
		add_buff(buff)
	characterData.buffs.clear()
	for buff in buffs:
		buff.apply_to(self)

	for eq in characterData.equipped_items:
		characterData.attack += eq.attack_bonus
		characterData.defense += eq.defense_bonus
		characterData.max_horniness += eq.Max_lust_bonus
		characterData.max_stamina += eq.Max_stamina_bonus
		characterData.max_stress += eq.Max_Guilt_bonus
		characterData.willpower += eq.willpower_bonus
		characterData.evasion += eq.evasion_bonus
		characterData.initiative += eq.initiative_bonus

func get_equipement_cooldown_reduction_for(skill: Skill) -> int: # for equipement
	var reduction := 0
	if not characterData:
		return reduction

	for eq in characterData.equipped_items:
		reduction += eq.global_cooldown_reduction
		if skill.name in eq.skill_specific_cooldown:
			reduction += eq.skill_specific_cooldown[skill.name]

	return reduction

func show_bark(text:String):
	if not characterData or characterData.bark_scene == null:
		return

	if current_bark and is_instance_valid(current_bark):
		current_bark.queue_free()

	current_bark = characterData.bark_scene.instantiate()
	add_child(current_bark)
	current_bark.set_text(text)
	var bark_offset_y := -240
	current_bark.position = Vector2(-60, bark_offset_y)

func slur():
	if characterData:
		show_bark(characterData.taunts.pick_random())

func update_ui():
	if hp_Jauge == null and _current_slot != null:
		_current_slot.Set_CharaUI()
		hp_Jauge = _current_slot.CharaUI.getHpbar()
		hornyJauge = _current_slot.CharaUI.get_HornyBar()
		dotsActions = _current_slot.CharaUI.getactionpoints()

	if not characterData:
		return

	if hp_Jauge:
		hp_Jauge.max_value = characterData.max_stamina
		hp_Jauge.value = characterData.current_stamina

	if hornyJauge:
		hornyJauge.self_modulate.a = (characterData.current_horniness * 2.0) / characterData.max_horniness

	for i in range(skills.size()):
		if i < dotsActions.size():
			var dot = dotsActions[i]
			var skill = skills[i]
			if skill.current_cooldown == 0:
				dot.modulate = Color(0.642,0.561,0.365)
				dot.size = Vector2(0.1,0.1)
			else:
				dot.modulate = Color(0.1,0.1,0.1)
				dot.size = Vector2(0.5, 0.5)
	
func add_buff(buff: Buff):
	var new_buff = buff.duplicate()
	buffs.append(new_buff)
	var icon =buffui.instantiate()
	icon.updatebuff(buff)
	if buff_bar == null:
		buff_bar = $HBoxContainer
	buff_bar.add_child(icon)
	buff_icons.append(icon)
	update_stats()
	print( " add buff "+buff.name+ " to "+characterData.Charaname)
	
	
func process_taunt():
	if taunt_duration > 0:
		taunt_duration -= 1
		if taunt_duration <= 0:
			taunted_by = null

func update_buffs() -> void:
	print("update buff for " + characterData.Charaname+ " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	for buff in buffs:
		buff.duration -= 1
		if buff.duration <= 0:
			remove_buff(buff)
	update_stats()

func remove_buff(buff: Buff):
	var index := buffs.find(buff)
	
	buffs.remove_at(index)
	var icon = buff_icons[index]
	if is_instance_valid(icon):
		icon.queue_free()
	buff_icons.remove_at(index)
	print ("remove buff "+ buff.name)
	update_stats()

func get_stat(stat_enum: int) -> int:
	var base_value = 0
	match stat_enum:
		Buff.Stat.ATTACK:
			base_value = characterData.base_attack
		Buff.Stat.DEFENSE:
			base_value = characterData.base_defense
		Buff.Stat.SPEED:
			base_value = characterData.base_initiative
		_:
			print("Stat inconnue : ", stat_enum)

	for buff in buffs:
		if buff.stat == stat_enum:
			base_value += buff.amount

	return base_value

func get_skill(index: int) -> Skill:
	if index >= 0 and index < skills.size():
		return skills[index]
	else:
		push_error("Skill index %d out of bounds for character %s" % [index, name])
		return null

func is_dead() -> bool:
	return dead

func can_act() -> bool:
	return not is_dead() and characterData and characterData.current_stress < 100 and characterData.current_horniness < 100

func set_targetable(state: bool):
	is_targetable = state
	arrow.visible = state
	if state:
		sprite.modulate = Color(1, 1, 1)
		Selector.visible=true
	else:
		sprite.modulate = Color(0.5, 0.5, 0.5)
		Selector.visible=false

func _input_event(_viewport, event, shape_idx):
	if is_targetable and event is InputEventMouseButton and event.pressed:
		emit_signal("target_selected", self)

func surprised():
	if characterData:
		characterData.stun = true
	exclamation = TextureRect.new()
	exclamation.texture = preload("res://UI/exclamation.png")
	exclamation.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	exclamation.custom_minimum_size = Vector2(32, 32)
	exclamation.position = Vector2(0, -164)
	add_child(exclamation)

func play_ai_turn(heroes : Array, enemies :Array):
	if not characterData or characterData.ai_brain == null:
		push_error("Aucun AiBrain assigné à %s" % name)
		return

	var decision = characterData.ai_brain.decide_action(self, heroes, enemies)
	if decision.is_empty():
		print("no decision")
		resetVisuel()
		return

	current_skill = decision["skill"]
	var targetPosistions: Array[PositionSlot] = decision.get("target", null)
	var target = targetPosistions[0].occupant
	combat_manager.pending_skill = current_skill
	current_skill.owner = self

	if target == null:
		current_skill.use()
		combat_manager.ui.logennemi(characterData.Charaname + " use " + current_skill.descriptionName)
	else:
		sprite.texture = current_skill.ImageSkill
		await animate_attack(targetPosistions[0].occupant)
		for thetarget in targetPosistions:
			current_skill.use(thetarget)
		combat_manager.ui.log(characterData.Charaname + " use " + current_skill.descriptionName)
		target.update_ui()
		#current_skill.end_turn(combat_manager)
	update_buffs()
	resetVisuel()

func reduce_cooldowns() -> void:
	for skill in skills:
		if skill.current_cooldown > 0:
			skill.current_cooldown -= 1

func start_turn():
	if not characterData:
		return
	print(characterData.Charaname + " start turn")

	var dmg = 0
	var dmgHorny = 0
	for buff in buffs:
		if buff.name == "poison":
			dmg += buff.amount
		if buff.name == "poisonHorny":
			dmgHorny += buff.amount
	if dmg > 0:
		take_damage(self, DamageEffect.Stat.STAMINA, dmg, false)
	elif dmgHorny > 0:
		take_damage(self, DamageEffect.Stat.HORNY, dmgHorny, false)
	else:
		await animate_start_Turn()

	update_stats()
	combat_manager.ui.update_ui_for_current_character(self)

func end_turn():
	CharaColor = Color(1.0,1.0,1.0,1.0)
	update_buffs()
	resetVisuel()

	reduce_cooldowns()
	combat_manager.ui.update_ui_for_current_character(self)
	

func isdead():
	dead = true
	print(characterData.Charaname + " is dead")

func select_as_target():
	print("Cible sélectionnée : ", self.name)
	combat_manager.select_target(self)
	arrow.visible = false

func take_damage(source: Character, stat: int, amount: int, typeMagic:bool, skillused: Skill= null) -> void:
	var damage := 0
	for buff in buffs:
		if buff.name == "Target":
			combat_manager.pending_skill.reducecost = buff.amount
	sprite.texture = characterData.Hit_texture
	match stat:
		DamageEffect.Stat.STAMINA:
			for tag in characterData.tags:
				if tag == "maso":
					var littlebuff := load("res://characters/kink/littleattackbuff.tres")
					add_buff(littlebuff)
					characterData.current_horniness = max(0, characterData.current_horniness + 2)

			if source != self:
				for tag in source.characterData.tags:
					if tag == "sadist":
						source.characterData.current_horniness = max(0, source.characterData.current_horniness + 2)
					if tag == "degrader":
						source.characterData.current_horniness = max(0, source.characterData.current_horniness + floor(characterData.current_stress / 2))

				damage = max(0, ((amount + source.characterData.attack) - characterData.defense))
				print(self.name + " take " + str(damage) + " damage from " + source.name)
			else:
				damage = amount

			for eq in characterData.equipped_items:
				eq.on_receive_attack(self, source, damage)

			if characterData.current_stamina > 0:
				characterData.current_stamina = clamp(characterData.current_stamina - damage, 0, characterData.max_stamina)
				if characterData.current_stamina == 0:
					sprite.self_modulate = Color(0.8, 0.1, 0.1)
					
			else:
				if characterData.IsDemon and typeMagic==true:
					combat_manager.nb_crystaleloot += 1
				isdead()

			if dead:
				animate_bonk()
			else:
				await animate_take_damage(damage, source)

		DamageEffect.Stat.HORNY:
			damage = amount
			if source == self:
				characterData.current_horniness = max(0, characterData.current_horniness + damage)
			else:
				damage = max(0, amount - characterData.willpower)
				characterData.current_horniness = max(0, characterData.current_horniness + damage)

			for eq in characterData.equipped_items:
				eq.on_receive_attack(self, source, damage)
			
			animate_get_horny(damage,source)
			update_ui()

		DamageEffect.Stat.STRESS:
			for tag in characterData.tags:
				if tag == "exib":
					amount -= 2
					take_damage(self, DamageEffect.Stat.STAMINA, 2, false)
					characterData.attack -= exibBonusAtt
					exibBonusAtt = floor(characterData.current_stress / 10)
					characterData.attack += exibBonusAtt
				if tag == "degenerate":
					var usedSkills : Array[Skill] = []
					for skill in skills:
						if skill.current_cooldown > 0:
							usedSkills.append(skill)
					if not usedSkills.is_empty():
						var reduceCooldownSkill :Skill = usedSkills.pick_random()
						reduceCooldownSkill.current_cooldown -= 1
					characterData.current_horniness = max(0, characterData.current_horniness + 2)

			damage = max(0, amount - characterData.willpower)
			characterData.current_stress = max(0, characterData.current_stress + damage)

	shake_camera(20.0)
	update_ui()

func resetVisuel():
	sprite.modulate = CharaColor
	self.scale = CharaScale
	if _current_slot&& not attacking&& not getattacked:
		self.z_index = _current_slot.z_index
	if characterData and characterData.current_stamina > 0 && not attacking&& not getattacked:
		sprite.texture = characterData.portrait_texture
		Selector.texture = characterData.portrait_texture
	if not attacking && not getattacked:
		self.global_position= _current_slot.global_position
	if characterData and characterData.current_stamina == 0:
		sprite.texture =characterData.dead_portrait_texture
		Selector.texture =characterData.dead_portrait_texture
	
	if !characterData.stun && characterData.current_stamina>0:
		modulate=Color(1.0,1.0,1.0)
	#print ("reset " + characterData.Charaname )
	
	update_ui()
	

func refresh_stats_from_equipment():
	characterData.attack = characterData.base_attack
	characterData.defense = characterData.base_defense
	characterData.willpower = characterData.base_willpower
	characterData.evasion = characterData.base_evasion
	characterData.initiative = characterData.base_initiative

	for eq in characterData.equipped_items:
		characterData.attack += eq.attack_bonus
		characterData.defense += eq.defense_bonus
		characterData.willpower += eq.willpower_bonus
		characterData.evasion += eq.evasion_bonus
		characterData.initiative += eq.initiative_bonus

func add_affinity(target: Character, amount: int):
	var key := target.characterData.Charaname
	if not characterData.affinity.has(key):
		return
	characterData.affinity[key] = clampi(characterData.affinity[key] + amount, 0, 100)

func reduce_affinity(target: Character, amount: int):
	add_affinity(target, -amount)

func get_affinity(target: Character) -> int:
	var key := target.characterData.Charaname
	if characterData.affinity.has(key):
		return characterData.affinity[key]
	return 0

# ------------------------------- Animation ------------------------------------------------
#--------Animation variables-----------------------
var start_pos
var normal_size
var attack_pos : Vector2
var target_pos : Vector2
var start_target_pos : Vector2
var outline : TextureRect
signal skill_animation_started
signal skill_animation_finished

func animate_start_Turn():
	emit_signal("skill_animation_started")
	var tween := create_tween() as Tween
	CharaScale = _current_slot.position_data.scale if _current_slot else CharaScale
	var normal_size = CharaScale
	var big_size = Vector2(normal_size.x * 1.1, normal_size.y * 1.3)
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")

func animate_get_horny(damage:int, source: Character = null):
	emit_signal("skill_animation_started")
	sprite.texture = characterData.Hit_texture
	var effect_instance = HornyEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -30)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage)
	if source== self:
		var tween := create_tween() as Tween
		var normal_size = CharaScale
		var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3)
		tween.tween_property(self, "scale", big_size, 0.2)
		tween.tween_property(self, "scale", normal_size, 0.2)
		await tween.finished
		sprite.texture = characterData.portrait_texture
	emit_signal("skill_animation_finished")

func animate_take_damage(damage:int, source:Character, usedSkill :Skill = null):
	
	emit_signal("skill_animation_started")
	await get_tree().create_timer(0.2).timeout

	if characterData.current_stamina>0:
		sprite.texture = characterData.Hit_texture
	var effect_instance = DamageEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(50, -140)
	
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage, Color(1,0.4,0.3))

	var normal_size = CharaScale
	var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3)
	var start_pos = position
	var direction = (source.global_position - global_position).normalized()
	var offset = direction * 10
	var dam_pos = start_pos + offset
	await get_tree().create_timer(0.5).timeout
	if source== self:
		if characterData.current_stamina>0:
			sprite.texture = characterData.portrait_texture
	#if source== self:
	#	var tween := create_tween() as Tween
	#	var tween2 := create_tween() as Tween
	#	tween.tween_property(self, "scale", big_size, 0.2)
	#	tween.tween_property(self, "scale", normal_size, 0.2)
	#	tween2.tween_property(self, "position", dam_pos, 0.02).set_delay(0.3)
	#	tween2.tween_property(self, "position", start_pos, 0.2)
	#	print ("self attacked------------------------------------------------------------")
		
	#	await tween.finished
	emit_signal("skill_animation_finished")

func animate_heal(damage:int, _source:Character, color=null):
	emit_signal("skill_animation_started")
	var delay =0.5
	await get_tree().create_timer(0.2).timeout
	if _source.characterData.Charaname == "Mystic":
		delay=1.0
	var effect_instance = healEffectScene.instantiate()
	#if _source == self:
	#	var tween := create_tween() as Tween
	#	var normal_size = CharaScale
	#	var big_size= Vector2(1.0,1.05)
	#	tween.tween_property(self, "scale", big_size, 0.2).set_delay(delay)
	#	tween.tween_property(self, "scale", normal_size, 0.2)
	#	await tween.finished
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(100, -240)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage,color)
	emit_signal("skill_animation_finished")

func DebuffAnim(text):
	emit_signal("skill_animation_started")
	var effect_instance = DebuffEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -210)
	if effect_instance.has_method("setup"):
		effect_instance.setup(text)
	emit_signal("skill_animation_finished")

func animate_attack(target: Character, _duration = 1.0):
	target.buff_bar.visible=false
	buff_bar.visible=false
	attacking = true
	target.getattacked=true
	_duration = 1.1
	emit_signal("skill_animation_started")
	combat_manager.ui.log(characterData.Charaname + " use " + combat_manager._pending_skill.descriptionName)
	var tween := create_tween() as Tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	self.z_index = 20
	target.z_index = 20
	var offset : Vector2
	
	target.sprite.texture=target.characterData.Hit_texture
	
	sprite.texture = current_skill.ImageSkill
	target.modulate.a = 0.0
	Selector.visible=false
	if sprite.texture == current_skill.ImageSkill:
		print ("change for skill texture  " + characterData.Charaname )
	start_pos = position
	start_target_pos =target.position
	target_pos = start_target_pos
	target_pos.y += 50
	
	var cam_bigZoom = Vector2(cam.baseZoom*1.1)
	if characterData.is_player_controlled:
		self.global_position =Vector2(-200,728)
	else :
		self.global_position  =Vector2(2000,728)
	
		
	if target.characterData.is_player_controlled:
		target_pos = Vector2(643,700)
	else :
		target_pos = Vector2(1300,700)

#--------------------contact---------------------------
	if target.characterData.size == "Small":
		target_pos.y -= 10
		if characterData.size == "Big":
			attack_pos.y +=250
	var direction = (target.global_position - global_position).normalized()
	if current_skill.is_contact:
		offset = direction * -current_skill.distance_contact
		attack_pos =  target_pos + offset
		if target.characterData.Charaname == "Slime":
			attack_pos.y += 70
		if target.characterData.size == "Big":
			target_pos.y += 70
			
		if !target.characterData.is_player_controlled:
			position=Vector2(-400,728)
		else:
			position=Vector2(2000,728)
			
				
#--------------------distance---------------------------
	else :
		offset = direction * 40
		if characterData.is_player_controlled:
			attack_pos = Vector2(643,728)
			if target.characterData.is_player_controlled:
				attack_pos = Vector2(443,728)
				target_pos = Vector2(843,728)
		else :
			attack_pos = Vector2(1400,728)
			if !target.characterData.is_player_controlled:
				attack_pos = Vector2(1500,750)
				target_pos = Vector2(1043,728)
				if target.characterData.Charaname == "Small":
					target_pos.y -= 00
			if characterData.Charaname == "Slime":
				attack_pos.y -= 70
	if target.sprite.texture == target.characterData.dead_portrait_texture && target.characterData.IsDemon:
		target_pos.y = 600
		
	sprite.texture = current_skill.ImageSkill

	normal_size = self.scale
	var big_size= normal_size*2
	
	self.modulate.a =0
	var timmmmmm = 0.1
	
	tween.parallel().tween_property(self, "position", attack_pos, timmmmmm)
	tween.parallel().tween_property(self, "scale", big_size, 0.0)
	tween.parallel().tween_property(self, "modulate:a", 1.0, timmmmmm)
	tween.parallel().tween_property(target, "scale", big_size, timmmmmm)
	tween.parallel().tween_property(target, "position", target_pos, timmmmmm)
	tween.parallel().tween_property(target, "modulate:a", 1.0, timmmmmm)
	
	tween.tween_callback(Callable(self, "_on_attack").bind(target, _duration))

	tween.parallel().tween_property(ShadowBackground, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(cam, "zoom", cam_bigZoom , timmmmmm)
	var camtargetpos = cam.position
	
	if current_skill.is_contact:
		#offset = direction * -current_skill.distance_contact
		#attack_pos =  target_pos + offset
		if !target.characterData.is_player_controlled:
			camtargetpos.x += 90
			tween.parallel().tween_property(cam, "position", camtargetpos , timmmmmm)
		else:
			camtargetpos.x -= 90
			tween.parallel().tween_property(cam, "position", camtargetpos , timmmmmm)
	
	
func _on_attack(target: Character, _duration: float =1.0):
	self.z_index = 6
	target.z_index = 6
	var tween = null
	var has_changeMask := current_skill.effects.any(func(e): return e is ChangeSkill)
	var has_heal := current_skill.effects.any(func(e): return e is HealEffect)
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	if !has_heal:
		if target.characterData.current_stamina >0:
			target.sprite.texture =target.characterData.Hit_texture
			target.Selector.texture = target.characterData.Hit_texture

	sprite.texture = current_skill.ImageSkill
	
	tween.parallel().tween_property(self, "position", _current_slot.global_position, 0.2).set_delay(_duration)
	tween.parallel().tween_property(self, "scale", normal_size, 0.2).set_delay(_duration)
	tween.parallel().tween_property(target, "scale", normal_size, 0.3).set_delay(_duration)
	
	tween.parallel().tween_property(target, "position", target._current_slot.global_position, 0.3).set_delay(_duration)
	tween.parallel().tween_property(cam, "zoom", cam.baseZoom, 0.3).set_delay(_duration)
	tween.parallel().tween_property(ShadowBackground, "modulate:a", 0.0, 0.3).set_delay(_duration)
	tween.parallel().tween_property(cam, "position", Vector2(960,540) ,0.3).set_delay(_duration)
	await tween.finished
	
	after_skilluse(target)
	
	
func after_skilluse(target: Character):
	attacking =false
	target.getattacked=false
	for tag in characterData.tags:
					if tag == "degrader":
						slur()
	for eq in characterData.equipped_items:
		eq.after_skill_use(self,current_skill, target)
	sprite.texture = characterData.portrait_texture
	
	Selector.visible=true
	if target.characterData.current_stamina>0:
		target.Selector.texture=target.characterData.portrait_texture
		target.sprite.texture = target.characterData.portrait_texture
	
	target.scale=target._current_slot.position_data.scale
	if _current_slot:
		self.z_index = _current_slot.z_index
	if target._current_slot:
		target.z_index = target._current_slot.z_index
	buff_bar.visible=true
	target.buff_bar.visible=true
	emit_signal("skill_animation_finished")
		
func miss_animation(target: Character):
	emit_signal("skill_animation_started")
	var Misseffect_instance= MissEffectScene.instantiate()
	get_tree().current_scene.add_child(Misseffect_instance)
	Misseffect_instance.global_position = global_position + Vector2(0, -140)
	if Misseffect_instance.has_method("setup"):
		Misseffect_instance.setup()
	var tween := create_tween() as Tween
	var start_pose 
	if characterData.is_player_controlled:
		start_pose = Vector2(543,728)
	else :
		start_pose = Vector2(1643,728)

	var direction = (target.global_position - global_position).normalized()
	
	var esquiv_pose= start_pose
	esquiv_pose.x -= 100
	
	if self.characterData.Charaname == "Small" :
		esquiv_pose.y = self.position.y
	tween.tween_property(self, "position", esquiv_pose, 0.00)
	tween.tween_property(self, "position", start_pose, 0.2).set_delay(0.2)
	await tween.finished
	emit_signal("skill_animation_finished")

func animate_bonk(): 
	emit_signal("skill_animation_started")
	if !characterData.IsDemon:
		var effect_instance = BonkEffectScene.instantiate()
		get_tree().current_scene.add_child(effect_instance)
		effect_instance.global_position = global_position + Vector2(0, -30)
		if effect_instance.has_method("setup"):
			effect_instance.setup(0)
		
	emit_signal("skill_animation_finished")

func shake_camera(strength := 5.0):
	
	if cam and cam.has_method("shake"):
		cam.shake(strength)
