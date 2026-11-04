extends RefCounted
class_name KinksLabel

# ════════════════════════════════════════════════════════════════════
#  LIGNE « Kinks : … » DES FICHES PERSONNAGE
# ════════════════════════════════════════════════════════════════════
#  Construite par code (aucune scène à retoucher). Deux usages :
#   - after_name() : collée à droite du nom du personnage, sur sa ligne,
#     et recalée à chaque changement de nom (longueur variable) ;
#   - at() : à une position fixe (panneau de survol du combat).
#  Les kinks sont les tags du personnage (CharacterData.tags).

const GOLD := Color(0.721569, 0.647059, 0.45098, 1)
const FONT := preload("res://UI/Euphorigenic.otf")


static func _make(parent: Node, font_size: int) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.name = "KinksLine"
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("normal_font", FONT)
	l.add_theme_font_override("italics_font", FONT)
	l.add_theme_font_size_override("normal_font_size", font_size)
	l.add_theme_font_size_override("italics_font_size", font_size)
	l.add_theme_color_override("default_color", GOLD)
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	l.size = Vector2(520, font_size + 10)
	# Ajout différé : souvent appelé depuis un _ready(), parent encore occupé.
	parent.add_child.call_deferred(l)
	return l


## Ligne posée juste après le texte de `name_label`, centrée sur sa hauteur.
static func after_name(name_label: Control, font_size: int = 22) -> RichTextLabel:
	var l := _make(name_label.get_parent(), font_size)
	l.z_index = name_label.z_index
	l.set_meta("name_label", name_label)
	return l


## Ligne à une position fixe, dans le repère de `parent`.
static func at(parent: Node, pos: Vector2, font_size: int = 18) -> RichTextLabel:
	var l := _make(parent, font_size)
	l.position = pos
	return l


## Remplit la ligne pour `chara` (CharacterData) et, si elle suit un nom,
## la recale derrière ce nom.
static func show_for(l: RichTextLabel, chara: CharacterData) -> void:
	if l == null or not is_instance_valid(l) or chara == null:
		return
	var list := ", ".join(chara.tags) if not chara.tags.is_empty() else "-"
	l.text = "Kinks: [color=#d8cfb5]%s[/color]" % list
	if l.has_meta("name_label"):
		var name_label := l.get_meta("name_label") as Control
		if is_instance_valid(name_label):
			_place_after(l, name_label)


static func _place_after(l: RichTextLabel, name_label: Control) -> void:
	var txt := ""
	var font: Font = null
	var fsize := 40
	if name_label is Label:
		txt = (name_label as Label).text
		if (name_label as Label).uppercase:
			txt = txt.to_upper()
		font = name_label.get_theme_font("font")
		fsize = name_label.get_theme_font_size("font_size")
	elif name_label is RichTextLabel:
		txt = (name_label as RichTextLabel).get_parsed_text()
		font = name_label.get_theme_font("normal_font")
		fsize = name_label.get_theme_font_size("normal_font_size")
	var w := 200.0
	if font != null:
		w = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var own := l.get_theme_font_size("normal_font_size")
	l.position = name_label.position + Vector2(w * name_label.scale.x + 24.0,
			(float(fsize) - float(own)) * 0.5 * name_label.scale.y)
