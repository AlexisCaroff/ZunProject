extends Control

@onready var portrait_nodes: Array[TextureRect] = [
	$Portrait,   # gauche        (slot 0 / "position 1")
	$Portrait3,  # centre-gauche (slot 1 / "position 2")
	$Portrait4,  # centre-droite (slot 2 / "position 3")
	$Portrait2,  # droite        (slot 3 / "position 4")
]
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Speaker

const COLOR_ACTIVE:   Color = Color(1, 1, 1, 1)
const COLOR_INACTIVE: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_HIDDEN:   Color = Color(1, 1, 1, 0)

var _participant_count: int = 0
## Slots actuellement utilisés (dans l'ordre où les participants seront
## affichés). Permet à set_portraits_multi() de savoir quel index visible
## correspond à quel slot du layout.
var _active_slots: Array[int] = []


func setup_layout(count: int) -> void:
	_participant_count = clamp(count, 1, 4)
	global_position = Vector2(0, 0)
	for node in portrait_nodes:
		node.visible = false

	match _participant_count:
		1:
			_active_slots = [0]
		2:
			_active_slots = [0, 3]
		3:
			_active_slots = [0, 1, 3]
		4:
			_active_slots = [0, 1, 2, 3]

	for slot in _active_slots:
		portrait_nodes[slot].visible = true


## Variante explicite : on choisit quels slots sont visibles. Utile pour
## les scènes spéciales où le layout par défaut (3 → 0,1,2) ne convient
## pas. Exemple : give_in branch → [0, 1, 3] pour laisser le slot 2 vide.
##
## L'ordre du tableau définit l'ordre d'affectation des textures dans
## set_portraits_multi() : textures[0] va dans slot_indices[0], etc.
func setup_layout_explicit(slot_indices: Array[int]) -> void:
	global_position = Vector2(0, 0)
	for node in portrait_nodes:
		node.visible = false

	_active_slots.clear()
	for slot in slot_indices:
		if slot >= 0 and slot < portrait_nodes.size():
			portrait_nodes[slot].visible = true
			_active_slots.append(slot)
	_participant_count = _active_slots.size()


# active_index = -1 → aucun portrait actif (cas Narrator)
func set_portraits_multi(textures: Array[Texture2D], active_index: int) -> void:
	# On itère sur _active_slots (ordre logique = ordre des textures)
	# plutôt que sur portrait_nodes (ordre visuel).
	for i in range(_active_slots.size()):
		var node: TextureRect = portrait_nodes[_active_slots[i]]
		if i < textures.size() and textures[i] != null:
			node.texture = textures[i]
			node.modulate = COLOR_ACTIVE if i == active_index else COLOR_INACTIVE
		else:
			node.modulate = COLOR_HIDDEN


func set_text(speaker: String, text: String, style_key: String = "") -> void:
	_init_bubble()
	name_label.text = speaker
	dialogue_text.bbcode_enabled = true
	dialogue_text.clear()
	dialogue_text.append_text(text)
	# Nouvelle réplique : pas de locuteur visible tant que le manager n'a pas
	# indiqué son portrait (cas du Narrator → pas de queue).
	_speaker_portrait = null
	var key := style_key if style_key != "" else speaker
	_apply_style(_styles.style_for(key) if _styles else DialogueBubbleStyle.new())
	_layout_bubble()


## Portrait du personnage qui parle : la queue de la bulle pointe vers lui.
## null = pas de queue (narrateur).
func set_speaker_portrait(portrait: Control) -> void:
	_speaker_portrait = portrait
	_layout_bubble()


# ═══════════════════════════════════════════════════════════════════
#  BULLE DE DIALOGUE
# ═══════════════════════════════════════════════════════════════════
#  Les éléments sont des nœuds de UI/dialogue_ui.tscn, modifiables dans
#  l'éditeur (couleurs par défaut, bord, coins, décos, images…) :
#    Bubble          Panel : StyleBox (bord, coins coupés), taille = texte
#      Deco*         décos des 4 coins, ancrées aux coins de la bulle
#    BubbleTail      queue : posée sur le bord haut, pointe vers le locuteur
#    NameTab         onglet du nom (NinePatch) : largeur = nom
#    Speaker         texte du nom      RichTextLabel   texte de la réplique
#    UiClickLeft     icône « clic », coin bas-droit de la bulle
#  Le script ne fait que placer / dimensionner ces nœuds à chaque réplique
#  et appliquer les couleurs du personnage (res://UI dialog/dialogue_styles.tres).

