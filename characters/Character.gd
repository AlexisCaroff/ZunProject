extends Node2D
class_name Character
#save

# --- Données visuelles
@export var portrait_texture: Texture2D
@export var explorationPortrait:Texture2D
@export var dead_portrait_texture: Texture2D
@export var initiative_icon: Texture2D
@onready var name_label = $name
@export var textureCamp: Texture2D

@onready var hp_Jauge 
@onready var hornyJauge 
@onready var sprite = $pivot/HerosTexture1

@onready var buff_bar = $HBoxContainer
@export var Charaname: String = "name"
@export var IsDemon: bool = false
# --- Stats de combat
@export var base_max_stamina: int = 100
@export var base_max_stress: int = 100
@export var base_max_horniness: int = 100

@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_willpower: int = 5
@export var base_initiative: int = 1
@export var base_evasion: int = 5
@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var evasion: int = 5
@export var initiative: int = 1
@export var peek :int =0
@export var equipped_items: Array[Equipment] = []
const MAX_EQUIPMENT = 2


@onready var Selector:TextureRect =$pivot/Selector

#etat
@export var stun : bool = false
var taunted_by: Character = null
var taunt_duration: int = 0
var buffs: Array[Buff] = []
@export var Chara_position:int = 0 

var _current_slot: PositionSlot = null
var current_slot:
	get: return _current_slot
	set(value):
		_current_slot = value
var CharaScale:Vector2 = Vector2(1.0, 1.0)

# --- Jauges
@export var max_stamina: int = 100
@export var max_stress: int = 100
@export var max_horniness: int = 100
@export var dead: bool = false
@export var current_stamina: int = 100
@export var current_stress: int = 0
@export var current_horniness: int = 0

var buff_icons: Array = []

# --- Compétences
var skills: Array[Skill] = []
@onready var skillText =$Skill
@export var skill_resources: Array[Resource] = []
# --- Tags (type, classe, etc.)
@export var tags: Array[String] = []
#combat
var combat_manager: Node = null 
# --- Contrôle
@export var is_player_controlled: bool = true
@export var ai_brain: AiBrain
@export var can_be_moved : bool = true
const HornyEffectScene := preload("res://actions/damageEffect/charmed-particules.tscn")
const DamageEffectScene := preload("res://actions/damageEffect/HitVFX.tscn")
const healEffectScene := preload("res://actions/damageEffect/HealVFX.tscn")
const MissEffectScene:= preload("res://actions/damageEffect/miss_vfx.tscn")
const DebuffEffectScene:= preload("res://actions/damageEffect/debuffVfx.tscn")
const BonkEffectScene:= preload("res://actions/damageEffect/bonkVFX.tscn")
@export var min_durationIddle: float = 0.6
@export var max_durationIddle: float = 1.0
@export var min_scale: float = 0.95
@export var max_scale: float = 1.0
signal target_selected()
var is_targetable: bool = false
@onready var arrow = $Arrow
@export var camp_skill_resources: Array[CampSkill] = []
@onready var dotsActions : Array[TextureRect] 


var exclamation :TextureRect
var CharaColor =Color(1.0,1.0,1.0,1.0)
var acte_twice : bool = false
var exibBonusAtt = 0
@export var bark_scene: PackedScene = preload("res://UI/bark.tscn")
@export var taunts := [
	"Is that all you've got?",
	"Try harder!",
	"Pathetic!",
	"You're wide open!",
	"You fight like a wet noodle!",
	"Oops! Did that hurt?",
	
]
var current_bark: Bark = null


func _ready():
	arrow.visible=false
	name_label.text = Charaname
	sprite.texture = portrait_texture
	Selector.texture = portrait_texture

	
	_updateSkills(skill_resources)

		#print("Compétence chargée : ", inst.name)


func _updateSkills(updated_skills: Array[Resource] ):
	skills.clear()
	for s in updated_skills:
		#print("Contenu de skill_resource :", s)
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst= s.duplicate()
		inst.owner = self
		var base_cd = inst.cooldown
		var reduced_cd = base_cd - get_equipement_cooldown_reduction_for(inst)
		reduced_cd = max(0, reduced_cd)
		inst.cooldown =reduced_cd
		skills.append(inst)
		
func update_stats():
	max_stamina= base_max_stamina
	max_horniness = base_max_horniness
	max_stress= base_max_stress
	attack = base_attack
	defense = base_defense
	initiative = base_initiative
	willpower = base_willpower
	evasion = base_evasion
	for tag in tags:
				if tag=="sadist":
					attack+=2
				if tag=="maso":
					evasion -=2
	for buff in buffs:
		buff.apply_to(self)
		
	for eq in equipped_items:
		attack += eq.attack_bonus
		defense += eq.defense_bonus
		max_horniness += eq.Max_lust_bonus
		max_stamina += eq.Max_stamina_bonus
		max_stress += eq.Max_Guilt_bonus
		willpower += eq.willpower_bonus
		evasion += eq.evasion_bonus
		initiative += eq.initiative_bonus
		
		
