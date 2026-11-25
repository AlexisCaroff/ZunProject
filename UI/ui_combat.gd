extends Control
class_name UI_combat

@onready var skill_buttons = [
	$CanvasLayer/ActionPanel/Action1,
	$CanvasLayer/ActionPanel/Action2,
	$CanvasLayer/ActionPanel/Action3,
	$CanvasLayer/ActionPanel/Action4,
	$CanvasLayer/ActionPanel/Action5,
]
@onready var passButton : Button = $CanvasLayer/ActionPass
@onready var RoundNumbersHolder : RichTextLabel = $RoundsLabel
@onready var Charaname_panel = $CanvasLayer/Charaname
@onready var charaPortrait = $CanvasLayer/charaPortrait
@onready var log_panel = $contexte
@onready var contextennemi= $contextennemi
@onready var labelAction= $CanvasLayer/LabelAction
@onready var combat_manager = $CombatManager
@onready var turnOrderPanel = $TurnOrderPanel

@onready var AttLabel = $CanvasLayer/AttLabel2
@onready var DefLabel = $CanvasLayer/DefLabel2
@onready var WillPower = $CanvasLayer/WillPower2
@onready var Stamina = $CanvasLayer/Stamina
@onready var StaminaNumber = $CanvasLayer/Stamina2
@onready var StaminaBar=$CanvasLayer/StaminaProgressBar
@onready var guilt= $CanvasLayer/Guilt
@onready var guiltNumber=$CanvasLayer/Guilt2
@onready var guiltBar=$CanvasLayer/GuiltProgressBar
@onready var horny = $CanvasLayer/Horny
@onready var hornyNumber = $CanvasLayer/Horny2
@onready var hornyBar=$CanvasLayer/LustProgressBar

@onready var charaPortrait2 = $CanvasLayer/overmenu/charaPortrait2
@onready var Charaname2 = $CanvasLayer/overmenu/Charaname2
@onready var AttLabel2 = $CanvasLayer/overmenu/AttLabel2
@onready var DefLabel2 = $CanvasLayer/overmenu/DefLabel2
@onready var Stamina2 = $CanvasLayer/overmenu/Stamina2
@onready var guilt2 = $CanvasLayer/overmenu/Guilt2
@onready var horny2 = $CanvasLayer/overmenu/Horny2
@onready var skills2 = $CanvasLayer/overmenu/ActionPanel2.get_children()
@onready var hideSkillsPanel = $CanvasLayer/EnnemiTurn
@onready var viewport: Viewport = $CanvasLayer/SubViewportContainer/SubViewport
@onready var donjon_map: Map = $CanvasLayer/SubViewportContainer/SubViewport/map
@onready var cooldown_bars = [
	$CanvasLayer/ActionPanel/Action1/CooldownBar,
	$CanvasLayer/ActionPanel/Action2/CooldownBar,
	$CanvasLayer/ActionPanel/Action3/CooldownBar,
	$CanvasLayer/ActionPanel/Action4/CooldownBar,
	$CanvasLayer/ActionPanel/Action5/CooldownBar
]

@onready var Items = $CanvasLayer/Items
@onready var MenuPerso:InventoryUI = $"../MenuPerso"
@onready var charaPortraitButton = $CanvasLayer/charaPortrait/charaPortraitButton

# ── Sac d'équipe consultable pendant le combat ───────────────────────
# Construit par code : il y a quatre scènes de combat (normale + trois
# boss), les mêmes nœuds posés quatre fois seraient quatre fois le même
# travail à refaire à chaque retouche.
#
# Lecture seule : on regarde ce qu'on a, on ne boit pas depuis ici. Boire
# passe par le menu perso, qui sait déjà gérer le tour, la cible et la fin
# de tour — refaire cette logique ici en ferait une deuxième version à
# maintenir.
@export var bag_rect: Rect2 = Rect2(1420, 802, 480, 264)
@export var bag_bg: Texture2D = preload("res://UI/UI inventory/UI_inventory_box_pack.png")
@export var bag_icon: Texture2D = preload("res://UI/UI inventory/UI_inventory_button_bag.png")
@export var bag_map_icon: Texture2D = preload("res://UI/UI inventory/UI_inventory_button_map.png")
var inventory_panel: DoorInventory = null
var bag_toggle: Button = null
var showing_inventory: bool = false
## Boutons carte / sac côte à côte (cf. UI/map_bag_buttons.gd).
var map_bag_buttons: Dictionary = {}
var card_hand: CardHand = null


