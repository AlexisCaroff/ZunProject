@tool
extends Control
class_name CardView

# ════════════════════════════════════════════════════════════════════
#  CARTE D'AFFINITÉ — scène res://UI/cards/card_view.tscn
# ════════════════════════════════════════════════════════════════════
#  Toute la mise en page (positions, tailles, polices, couleurs) se règle
#  dans la scène. Le script ne fait que remplir les nœuds avec la carte :
#
#      ┌──────────────────────────────┐
#      │ [joueur]  [cibles]  (coût)   │  TopBand
#      ├──────────────────────────────┤
#      │            Titre             │  Title
#      │       [ illustration ]       │  ArtBox/Art
#      │  Description de l'effet…     │  DescBox/Desc
#      └──────────────────────────────┘
#
#  Toujours construite à sa taille réelle (SIZE) puis réduite par `scale` :
#  la petite carte de l'inventaire et la grande d'aperçu ont la même mise
#  en page. Aperçu dans l'éditeur : mets une carte (.tres) dans `card`.

const SCENE_PATH := "res://UI/cards/card_view.tscn"
const SIZE := Vector2(240, 340)
const TITLE_FONT := preload("res://UI/Euphorigenic.otf")
const BODY_FONT := preload("res://font/MarcellusSC-Regular.ttf")
const GOLD := Color(0.721569, 0.647059, 0.45098, 1)
const GOLD_BRIGHT := Color(1.0, 0.88, 0.55, 1)

## Carte affichée (aussi pour l'aperçu dans l'éditeur).
@export var card: AffinityCard:
	set(value):
		card = value
		if is_node_ready():
			refresh()

@export_group("Silhouettes")
## Joueur « tout le monde » et cible « un personnage au choix ».
@export var silhouette_neutral: Texture2D
## Un autre membre du groupe.
@export var silhouette_other: Texture2D
## Le joueur de la carte lui-même.
@export var silhouette_self: Texture2D

@export_group("Portraits")
## Où chercher le portrait du joueur quand GameManager n'est pas là
## (éditeur). En jeu, les personnages de GameManager passent d'abord.
@export var portrait_sources: Array[CharacterData] = []
## Taille mini / maxi de la police du titre (réduite si le titre est long).
@export var title_font_min := 14

@onready var _frame_panel: Panel = $Frame
@onready var _user_portrait: TextureRect = $TopBand/PortraitClip/UserPortrait
@onready var _targets: HBoxContainer = $TopBand/Targets
@onready var _cost_label: Label = $TopBand/CostBadge/CostLabel
@onready var _title: Label = $Title
@onready var _art: TextureRect = $ArtBox/Art
@onready var _desc: RichTextLabel = $DescBox/Desc

var _frame: StyleBoxFlat
var _frame_border := 4
var _title_size := 24


static func make(the_card: AffinityCard, card_scale: float = 1.0) -> CardView:
	var v: CardView = (load(SCENE_PATH) as PackedScene).instantiate()
	v.card = the_card
	v.scale = Vector2.ONE * card_scale
	return v


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	# StyleBox propre à cette carte (set_selected la modifie).
	var sb := _frame_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		_frame_border = sb.border_width_top
		if not Engine.is_editor_hint():
			_frame = sb.duplicate()
			_frame_panel.add_theme_stylebox_override("panel", _frame)
	_title_size = _title.get_theme_font_size("font_size")
	refresh()


## Remplit la carte. Sans carte (scène ouverte seule), garde les textes
## d'exemple de la scène.
func refresh() -> void:
	if card == null:
		return
	_title.text = card.title
	_fit_title()
	_desc.text = "[center]%s[/center]" % card.description
	_cost_label.text = str(card.cost)
	_art.texture = card.illustration if card.illustration != null else card.icon
	_user_portrait.texture = _user_texture()
	_fill_targets()


func set_selected(on: bool) -> void:
	if _frame != null:
		_frame.border_color = GOLD_BRIGHT if on else GOLD
		_frame.set_border_width_all(_frame_border + 2 if on else _frame_border)


## Carte grisée : pas jouable maintenant (mauvais personnage, trop chère…).
func set_dimmed(on: bool) -> void:
	modulate = Color(0.55, 0.55, 0.55, 1) if on else Color.WHITE


# ── Bandeau ─────────────────────────────────────────────────────────

## Silhouettes des cibles, de gauche à droite.
func target_icons() -> Array[Texture2D]:
	var o := silhouette_other
	match card.target:
		AffinityCard.Target.SELF:
			return [silhouette_self]
		AffinityCard.Target.OTHER_ALLY:
			return [o]
		AffinityCard.Target.ANY_ALLY:
			return [silhouette_neutral]
		AffinityCard.Target.OTHERS:
			return [o, o, o]
	return [o, o, o, silhouette_self]   # ALL : tout le groupe


func _fill_targets() -> void:
	var icons := target_icons()
	var slots := _targets.get_children()
	for i in slots.size():
		var slot := slots[i] as TextureRect
		if slot == null:
			continue
		slot.visible = i < icons.size()
		if slot.visible:
			slot.texture = icons[i]


func _user_texture() -> Texture2D:
	if card.is_for_anyone():
		return silhouette_neutral
	var cd := _user_data()
	if cd != null and cd.explorationPortrait != null:
		return cd.explorationPortrait
	return silhouette_neutral


func _user_data() -> CharacterData:
	var pool: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	var gm: Node = tree.root.get_node_or_null("GameManager") if tree != null and tree.root != null else null
	if gm != null:
		pool.append_array(gm.characters)
	pool.append_array(portrait_sources)
	for cd in pool:
		if cd != null and cd.Charaname == card.user_name:
			return cd
	return null


## Réduit la police du titre jusqu'à ce qu'il tienne sur une ligne.
func _fit_title() -> void:
	var font := _title.get_theme_font("font")
	var fs := _title_size
	while fs > title_font_min and font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > _title.size.x - 4.0:
		fs -= 1
	_title.add_theme_font_size_override("font_size", fs)