func get_equipement_cooldown_reduction_for(skill: Skill) -> int: #for equipement
	var reduction := 0

	for eq in equipped_items:
		# Réduction globale
		reduction += eq.global_cooldown_reduction

		# Réduction ciblée
		if skill.name in eq.skill_specific_cooldown:
			reduction += eq.skill_specific_cooldown[skill.name]

	return reduction

func show_bark(text:String):
	if bark_scene == null:
		return
	
	# Si un bark existe déjà, on le supprime avant d’en créer un nouveau
	if current_bark and is_instance_valid(current_bark):
		current_bark.queue_free()
	
	current_bark = bark_scene.instantiate()
	add_child(current_bark) # 🔥 Instancié comme enfant du personnage
	
	current_bark.set_text(text)
	
	# Position ajustée au-dessus du personnage
	var bark_offset_y :=  - 240 # un peu au-dessus de la tête
	current_bark.position = Vector2(-60, bark_offset_y)

func slur():
	show_bark(taunts.pick_random())
func update_ui():

	if not hp_Jauge:
		print("no hpJauge")
		_current_slot.Set_CharaUI()
		hp_Jauge=_current_slot.CharaUI.getHpbar()
		hornyJauge=_current_slot.CharaUI.get_HornyBar()
		dotsActions=_current_slot.CharaUI.getactionpoints()
		
	
		# return
	hp_Jauge.max_value=max_stamina
	hp_Jauge.value=current_stamina
	
	hornyJauge.self_modulate.a = (current_horniness*2.0)/max_horniness

	
	for i in range(skills.size()):
		if i<dotsActions.size():
			var dot = dotsActions[i]
			var skill= skills[i]
			if skill.current_cooldown == 0:
				dot.modulate = Color(0.642,0.561,0.365)
				dot.size = Vector2(0.1,0.1)
			else:
				dot.modulate = Color(0.1,0.1,0.1)
				dot.size = Vector2(0.5, 0.5)
	
	
func add_buff(buff: Buff):
	var new_buff = buff.duplicate()
	buffs.append(new_buff)
	var icon = TextureRect.new()
	icon.texture = buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	if buff_bar ==null:
		buff_bar =$HBoxContainer
	buff_bar.add_child(icon)
	buff_icons.append(icon)  # on stocke l’icône au même index
	update_stats()

func process_taunt():
	if taunt_duration > 0:
		taunt_duration -= 1
		if taunt_duration <= 0:
			taunted_by = null

func update_buffs() -> void:
	for buff in buffs:
		buff.duration -= 1
		if buff.duration<=0:
			remove_buff(buff)
			
	update_stats()

func remove_buff(buff: Buff):
	var index := buffs.find(buff)
	if index != -1:
		buffs.remove_at(index)

		var icon = buff_icons[index]
		if is_instance_valid(icon):
			icon.queue_free()
		buff_icons.remove_at(index)

	update_stats()

func get_stat(stat_enum: int) -> int:
	var base_value = 0
	match stat_enum:
		Buff.Stat.ATTACK: base_value = base_attack
		Buff.Stat.DEFENSE: base_value = base_defense
		Buff.Stat.SPEED: base_value = base_initiative
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
	return not is_dead() and current_stress < 100 and current_horniness < 100
	
	
func set_targetable(state: bool):
	is_targetable = state
	arrow.visible= state
	if state :
		sprite.modulate = Color(1, 1, 1)
		#print(Charaname+" is targetable")
	else:
		sprite.modulate = Color(0.5, 0.5, 0.5)
		#print(Charaname+" absolutly no a target")
	
		
func _input_event(viewport, event, shape_idx):
	if is_targetable and event is InputEventMouseButton and event.pressed:
		emit_signal("target_selected", self)
		

func surprised():
	stun=true
	exclamation = TextureRect.new()
	exclamation.texture = preload("res://UI/exclamation.png")  # ton image
	exclamation.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	exclamation.custom_minimum_size = Vector2(32, 32)

	exclamation.position = Vector2(0, -164)
	add_child(exclamation)
	
	
