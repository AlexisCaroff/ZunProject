extends Control
class_name buffUI

## Icône d'un buff sous un personnage en combat. Au survol, une bulle
## montre l'échelle du buff (+1 +3 +6 +10 +15) avec le palier atteint, ou,
## pour un état binaire (stun, taunt…), les tours restants.

@onready var back                       = $Box2
@onready var texture    : TextureRect   = $TextureBuff
@onready var textconteneur              = $TextLabel

const STAT_HOVER := preload("res://UI/stat_hover.gd")
const FONT := preload("res://UI/Euphorigenic.otf")
const STAT_LABEL := {
	Buff.Stat.ATTACK: "Attack", Buff.Stat.DEFENSE: "Defense",
	Buff.Stat.SPEED: "Speed", Buff.Stat.WILL_POWER: "Willpower",
	Buff.Stat.EVASION: "Evasion", Buff.Stat.PRECISION: "Precision",
	Buff.Stat.STUN: "Stun", Buff.Stat.TAUNT: "Taunt",
	Buff.Stat.IMMOBILIZE: "Immobilized",
}

var buff   : Buff   = null
var offset : Vector2 = Vector2.ZERO

var _hovering := false
var _tip: PanelContainer = null
var _tip_text: RichTextLabel = null
## Colonne de droite : l'échelle, un palier par ligne.
var _tip_ladder: RichTextLabel = null
var _badge: Label = null


func _ready() -> void:
	# L'ancienne bulle de la scène est trop petite pour l'échelle.
	back.visible = false
	textconteneur.visible = false
	_build_badge()
	_build_tip()
	refresh()


func _process(_delta):
	if texture == null:
		return
	var hovering = Rect2(Vector2.ZERO, texture.size).has_point(texture.get_local_mouse_position()) \
			and is_visible_in_tree()
	if hovering == _hovering:
		return
	_hovering = hovering
	if hovering:
		_show_tip()
	elif _tip != null:
		_tip.visible = false


func updatebuff(thebuff: Buff):
	buff = thebuff
	if texture == null:
		texture = $TextureBuff
	texture.texture = buff.icon
	refresh()


func refresh():
	if buff == null or not is_inside_tree():
		return
	if _badge != null:
		_badge.visible = buff.is_ladder()
		if buff.is_ladder():
			_badge.text = ("%d" % buff.amount) if buff.is_poison() else ("%+d" % buff.amount)
			_badge.add_theme_color_override("font_color", _color())
	if _tip != null and _tip.visible:
		_show_tip()


func _color() -> Color:
	if buff.is_poison():
		return Color("e070ff")
	return Color.WHITE if buff.amount >= 0 else Color("ff7a6b")


func _title() -> String:
	if buff.name == "poison":
		return "Poison"
	if buff.name == "poisonHorny":
		return "Lust poison"
	if buff.name != "" and buff.name != "name" and buff.name != "Buff":
		return buff.name
	return STAT_LABEL.get(buff.stat, "Effect")


func _describe() -> String:
	var col := "#" + _color().to_html(false)
	var out := "[center][font_size=18][color=#f2d38a]%s[/color][/font_size]" % _title()
	if buff.is_ladder():
		var effect := ""
		if buff.name == "poison":
			effect = "Takes %d stamina damage at turn start" % buff.amount
		elif buff.name == "poisonHorny":
			effect = "Gains %d lust at turn start" % buff.amount
		else:
			effect = "%s %+d" % [STAT_LABEL.get(buff.stat, "Stat"), buff.amount]
		out += "\n[color=%s]%s[/color]" % [col, effect]
	else:
		if buff.fights_left > 0:
			out += "\n[color=#b5a993]%d fights[/color]" % buff.fights_left
		else:
			out += "\n[color=#b5a993]%d turn%s[/color]" % [buff.duration, "" if buff.duration == 1 else "s"]
		out += "\n[color=#b5a993][font_size=13]Does not stack[/font_size][/color]"
	return out + "[/center]"


func _show_tip() -> void:
	if _tip == null or buff == null:
		return
	_tip_text.text = _describe()
	var ladder := buff.is_ladder()
	_tip_ladder.visible = ladder
	if ladder:
		_tip_ladder.text = "[right][font_size=16]%s[/font_size][/right]" % buff.ladder_bbcode(true)
	# Largeurs mesurées sur le texte (pas de retour à la ligne).
	_fit_width(_tip_text, 120.0 if not ladder else 0.0)
	if ladder:
		_fit_width(_tip_ladder, 0.0)
	_tip.size = Vector2.ZERO
	_tip.reset_size()
	_tip.size = _tip.get_combined_minimum_size()
	_tip.position = Vector2(texture.size.x * 0.5 - _tip.size.x * 0.5, -_tip.size.y - 6.0)
	STAT_HOVER.pop_in(_tip)


func _fit_width(label: RichTextLabel, min_w: float) -> void:
	label.custom_minimum_size = Vector2.ZERO
	label.size = Vector2.ZERO
	label.custom_minimum_size = Vector2(max(label.get_content_width(), min_w), 0)


func _make_tip_label() -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("normal_font", FONT)
	l.add_theme_font_override("bold_font", FONT)
	l.add_theme_font_size_override("normal_font_size", 15)
	l.add_theme_font_size_override("bold_font_size", 15)
	return l


func _build_tip() -> void:
	_tip = PanelContainer.new()
	_tip.name = "LadderTip"
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = 40
	_tip.z_as_relative = false
	_tip.visible = false
	var style := STAT_HOVER.bubble_style()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_tip.add_theme_stylebox_override("panel", style)
	# Description à gauche, échelle verticale à droite.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	_tip_text = _make_tip_label()
	_tip_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_tip_text)
	_tip_ladder = _make_tip_label()
	row.add_child(_tip_ladder)
	_tip.add_child(row)
	add_child(_tip)


## Valeur actuelle de l'échelle, en petit dans le coin de l'icône.
func _build_badge() -> void:
	_badge = Label.new()
	_badge.name = "LevelBadge"
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.add_theme_font_override("font", FONT)
	_badge.add_theme_font_size_override("font_size", 12)
	_badge.add_theme_color_override("font_outline_color", Color.BLACK)
	_badge.add_theme_constant_override("outline_size", 4)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_badge.visible = false
	texture.add_child(_badge)
	# Ancré en bas à droite de l'icône, quelle que soit sa taille finale.
	# Centré sous l'icône, à sa largeur : les icônes voisines sont collées.
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.anchor_left = 0.0
	_badge.anchor_right = 1.0
	_badge.anchor_top = 1.0
	_badge.anchor_bottom = 1.0
	_badge.offset_left = -2.0
	_badge.offset_right = 2.0
	_badge.offset_top = -9.0
	_badge.offset_bottom = 5.0


func btover():
	_show_tip()


func btexit():
	if _tip != null:
		_tip.visible = false
