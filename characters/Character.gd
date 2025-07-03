extends Node2D

class_name Character

# --- Données visuelles
@export var portrait_texture: Texture2D
@export var dead_portrait_texture: Texture2D
@export var initiative_icon: Texture2D
@onready var name_label = $name
@onready var hp_label = $HP
@onready var stress_label = $Stress
@onready var horny_label = $horny
@onready var sprite = $HerosTexture1
var combat_manager: Node = null 
@onready var buff_bar = $HBoxContainer
@export var Charaname: String = "name"

# --- Stats de combat
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_willpower: int = 5
@export var base_initiative: int = 1
@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var evasion: int = 5
@export var initiative: int = 1
@export var base_evasion: int = 5
@export var action_points: int = 2
@onready var Selector:TextureRect =$Selector

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
var current_stamina: int = max_stamina
var current_stress: int = 0
var current_horniness: int = 0

# --- Compétences
var skills: Array[Skill] = []
@export var skill_resources: Array[Resource] = []
# --- Tags (type, classe, etc.)
var tags: Array[String] = []

# --- Contrôle
@export var is_player_controlled: bool = true
const HornyEffectScene := preload("res://actions/damageEffect/charmed-particules.tscn")
const DamageEffectScene := preload("res://actions/damageEffect/HitVFX.tscn")
const MissEffectScene:= preload("res://actions/damageEffect/miss_vfx.tscn")

signal target_selected(target: Character)
var is_targetable: bool = false


func _ready():
	name_label.text = Charaname
	sprite.texture = portrait_texture
	Selector.texture = portrait_texture
	#sprite.mouse_filter=2

	update_ui()
	
	for s in skill_resources:
		#print("Contenu de skill_resource :", s)
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst= s.duplicate()
		inst.owner = self
		skills.append(inst)
		#print("Compétence chargée : ", inst.name)
func update_stats():

	attack = base_attack
	defense = base_defense
	initiative = base_initiative
	willpower = base_willpower

	
	for buff in buffs:
		buff.apply_to(self)

func update_ui():
	hp_label.text = "HP: %d / %d" % [current_stamina, max_stamina]
	stress_label.text = "Stress: %d / %d" % [current_stress, max_stress]
	horny_label.text = "Horny: %d / %d" % [current_horniness, max_horniness]
	
func add_buff(buff: Buff):
	buffs.append(buff.duplicate()) 
	var icon = TextureRect.new()
	icon.texture = buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)  # taille d'icône
	buff_bar.add_child(icon)
	update_stats()

func process_taunt():
	if taunt_duration > 0:
		taunt_duration -= 1
		if taunt_duration <= 0:
			taunted_by = null

func update_buffs() -> void:
	for buff in buffs:
		buff.duration -= 1
	buffs = buffs.filter(func(b): return b.duration > 0)
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
	if state :
		sprite.modulate = Color(1, 1, 1)
	else:
		sprite.modulate = Color(0.5, 0.5, 0.5)
		#print(self.name+"not targetable")
	
		
func _input_event(viewport, event, shape_idx):
	if is_targetable and event is InputEventMouseButton and event.pressed:
		emit_signal("target_selected", self)
		
		
func play_ai_turn(heroes : Array, ennemies :Array):
	var usable_skills := skills.filter(func(s): return s.can_use())

	if usable_skills.is_empty():
		print("%s n'a aucune compétence utilisable." % name)
		resetVisuel()
		return

	# Étape 2 : choisir une compétence au hasard
	var skill: Skill = usable_skills[randi() % usable_skills.size()]
	skill.owner = self  # important !

	# Étape 3 : choisir une cible selon le type de compétence
	var possible_targets: Array[Character] = []

	match skill.the_target_type:
		skill.target_type.SELF:
			skill.use(self.current_slot)
			update_ui()
			resetVisuel()
			return

		skill.target_type.ALLY:
			possible_targets = ennemies  # les alliés pour l'ennemi, donc ennemies du joueur
		skill.target_type.ENNEMY:
			possible_targets = heroes
		skill.target_type.ALL_ALLY, skill.target_type.ALL_ENNEMY:
			skill.use()  # le skill se charge lui-même de cibler tous
			resetVisuel()
			return

	# Étape 4 : forcer la cible si provoqué
	var target: Character
	if taunted_by != null:
		if skill.the_target_type == skill.target_type.ENNEMY:
			target = taunted_by
		else:
			target = self  # skill d'auto-soin ou allié, pas affecté par la provocation
	else:
		target = possible_targets[randi() % possible_targets.size()]

	# Étape 5 : animer et appliquer le sort
	await animate_attack(target)
	skill.use(target.current_slot)
	target.update_ui()
	resetVisuel()

