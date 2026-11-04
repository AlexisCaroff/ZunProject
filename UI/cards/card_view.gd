extends Control
class_name CardView

# ════════════════════════════════════════════════════════════════════
#  DESSIN D'UNE CARTE D'AFFINITÉ (généré en code, pas d'illustration requise)
# ════════════════════════════════════════════════════════════════════
#  Toujours construite à sa taille réelle (SIZE) puis réduite par `scale` :
#  la petite carte de l'inventaire et la grande carte d'aperçu ont ainsi
#  exactement la même mise en page.
#
#      ┌─(coût)──────────────┐
#      │       Titre         │
#      │  [portrait / art]   │
#      │  Joueur · Cible     │
#      │  Description…       │
#      └─────────────────────┘

const SIZE := Vector2(240, 340)
const TITLE_FONT := preload("res://UI/Euphorigenic.otf")
const BODY_FONT := preload("res://font/MarcellusSC-Regular.ttf")
const GOLD := Color(0.721569, 0.647059, 0.45098, 1)
const GOLD_BRIGHT := Color(1.0, 0.88, 0.55, 1)

var card: AffinityCard
var _frame: StyleBoxFlat


static func make(the_card: AffinityCard, card_scale: float = 1.0) -> CardView:
	var v := CardView.new()
	v.card = the_card
	v.scale = Vector2.ONE * card_scale
	v._build()
	return v


func _build() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := Panel.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.size = SIZE
	_frame = StyleBoxFlat.new()
	_frame.bg_color = Color(0.11, 0.075, 0.07, 1)
	_frame.border_color = GOLD
	_frame.set_border_width_all(4)
	_frame.set_corner_radius_all(14)
	bg.add_theme_stylebox_override("panel", _frame)
	add_child(bg)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = card.title if card != null else "?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.position = Vector2(54, 8)
	title.size = Vector2(SIZE.x - 66, 48)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD_BRIGHT)
	add_child(title)

	# Art : illustration, sinon portrait du joueur, sinon l'icône d'effet.
	var art_box := Panel.new()
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.position = Vector2(16, 58)
	art_box.size = Vector2(SIZE.x - 32, 140)
	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color(0.2, 0.14, 0.12, 1)
	art_style.border_color = GOLD.darkened(0.3)
	art_style.set_border_width_all(2)
	art_style.set_corner_radius_all(8)
	art_box.add_theme_stylebox_override("panel", art_style)
	add_child(art_box)
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(4, 4)
	art.size = art_box.size - Vector2(8, 8)
	art.texture = _art_texture()
	art_box.add_child(art)
	if art.texture == null:
		var all := Label.new()
		all.text = "Everyone"
		all.mouse_filter = Control.MOUSE_FILTER_IGNORE
		all.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		all.size = art_box.size
		all.add_theme_font_override("font", TITLE_FONT)
		all.add_theme_font_size_override("font_size", 30)
		all.add_theme_color_override("font_color", GOLD)
		art_box.add_child(all)

	# Petite icône d'effet dans le coin de l'art.
	if card != null and card.icon != null and card.illustration != null:
		var ic := TextureRect.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.texture = card.icon
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(40, 40)
		ic.position = art_box.position + art_box.size - Vector2(44, 44)
		add_child(ic)

	var who := Label.new()
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who.text = _who_text()
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.position = Vector2(12, 202)
	who.size = Vector2(SIZE.x - 24, 26)
	who.add_theme_font_override("font", BODY_FONT)
	who.add_theme_font_size_override("font_size", 15)
	who.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	add_child(who)

	var desc := RichTextLabel.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.bbcode_enabled = true
	desc.scroll_active = false
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = "[center]%s[/center]" % (card.description if card != null else "")
	desc.position = Vector2(14, 230)
	desc.size = Vector2(SIZE.x - 28, SIZE.y - 240)
	desc.add_theme_font_override("normal_font", BODY_FONT)
	desc.add_theme_font_size_override("normal_font_size", 16)
	desc.add_theme_color_override("default_color", Color(0.95, 0.93, 0.88))
	add_child(desc)

	# Pastille de coût dans le coin haut-gauche (à l'intérieur : la grille
	# défilante de l'inventaire rognerait une pastille qui déborde).
	var cost := Panel.new()
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost.position = Vector2(6, 6)
	cost.size = Vector2(46, 46)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.45, 0.16, 0.13, 1)
	cs.border_color = GOLD_BRIGHT
	cs.set_border_width_all(3)
	cs.set_corner_radius_all(23)
	cost.add_theme_stylebox_override("panel", cs)
	add_child(cost)
	var cl := Label.new()
	cl.text = str(card.cost) if card != null else "?"
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cl.size = cost.size
	cl.add_theme_font_override("font", TITLE_FONT)
	cl.add_theme_font_size_override("font_size", 28)
	cl.add_theme_color_override("font_color", Color.WHITE)
	cost.add_child(cl)


func set_selected(on: bool) -> void:
	if _frame != null:
		_frame.border_color = GOLD_BRIGHT if on else GOLD
		_frame.set_border_width_all(6 if on else 4)


## Carte grisée : pas jouable maintenant (mauvais personnage, trop chère…).
func set_dimmed(on: bool) -> void:
	modulate = Color(0.55, 0.55, 0.55, 1) if on else Color.WHITE


func _art_texture() -> Texture2D:
	if card == null:
		return null
	if card.illustration != null:
		return card.illustration
	if not card.is_for_anyone():
		var cd := _user_data()
		if cd != null and cd.explorationPortrait != null:
			return cd.explorationPortrait
	return card.icon


func _who_text() -> String:
	if card == null:
		return ""
	var who := "Anyone" if card.is_for_anyone() else card.user_name
	return "%s  ·  %s" % [who, card.target_label()]


func _user_data() -> CharacterData:
	var tree := Engine.get_main_loop() as SceneTree
	var gm: Node = tree.root.get_node_or_null("GameManager") if tree != null else null
	if gm == null:
		return null
	for cd in gm.characters:
		if cd != null and cd.Charaname == card.user_name:
			return cd
	return null
