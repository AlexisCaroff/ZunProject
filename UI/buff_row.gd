extends Control
class_name BuffRow

# ════════════════════════════════════════════════════════════════════
#  LIGNE « Buffs : » DE LA FICHE PERSONNAGE
# ════════════════════════════════════════════════════════════════════
#
#  Affiche les icônes des buffs et debuffs actifs du personnage
#  sélectionné. Survoler une icône donne la statistique touchée, le
#  montant et le nombre de tours restants.
#
#  Deux usages :
#   - la scène contient déjà un libellé « Buffs : » → on lui colle les
#     icônes juste derrière (position_after) et on n'écrit pas de titre ;
#   - la scène n'en a pas → la ligne dessine son propre titre.
#
#  Le tout est construit par code : aucune scène à modifier, ni pour
#  l'exploration ni pour les portes (ni pour les salles qui héritent du
#  template d'exploration).
#
#  Hors combat les buffs vivent dans characterData.buffs — c'est là que
#  les potions les déposent et que CharaExplo les relit.

## Côté d'une icône de buff.
const ICON_SIZE := 44.0
## Espace entre deux icônes. Les icônes sont rognées à leur dessin (cf.
## _trimmed), cet écart est donc l'espace réellement visible.
const ICON_GAP := 2
## Texte affiché quand le personnage n'a aucun buff.
const EMPTY_TEXT := "-"

## Icônes déjà rognées, par texture source : le rognage lit les pixels, on
## ne le fait qu'une fois par icône pour toute la partie.
static var _trim_cache: Dictionary = {}
## Largeur totale réservée à la ligne : au-delà, les icônes sont rognées.
const ROW_WIDTH := 460.0

var title: Label
var icons: HBoxContainer
var empty_label: Label


## Construit la ligne et l'accroche à `parent` (la racine de l'interface).
## `style_from` est un libellé déjà présent dans la scène — police, taille
## et couleur en sont recopiées. `with_title` à false n'écrit pas de titre :
## à utiliser quand la scène porte déjà son propre libellé « Buffs : ».
static func create(parent: Node, pos: Vector2, style_from: Control = null,
		with_title: bool = true, z: int = 6) -> BuffRow:
	var row := BuffRow.new()
	row.name = "BuffRow"
	row._build(style_from, with_title)
	row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	row.offset_left = pos.x
	row.offset_top = pos.y
	row.offset_right = pos.x + ROW_WIDTH
	row.offset_bottom = pos.y + ICON_SIZE
	row.z_index = z
	# La ligne elle-même ne capte rien : seules les icônes réagissent au
	# survol, pour ne pas voler les clics des libellés en dessous.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.clip_contents = true
	# add_child() échoue ("Parent node is busy setting up children") quand on
	# appelle create() depuis le _ready() d'un enfant : le parent est encore
	# en train d'initialiser sa descendance. En differé, l'ajout passe dans
	# tous les cas, et remplir la ligne entre-temps ne pose pas de problème.
	parent.add_child.call_deferred(row)
	return row


## Coin haut-gauche à passer à create() pour poser les icônes juste après le
## texte d'un libellé déjà présent dans la scène (« Buffs : »). Les icônes
## sont centrées verticalement sur la ligne de texte.
static func position_after(label: Control, gap: float = 12.0) -> Vector2:
	var txt := ""
	var font: Font = null
	var fsize := 20

	if label is RichTextLabel:
		txt = (label as RichTextLabel).get_parsed_text()
		font = label.get_theme_font("normal_font")
		fsize = label.get_theme_font_size("normal_font_size")
	elif label is Label:
		txt = (label as Label).text
		font = label.get_theme_font("font")
		fsize = label.get_theme_font_size("font_size")

	# Un libellé peut porter un retour à la ligne : seule la première
	# compte pour savoir où finit « Buffs : ».
	txt = txt.split("\n")[0]

	var w := 110.0
	if font != null:
		w = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x

	return Vector2(
		label.position.x + w + gap,
		label.position.y + (float(fsize) - ICON_SIZE) * 0.5
	)