# ════════════════════════════════════════════════════════════════════
#  STATS DU PERSONNAGE ACTIF : même présentation qu'en exploration / porte
# ════════════════════════════════════════════════════════════════════
#  CombatInterface.tscn porte cette mise en page dans sa scène (modifiable
#  dans l'éditeur). Les autres interfaces de combat qui partagent ce script
#  la reçoivent par code (build_stat_layout) : positions de la porte,
#  recalées sur le nom du personnage. Portrait, objets et kinks ne bougent pas.

const STAT_HOVER := preload("res://UI/stat_hover.gd")
const ICON_STAMINA := preload("res://UI/Stamina.png")
const ICON_LUST := preload("res://UI/lustIcon.png")
const ICON_GUILT := preload("res://UI/GuiltIcon.png")
const ICON_ATTACK := preload("res://UI/attack.png")
const ICON_DEF := preload("res://UI/buffDeff.png")
const ICON_WILL := preload("res://UI/WillPowerIcon.png")
const GOLD := Color(0.721569, 0.647059, 0.45098, 1)
## Repère de la porte : son nom est en (266, 801).
const DOOR_NAME_POS := Vector2(266, 801)

var buff_row: BuffRow = null
var _current_for_stats: Character = null


func _setup_stat_layout() -> void:
	var layer := get_node_or_null("CanvasLayer")
	if layer == null:
		return
	# Interface déjà mise en page dans sa scène (CombatInterface.tscn) : on
	# garde ses réglages tels quels. Les autres sont mises en page ici.
	if layer.get_node_or_null("StatStaminaIcon") == null:
		build_stat_layout(layer)
	_wire_stat_layout(layer)
	# Le CombatManager a pu masquer la lust (tutoriel) avant que les icônes
	# créées ici existent : on réapplique.
	if combat_manager != null and combat_manager.lust_hidden:
		combat_manager._apply_lust_visibility()


