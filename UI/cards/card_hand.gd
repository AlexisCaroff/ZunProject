extends Control
class_name CardHand

# ════════════════════════════════════════════════════════════════════
#  INVENTAIRE DE CARTES D'AFFINITÉ (HUD, en bas à droite)
# ════════════════════════════════════════════════════════════════════
#  Un bouton « cartes » à côté de la carte et du sac ouvre un panneau qui
#  couvre la même zone. Les cartes y sont en petit ; la carte survolée (ou
#  sélectionnée) s'affiche en grand à gauche du panneau.
#
#  Jouer une carte (seulement là où `playable`, c.-à-d. au campement) :
#   - clic maintenu sur une petite carte, glisser, relâcher sur la cible ;
#   - ou clic sur une carte (sélection), puis glisser depuis la grande carte.
#  Pendant le glissé une petite carte suit la souris. Au relâchement le
#  panneau émet card_dropped ; c'est la scène (Campement) qui trouve la
#  cible sous la souris et applique la carte.
#
#  Installation (une ligne par scène) :
#      var hand := CardHand.install(parent, panel_rect, button_center, playable)

signal card_dropped(card: AffinityCard)
signal opened_changed(open: bool)

const SMALL := 0.36
const BIG := 0.85
const PAD := 12.0
const GAP := 8.0
const DRAG_THRESHOLD := 10.0
const BUTTON_PX := 81.0

## Vrai au campement : les cartes peuvent être glissées sur un personnage.
var playable := false
## Optionnel : Callable(card) -> String, raison pour laquelle la carte n'est
## pas jouable maintenant ("" = jouable). Sert à griser les cartes.
var refusal: Callable
var toggle_button: Button

var selected: AffinityCard = null
var hovered: AffinityCard = null
var _gm: Node
var _grid: GridContainer
var _scroll: ScrollContainer
var _empty: Label
var _preview: CardView = null
var _preview_card: AffinityCard = null
var _views: Dictionary = {}   # CardView -> AffinityCard

var _press_card: AffinityCard = null
var _press_pos := Vector2.ZERO
var _dragging := false
var _ghost: CardView = null


static func install(parent: Node, panel_rect: Rect2, button_center: Vector2,
		is_playable: bool, start_open: bool = false) -> CardHand:
	var hand := CardHand.new()
	hand.name = "CardHand"
	hand.playable = is_playable
	hand.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hand.position = panel_rect.position
	hand.size = panel_rect.size
	hand.z_as_relative = false
	hand.z_index = HudFrame.Z_PANEL
	hand.visible = start_open
	hand.toggle_button = _make_button(button_center)
	hand.toggle_button.pressed.connect(hand.toggle)
	# Ajouts différés : install() est appelé depuis des _ready().
	parent.add_child.call_deferred(hand)
	parent.add_child.call_deferred(hand.toggle_button)
	return hand


## HUD : boutons voisins (carte, sac, fiche…) à gauche desquels se pose le
## bouton cartes, et zone (sac / carte) que le panneau recouvre.
var _align_buttons: Array = []
var _align_area: Control = null


## Variante HUD : le panneau couvre `area` (le sac de la scène) et le bouton
## se range à gauche du plus à gauche des `buttons`, une fois la mise en
## page faite (le bouton sac est ajouté en différé).
static func install_hud(parent: Node, buttons: Array, area: Control,
		is_playable: bool = false) -> CardHand:
	var rect := Rect2(1223, 776, 679, 292)
	var hand := install(parent, rect, Vector2(-500, -500), is_playable, false)
	hand._align_buttons = buttons
	hand._align_area = area
	return hand


func _ready() -> void:
	_gm = get_tree().root.get_node_or_null("GameManager")
	if is_instance_valid(_align_area):
		var r := _align_area.get_global_rect()
		var view := get_viewport_rect().size
		r.end = Vector2(minf(r.end.x, view.x - 4.0), minf(r.end.y, view.y - 4.0))
		global_position = r.position
		size = r.size
	if not _align_buttons.is_empty():
		_align_button.call_deferred()
	_build()
	if _gm != null and _gm.has_signal("cards_changed"):
		_gm.cards_changed.connect(rebuild)
	rebuild()
	_update_button()