func _build(style_from: Control, with_title: bool) -> void:
	var font: Font = null
	var col := Color(0.721569, 0.647059, 0.45098, 1)
	var fsize := 20

	if style_from != null and style_from.is_inside_tree():
		if style_from is RichTextLabel:
			font = style_from.get_theme_font("normal_font")
			fsize = style_from.get_theme_font_size("normal_font_size")
			col = style_from.get_theme_color("default_color")
		elif style_from is Label:
			font = style_from.get_theme_font("font")
			fsize = style_from.get_theme_font_size("font_size")
			col = style_from.get_theme_color("font_color")

	# Largeur du titre mesurée dans sa propre police : les icônes se calent
	# juste derrière. Sans titre, elles partent du bord de la ligne.
	var tw := 0.0
	if with_title:
		tw = 110.0
		if font != null:
			tw = font.get_string_size("Buffs :", HORIZONTAL_ALIGNMENT_LEFT, -1,
					fsize).x + 12.0

		title = Label.new()
		title.name = "Title"
		title.text = "Buffs :"
		if font != null:
			title.add_theme_font_override("font", font)
		title.add_theme_font_size_override("font_size", fsize)
		title.add_theme_color_override("font_color", col)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.set_anchors_preset(Control.PRESET_TOP_LEFT)
		title.offset_left = 0.0
		title.offset_top = 0.0
		title.offset_right = tw
		title.offset_bottom = ICON_SIZE
		add_child(title)

	icons = HBoxContainer.new()
	icons.name = "Icons"
	icons.add_theme_constant_override("separation", ICON_GAP)
	icons.alignment = BoxContainer.ALIGNMENT_BEGIN
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.set_anchors_preset(Control.PRESET_TOP_LEFT)
	icons.offset_left = tw
	icons.offset_top = 0.0
	icons.offset_right = ROW_WIDTH
	icons.offset_bottom = ICON_SIZE
	add_child(icons)

	empty_label = Label.new()
	empty_label.name = "Empty"
	empty_label.text = EMPTY_TEXT
	if font != null:
		empty_label.add_theme_font_override("font", font)
	empty_label.add_theme_font_size_override("font_size", fsize)
	empty_label.add_theme_color_override("font_color", Color(0.667, 0.667, 0.667, 1))
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	empty_label.offset_left = tw + 4.0
	empty_label.offset_top = 0.0
	empty_label.offset_right = ROW_WIDTH
	empty_label.offset_bottom = ICON_SIZE
	add_child(empty_label)


## Redessine la ligne pour le personnage donné. Accepte aussi bien une
## CharacterData qu'un tableau de Buff.
func show_for(source) -> void:
	var list: Array = []
	if source is Array:
		list = source
	elif source != null and source.get("buffs") != null:
		list = source.buffs
	_fill(list)


func _fill(list: Array) -> void:
	if not is_instance_valid(icons):
		return
	for child in icons.get_children():
		icons.remove_child(child)
		child.queue_free()

	var shown := 0
	for b in list:
		if b == null or not (b is Buff):
			continue
		var tex := TextureRect.new()
		var icon := _trimmed((b as Buff).icon)
		tex.texture = icon
		# Largeur au prorata du dessin : une icône étroite ne réserve pas un
		# carré entier, les suivantes se collent à elle.
		var w := ICON_SIZE
		if icon != null and icon.get_height() > 0:
			w = ICON_SIZE * float(icon.get_width()) / float(icon.get_height())
		tex.custom_minimum_size = Vector2(w, ICON_SIZE)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Seule l'icône capte la souris, pour l'infobulle.
		tex.mouse_filter = Control.MOUSE_FILTER_STOP
		tex.tooltip_text = _describe(b as Buff)
		icons.add_child(tex)
		shown += 1

	if is_instance_valid(empty_label):
		empty_label.visible = shown == 0


## Icône réduite à sa zone réellement dessinée : les sources ont de larges
## marges transparentes, qui faisaient paraître les icônes très espacées.
static func _trimmed(src: Texture2D) -> Texture2D:
	if src == null:
		return null
	if _trim_cache.has(src):
		return _trim_cache[src]
	var out: Texture2D = src
	var img := src.get_image()
	if img != null and img.is_compressed() and img.decompress() != OK:
		img = null
	if img != null:
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0 and used.size != img.get_size():
			var atlas := AtlasTexture.new()
			atlas.atlas = src
			atlas.region = Rect2(used)
			out = atlas
	_trim_cache[src] = out
	return out


## Texte de l'infobulle : « Attack +5 — 3 tours », précédé du nom du buff
## quand il en porte un.
func _describe(b: Buff) -> String:
	var keys := Buff.Stat.keys()
	var stat_name := "Effet"
	if b.stat >= 0 and b.stat < keys.size():
		stat_name = str(keys[b.stat]).capitalize()

	var line := stat_name
	if b.amount != 0:
		line += " %+d" % b.amount
	line += " — %d tours" % b.duration

	var out := line
	if b.name != "" and b.name != "Buff":
		out = "%s\n%s" % [b.name, line]
	if b.description != "" and b.description != "Effet temporaire sur les statistiques.":
		out += "\n%s" % b.description
	return out