func reduce_cooldowns() -> void:
	for skill in skills:
		if skill.current_cooldown > 0:
			skill.current_cooldown -= 1	
	
func end_turn():
	
	for buff in buffs:
		buff.duration -= 1
	buffs = buffs.filter(func(b): return b.duration > 0)
	resetVisuel()
	update_buffs()
	reduce_cooldowns()
	
	update_stats()
	
	
	


func select_as_target():
	print("Cible sélectionnée : ", self.name)
	combat_manager.select_target(self)



func _on_button_button_down() -> void:
	
	if combat_manager != null && is_targetable:
		Selector.self_modulate= Color(1.0,1.0,1.0,1.0)
		#emit_signal("target_selected", self)
		combat_manager._on_target_selected(self)


func _on_button_mouse_entered() -> void:
	Selector.self_modulate= Color(1.0,1.0,1.0,0.5)

func _on_button_mouse_exited() -> void:
	Selector.self_modulate= Color(.0,1.0,1.0,0.0)
	
	
func take_damage(source: Character, stat: int, amount: int) -> void:
	var damage := 0
	
	match stat:
		DamageEffect.Stat.STAMINA:
			damage = max(0, (amount + source.attack) - defense)
			animate_take_damage(damage, source)
			if current_stamina > 0:
				
				current_stamina = clamp(current_stamina - damage, 0, max_stamina)
				
				if current_stamina == 0:
					sprite.self_modulate = Color(0.8, 0.1, 0.1)
			else:
				dead = true
				sprite.texture = dead_portrait_texture
				Selector.texture = dead_portrait_texture

		DamageEffect.Stat.HORNY:
			damage = max(0, amount - willpower)
			current_horniness = max(0, current_horniness + damage)
			animate_get_horny(damage)
			update_ui()
			

		DamageEffect.Stat.STRESS:
			damage = max(0, amount - willpower)
			current_stress = max(0, current_stress + damage)
	shake_camera(20.0)
	print("%s inflige %d de %s à %s" % [
		source.name, damage, DamageEffect.Stat.keys()[stat], name
	])
	update_ui()
	
	
	
func resetVisuel()-> void:
	sprite.modulate=Color(1.0,1.0,1.0,1.0)
	self.scale = CharaScale
	self.z_index = 0
	
	
func animate_start_Turn():
	var tween := create_tween() as Tween
	CharaScale = current_slot.position_data.scale
	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.1) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	combat_manager.ui.log( str(normal_size))
	await tween.finished

func animate_get_horny(damage:int):
	var effect_instance = HornyEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)

	effect_instance.global_position = global_position + Vector2(0, -30)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage)
	var tween := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.1) 
	tween.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	
func animate_take_damage(damage:int, source:Character):
	var effect_instance = DamageEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)

	effect_instance.global_position = global_position + Vector2(0, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage)
		
	var tween := create_tween() as Tween
	var tween2 := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.05) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	var start_pos = position
	var direction = (source.global_position + global_position).normalized()
	var offset = direction * 10
	var attack_pos = start_pos + offset
	tween2.tween_property(self, "position", attack_pos, 0.02).set_delay(0.02)
	tween2.tween_property(self, "position", start_pos, 0.2)
	await tween.finished
	
func animate_attack(target: Character):

	# Création d'un nouveau Tween
	var tween := create_tween() as Tween
	var scaletween := create_tween() as Tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	self.z_index = 10 

	var start_pos = position
	var direction = (target.global_position - global_position).normalized()
	var offset = direction * 100
	var attack_pos = start_pos + offset
	var normal_size = self.scale
	var big_size= Vector2(1.2,1.2) 

	scaletween.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(self, "position", attack_pos, 0.2)
	tween.tween_property(self, "position", start_pos, 0.2).set_delay(0.2)

	scaletween.tween_property(self, "scale", normal_size, 0.2).set_delay(0.2)

	#await tween.finished
	
func miss_animation(target: Character):
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
	
	
func shake_camera(strength := 5.0):
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(strength)
