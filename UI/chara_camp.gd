extends Node2D
class_name CharaCamp
@export var portrait_texture: Texture2D
@export var dead_portrait_texture: Texture2D
@export var initiative_icon: Texture2D

var portrait_path: String = ""
var dead_portrait_path: String = ""
var initiative_icon_path: String = ""
@onready var name_label = $name
@onready var Selector =$pivot/Selector
@onready var stress_label = $Stress

@onready var sprite = $pivot/HerosTexture1
@onready var buff_bar = $HBuffsContainer
@onready var hp_Jauge=$HPProgressBar
@onready var guilt_Jauge=$Stress/GuiltrogressBar

@onready var Arrow = $Arrow
# --- Infos de base


@onready var buff_icons = $HBuffsContainer
# --- Valeurs dynamiques

var campposition :CampPosition 
var targetable : bool = false 
var CharaScale : Vector2
const healEffectScene := preload("res://actions/damageEffect/HealVFX.tscn")
var characterData: CharacterData
var CharaCampPoints : int = 2
var camp : Campement
var camp_skills: Array[CampSkill] = []

func _ready() -> void:
	CharaScale= self.scale
	print("chara ready")
	
	update_display()

# Appelée après instanciation, pour charger les données du GameStat
func load_camp_chara(charaData : CharacterData) -> void:
		characterData=charaData 
		portrait_texture = charaData.textureCamp
		_updateSkills(characterData.camp_skill_resources)
	
		
func set_targetable(targe : bool):
	targetable = targe 
	Arrow.visible= targe
func add_buff(buff: Buff):
	var new_buff = buff.duplicate()
	characterData.buffs.append(new_buff)
	var icon = TextureRect.new()
	icon.texture = buff.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(32, 32)
	icon.size= Vector2(32, 32)
	buff_bar.add_child(icon)
	#buff_icons.add_child(icon)
	print("add buff")
	
func update_display() -> void:
	if not hp_Jauge or not guilt_Jauge :
		hp_Jauge=$HPProgressBar
		guilt_Jauge=$Stress/GuiltrogressBar
		#horny_Jauge=$horny/HornyProgressBar
		# return
	hp_Jauge.value=characterData.current_stamina
	guilt_Jauge.value=characterData.current_stress
	#horny_Jauge.value=current_horny
	name_label.text = characterData.Charaname
	Selector.texture =portrait_texture
	
	sprite.texture = portrait_texture
	
func gomasturbate():
	campposition.visible=false
	
signal skill_animation_started
signal skill_animation_finished
func animate_heal(damage:int, source:CharaCamp, color=null):
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
	
func _updateSkills(updated_skills: Array[CampSkill] ):
	camp_skills.clear()
	for s in updated_skills:
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst= s.duplicate()
		
		camp_skills.append(inst)