## Crée et place icônes, jauges et ligne « Buff: ». Appelée en jeu pour les
## interfaces pas encore mises en page, et par tools/bake_combat_stats.gd
## pour écrire cette mise en page dans une scène (n'utilise que get_node :
## marche sur une scène instanciée hors de l'arbre).
func build_stat_layout(layer: Node) -> void:
	var name_lbl := layer.get_node_or_null("Charaname") as Control
	if name_lbl == null:
		return
	var o: Vector2 = name_lbl.position - DOOR_NAME_POS

	# Anciens libellés « Stamina: / Lust: / Guilt: » : remplacés par les icônes.
	for n in ["Stamina3", "Horny3", "Guilt3"]:
		var old := layer.get_node_or_null(n) as CanvasItem
		if old != null:
			old.visible = false

	# Jauges épaisses, valeur écrite dedans.
	var bars := [["StaminaProgressBar", 871.0], ["LustProgressBar", 913.0], ["GuiltProgressBar", 955.0]]
	for b in bars:
		var bar := layer.get_node_or_null(b[0]) as Control
		if bar == null:
			continue
		bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bar.position = Vector2(336, b[1]) + o
		bar.size = Vector2(181, 16)
		bar.scale = Vector2(1.00234, 1.40121)
		bar.z_index = 7
	var nums := [["Stamina2", Vector2(339.645, 868)], ["Horny2", Vector2(340.645, 910)],
			["Guilt2", Vector2(339.645, 952)]]
	for n in nums:
		var lbl := layer.get_node_or_null(n[0]) as Control
		if lbl == null:
			continue
		lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lbl.position = n[1] + o
		lbl.size = Vector2(121, 55)
		lbl.scale = Vector2.ONE
		lbl.z_index = 8
		if lbl is RichTextLabel:
			lbl.add_theme_color_override("default_color", Color.WHITE)
			lbl.add_theme_font_size_override("normal_font_size", 20)
		elif lbl is Label:
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_font_size_override("font_size", 20)

	# Icônes des jauges (noms repris par le masquage de la lust du tutoriel).
	_icon(layer, "StatStaminaIcon", ICON_STAMINA, Vector2(308.285, 884) + o, Vector2.ONE * 0.456722, Color(0.878431, 0.584314, 0.341176))
	_icon(layer, "StatLustIcon", ICON_LUST, Vector2(307.645, 927) + o, Vector2.ONE * 0.439111, Color(0.933333, 0.109804, 0.72549))
	_icon(layer, "StatGuiltIcon", ICON_GUILT, Vector2(304.285, 970.39) + o, Vector2(0.617867, 0.525407), Color(0.266667, 0.294118, 0.364706))

	# Ligne Attaque / Défense / Volonté : icônes de même hauteur, alignées,
	# valeur collée à droite de chacune.
	var row_y := 1013.0 + o.y
	var row := [
		[_icon(layer, "StatAttackIcon", ICON_ATTACK, Vector2(305.645 + o.x, row_y), Vector2.ONE, Color(0.286, 0.576, 0.784)), "AttLabel2"],
		[_icon(layer, "StatDefIcon", ICON_DEF, Vector2(415.645 + o.x, row_y), Vector2.ONE, Color.WHITE), "DefLabel2"],
		[_icon(layer, "StatWillIcon", ICON_WILL, Vector2(543.645 + o.x, row_y), Vector2.ONE, Color(0.223, 0.534, 0.749)), "WillPower2"],
	]
	for p in row:
		var icon: Sprite2D = p[0]
		var k := 36.0 / float(icon.texture.get_height())
		icon.scale = Vector2(k, k)
		var lbl := layer.get_node_or_null(p[1]) as RichTextLabel
		if lbl == null:
			continue
		lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lbl.scale = Vector2.ONE
		lbl.size = Vector2(120, 40)
		lbl.add_theme_font_size_override("normal_font_size", 25)
		lbl.position = Vector2(icon.position.x + icon.texture.get_width() * k * 0.5 + 6.0, row_y - 15.0)
		lbl.z_index = 8

	# Libellé « Buff: » ; les icônes des buffs sont posées derrière en jeu.
	var buffs_label := RichTextLabel.new()
	buffs_label.name = "Buffs"
	buffs_label.bbcode_enabled = true
	buffs_label.scroll_active = false
	buffs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buffs_label.text = "Buff: "
	buffs_label.add_theme_color_override("default_color", GOLD)
	buffs_label.add_theme_font_override("normal_font", preload("res://UI/Euphorigenic.otf"))
	buffs_label.add_theme_font_size_override("normal_font_size", 25)
	buffs_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	buffs_label.position = Vector2(291.645, 1036) + o
	buffs_label.size = Vector2(341, 55)
	buffs_label.z_index = 7
	layer.add_child(buffs_label)


## Partie dynamique, toujours faite en jeu : icônes des buffs et détail des
## stats au survol (base + kinks + équipement + buffs de combat).
func _wire_stat_layout(layer: Node) -> void:
	var buffs_label := layer.get_node_or_null("Buffs") as Control
	if buffs_label != null:
		buff_row = BuffRow.create(layer, BuffRow.position_after(buffs_label), buffs_label, false, 8)
	var hover = STAT_HOVER.new(layer)
	for p in [["StatAttackIcon", AttLabel, "attack"], ["StatDefIcon", DefLabel, "defense"],
			["StatWillIcon", WillPower, "willpower"]]:
		var icon := layer.get_node_or_null(p[0]) as Sprite2D
		if icon != null:
			hover.attach(icon, p[1], _combat_stat_text.bind(p[2]))


