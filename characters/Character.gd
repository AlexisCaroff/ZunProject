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

@export var Charaname: String = "name"
# --- Stats de combat
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_willpower: int = 5
@export var base_initiative: int = 1
@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var initiative: int = 1

@export var base_evasion: int = 5
@export var action_points: int = 2
@onready var Selector:TextureRect =$Selector

#etat
@export var stun : bool = false

var buffs: Array[Buff] = []

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
	# Reset des stats modifiées
	attack = base_attack
	defense = base_defense
	initiative = base_initiative
	willpower = base_willpower

	# Appliquer les buffs actifs
	for buff in buffs:
		buff.apply_to(self)
	# Tu peux ajouter d'autres stats ici
func update_ui():
	hp_label.text = "HP: %d / %d" % [current_stamina, max_stamina]
	stress_label.text = "Stress: %d / %d" % [current_stress, max_stress]
	horny_label.text = "Horny: %d / %d" % [current_horniness, max_horniness]
	
func add_buff(buff: Buff):
	buffs.append(buff.duplicate()) # On duplique pour éviter de modifier l’original
	update_stats()
	
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
		modulate = Color(1, 1, 1) if state else Color(0.5, 0.5, 0.5)
		
		
func _input_event(viewport, event, shape_idx):
	if is_targetable and event is InputEventMouseButton and event.pressed:
		emit_signal("target_selected", self)
		
		
func play_ai_turn(heroes : Array, ennemies :Array):
	# IA simplifiée
	if skills.size() > 0:
		skills[0].use(heroes[0])
		animate_attack(heroes[0])

func reduce_cooldowns() -> void:
	for skill in skills:
		if skill.current_cooldown > 0:
			skill.current_cooldown -= 1	
	
func end_turn():
	for buff in buffs:
		buff.duration -= 1
	buffs = buffs.filter(func(b): return b.duration > 0)
	update_buffs()
	reduce_cooldowns()
	update_stats()
	
	
	
		
func select_as_target():
	print("Cible sélectionnée : ", self.name)
	combat_manager.select_target(self)



func _on_button_button_down() -> void:
	
	if combat_manager != null && is_targetable:
		Selector.self_modulate= Color(1.0,1.0,1.0,1.0)
		combat_manager._on_target_selected(self)


func _on_button_mouse_entered() -> void:
	Selector.self_modulate= Color(1.0,1.0,1.0,0.5)


func _on_button_mouse_exited() -> void:
		Selector.self_modulate= Color(1.0,1.0,1.0,0.0)


func animate_attack(target: Character):


	# Création d'un nouveau Tween
	var tween := create_tween() as Tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var start_pos = position
	var direction = (target.global_position - global_position).normalized()
	var offset = direction * 50
	var attack_pos = start_pos + offset

	tween.tween_property(self, "position", attack_pos, 0.2)
	tween.tween_property(self, "position", start_pos, 0.2).set_delay(0.2)

	await tween.finished
