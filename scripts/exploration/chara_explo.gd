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


const healEffectScene := preload("res://actions/damageEffect/HealVFX.tscn")
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
var explorationPortrait:Texture2D
var exploPortrait :Sprite2D
var CharaPosition :Node2D
var characterData : CharacterData

func _ready() -> void:
	print("chara ready")
	update_display()

# Appelée après instanciation, pour charger les données du GameStat
func load_chara() -> void:
	Charaname = characterData.Charaname
	sprite.texture =characterData.portrait_texture
	current_position = characterData.Chara_position
	for buff in characterData.buffs:
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
	icon.texture = new_buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	buff_bar.add_child(icon)
	characterData.buffs.append(buff)
	#buff_icons.add_child(icon)
	print("add buff")
	
signal skill_animation_started
signal skill_animation_finished
func animate_heal(damage:int, source:CharaExplo, color=null):
	emit_signal("skill_animation_started")
	var effect_instance = healEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage,color)
		
	var tween := create_tween() as Tween
	
	var normal_size = self.scale
	var big_size= Vector2(1.0,1.05) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
	
func animate_selected():
	emit_signal("skill_animation_started")
	var tween := create_tween() as Tween
	var CharaScale = self.scale
	var normal_size = CharaScale
	var big_size= Vector2(1.0,1.1) 
	tween.tween_property(self, "scale", big_size, 0.2).set_delay(0.2)
	tween.tween_property(self, "scale", normal_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")
