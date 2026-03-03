extends Control
class_name UI_combat

@onready var skill_buttons = [
	$CanvasLayer/ActionPanel/Action1,
	$CanvasLayer/ActionPanel/Action2,
	$CanvasLayer/ActionPanel/Action3,
	$CanvasLayer/ActionPanel/Action4,
	$CanvasLayer/ActionPanel/Action5
]

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


func _ready():
	var current_character = combat_manager.get_current_character()
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	await get_tree().process_frame
	#call_deferred("update_ui_for_current_character", current_character)
	
	
	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource, viewport)

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
	if !MenuPerso:
		MenuPerso = $"../MenuPerso"
	MenuPerso.select_character(character.characterData)
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
			if character.characterData.current_horniness>=100 :
				button.disabled = true
			if character.characterData.stun ==true:
				button.disabled = true
				print("Chara is stun !!!")
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
	MenuPerso.showMenu() 