const STYLES_PATH := "res://UI dialog/dialogue_styles.tres"

@export_group("Bulle")
## Centre horizontal et bord bas de la bulle (repère de DialogueUI).
@export var bubble_center_x := 945.0
@export var bubble_bottom := 1020.0
@export var bubble_min_width := 560.0
@export var bubble_max_width := 900.0
@export var bubble_min_height := 130.0
## Marges intérieures autour du texte.
@export var text_padding := Vector2(46, 30)
## Marge Icône
@export var click_room := 12.0
@export var click_icon_size := 26.0
## Retrait de l'icône depuis le coin bas-droit .
@export var click_icon_inset := Vector2(46, 12)

@export_group("Queue")
## Distance mini entre la base de la queue et les bords de la bulle.
@export var tail_edge := 70.0
## Rotation maxi de la queue (degrés) pour viser le locuteur.
@export var tail_max_rotation := 40.0
## Point visé dans le portrait du locuteur (0..1 de sa largeur / hauteur).
@export var tail_target := Vector2(0.5, 0.45)
## Pointe de la queue dans son image (pixels de UI_convo_tail.png).
@export var tail_tip_px := Vector2(0, 0)
## Largeur de la queue à l'écran. Le nœud BubbleTail peut avoir n'importe
## quelle taille dans la scène (pour l'éditer confortablement) : il est mis
## à l'échelle pour cette largeur.
##
## Jonction queue / bulle : lue dans la scène telle que montée dans
## l'éditeur. C'est le point de la queue où passe le bord haut de Bubble,
## à l'abscisse du centre des cercles caches (enfants de BubbleTail, ex.
## TailCache, TailCache2). La queue tourne autour de ce point, posé sur le
## bord haut de la bulle ; les cercles gardent leur place dans la queue,
## tournent avec elle et sont dessinés au-dessus de la bulle (z_index 1).
@export var tail_display_width := 120.0
## Décalage horizontal des cercles caches le long du bord de la bulle,
## selon l'inclinaison de la queue (pixels écran ; négatif = vers la pointe,
## positif = à l'opposé). Interpolé entre les deux angles ci-dessous, mesurés
## depuis la verticale (0° = queue droite, 90° = couchée).
@export var tail_cache_shift_vertical := 4.0
@export var tail_cache_shift_horizontal := -6.0
@export var tail_angle_vertical := 20.0
@export var tail_angle_horizontal := 65.0

@export_group("Onglet du nom")
## Largeur ajoutée autour du nom (pixels écran).
@export var name_padding := 70.0
## Écart entre la queue et l'onglet.
@export var name_gap := 14.0

@onready var _bubble: Panel = get_node_or_null("Bubble")
@onready var _tail: TextureRect = get_node_or_null("BubbleTail")
## Cercles caches : enfants de BubbleTail (tous ceux de la scène).
var _tail_caches: Array[Control] = []
## Jonction dans le repère local de BubbleTail (lue dans la scène).
var _tail_base_local := Vector2.ZERO
## Position des cercles telle que réglée dans la scène.
var _tail_cache_pos0: Array[Vector2] = []
@onready var _name_tab: NinePatchRect = get_node_or_null("NameTab")
@onready var _click: Control = get_node_or_null("UiClickLeft")

var _styles: DialogueStyleSet = null
var _speaker_portrait: Control = null
var _box_style: StyleBoxFlat = null
var _ready_bubble := false


func _init_bubble() -> void:
	if _ready_bubble:
		return
	_ready_bubble = true
	if _tail != null:
		for c in _tail.get_children():
			if c is Control:
				_tail_caches.append(c)
				_tail_cache_pos0.append(c.position)
		_tail_base_local = _scene_tail_junction()
	if ResourceLoader.exists(STYLES_PATH):
		_styles = load(STYLES_PATH) as DialogueStyleSet
	if _bubble != null:
		# Copie propre à cette instance : les couleurs changent par réplique.
		var sb := _bubble.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			_box_style = sb.duplicate()
			_bubble.add_theme_stylebox_override("panel", _box_style)
	for n in _recolored_nodes():
		if n.material != null:
			n.material = n.material.duplicate()


func _recolored_nodes() -> Array[CanvasItem]:
	var out: Array[CanvasItem] = []
	if _tail: out.append(_tail)
	out.append_array(_tail_caches)
	if _name_tab: out.append(_name_tab)
	if _bubble:
		for c in _bubble.get_children():
			if c is CanvasItem and (c as CanvasItem).material is ShaderMaterial:
				out.append(c)
	return out