func _icon(layer: Node, n: String, tex: Texture2D, pos: Vector2, sc: Vector2, col: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = n
	s.texture = tex
	s.position = pos
	s.scale = sc
	s.modulate = col
	s.z_index = 7
	layer.add_child(s)
	return s


func _combat_stat_text(stat: String) -> String:
	if _current_for_stats == null or not is_instance_valid(_current_for_stats):
		return ""
	return _current_for_stats.characterData.stat_tooltip(stat, _current_for_stats.buffs)


## Lignes « Kinks : … » (cf. UI/kinks_label.gd) : personnage dont c'est le
## tour (derrière son nom) et personnage survolé (panneau fiche).
var kinks_current: RichTextLabel = null
var kinks_hover: RichTextLabel = null


## Infobulle des skills : fond sombre, hauteur ajustée au texte, posée
## au-dessus de la rangée de boutons (cf. action_Button._fit_tip).
func _setup_action_label() -> void:
	var tip := labelAction as RichTextLabel
	if tip == null:
		return
	if not tip.has_meta("tip_anchor"):
		# Cachée tant qu'aucun bouton n'est survolé : avec son fond, une
		# infobulle vide resterait affichée comme un rectangle sous les skills.
		tip.visible = false
		tip.text = ""
		tip.bbcode_enabled = true
		tip.scroll_active = false
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tip.size.x = 660
		var style := STAT_HOVER.bubble_style()
		style.set_content_margin_all(14)
		tip.add_theme_stylebox_override("normal", style)
	# Recalculé à chaque tour : la rangée peut avoir bougé.
	var row: Rect2 = (skill_buttons[0] as Control).get_parent().get_global_rect()
	tip.set_meta("tip_anchor", Vector2(row.get_center().x, row.position.y - 18))


const PASS_TIP := "End Turn"
var _pass_tip: Label = null

## Infobulle du bouton de fin de tour : petite bulle noire (même style que
## les autres survols), centrée au-dessus du bouton.
func _on_pass_button_mouse_entered() -> void:
	if _pass_tip == null:
		_pass_tip = Label.new()
		_pass_tip.text = PASS_TIP
		_pass_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pass_tip.z_as_relative = false
		_pass_tip.z_index = 50
		_pass_tip.add_theme_font_override("font", STAT_HOVER.FONT)
		_pass_tip.add_theme_font_size_override("font_size", 24)
		_pass_tip.add_theme_color_override("font_color", Color("#f2d38a"))
		var style := STAT_HOVER.bubble_style()
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		_pass_tip.add_theme_stylebox_override("normal", style)
		passButton.get_parent().add_child(_pass_tip)
	_pass_tip.size = Vector2.ZERO
	_pass_tip.size = _pass_tip.get_minimum_size()
	var btn := passButton.get_global_rect()
	_pass_tip.global_position = Vector2(btn.get_center().x - _pass_tip.size.x * 0.5,
			btn.position.y - 12 - _pass_tip.size.y)
	_pass_tip.visible = true


const PASS_OUTLINE_SHADER := preload("res://characters/character_outline.gdshader")
const PASS_HOVER_SCALE := 1.15
const PASS_PRESS_SCALE := 0.88

## Bouton de fin de tour : grossit au survol, contour blanc + rapetisse
## pendant le clic (même contour que les skills sélectionnés).
func _setup_pass_button_feedback() -> void:
	var icon := passButton.get_node_or_null("UiClose") as CanvasItem
	if icon != null:
		var mat := ShaderMaterial.new()
		mat.shader = PASS_OUTLINE_SHADER
		mat.set_shader_parameter("enabled", false)
		mat.set_shader_parameter("outline_color", Color.WHITE)
		mat.set_shader_parameter("outline_width", 8.0)
		mat.set_shader_parameter("outline_direction", Vector2.ZERO)
		icon.material = mat
	passButton.pivot_offset = passButton.size * 0.5
	passButton.mouse_entered.connect(func(): _tween_pass_scale(PASS_HOVER_SCALE))
	passButton.mouse_exited.connect(func():
		_set_pass_outline(false)
		_tween_pass_scale(1.0))
	passButton.button_down.connect(func():
		_set_pass_outline(true)
		_tween_pass_scale(PASS_PRESS_SCALE, 0.08))
	passButton.button_up.connect(func():
		_set_pass_outline(false)
		_tween_pass_scale(PASS_HOVER_SCALE if passButton.is_hovered() else 1.0))


func _tween_pass_scale(factor: float, duration: float = 0.15) -> void:
	passButton.create_tween().tween_property(passButton, "scale", Vector2.ONE * factor, duration) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_pass_outline(on: bool) -> void:
	var icon := passButton.get_node_or_null("UiClose") as CanvasItem
	if icon != null and icon.material is ShaderMaterial:
		(icon.material as ShaderMaterial).set_shader_parameter("enabled", on)


func _on_pass_button_mouse_exited() -> void:
	if _pass_tip != null:
		_pass_tip.visible = false


func _ready():
	_setup_stat_layout()
	_setup_action_label()
	kinks_current = KinksLabel.after_name(Charaname_panel)
	var overmenu := get_node_or_null("CanvasLayer/overmenu")
	if overmenu != null:
		kinks_hover = KinksLabel.at(overmenu, Vector2(117, 158))
	var current_character = combat_manager.get_current_character()
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	await get_tree().process_frame
	#call_deferred("update_ui_for_current_character", current_character)


	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource, viewport)

	_setup_bag(gm)
	charaPortraitButton.connect("button_down", showMenuPerso)
	passButton.mouse_entered.connect(_on_pass_button_mouse_entered)
	passButton.mouse_exited.connect(_on_pass_button_mouse_exited)
	_setup_pass_button_feedback()
	#MenuPerso.inventory_items = gm.inventory
	#MenuPerso.update_inventory_ui()
	log_panel.visible = false
	contextennemi.visible = false

