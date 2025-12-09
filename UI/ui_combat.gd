extends Control
class_name UI_combat

@onready var skill_buttons = [
	$ActionPanel/Action1,
	$ActionPanel/Action2,
	$ActionPanel/Action3,
	$ActionPanel/Action4,
	$ActionPanel/Action5
]

@onready var Charaname_panel = $Charaname
@onready var charaPortrait = $charaPortrait
@onready var log_panel = $contexte
@onready var contextennemi= $contextennemi
@onready var labelAction= $LabelAction
@onready var combat_manager = $CombatManager
@onready var turnOrderPanel = $TurnOrderPanel

@onready var AttLabel = $AttLabel
@onready var DefLabel = $DefLabel
@onready var Stamina = $Stamina
@onready var guilt= $Guilt
@onready var horny = $Horny

@onready var charaPortrait2 = $overmenu/charaPortrait2
@onready var Charaname2 = $overmenu/Charaname2
@onready var AttLabel2 = $overmenu/AttLabel2
@onready var DefLabel2 = $overmenu/DefLabel2
@onready var Stamina2 = $overmenu/Stamina2
@onready var guilt2 = $overmenu/Guilt2
@onready var horny2 = $overmenu/Horny2
@onready var skills2 = $overmenu/ActionPanel2.get_children()
@onready var hideSkillsPanel = $EnnemiTurn
@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var donjon_map: Map = $SubViewportContainer/SubViewport/map
@onready var cooldown_bars = [
	$ActionPanel/Action1/CooldownBar,
	$ActionPanel/Action2/CooldownBar,
	$ActionPanel/Action3/CooldownBar,
	$ActionPanel/Action4/CooldownBar,
	$ActionPanel/Action5/CooldownBar
]

@onready var Items = $Items
@onready var MenuPerso:InventoryUI = $"../MenuPerso"
@onready var charaPortraitButton = $charaPortrait/charaPortraitButton


func _ready():
	var current_character = combat_manager.get_current_character()
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager

	call_deferred("update_ui_for_current_character", current_character)
	await get_tree().process_frame
	
	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource, viewport)

	charaPortraitButton.connect("button_down", showMenuPerso)
	MenuPerso.inventory_items = gm.inventory
	MenuPerso.update_inventory_ui()
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

	for c in queue:
		var portraitChara = TextureRect.new()
		portraitChara.texture = c.characterData.explorationPortrait  # CHANGED
		portraitChara.custom_minimum_size = Vector2(64, 64)
		portraitChara.expand_mode= TextureRect.EXPAND_IGNORE_SIZE
		portraitChara.stretch_mode= TextureRect.STRETCH_SCALE
		portraitChara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		turnOrderPanel.add_child(portraitChara)


# -------------------------------------------------------------------------
# ➤ MET À JOUR L’UI DU PERSONNAGE ACTIF
# -------------------------------------------------------------------------
func update_ui_for_current_character(character: Character):

	hideSkillsPanel.visible = !character.characterData.is_player_controlled # CHANGED

	update_equipment_icons(character)

	Charaname_panel.text = character.characterData.Charaname
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

			var index = i
			button.pressed.connect(func(): combat_manager.use_skill(index))

			update_cooldown_bar(cooldown_bars[i], skill)

		else:
			button.text = "—"
			button.disabled = true

	# --- CHANGED (toutes les stats viennent maintenant de characterData)
	AttLabel.text = "Attack: %d" % character.characterData.attack
	DefLabel.text = "Defense: %d" % character.characterData.defense
	Stamina.text = "Stamina: %d / %d" % [
		character.characterData.current_stamina,
		character.characterData.max_stamina
	]
	guilt.text = "Guilt: %d / %d" % [
		character.characterData.current_stress,
		character.characterData.max_stress
	]
	horny.text = "Horny: %d / %d" % [
		character.characterData.current_horniness,
		character.characterData.max_horniness
	]


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

	Charaname2.text = character.characterData.Charaname
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
	guilt2.text = "Guilt: %d / %d" % [
		character.characterData.current_stress,
		character.characterData.max_stress
	]
	horny2.text = "Horny: %d / %d" % [
		character.characterData.current_horniness,
		character.characterData.max_horniness
	]


# -------------------------------------------------------------------------
# ➤ LOG
# -------------------------------------------------------------------------
func log(text):
	var cc = combat_manager.current_character
	if cc.characterData.is_player_controlled:
		log_panel.visible = true
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
	MenuPerso.visible = true