# ── Ouverture ─────────────────────────────────────────────────────────

func open() -> void:
	_set_open(true)


func close() -> void:
	_set_open(false)


func toggle() -> void:
	_set_open(not visible)


func _set_open(on: bool) -> void:
	if visible == on:
		return
	visible = on
	if not on:
		_cancel_drag()
		hovered = null
		_refresh_preview()
	_update_button()
	opened_changed.emit(on)


func _update_button() -> void:
	if is_instance_valid(toggle_button):
		toggle_button.modulate = MapBagButtons.ACTIVE if visible else MapBagButtons.INACTIVE


# ── Construction ──────────────────────────────────────────────────────

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fond noir : le cadre (boîte qui déborde, contour de la carte) est
	# commun aux vues du coin, posé par HudFrame.
	var bg := ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)

	var title := Label.new()
	title.text = "Affinity cards"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = Vector2(PAD + 14, 6)
	title.add_theme_font_override("font", CardView.TITLE_FONT)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", CardView.GOLD)
	add_child(title)

	var hint := Label.new()
	hint.text = "Drag a card onto a character to play it" if playable \
			else "Cards can only be played at camp"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.position = Vector2(PAD + 14, size.y - 30)
	hint.add_theme_font_override("font", CardView.BODY_FONT)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	add_child(hint)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(PAD, 36)
	_scroll.size = Vector2(size.x - PAD * 2.0, size.y - 36 - 28)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_grid = GridContainer.new()
	var cell := CardView.SIZE * SMALL
	_grid.columns = maxi(1, int((_scroll.size.x + GAP) / (cell.x + GAP)))
	_grid.add_theme_constant_override("h_separation", int(GAP))
	_grid.add_theme_constant_override("v_separation", int(GAP))
	_scroll.add_child(_grid)

	_empty = Label.new()
	_empty.text = "No cards yet. Win fights to earn some."
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.position = Vector2(PAD + 14, 60)
	_empty.add_theme_font_override("font", CardView.BODY_FONT)
	_empty.add_theme_font_size_override("font_size", 16)
	_empty.add_theme_color_override("font_color", Color(0.6, 0.58, 0.54))
	add_child(_empty)


## Redessine les petites cartes depuis GameManager.affinity_cards.
func rebuild() -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()
	_views.clear()
	var cards: Array = _gm.affinity_cards if _gm != null else []
	if selected != null and not cards.has(selected):
		selected = null
	var cell := CardView.SIZE * SMALL
	for card in cards:
		if card == null:
			continue
		var slot := Control.new()
		slot.custom_minimum_size = cell
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := CardView.make(card, SMALL)
		slot.add_child(v)
		_views[v] = card
		v.mouse_entered.connect(func(): _on_hover(card, true))
		v.mouse_exited.connect(func(): _on_hover(card, false))
		v.gui_input.connect(func(e): _on_card_input(e, card))
		_grid.add_child(slot)
	_empty.visible = cards.is_empty()
	refresh_state()


## Sélection et cartes grisées (à rappeler quand le personnage choisi ou
## les points de camp changent).
func refresh_state() -> void:
	for v in _views:
		if not is_instance_valid(v):
			continue
		var card: AffinityCard = _views[v]
		v.set_selected(card == selected)
		v.set_dimmed(playable and refusal.is_valid() and refusal.call(card) != "")
	_refresh_preview()


# ── Survol / sélection / aperçu ───────────────────────────────────────

func _on_hover(card: AffinityCard, entered: bool) -> void:
	if entered:
		hovered = card
	elif hovered == card:
		hovered = null
	_refresh_preview()


func select(card: AffinityCard) -> void:
	selected = card
	refresh_state()