func play_ai_turn(heroes : Array, enemies :Array):
	if ai_brain == null:
		push_error("Aucun AiBrain assigné à %s" % name)
		return

	var decision = ai_brain.decide_action(self, heroes, enemies)
	if decision.is_empty():
		print("no decision")
		resetVisuel()
		return

	var skill: Skill = decision["skill"]
	var targetPosistions: Array[PositionSlot] = decision.get("target", null)
	var target = targetPosistions[0].occupant
	combat_manager.pending_skill = skill
	skill.owner = self

	if target == null:
		skill.use()
		combat_manager.ui.logennemi(Charaname+" use "+skill.descriptionName)
	else:
		await animate_attack(targetPosistions[0].occupant)
		for thetarget in targetPosistions:
			skill.use(thetarget)
		combat_manager.ui.log(Charaname+" use "+skill.descriptionName)
		target.update_ui()
	
	resetVisuel()

func reduce_cooldowns() -> void:
	for skill in skills:
		if skill.current_cooldown > 0:
			skill.current_cooldown -= 1	
func start_turn():
	print(Charaname+ "start turn")
	
	var dmg =0
	var dmgHorny=0
	for buff in buffs:
		if buff.name=="poison":
			print (str(buff.amount)+ "dmg")
			dmg += buff.amount
		if buff.name=="poisonHorny":
			print (str(buff.amount)+ "dmg horny")
			dmgHorny += buff.amount
	if dmg>0:
		take_damage(self,0,dmg,false)	
	elif dmgHorny>0:
		take_damage(self,1,dmgHorny,false)	
	else :
		animate_start_Turn()
	update_stats()
	combat_manager.ui.update_ui_for_current_character(self)
func end_turn():
	
	CharaColor=Color(1.0,1.0,1.0,1.0)
	resetVisuel()
	update_buffs()
	reduce_cooldowns()
	combat_manager.ui.update_ui_for_current_character(self)

	


func isdead():
	dead = true
	
	print (Charaname+ " is dead")
			
func select_as_target():
	print("Cible sélectionnée : ", self.name)
	combat_manager.select_target(self)
	arrow.visible=false

func take_damage(source: Character, stat: int, amount: int, type:bool) -> void:
	var damage := 0
	
	for buff in buffs:
		if buff.name == "Target":
			combat_manager.pending_skill.reducecost = buff.amount
	match stat:
		DamageEffect.Stat.STAMINA:
			for tag in tags:
				if tag=="maso":
					var littlebuff := load("res://characters/kink/littleattackbuff.tres")
					add_buff(littlebuff)
					current_horniness = max(0, current_horniness + 2)
			if source != self:
				for tag in source.tags:
					if tag =="sadist":
						source.current_horniness = max(0, source.current_horniness + 2)
					if tag =="degrader":
						source.current_horniness = max(0, source.current_horniness + floor(current_stress/2))
			if source != self:
				print (str(amount)+ " "+" -"+ str(defense))
				damage = max(0, ((amount + source.attack) - defense))
				print(self.Charaname+ " take "+ str(damage) +" damage from "+ source.Charaname)
			else :
				damage=amount
			for eq in equipped_items:
				eq.on_receive_attack(self, source, damage)
			if current_stamina > 0:
				
				current_stamina = clamp(current_stamina - damage, 0, max_stamina)
				
				if current_stamina == 0:
					
					sprite.self_modulate = Color(0.8, 0.1, 0.1)
					sprite.texture = dead_portrait_texture
					Selector.texture = dead_portrait_texture
			else:
				if IsDemon && type:
					combat_manager.nb_crystaleloot += 1 
				isdead()
			if dead:
				animate_bonk()
			else:
				animate_take_damage(damage, source)

		
				

		DamageEffect.Stat.HORNY:
			damage=amount
			if source == self:
				
				current_horniness = max(0, current_horniness + damage)
				print ("tack"+str(damage)+" dmg horny" )
			else :
				damage = max(0, amount - willpower)
				current_horniness = max(0, current_horniness + damage)
			for eq in equipped_items:
				eq.on_receive_attack(self, source, damage)
			animate_get_horny(damage)
			update_ui()
			

		DamageEffect.Stat.STRESS:
			for tag in tags:
				if tag=="exib":
					amount -= 2
					take_damage(self, 2, 2,false)
					attack -= exibBonusAtt
					exibBonusAtt =  floor(current_stress/10)
					attack += exibBonusAtt
				if tag=="degenerate":
					var usedSkills : Array[Skill]
					for skill in skills:
						if skill.current_cooldown >0:
							usedSkills.append(skill)
					if not usedSkills.is_empty():
						var reduceCooldownSkill :Skill = usedSkills.pick_random()
						reduceCooldownSkill.current_cooldown -=1
					current_horniness = max(0, current_horniness + 2)
					
			damage = max(0, amount - willpower)
			current_stress = max(0, current_stress + damage)
			
	shake_camera(20.0)
	#print("%s inflige %d de %s à %s" % [source.name, damage, DamageEffect.Stat.keys()[stat], name])
	update_ui()
	
	
	
