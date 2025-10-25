extends Node2D
class_name CharaExplo

# --- Données d'affichage
@export var portrait_texture: Texture2D
@export var dead_portrait_texture: Texture2D
@export var initiative_icon: Texture2D
var portrait_path: String = ""
var dead_portrait_path: String = ""
var initiative_icon_path: String = ""
@onready var sprite = $pivot/HerosTexture1
@onready var buff_bar = $HBoxContainer
@onready var hp_Jauge=$HPProgressBar

@onready var hornyJauge=$HornyJauge/HornyJaugePleine

# --- Infos de base
@export var Charaname: String = "name"
@export var IsDemon: bool = false

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
		var port_path = data["portrait_texture_path"]
		portrait_texture = Utils.load_texture(port_path)
	if data.has("dead_portrait_texture_path"):
		var dead_port_path = data["dead_portrait_texture_path"]
		dead_portrait_texture = Utils.load_texture(dead_port_path)
	if data.has("initiative_icon_path"):
		var init_icon_path = data["initiative_icon_path"]
		initiative_icon = Utils.load_texture(init_icon_path)
	if data.has("position"):
		var pos= data["position"]
		current_position=pos
	if data.has("buffs"):
		var buffs = data["buffs"]
		for buff in buffs:
			add_buff(buff)
	

func update_display() -> void:
	if not hp_Jauge or not hornyJauge:
		hp_Jauge=$HP/HPProgressBar

		hornyJauge=$HornyJauge/HornyJaugePleine
		# return
	hp_Jauge.max_value=max_stamina
	hp_Jauge.value=current_stamina
	
	hornyJauge.self_modulate.a = (current_horny*2.0)/max_horniness


	
	sprite.texture = portrait_texture
	
func add_buff(buff: Buff):
	if buff_bar ==null:
		buff_bar = $HBoxContainer
	var new_buff = buff.duplicate()
	var icon = TextureRect.new()
	icon.texture = buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	buff_bar.add_child(icon)
	#buff_icons.add_child(icon)
	print("add buff")