func _refresh_preview() -> void:
	var show: AffinityCard = hovered if hovered != null else selected
	if not visible:
		show = null
	if show == _preview_card and (show == null or is_instance_valid(_preview)):
		if is_instance_valid(_preview):
			_preview.set_selected(show == selected)
		return
	if is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null
	_preview_card = show
	if show == null:
		return
	_preview = CardView.make(show, BIG)
	var big := CardView.SIZE * BIG
	_preview.position = Vector2(-big.x - GAP * 2.0, size.y - big.y)
	_preview.gui_input.connect(func(e): _on_card_input(e, show))
	add_child(_preview)
	_preview.set_selected(show == selected)


# ── Glisser-déposer ───────────────────────────────────────────────────

func _on_card_input(event: InputEvent, card: AffinityCard) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		select(card)
		_press_card = card
		_press_pos = get_global_mouse_position()
		_dragging = false
		accept_event()


func _input(event: InputEvent) -> void:
	if _press_card == null:
		return
	if event is InputEventMouseMotion:
		var mouse := get_global_mouse_position()
		if not _dragging and playable and mouse.distance_to(_press_pos) > DRAG_THRESHOLD:
			_start_ghost(_press_card)
		if _dragging and is_instance_valid(_ghost):
			_ghost.global_position = mouse - CardView.SIZE * SMALL * 0.5
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var card := _press_card
		var was_dragging := _dragging
		_cancel_drag()
		if was_dragging:
			card_dropped.emit(card)


func _start_ghost(card: AffinityCard) -> void:
	_dragging = true
	_ghost = CardView.make(card, SMALL)
	_ghost.top_level = true
	_ghost.z_as_relative = false
	_ghost.z_index = 100
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.modulate.a = 0.9
	add_child(_ghost)
	_ghost.global_position = get_global_mouse_position() - CardView.SIZE * SMALL * 0.5


func _cancel_drag() -> void:
	_press_card = null
	_dragging = false
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null


# ── Bouton du HUD ─────────────────────────────────────────────────────

func _align_button() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var left := INF
	var y := 0.0
	var step := 88.0
	for b in _align_buttons:
		if not (b is Control) or not is_instance_valid(b) or not b.is_inside_tree():
			continue
		var c: Vector2 = (b as Control).get_global_rect().get_center()
		if c.x < left:
			left = c.x
			y = c.y
	if left == INF or not is_instance_valid(toggle_button):
		return
	var half := Vector2(BUTTON_PX, BUTTON_PX) * 0.5
	toggle_button.global_position = Vector2(left - step, y) - half


static func _make_button(center: Vector2) -> Button:
	var b := Button.new()
	b.name = "ButtonCards"
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = "Affinity cards"
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var half := BUTTON_PX * 0.5
	b.offset_left = center.x - half
	b.offset_top = center.y - half
	b.offset_right = center.x + half
	b.offset_bottom = center.y + half
	b.z_as_relative = false
	b.z_index = HudFrame.Z_BUTTONS
	MapBagButtons.ensure_box(b, BUTTON_PX)
	var icon := _CardsIcon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(BUTTON_PX, BUTTON_PX)
	b.add_child(icon)
	MapBagButtons.add_hover(b)
	return b


## Icône du bouton : deux petites cartes en éventail.
class _CardsIcon extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.2, 0.13, 0.11)
		st.border_color = CardView.GOLD
		st.set_border_width_all(2)
		st.set_corner_radius_all(4)
		var card := Vector2(24, 34)
		draw_set_transform(c + Vector2(-6, 2), -0.25)
		draw_style_box(st, Rect2(-card * 0.5, card))
		draw_set_transform(c + Vector2(6, -1), 0.2)
		st.bg_color = Color(0.32, 0.18, 0.14)
		st.border_color = CardView.GOLD_BRIGHT
		draw_style_box(st, Rect2(-card * 0.5, card))
		draw_set_transform(Vector2.ZERO, 0.0)