func _apply_style(st: DialogueBubbleStyle) -> void:
	if _box_style != null:
		_box_style.bg_color = st.fill
		_box_style.border_color = st.border
	dialogue_text.add_theme_color_override("default_color", st.text_color)
	name_label.add_theme_color_override("font_color", st.name_text)
	if _tail: _set_dst(_tail, st.border, st.fill)
	for c in _tail_caches:
		_set_dst(c, Color.BLACK, st.fill)
	if _name_tab: _set_dst(_name_tab, st.name_border, st.name_fill)
	if _bubble:
		for c in _bubble.get_children():
			if c is CanvasItem and (c as CanvasItem).material is ShaderMaterial:
				_set_dst(c, Color.BLACK, st.deco)


## Les couleurs d'origine (src_a / src_b) restent celles réglées dans la
## scène ; seules les couleurs de destination changent.
func _set_dst(node: CanvasItem, dst_a: Color, dst_b: Color) -> void:
	var m := node.material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("dst_a", dst_a)
	m.set_shader_parameter("dst_b", dst_b)


## Décale les cercles le long du bord de la bulle selon l'inclinaison de la
## queue : vers la pointe quand elle est couchée, à l'opposé quand elle est
## droite. Le décalage est horizontal à l'écran, converti dans le repère de
## la queue (tournée, mise à l'échelle, éventuellement retournée).
func _shift_tail_caches(base_local: Vector2, tip_local: Vector2) -> void:
	var dir := ((tip_local - base_local) * _tail.scale).rotated(_tail.rotation)
	var from_vertical := rad_to_deg(absf(atan2(dir.x, -dir.y)))
	var t := clampf(inverse_lerp(tail_angle_vertical, tail_angle_horizontal, from_vertical), 0.0, 1.0)
	var shift := lerpf(tail_cache_shift_vertical, tail_cache_shift_horizontal, t)
	# Écran : signe vers la pointe = côté où penche la queue.
	var toward_tip := -1.0 if dir.x < 0.0 else 1.0
	var screen := Vector2(-shift * toward_tip, 0.0)
	var local := (screen.rotated(-_tail.rotation)) / _tail.scale
	for i in _tail_caches.size():
		_tail_caches[i].position = _tail_cache_pos0[i] + local
	_last_tail_angle = from_vertical


var _last_tail_angle := 0.0


## Jonction queue / bulle d'après la scène (positions avant toute mise en
## page) : hauteur = bord haut de Bubble dans le repère de la queue,
## abscisse = centre moyen des cercles caches.
func _scene_tail_junction() -> Vector2:
	var inv := _tail.get_transform().affine_inverse()
	var y := 0.0
	if _bubble != null:
		y = (inv * _bubble.position).y
	var x := 0.0
	if _tail_caches.is_empty():
		x = _tail.size.x * 0.5
	else:
		for c in _tail_caches:
			x += (c.get_transform() * (c.size * 0.5)).x
		x /= _tail_caches.size()
	return Vector2(x, y)


