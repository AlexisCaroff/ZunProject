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


func _ready():
	var current_character = combat_manager.get_current_character()
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	await get_tree().process_frame
	#call_deferred("update_ui_for_current_character", current_character)


	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource, viewport)

	_setup_bag(gm)
	charaPortraitButton.connect("button_down", showMenuPerso)
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
	charaPortrait.texture = character.characterData.explorationPortrait

	# Clear anciens signaux
	for button in skill_buttons:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var skill = character.get_skill(i)
		button.label =labelAction

		if skill != null:
			button.Actiontext = skill.descriptionName + "\n" + skill.description
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
	
	AttLabel.text = "Attack: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.attack, chara.base_attack, (chara.attack - chara.base_attack)]
	DefLabel.text = "Defense: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.defense, chara.base_defense, (chara.defense - chara.base_defense)]
	WillPower.text = "Willpower: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.willpower, chara.base_willpower, (chara.willpower - chara.base_willpower)]
	
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

	for i in range(max_cd):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(5, 5)
		rect.color = Color(0.2,0.2,0.2)
		if i <= charged:
			rect.color = Color(0.64,0.56,0.36)
		container.add_child(rect)


# -------------------------------------------------------------------------
# ➤ UI D’UN PERSONNAGE SURVOLÉ
# -------------------------------------------------------------------------
func update_ui_for_overed_character(character: Character):

	Charaname2.text = character.characterData.Name
	charaPortrait2.texture = character.characterData.explorationPortrait

	for button in skills2:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	for i in range(skills2.size()):
		var button = skills2[i]
		var skill = character.get_skill(i)

		if skill != null:
			button.Actiontext = skill.descriptionName + "\n" + skill.description
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

	bag_toggle.tooltip_text = "Carte / sac d'équipe"
	if not bag_toggle.pressed.is_connected(_on_toggle_map_inventory):
		bag_toggle.pressed.connect(_on_toggle_map_inventory)

	# Un objet ramassé pendant que le sac est ouvert doit s'y afficher.
	if gm != null and not gm.inventory_changed.is_connected(_on_bag_inventory_changed):
		gm.inventory_changed.connect(_on_bag_inventory_changed)

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
	if bag_toggle:
		# L'icône annonce la vue vers laquelle on basculera. Le bouton déjà
		# présent dans la scène de combat n'a qu'une icône de carte : dans ce
		# cas on la laisse allumée, sinon le bouton deviendrait vide.
		var bag := bag_toggle.get_node_or_null("IconBag") as CanvasItem
		var mp := bag_toggle.get_node_or_null("IconMap") as CanvasItem
		if bag != null and mp != null:
			bag.visible = not showing_inventory
			mp.visible = showing_inventory
		elif bag != null:
			bag.visible = true
		elif mp != null:
			mp.visible = true
