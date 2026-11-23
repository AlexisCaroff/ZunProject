extends CanvasLayer
class_name EcstasyOverlay

# ════════════════════════════════════════════════════════════════════
#  EXTASE : UN HÉROS ATTEINT SA LUST MAX
# ════════════════════════════════════════════════════════════════════
#  Plein écran, au-dessus de tout : le jeu s'assombrit (noir 60 %), le halo
#  ECSTASY_fx grossit lentement derrière le visuel du personnage, et le
#  cadre sous le personnage affiche « <Nom> lost control ».
#
#  Usage :  await EcstasyOverlay.play(character_data, get_tree())
#  Visuel : CharacterData.ecstasy_texture, sinon
#           res://FX Ecstasy/ECSTASY_<nom en minuscules>.png
#  Texte  : clé LOST_CONTROL de texts/lust_barks_<langue>.txt
# ════════════════════════════════════════════════════════════════════

const FX_PATH := "res://FX Ecstasy/ECSTASY_fx.png"
const FONT := preload("res://UI/Euphorigenic.otf")
const FALLBACK_PATH := "res://FX Ecstasy/ECSTASY_%s.png"

## Cadre noir dessiné dans les images (pixels de l'image 1197×943).
const TEXT_BOX := Rect2(330, 676, 523, 106)

## Opacité du voile noir.
const VEIL_ALPHA := 0.6
## Taille du visuel par rapport à sa taille d'origine.
const ART_SCALE := 0.9
## Le halo part de FX_START et grossit jusqu'à FX_END pendant l'affichage.
const FX_START := 0.85
const FX_END := 1.05
const FADE_IN := 0.3
const HOLD := 2.2
const FADE_OUT := 0.35

signal finished

var _root: Control
var _skip := false


## Joue la séquence et attend qu'elle se termine (clic = passer).
static func play(data: CharacterData, tree: SceneTree) -> void:
	var tex := texture_for(data)
	if tex == null or tree == null:
		return
	var o := EcstasyOverlay.new()
	o.layer = 90
	tree.root.add_child(o)
	o._build(tex, data.Charaname)
	await o._run()
	o.queue_free()


static func texture_for(data: CharacterData) -> Texture2D:
	if data == null:
		return null
	var t = data.get("ecstasy_texture")
	if t is Texture2D:
		return t
	var path := FALLBACK_PATH % data.Charaname.to_lower()
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _build(tex: Texture2D, chara_name: String) -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_skip = true)
	_root.modulate.a = 0.0
	add_child(_root)

	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, VEIL_ALPHA)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(veil)

	var screen := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1920),
		ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	var center := screen * 0.5

	# Halo derrière, qui grossit.
	var fx := Sprite2D.new()
	fx.name = "FX"
	fx.texture = load(FX_PATH)
	fx.position = center
	fx.scale = Vector2.ONE * FX_START * ART_SCALE
	_root.add_child(fx)

	# Visuel du personnage (cadre texte compris), centré.
	var art := Sprite2D.new()
	art.name = "Art"
	art.texture = tex
	art.position = center
	art.scale = Vector2.ONE * ART_SCALE
	_root.add_child(art)

	# Texte dans le cadre noir de l'image.
	var img_size := tex.get_size()
	var label := Label.new()
	label.text = LustBreak.line("LOST_CONTROL", chara_name)
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color("ffd6f2"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = center + (TEXT_BOX.position - img_size * 0.5) * ART_SCALE
	label.size = TEXT_BOX.size * ART_SCALE
	_root.add_child(label)


func _run() -> void:
	var fx := _root.get_node("FX") as Sprite2D
	var grow := create_tween()
	grow.tween_property(fx, "scale", Vector2.ONE * FX_END * ART_SCALE, FADE_IN + HOLD + FADE_OUT) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, FADE_IN)
	await t.finished

	var waited := 0.0
	while waited < HOLD and not _skip:
		await get_tree().process_frame
		waited += get_process_delta_time()

	var out := create_tween()
	out.tween_property(_root, "modulate:a", 0.0, FADE_OUT)
	await out.finished
	finished.emit()