# -------------------------------------------------------------------------
# ➤ AFFICHE LA FILE DE PRIORITÉ
# -------------------------------------------------------------------------
func update_turn_queue_ui(queue: Array[Character]):
	if turnOrderPanel == null: 
		turnOrderPanel=$TurnOrderPanel
	
	for child in turnOrderPanel.get_children():
		child.queue_free()
	var first =true
	for c in queue:
		var portraitChara = TextureRect.new()
		portraitChara.texture = c.characterData.initiative_icon  # CHANGED
		portraitChara.custom_minimum_size = Vector2(120, 120)
		portraitChara.modulate = Color(0.7,0.7,0.7,1.0)
		portraitChara.expand_mode= TextureRect.EXPAND_IGNORE_SIZE
		portraitChara.stretch_mode= TextureRect.STRETCH_SCALE
		portraitChara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if !first:
			portraitChara.custom_minimum_size = Vector2(90, 90)
			portraitChara.modulate = Color(0.7,0.7,0.7,1.0)
		turnOrderPanel.add_child(portraitChara)
		
		first=false


# -------------------------------------------------------------------------
# ➤ MET À JOUR L’UI DU PERSONNAGE ACTIF
# -------------------------------------------------------------------------
func update_ui_for_current_character(character: Character):
	if !character.characterData.is_player_controlled:
		update_ui_for_overed_character(character)
		for i in range(skill_buttons.size()):
			var button : Button = skill_buttons[i]
			button.disabled = true
			passButton.disabled=true
		return
	passButton.disabled=false
	if !MenuPerso:
		MenuPerso = $"../MenuPerso"
	MenuPerso.select_character(character.characterData)
	hideSkillsPanel.visible = !character.characterData.is_player_controlled # CHANGED

	update_equipment_icons(character)

	Charaname_panel.text = character.characterData.Name
	KinksLabel.show_for(kinks_current, character.characterData)
	charaPortrait.texture = character.characterData.explorationPortrait

	# Clear anciens signaux
	for button in skill_buttons:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	_setup_action_label()
	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var skill = character.get_skill(i)
		button.label =labelAction

		if skill != null:
			button.Actiontext = skill.tooltip_bbcode()
			button.disabled = !skill.can_use()
			button.icon = skill.icon
			var mat := ShaderMaterial.new()
			mat.shader = load("res://characters/character_outline.gdshader")
			button.material = mat
			(button.material as ShaderMaterial).set_shader_parameter("enabled", false)
			mat.set_shader_parameter("outline_direction", Vector2.ZERO)
			#print("set skill buttons")
			if character.characterData.current_horniness>=100 :
				button.disabled = true
			if character.stunned ==true:
				button.disabled = true
			var index = i
			button.pressed.connect(func(): combat_manager.use_skill(index))

			update_cooldown_bar(cooldown_bars[i], skill)

		else:
			button.text = "—"
			button.disabled = true
	var chara = character.characterData
	AttLabel.bbcode_enabled = true
	DefLabel.bbcode_enabled = true
	WillPower.bbcode_enabled = true
	
	# Présentation exploration / porte : l'icône dit la stat, le libellé ne
	# porte que la valeur (déjà calculée par Character.update_stats).
	_current_for_stats = character
	AttLabel.text = " %d" % chara.attack
	DefLabel.text = " %d" % chara.defense
	WillPower.text = " %d" % chara.willpower
	if buff_row != null:
		buff_row.show_for(character.buffs)
	
	StaminaNumber.text = "%d / %d" % [
		character.characterData.current_stamina,
		character.characterData.max_stamina
	]
	StaminaBar.value=character.characterData.current_stamina
	guiltNumber.text = "%d / %d" % [
		character.characterData.current_stress,
		character.characterData.max_stress
	]
	guiltBar.value=character.characterData.current_stress
	hornyNumber.text = "%d / %d" % [
		character.characterData.current_horniness,
		character.characterData.max_horniness
	]
	hornyBar.value=character.characterData.current_horniness

