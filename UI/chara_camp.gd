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
@onready var ui :CharaUi
@onready var sprite = $pivot/HerosTexture1
@onready var buff_bar
@onready var hp_Jauge 
@onready var horny_Jauge 
@onready var horny_Rect 
@onready var actionspoints : Array[TextureRect] 

@onready var Arrow = $Arrow
# --- Infos de base


@onready var buff_icons 
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
	var mat := ShaderMaterial.new()
	mat.shader = load("res://characters/character_outline.gdshader")
	sprite.material = mat
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	for p in actionspoints:
		p.visible =false
	CharaScale= self.scale
	print("chara ready")

func set_UI(theUI):
	print("set UI for "+characterData.Charaname)
	ui = theUI
	buff_bar    = ui.get_buff_bar()
	hp_Jauge    = ui.getHpbar()
	horny_Jauge = ui.getLustbar()
	horny_Rect  = ui.get_HornyBar()
	actionspoints = ui.getactionpoints()
	buff_icons  = ui.get_buff_bar()
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
	if not hp_Jauge or not horny_Jauge:
		push_warning("CharaCamp: UI non initialisée pour " + characterData.Charaname)
		return
	hp_Jauge.value=characterData.current_stamina
	horny_Jauge.value=characterData.current_horniness
	horny_Rect.modulate.a =characterData.current_horniness
	name_label.text = characterData.Name
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