func resetVisuel()-> void:
	sprite.modulate= CharaColor
	self.scale = CharaScale
	self.z_index = _current_slot.z_index
	if current_stamina > 0:
			sprite.texture = portrait_texture
			Selector.texture = portrait_texture
	update_ui()




func refresh_stats_from_equipment():
	attack = base_attack
	defense = base_defense
	willpower = base_willpower
	evasion = base_evasion
	initiative = base_initiative

	for eq in equipped_items:
		attack += eq.attack_bonus
		defense += eq.defense_bonus
		willpower += eq.willpower_bonus
		evasion += eq.evasion_bonus
		initiative += eq.initiative_bonus


#------------------------------- Animation ------------------------------------------------


var outline : TextureRect
signal skill_animation_started
signal skill_animation_finished

	
func animate_start_Turn():
	emit_signal("skill_animation_started")
	var tween := create_tween() as Tween
	CharaScale = current_slot.position_data.scale
	var normal_size = CharaScale
	var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")

func animate_get_horny(damage:int):
	emit_signal("skill_animation_started")
	var effect_instance = HornyEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)

	effect_instance.global_position = global_position + Vector2(0, -30)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage)
	var tween := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3) 
	tween.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
func animate_take_damage(damage:int, source:Character):
	emit_signal("skill_animation_started")
	var effect_instance = DamageEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage, Color(1,0.4,0.3))
		
	var tween := create_tween() as Tween
	var tween2 := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3) 
	tween.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	var start_pos = position
	var direction = (source.global_position + global_position).normalized()
	var offset = direction * 10
	var attack_pos = start_pos + offset
	tween2.tween_property(self, "position", attack_pos, 0.02).set_delay(0.02)
	tween2.tween_property(self, "position", start_pos, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
	
func animate_heal(damage:int, source:Character, color=null):
	emit_signal("skill_animation_started")
	var effect_instance = healEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage,color)
		
	var tween := create_tween() as Tween

	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.05) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
func DebuffAnim(text):
	emit_signal("skill_animation_started")
	var effect_instance = DebuffEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -210)
	if effect_instance.has_method("setup"):
		effect_instance.setup(text)
	
	emit_signal("skill_animation_finished")
	
func animate_attack(target: Character):
	emit_signal("skill_animation_started")
	combat_manager.ui.log(Charaname+ " use " + combat_manager._pending_skill.descriptionName)

	if is_player_controlled:
		combat_manager.SpriteHeros.attack_anim(self)
	else:
		combat_manager.SpriteEnnemies.attack_anim(self)
	var tween := create_tween() as Tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	self.z_index = 10 

	var start_pos = position
	var direction = (target.global_position - global_position).normalized()
	var offset = direction * -50
	var attack_pos = start_pos + offset
	var normal_size = self.scale
	var big_size= Vector2(2,2) 

	
	tween.parallel().tween_property(self, "position", attack_pos, 0.1)
	tween.parallel().tween_property(self, "scale", big_size, 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(1.0)
	tween.parallel().tween_property(self, "position", start_pos, 0.2).set_delay(1.0)
	tween.parallel().tween_property(self, "scale", normal_size, 0.2).set_delay(1.0)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished	
	
	emit_signal("skill_animation_finished")
	
func miss_animation(target: Character):
	emit_signal("skill_animation_started")
	var Misseffect_instance= MissEffectScene.instantiate()
	get_tree().current_scene.add_child(Misseffect_instance)

	Misseffect_instance.global_position = global_position + Vector2(0, -140)
	if Misseffect_instance.has_method("setup"):
		Misseffect_instance.setup()
	var tween := create_tween() as Tween
	
	var start_pose = position
	var direction = (target.global_position - global_position).normalized()
	var offset = direction * -50
	var esquiv_pose= start_pose + offset
	
	tween.tween_property(self, "position", esquiv_pose, 0.05)
	tween.tween_property(self, "position", start_pose, 0.2).set_delay(0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
func animate_bonk(): 
	emit_signal("skill_animation_started")
	var effect_instance = BonkEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)

	effect_instance.global_position = global_position + Vector2(0, -30)
	if effect_instance.has_method("setup"):
		effect_instance.setup(0)
	var tween := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(normal_size.x*1.1,normal_size.y*1.3) 
	tween.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
func shake_camera(strength := 5.0):
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(strength)