func disableActionButton():
	for button : Button in skill_buttons:
		button.disabled=true
# -------------------------------------------------------------------------
# ➤ ÉQUIPEMENT (basé sur characterData)
# -------------------------------------------------------------------------
func update_equipment_icons(character: Character):
	var slots = [
		Items.get_node("Item1"),
		Items.get_node("Item2")
	]

	for s in slots:
		s.remove_item()

	for i in range(character.characterData.equipped_items.size()):
		if i >= slots.size(): break
		var equip: Equipment = character.characterData.equipped_items[i]
		slots[i].assigne_item(equip)


# -------------------------------------------------------------------------
# ➤ BARRE DE COOLDOWN
# -------------------------------------------------------------------------
func update_cooldown_bar(container: HBoxContainer, skill):

	for child in container.get_children():
		child.queue_free()

	if skill == null: return
	if skill.cooldown <= 0: return

	var max_cd = skill.cooldown
	var current_cd = skill.current_cooldown
	var charged = max_cd - current_cd

	# Un effet peut allonger la recharge au-delà du maximum : un point par tour.
	for i in range(maxi(max_cd, current_cd)):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(5, 5)
		rect.color = Color(0.2,0.2,0.2)
		if i < charged:
			rect.color = Color(0.64,0.56,0.36)
		container.add_child(rect)


# -------------------------------------------------------------------------
# ➤ UI D’UN PERSONNAGE SURVOLÉ
# -------------------------------------------------------------------------
func update_ui_for_overed_character(character: Character):

	Charaname2.text = character.characterData.Name
	KinksLabel.show_for(kinks_hover, character.characterData)
	charaPortrait2.texture = character.characterData.explorationPortrait

	for button in skills2:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	for i in range(skills2.size()):
		var button = skills2[i]
		var skill = character.get_skill(i)

		if skill != null:
			button.Actiontext = skill.tooltip_bbcode()
			button.icon = skill.icon
		else:
			button.text = "—"
			button.disabled = true

	# --- CHANGED stats runtime
	AttLabel2.text = "Attack: %d" % character.characterData.attack
	DefLabel2.text = "Defense: %d" % character.characterData.defense
	Stamina2.text = "Stamina: %d / %d" % [
		character.characterData.current_stamina,
		character.characterData.max_stamina
	]
	if character.characterData.is_player_controlled:
		guilt2.text = "Guilt: %d / %d" % [
			character.characterData.current_stress,
			character.characterData.max_stress
		]
		horny2.text = "Horny: %d / %d" % [
			character.characterData.current_horniness,
			character.characterData.max_horniness
		]
	else :
		guilt2.text =""
		horny2.text =""
		


