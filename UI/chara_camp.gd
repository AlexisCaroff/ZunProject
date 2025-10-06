extends Node2D
class_name CharaCamp
@export var portrait_texture: Texture2D
@export var dead_portrait_texture: Texture2D
@export var initiative_icon: Texture2D
var campSkills: Array[CampSkill] = []
var portrait_path: String = ""
var dead_portrait_path: String = ""
var initiative_icon_path: String = ""
@onready var name_label = $name
@onready var hp_label = $HP
@onready var stress_label = $Stress
@onready var horny_label = $horny
@onready var sprite = $pivot/HerosTexture1
@onready var buff_bar = $HBuffsContainer
@onready var hp_Jauge=$HP/HPProgressBar
@onready var guilt_Jauge=$Stress/GuiltrogressBar
@onready var horny_Jauge=$horny/HornyProgressBar
@onready var Arrow = $Arrow
# --- Infos de base
@export var Charaname: String = "name"
@export var IsDemon: bool = false
var camp_skill_resources: Array[CampSkill] = []
# --- Stats de combat
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
var buffs: Array[Buff] = []
@onready var buff_icons = $HBuffsContainer
# --- Valeurs dynamiques
var current_stamina: int = 100
var max_stamina: int = 100
var current_stress: int = 0
var max_stress: int =100
var current_horny: int = 0 
var max_horniness: int = 100
var current_position: int =0


var campposition
var targetable : bool = false 
var CharaScale : Vector2
const healEffectScene := preload("res://actions/damageEffect/HealVFX.tscn")

var CharaCampPoints : int = 2
var camp : Campement


func _ready() -> void:
	CharaScale= self.scale
	print("chara ready")
	
	update_display()

# Appelée après instanciation, pour charger les données du GameStat
func load_from_dict(data: Dictionary) -> void:
	if data.has("name"):
		Charaname = data["name"]
		print(Charaname)
	if data.has("attack"):
		attack = data["attack"]
	if data.has("defense"):
		defense = data["defense"]
	if data.has("willpower"):
		willpower = data["willpower"]
	if data.has("evasion"):
		evasion = data["evasion"]
	if data.has("initiative"):
		initiative = data["initiative"]
	if data.has("stamina"):
		current_stamina = data["stamina"]
	if data.has("max_stamina"):
		max_stamina = data["max_stamina"]
	if data.has("stress"):
		current_stress = data["stress"]
	if data.has("horny"):
		current_horny = data["horny"]
	if data.has("portrait_texture_path"):
		var portrait_path = data["portrait_texture_path"]
		portrait_texture = Utils.load_texture(portrait_path)
	if data.has("dead_portrait_texture_path"):
		var dead_portrait_path = data["dead_portrait_texture_path"]
		dead_portrait_texture = Utils.load_texture(dead_portrait_path)
	if data.has("initiative_icon_path"):
		var initiative_icon_path = data["initiative_icon_path"]
		initiative_icon = Utils.load_texture(initiative_icon_path)
	if data.has("position"):
		var position= data["position"]
		current_position=position
	if data.has("camp_skills"):
		camp_skill_resources = data["camp_skills"]
		
func set_targetable(targe : bool):
	targetable = targe 
	Arrow.visible= targe
func add_buff(buff: Buff):
	var new_buff = buff.duplicate()
	buffs.append(new_buff)
	var icon = TextureRect.new()
	icon.texture = buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	buff_bar.add_child(icon)
	#buff_icons.add_child(icon)
	print("add buff")
	
func update_display() -> void:
	if not hp_Jauge or not guilt_Jauge or not horny_Jauge:
		hp_Jauge=$HP/HPProgressBar
		guilt_Jauge=$Stress/GuiltrogressBar
		horny_Jauge=$horny/HornyProgressBar
		# return
	hp_Jauge.value=current_stamina
	guilt_Jauge.value=current_stress
	horny_Jauge.value=current_horny
	name_label.text = Charaname

	
	sprite.texture = portrait_texture
	
func gomasturbate():
	campposition.visible=false
	
func animate_heal(damage:int, source:CharaCamp, color=null):
	#emit_signal("skill_animation_started")
	var effect_instance = healEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage,color)
		
	var tween := create_tween() as Tween
	var tween2 := create_tween() as Tween
	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.05) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	#emit_signal("skill_animation_finished")
