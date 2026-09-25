extends Control
class_name PotionConfirmPopup

# ════════════════════════════════════════════════════════════════════
#  POPUP DE CONFIRMATION D'UTILISATION D'UNE POTION
# ════════════════════════════════════════════════════════════════════
#  Entièrement construit par code : aucune scène à maintenir, et il peut
#  donc être appelé depuis n'importe quel inventaire (menu perso,
#  exploration, porte, combat) sans toucher aux .tscn.
#
#  Usage :
#      var popup := PotionConfirmPopup.open(parent_canvas, potion,
#                                           "Priestess", slot_global_pos,
#                                           true, "", self)
#      popup.confirmed.connect(...)
#
#  `opener` (le dernier argument) est l'inventaire qui ouvre le popup :
#  s'il quitte l'arbre (changement de salle) ou se cache, le popup se
#  ferme avec lui. Sans ça, un popup posé sur une scène persistante
#  restait ouvert par-dessus la salle suivante.
# ════════════════════════════════════════════════════════════════════

signal confirmed
signal cancelled

const GOLD      := Color(0.642, 0.561, 0.365)
const GOLD_DIM  := Color(0.40, 0.35, 0.23)
const BG        := Color(0.07, 0.06, 0.06, 0.97)
const PANEL_W   := 330.0

var _panel: PanelContainer
var _potion: Potion
var _closed: bool = false


## Ouvre le popup près de `anchor_global` (typiquement la position de la
## case cliquée). `parent` doit être un CanvasLayer ou un Control affiché
## au-dessus de l'inventaire.
static func open(parent: Node, potion: Potion, target_name: String,
		anchor_global: Vector2, can_use: bool = true,
		reason: String = "", opener: Node = null) -> PotionConfirmPopup:
	var popup := PotionConfirmPopup.new()
	popup._potion = potion
	parent.add_child(popup)
	popup._build(potion, target_name, can_use, reason)
	popup._place_near(anchor_global)
	popup._bind_to(opener)
	return popup


## Ferme le popup quand l'inventaire qui l'a ouvert disparaît ou se cache.
func _bind_to(opener: Node) -> void:
	if opener == null:
		return
	opener.tree_exiting.connect(_on_cancel)
	# Méthodes et non lambdas : Godot retire ces connexions tout seul quand
	# le popup est libéré, l'inventaire ne rappelle jamais un popup détruit.
	if opener is CanvasItem:
		opener.visibility_changed.connect(_on_opener_visibility_changed.bind(opener))


func _on_opener_visibility_changed(opener: CanvasItem) -> void:
	if is_instance_valid(opener) and not opener.is_visible_in_tree():
		_on_cancel()


func _init() -> void:
	name = "PotionConfirmPopup"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100


func _build(potion: Potion, target_name: String, can_use: bool, reason: String) -> void:
	# Voile sombre : clic à côté = annuler.
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.35)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.gui_input.connect(_on_veil_input)
	add_child(veil)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	# ── Ligne titre : icône + nom (+ quantité) ──────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var icon := TextureRect.new()
	icon.texture = potion.icon
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var qty := "  [color=888888]x%d[/color]" % potion.number if potion.number > 1 else ""
	title.text = "[b][color=#A48F5D]%s[/color][/b]%s" % [potion.name, qty]
	header.add_child(title)

	# ── Description + effets ────────────────────────────────────────
	var effects := potion.effects_bbcode()
	var body_text := ""
	if potion.description != "":
		body_text += "[color=999999][i]%s[/i][/color]\n" % potion.description
	if effects != "":
		body_text += effects
	if body_text != "":
		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.fit_content = true
		body.scroll_active = false
		body.custom_minimum_size = Vector2(PANEL_W - 28, 0)
		body.text = body_text
		box.add_child(body)

	box.add_child(_separator())

	# ── Question ────────────────────────────────────────────────────
	var question := RichTextLabel.new()
	question.bbcode_enabled = true
	question.fit_content = true
	question.scroll_active = false
	question.custom_minimum_size = Vector2(PANEL_W - 28, 0)
	if can_use:
		question.text = "[center]%s[/center]" % potion.confirm_message(target_name)
	else:
		question.text = "[center][color=CC5555]%s[/color][/center]" % (
			reason if reason != "" else "This potion can't be used here.")
	box.add_child(question)

	# ── Boutons ─────────────────────────────────────────────────────
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	if can_use:
		var yes := _make_button("Drink", GOLD)
		yes.pressed.connect(_on_confirm)
		buttons.add_child(yes)

	var no := _make_button("Cancel" if can_use else "Close", GOLD_DIM)
	no.pressed.connect(_on_cancel)
	buttons.add_child(no)

	# Petite animation d'apparition, dans l'esprit de item_ui.tscn.
	_panel.pivot_offset = Vector2(PANEL_W * 0.5, 0)
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.12)


# ── Placement ───────────────────────────────────────────────────────

## Colle le popup contre la case cliquée, en le rabattant si besoin pour
## qu'il reste entièrement à l'écran.
func _place_near(anchor_global: Vector2) -> void:
	await get_tree().process_frame
	if not is_instance_valid(_panel):
		return

	var view: Vector2 = get_viewport_rect().size
	var size_panel: Vector2 = _panel.size
	var pos := anchor_global + Vector2(90, -20)

	if pos.x + size_panel.x > view.x - 16:
		pos.x = anchor_global.x - size_panel.x - 24
	pos.x = clamp(pos.x, 16.0, max(16.0, view.x - size_panel.x - 16.0))
	pos.y = clamp(pos.y, 16.0, max(16.0, view.y - size_panel.y - 16.0))

	_panel.global_position = pos
	_panel.pivot_offset = size_panel * 0.5


# ── Entrées ─────────────────────────────────────────────────────────

func _on_veil_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_cancel()


func _unhandled_input(event: InputEvent) -> void:
	if _closed:
		return
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_cancel()
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		_on_confirm()


func _on_confirm() -> void:
	if _closed:
		return
	_closed = true
	confirmed.emit()
	queue_free()


func _on_cancel() -> void:
	if _closed:
		return
	_closed = true
	cancelled.emit()
	queue_free()


# ── Helpers de style ────────────────────────────────────────────────

func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_expand_margin_all(0)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 8
	return sb


func _make_button(text: String, tint: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 38)
	b.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.11, 0.09, 1.0)
	normal.border_color = tint
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.19, 0.13, 1.0)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.30, 0.26, 0.17, 1.0)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	return b


func _separator() -> HSeparator:
	var sep := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = GOLD_DIM
	sb.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sb)
	return sep
