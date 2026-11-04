extends RefCounted
class_name StatHover

# ════════════════════════════════════════════════════════════════════
#  SURVOL D'UNE STAT : détail immédiat + petit grossissement
# ════════════════════════════════════════════════════════════════════
#  Une zone invisible couvre l'icône ET la valeur d'une stat. Dès que la
#  souris y entre (sans le délai des infobulles Godot), l'icône et la valeur
#  grossissent un peu et une bulle s'affiche au-dessus, avec le fond des
#  bulles de bark (noir, cadre doré, coins biseautés).
#
#  Usage :
#      var hover := StatHover.new(parent_control)
#      hover.attach(icon_sprite, value_label, func(): return "texte")

const BUBBLE_TEX := preload("res://UI/UI boxes/UI_camp_points.png")
const FONT := preload("res://UI/Euphorigenic.otf")
const GROW := 1.12
## Marge intérieure de la bulle (texte ↔ bord), proche de celle des barks.
const PAD := Vector2(14, 8)

var _parent: Node
var _bubble: Panel = null
var _text: RichTextLabel = null


func _init(parent: Node) -> void:
	_parent = parent


## `icon` : Sprite2D de la stat ; `label` : sa valeur ; `get_text` : renvoie
## le détail à afficher (appelé à chaque survol, donc toujours à jour).
func attach(icon: Sprite2D, label: Control, get_text: Callable) -> void:
	if icon == null or label == null or icon.texture == null:
		return
	var icon_size := icon.texture.get_size() * icon.scale
	var icon_rect := Rect2(icon.position - icon_size * 0.5, icon_size)
	var text_w := _text_width(label)
	var label_rect := Rect2(label.position, Vector2(text_w + 8.0, label.size.y))
	var area_rect := icon_rect.merge(label_rect)

	var area := Control.new()
	area.name = "StatHover_%s" % label.name
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	area.set_anchors_preset(Control.PRESET_TOP_LEFT)
	area.position = area_rect.position
	area.size = area_rect.size
	area.z_index = 20
	_parent.add_child.call_deferred(area)

	var icon_scale := icon.scale
	label.pivot_offset = Vector2(0, label.size.y * 0.5)
	label.tooltip_text = ""
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.mouse_entered.connect(func():
		_tween(icon, "scale", icon_scale * GROW)
		_tween(label, "scale", Vector2.ONE * GROW)
		_show(get_text.call(), area))
	area.mouse_exited.connect(func():
		_tween(icon, "scale", icon_scale)
		_tween(label, "scale", Vector2.ONE)
		_hide())


func _tween(node: CanvasItem, prop: String, value) -> void:
	if is_instance_valid(node):
		node.create_tween().tween_property(node, prop, value, 0.12) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _text_width(label: Control) -> float:
	if label is RichTextLabel:
		var rtl := label as RichTextLabel
		var font := rtl.get_theme_font("normal_font")
		var fsize := rtl.get_theme_font_size("normal_font_size")
		if font != null:
			return font.get_string_size(rtl.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	return 60.0


func _ensure_bubble() -> void:
	if is_instance_valid(_bubble):
		return
	# Même fond que la bulle des refus au camp (CharaCamp.say) : noir simple,
	# coins arrondis.
	_bubble = Panel.new()
	_bubble.name = "StatBubble"
	_bubble.add_theme_stylebox_override("panel", bubble_style())
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.z_index = 60
	_bubble.z_as_relative = false
	_bubble.visible = false
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_override("normal_font", FONT)
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_color_override("default_color", Color.WHITE)
	_text.position = PAD
	_bubble.add_child(_text)
	_parent.add_child(_bubble)


## Fond des bulles de détail (stats, buffs du HUD, buffs sous les
## personnages) : noir simple, coins arrondis.
static func bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.88)
	style.set_corner_radius_all(10)
	return style


## Apparition commune : la bulle grandit depuis son bas.
static func pop_in(bubble: Control) -> void:
	bubble.pivot_offset = Vector2(bubble.size.x * 0.5, bubble.size.y)
	bubble.scale = Vector2.ONE * 0.6
	bubble.modulate.a = 0.0
	bubble.visible = true
	var t := bubble.create_tween().set_parallel(true)
	t.tween_property(bubble, "scale", Vector2.ONE, 0.16) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bubble, "modulate:a", 1.0, 0.1)


func _show(text: String, area: Control) -> void:
	_ensure_bubble()
	_text.text = text
	var font_h := 20.0 * 1.3
	var lines := text.count("\n") + 1
	var w := 0.0
	for line in text.split("\n"):
		w = max(w, FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x)
	_text.size = Vector2(w + 4, lines * font_h)
	_bubble.size = Vector2(w + 4, lines * font_h) + PAD * 2.0
	# Au-dessus de la zone survolée, recalée dans l'écran.
	var view := _bubble.get_viewport_rect().size
	var pos := Vector2(area.position.x, area.position.y - _bubble.size.y - 8)
	pos.x = clampf(pos.x, 8.0, view.x - _bubble.size.x - 8.0)
	pos.y = max(8.0, pos.y)
	_bubble.position = pos
	pop_in(_bubble)


func _hide() -> void:
	if is_instance_valid(_bubble):
		_bubble.visible = false
