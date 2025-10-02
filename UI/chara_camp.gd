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
@onready var buff_bar = $HBoxContainer
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

# --- Valeurs dynamiques
var current_stamina: int = 100
var max_stamina: int = 100
var current_stress: int = 0
var max_stress: int =100
var current_horny: int = 0 
var max_horniness: int = 100
var current_position: int =0
var targetable : bool = false 
var CharaCampPoints : int = 2
var camp : Campement

func _ready() -> void:
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