func _layout_bubble() -> void:
	if _bubble == null:
		return
	var border := 0.0
	if _box_style != null:
		border = _box_style.border_width_top

	# ── Texte : largeur naturelle (sans retour à la ligne), bornée.
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	dialogue_text.custom_minimum_size = Vector2.ZERO
	dialogue_text.size = Vector2(4000, 10)
	var natural_w := dialogue_text.get_content_width()
	var side := text_padding.x + click_room
	var extra := side * 2.0
	var text_w := clampf(natural_w + 4.0, bubble_min_width - extra, bubble_max_width - extra)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size = Vector2(text_w, 10)
	# Après retour à la ligne, la bulle se resserre sur la ligne la plus longue.
	text_w = clampf(dialogue_text.get_content_width() + 4.0, bubble_min_width - extra, text_w)
	dialogue_text.size = Vector2(text_w, 10)
	var text_h := dialogue_text.get_content_height()

	var box_size := Vector2(text_w + extra, maxf(text_h + text_padding.y * 2.0, bubble_min_height))
	var box_pos := Vector2(bubble_center_x - box_size.x * 0.5, bubble_bottom - box_size.y)
	_bubble.position = box_pos
	_bubble.size = box_size
	dialogue_text.position = box_pos + Vector2(side, (box_size.y - text_h) * 0.5)
	dialogue_text.size = Vector2(text_w, text_h)

	if _click != null:
		_click.size = Vector2.ONE * click_icon_size
		_click.position = box_pos + box_size - Vector2.ONE * click_icon_size - click_icon_inset

	# ── Queue : base sur le bord haut, au plus près du locuteur, pointe
	# tournée vers lui.
	var has_tail := _tail != null and _speaker_portrait != null and is_instance_valid(_speaker_portrait) \
			and _speaker_portrait.visible
	var on_right := false
	var base_x := box_pos.x + tail_edge
	if _tail != null:
		_tail.visible = has_tail
	if has_tail:
		var inv := get_global_transform().affine_inverse()
		var pr := _speaker_portrait.get_global_rect()
		var target: Vector2 = inv * (pr.position + pr.size * tail_target)
		base_x = clampf(target.x, box_pos.x + tail_edge, box_pos.x + box_size.x - tail_edge)
		on_right = target.x > base_x + 1.0 or (absf(target.x - base_x) <= 1.0 and target.x > bubble_center_x)
		# Taille à l'écran par échelle : le nœud garde la taille réglée dans la
		# scène (agrandie pour l'édition), le cercle enfant suit en proportion.
		# Côté droit : échelle x négative → la queue ET le cercle sont
		# retournés ensemble, sans déplacer le cercle dans la queue.
		_tail.flip_h = false
		var s := tail_display_width / _tail.size.x if _tail.size.x > 0.0 else 1.0
		_tail.scale = Vector2(-s if on_right else s, s)
		# Points de l'image → repère local (non mis à l'échelle) du nœud.
		var tex_size := _tail.texture.get_size()
		var k := Vector2(_tail.size.x / tex_size.x, _tail.size.y / tex_size.y)
		var base_local := _tail_base_local
		var tip_local := tail_tip_px * k
		# Pivot = base : rotation et échelle se font autour de la jonction.
		_tail.pivot_offset = base_local
		# Base sur le bord haut de la bulle ; le bas de la queue passe dessous.
		var base := Vector2(base_x, box_pos.y)
		_tail.position = base - base_local
		var natural := ((tip_local - base_local) * _tail.scale).angle()
		var wanted := (target - base).angle()
		var rot := wrapf(wanted - natural, -PI, PI)
		var lim := deg_to_rad(tail_max_rotation)
		_tail.rotation = clampf(rot, -lim, lim)
		_shift_tail_caches(base_local, tip_local)

	# ── Onglet du nom : largeur selon le nom, posé sur le bord haut, à côté
	# de la queue (côté intérieur de la bulle).
	var has_name := name_label.text.strip_edges() != ""
	name_label.visible = has_name
	if _name_tab == null:
		return
	_name_tab.visible = has_name
	if not has_name:
		return
	var font := name_label.get_theme_font("font")
	var fsize := name_label.get_theme_font_size("font_size")
	var name_w := font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var sc := _name_tab.scale.x if _name_tab.scale.x > 0.0 else 1.0
	var tab_h := _name_tab.region_rect.size.y * sc
	var caps := (_name_tab.patch_margin_left + _name_tab.patch_margin_right) * sc
	var tab_w := maxf(name_w + name_padding, caps + 20.0)
	# Construit en pixels « image » puis réduit par scale (bords nets).
	_name_tab.size = Vector2(tab_w / sc, _name_tab.region_rect.size.y)
	var tail_half := 0.0
	if has_tail:
		tail_half = tail_display_width * 0.3
	var tab_x: float
	if not has_tail:
		tab_x = box_pos.x + tail_edge * 0.6
	elif on_right:
		tab_x = base_x - tail_half - name_gap - tab_w
	else:
		tab_x = base_x + tail_half + name_gap
	tab_x = clampf(tab_x, box_pos.x + 10.0, box_pos.x + box_size.x - tab_w - 10.0)
	# Le bas de l'onglet recouvre le bord de la bulle.
	var tab_y := box_pos.y - tab_h + border
	_name_tab.position = Vector2(tab_x, tab_y)
	name_label.position = Vector2(tab_x, tab_y + 2.0)
	name_label.size = Vector2(tab_w, tab_h - 10.0)


func set_portraits(left: Texture2D, right: Texture2D, active_side: String = "left") -> void:
	set_portraits_multi(
		[left, right] as Array[Texture2D],
		0 if active_side == "left" else 1
	)
