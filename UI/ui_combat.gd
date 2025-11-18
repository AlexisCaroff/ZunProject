extends Control

@onready var skill_buttons = [
	$ActionPanel/Action1,
	$ActionPanel/Action2,
	$ActionPanel/Action3,
	$ActionPanel/Action4,
	$ActionPanel/Action5

]
@onready var Charaname_panel = $Charaname
@onready var charaPortrait= $charaPortrait
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
@onready var Charanpnale2 = $overmenu/charaPortrait2
@onready var Charaname2 = $overmenu/Charaname2
@onready var AttLabel2 = $overmenu/AttLabel2
@onready var DefLabel2 = $overmenu/DefLabel2
@onready var Stamina2 = $overmenu/Stamina2
@onready var guilt2= $overmenu/Guilt2
@onready var horny2 = $overmenu/Horny2
@onready var skills2 = $overmenu/ActionPanel2.get_children()
@onready var hideSkillsPanel =$EnnemiTurn
@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var donjon_map: Map = $SubViewportContainer/SubViewport/map
@onready var cooldown_bars = [
	$ActionPanel/Action1/CooldownBar,
	$ActionPanel/Action2/CooldownBar,
	$ActionPanel/Action3/CooldownBar,
	$ActionPanel/Action4/CooldownBar,
	$ActionPanel/Action5/CooldownBar
]
@onready var thebutton =$Button
func _ready():
	#thebutton.visible=false
	var current_character = combat_manager.get_current_character()
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager

	call_deferred("update_ui_for_current_character", current_character)
	await get_tree().process_frame  # attendre que la frame d'instanciation soit finie
	
	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource, viewport)
	


func update_turn_queue_ui(queue: Array[Character]):
	if turnOrderPanel == null:
		turnOrderPanel=$TurnOrderPanel
	for child in turnOrderPanel.get_children():
		child.queue_free()
	
	for c in queue:
		var portraitChara = TextureRect.new()
		portraitChara.texture = c.explorationPortrait
		portraitChara.custom_minimum_size = Vector2(64, 64)  # optionnel, fixe une taille
		portraitChara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portraitChara.expand_mode= TextureRect.EXPAND_FIT_WIDTH
		turnOrderPanel.add_child(portraitChara)
		

func update_ui_for_current_character(character: Character):
	if character.is_player_controlled:
		hideSkillsPanel.visible=false
	else:
		hideSkillsPanel.visible=true
		
	if skill_buttons == null:
		#push_error("skill_buttons est null pour %s" % character.Charaname)
		skill_buttons = [
		$ActionPanel/Action1,
		$ActionPanel/Action2,
		$ActionPanel/Action3,
		$ActionPanel/Action4,
		$ActionPanel/Action5
		]
		cooldown_bars = [
		$ActionPanel/Action1/CooldownBar,
		$ActionPanel/Action2/CooldownBar,
		$ActionPanel/Action3/CooldownBar,
		$ActionPanel/Action4/CooldownBar,
		$ActionPanel/Action5/CooldownBar
		]
		return

	
	Charaname_panel.text = character.Charaname
	charaPortrait.texture=character.explorationPortrait
	# Déconnexion de tous les anciens signaux pour éviter les doublons
	for button in skill_buttons:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])
		button.label=labelAction
		

	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var skill = character.get_skill(i)
		
		
		if skill != null:
			skill_buttons[i].Actiontext = skill.descriptionName + "\n" + skill.description
			button.disabled = !skill.can_use()
			button.icon = skill.icon
			

			var index = i  # capture locale de la bonne valeur
			button.pressed.connect(
				func(): combat_manager.use_skill(index)
			)
			update_cooldown_bar(cooldown_bars[i],skill)
		else:
			button.text = "—"
			button.disabled = true
		AttLabel.text = "Attaque: %d" % [character.attack]
		DefLabel.text = "Defence: %d" % [character.defense]
		Stamina.text = "Stamina: %d / %d" % [character.current_stamina, character.max_stamina]
		guilt.text = "Guilt: %d / %d" % [character.current_stress, character.max_stress]
		horny.text = "Horny: %d / %d" % [character.current_horniness, character.max_horniness]


func update_cooldown_bar(container: HBoxContainer, skill):
	
	for child in container.get_children():
		child.queue_free()
	
	if skill == null:
		return

	var max_cd = skill.cooldown  # nombre de tours total
	var current_cd = skill.current_cooldown  # combien il en reste

	# Sécurité : éviter erreurs si pas défini
	if max_cd <= 0:
		return
	var charged : int = max_cd-current_cd
	for i in range(max_cd):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(5, 5)
		rect.color = Color(0.2,0.2,0.2)

		# Si ce tour est déjà "récupéré", on le met orange
		if i <= charged :
			rect.color = Color(0.64,0.56,0.36)
		container.add_child(rect)
func update_ui_for_overed_character(character: Character):
	
	if skills2 == null:
		#push_error("skill_buttons est null pour %s" % character.Charaname)
		skills2 = [
			$overmenu/ActionPanel2.get_children()
		]
		return

	
	Charaname2.text = character.Charaname
	charaPortrait2.texture=character.explorationPortrait
	# Déconnexion de tous les anciens signaux pour éviter les doublons
	for button in skills2:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	for i in range(skills2.size()):
		var button = skills2[i]
		var skill = character.get_skill(i)
		
		
		if skill != null:
			skills2[i].Actiontext = skill.descriptionName + "\n" + skill.description
			button.icon = skill.icon
		
			
		else:
			button.text = "—"
			button.disabled = true
		AttLabel2.text = "Attaque: %d" % [character.attack]
		DefLabel2.text = "Defence: %d" % [character.defense]
		Stamina2.text = "Stamina: %d / %d" % [character.current_stamina, character.max_stamina]
		guilt2.text = "Guilt: %d / %d" % [character.current_stress, character.max_stress]
		horny2.text = "Horny: %d / %d" % [character.current_horniness, character.max_horniness]
		

func update_cooldown(character:Character):
	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var dot = character.dotsActions[i-1]
		var skill = character.get_skill(i)
		
		#print ("update skill"+skill.name+str(skill.current_cooldown))
		if skill != null:
			skill_buttons[i].Actiontext = skill.descriptionName + "\n" + skill.description
			button.disabled = !skill.can_use()
			button.icon = skill.icon
			

		
	

			var index = i  # capture locale de la bonne valeur
			button.pressed.connect(
				func(): combat_manager.use_skill(index)
			)
		else:
			button.text = "—"
			button.disabled = true


func log(text):
	if combat_manager == null:
		combat_manager = $CombatManager 
	else:
		if combat_manager.current_character.is_player_controlled:
			if log_panel==null:
				log_panel=$contexte
				log_panel.text =  text
			else:
				log_panel.text =  text
			contextennemi.text = ""
			var fenetre = contextennemi.get_child(0)
			fenetre.visible = false
			var fenetre2 = log_panel.get_child(0)
			if text != "":
				fenetre2.visible = true
			else:
				fenetre2.visible = false
		else :
			if contextennemi==null:
				contextennemi=$contextennemi
				contextennemi.text =  text
			else:
				contextennemi.text =  text

			var fenetre = contextennemi.get_child(0)
			if text != "":
				fenetre.visible = true
			else:
				fenetre.visible = false
			log_panel.text = ""
			var fenetre2 = log_panel.get_child(0)
			fenetre2.visible = false
