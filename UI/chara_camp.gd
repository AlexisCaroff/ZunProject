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
#@onready var stress_label = $Stress
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
const BUFF_UI := preload("res://UI/buffUi.tscn")
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
	_add_buff_icon(new_buff)
	if camp != null and camp.get("selected_chara") == self:
		camp.refresh_buffs(characterData)
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
	# La BuffBar du slot est reconstruite à partir des données : c'est la
	# seule source de vérité hors combat.
	if buff_bar != null:
		for child in buff_bar.get_children():
			buff_bar.remove_child(child)
			child.queue_free()
		for buff in characterData.buffs:
			_add_buff_icon(buff)


## Même icône qu'en combat (UI/buffUi.tscn) : même taille, même espacement
## dans la BuffBar, et l'infobulle stat / montant / tours au survol.
func _add_buff_icon(buff: Buff) -> void:
	if buff_bar == null:
		return
	var icon = BUFF_UI.instantiate()
	buff_bar.add_child(icon)
	icon.updatebuff(buff)

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
		
	await _bounce(Vector2(1.0, 1.05))
	emit_signal("skill_animation_finished")


func animate_selected():
	emit_signal("skill_animation_started")
	
	await _bounce(Vector2(1.0, 1.1))
	emit_signal("skill_animation_finished")


var _bounce_tween: Tween = null

## Petit étirement puis retour à la taille de REPOS (CharaScale, prise au
## _ready) — et non à la taille du moment : des clics rapprochés repartaient
## d'une taille déjà étirée et le personnage restait bloqué ainsi. Un nouveau
## clic coupe l'animation en cours au lieu de s'empiler dessus.
func _bounce(stretch: Vector2) -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	scale = CharaScale
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "scale", CharaScale * stretch, 0.2).set_delay(0.2)
	_bounce_tween.tween_property(self, "scale", CharaScale, 0.2)
	await _bounce_tween.finished


# ════════════════════════════════════════════════════════════════════
#  BULLE DE TEXTE AU-DESSUS DE LA TÊTE
# ════════════════════════════════════════════════════════════════════

const BUBBLE_FONT := preload("res://UI/Euphorigenic.otf")
var _bubble: Control = null

## Petite bulle noire, texte blanc, au-dessus de la tête ; disparaît seule.
func say(text: String, duration: float = 2.5) -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.88)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", BUBBLE_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	# Posée dans le camp et non sur le personnage : son étirement ne la
	# déforme pas, et elle passe au-dessus des autres personnages.
	var host: Node = camp if camp != null else get_parent()
	host.add_child(panel)
	panel.z_index = 50
	panel.z_as_relative = false
	_bubble = panel
	panel.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	panel.global_position = _head_top() - Vector2(panel.size.x * 0.5, panel.size.y + 12)
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)


## Point au-dessus de la tête, en coordonnées globales. On s'aligne sur la
## flèche de ciblage (nœud Arrow), placée dans la scène juste au-dessus du
## personnage assis. get_global_rect() du sprite ne convenait pas : il ignore
## les échelles des parents (×2, ×1.2…) et inclut le vide au-dessus de la pose.
@export var bubble_offset: Vector2 = Vector2(0, -20)

func _head_top() -> Vector2:
	if Arrow != null:
		return Arrow.global_position + bubble_offset
	return global_position + Vector2(0, -250) + bubble_offset
	
func _updateSkills(updated_skills: Array[CampSkill] ):
	camp_skills.clear()
	for s in updated_skills:
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst= s.duplicate()
		
		camp_skills.append(inst)