# -------------------------------------------------------------------------
# ➤ LOG
# -------------------------------------------------------------------------
func log(text):
	var cc = combat_manager.current_character
	if cc.characterData.is_player_controlled:
		log_panel.visible = false
		contextennemi.visible = false
		log_panel.text = text
		contextennemi.text = ""
		
	else:
		contextennemi.text = text
		contextennemi.visible = true
		log_panel.text = ""
		log_panel.visible = false
		
func hide_Panel_action():
	log_panel.visible = false
	contextennemi.visible = false

# -------------------------------------------------------------------------
func set_MenuPerso(heroes:Array[CharacterData]):
	if MenuPerso == null:
		MenuPerso = $"../MenuPerso"
	MenuPerso.characters = heroes

func showMenuPerso():
	MenuPerso.showMenu() 

func updateRound(roundnumber:int):
	RoundNumbersHolder.text = "Round "+ str(roundnumber)
	var tween      := create_tween() as Tween
	var theScale      = Vector2(1,1)

	var big_size    = Vector2(theScale .x * 1.1, theScale .y * 1.3)
	tween.tween_property(RoundNumbersHolder, "scale", big_size,  0.2)
	tween.tween_property(RoundNumbersHolder, "scale", theScale  , 0.2)


# ════════════════════════════════════════════════════════════════════
#  SAC D'ÉQUIPE EN COMBAT
# ════════════════════════════════════════════════════════════════════

func _setup_bag(gm: GameManager) -> void:
	var layer := get_node_or_null("CanvasLayer") as CanvasLayer
	if layer == null:
		return

	inventory_panel = DoorInventory.create_panel(bag_rect, bag_bg)
	# Réglages avant l'entrée dans l'arbre : c'est _ready() du panneau qui
	# construit la grille, il lit ces valeurs à ce moment-là.
	inventory_panel.cell_size = Vector2(72, 72)
	inventory_panel.cell_separation = 4
	inventory_panel.potions_usable = false
	inventory_panel.equip_enabled = false
	inventory_panel.z_index = 9
	inventory_panel.visible = false
	layer.add_child(inventory_panel)

	# La scène de combat a déjà un bouton posé au-dessus de la carte, câblé
	# à rien : on s'en sert. S'il manque (autre scène de boss), on en crée un.
	bag_toggle = get_node_or_null("CanvasLayer/ContourMap/ButtonMap") as Button
	if bag_toggle == null:
		bag_toggle = Button.new()
		bag_toggle.name = "ToggleMapInventory"
		bag_toggle.flat = true
		bag_toggle.focus_mode = Control.FOCUS_NONE
		bag_toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		bag_toggle.z_index = 10
		bag_toggle.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bag_toggle.offset_left = bag_rect.position.x + bag_rect.size.x - 104.0
		bag_toggle.offset_top = bag_rect.position.y - 62.0
		bag_toggle.offset_right = bag_toggle.offset_left + 104.0
		bag_toggle.offset_bottom = bag_toggle.offset_top + 104.0
		layer.add_child(bag_toggle)

		var icon := Sprite2D.new()
		icon.name = "IconBag"
		icon.position = Vector2(52, 52)
		icon.scale = Vector2(0.35, 0.35)
		icon.texture = bag_icon
		bag_toggle.add_child(icon)

		var icon_map := Sprite2D.new()
		icon_map.name = "IconMap"
		icon_map.visible = false
		icon_map.position = Vector2(52, 52)
		icon_map.scale = Vector2(0.35, 0.35)
		icon_map.texture = bag_map_icon
		bag_toggle.add_child(icon_map)

	# Le bouton de la scène est enfant du cadre de la carte (repère réduit à
	# 0.75) : 96 unités locales ≈ 72 px à l'écran.
	var spacing := 96.0 if bag_toggle.get_parent() is TextureRect else 88.0
	map_bag_buttons = MapBagButtons.split(bag_toggle, null, bag_icon, spacing)
	map_bag_buttons.map.pressed.connect(_show_inventory.bind(false))
	map_bag_buttons.bag.pressed.connect(_show_inventory.bind(true))
	# Au-dessus du panneau du sac (z 9) : sinon, sac ouvert, les boutons
	# passaient dessous. Le bouton fiche personnage voisin suit le même rang.
	MapBagButtons.raise(map_bag_buttons, 10)
	# L'icône carte du combat porte son cadre dans l'image ; celle du sac
	# non. Cadre ajouté à la taille de l'icône carte (256 px × 0.38).
	MapBagButtons.ensure_box(map_bag_buttons.bag, 97.0)
	var chara_info := get_node_or_null("CanvasLayer/ContourMap/ButtonCharainfo") as Button
	if chara_info != null:
		chara_info.z_as_relative = false
		chara_info.z_index = 10
		map_bag_buttons["chara"] = chara_info
		# Fiche personnage (overmenu.gd l'affiche) : le sac se referme.
		chara_info.button_down.connect(func():
			showing_inventory = false
			_apply_map_inventory_view())

	# Cartes d'affinité : consultables en combat, jouables seulement au camp.
	var cards_area: Control = inventory_panel if inventory_panel != null 			else get_node_or_null("CanvasLayer/SubViewportContainer") as Control
	card_hand = CardHand.install_hud(layer,
			[map_bag_buttons.map, map_bag_buttons.bag, map_bag_buttons.get("chara")], cards_area)
	map_bag_buttons.map.pressed.connect(card_hand.close)
	map_bag_buttons.bag.pressed.connect(card_hand.close)
	if map_bag_buttons.get("chara") != null:
		map_bag_buttons.chara.button_down.connect(card_hand.close)
	# Carte, sac et cartes : même rectangle (celui du sac), même cadre. Le
	# cadre de la scène (ContourMap) devient transparent, ses boutons restent.
	HudFrame.install(layer, bag_rect,
			get_node_or_null("CanvasLayer/SubViewportContainer") as Control,
			get_node_or_null("CanvasLayer/ContourMap") as CanvasItem, inventory_panel,
			[map_bag_buttons.map, map_bag_buttons.bag, map_bag_buttons.get("chara"),
			card_hand.toggle_button])

	# Un objet ramassé pendant que le sac est ouvert doit s'y afficher.
	if gm != null and not gm.inventory_changed.is_connected(_on_bag_inventory_changed):
		gm.inventory_changed.connect(_on_bag_inventory_changed)

	_apply_map_inventory_view()


func _show_inventory(on: bool) -> void:
	showing_inventory = on
	_apply_map_inventory_view()


func _on_toggle_map_inventory() -> void:
	showing_inventory = not showing_inventory
	_apply_map_inventory_view()


func _on_bag_inventory_changed(_item = null) -> void:
	if showing_inventory and inventory_panel != null:
		var gm := get_tree().root.get_node_or_null("GameManager") as GameManager
		if gm != null:
			inventory_panel.refresh(gm.inventory)


## La carte et le sac occupent le même coin. On masque la vue de la carte
## mais PAS son cadre : le bouton de bascule est posé dessus, le cacher
## rendrait le retour impossible.
func _apply_map_inventory_view() -> void:
	var map_view := get_node_or_null("CanvasLayer/SubViewportContainer") as Control
	if map_view:
		map_view.visible = not showing_inventory
	if inventory_panel:
		inventory_panel.visible = showing_inventory
		if showing_inventory:
			var gm := get_tree().root.get_node_or_null("GameManager") as GameManager
			if gm != null:
				inventory_panel.refresh(gm.inventory)
	# Trois vues dans le même coin : carte, sac, fiche personnage.
	var overmenu := get_node_or_null("CanvasLayer/overmenu") as CanvasItem
	if overmenu != null and showing_inventory:
		overmenu.visible = false
	MapBagButtons.set_active(map_bag_buttons, showing_inventory)
	var chara_btn := map_bag_buttons.get("chara") as CanvasItem
	if chara_btn != null and overmenu != null:
		# Le bouton de la vue affichée est allumé, les autres grisés.
		var chara_shown := overmenu.visible and not showing_inventory
		chara_btn.modulate = MapBagButtons.ACTIVE if chara_shown else MapBagButtons.INACTIVE
		if chara_shown:
			(map_bag_buttons.map as CanvasItem).modulate = MapBagButtons.INACTIVE
