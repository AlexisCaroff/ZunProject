extends Control

@onready var skill_buttons = [
	$ActionPanel/Action1,
	$ActionPanel/Action2,
	$ActionPanel/Action3,
	$ActionPanel/Action4
]
@onready var Charaname_panel = $Charaname
@onready var charaPortrait= $charaPortrait
@onready var log_panel = $contexte
@onready var combat_manager = $CombatManager 
@onready var turnOrderPanel = $TurnOrderPanel
@onready var cooldownLabel = [
	$ActionPanel/Action1/cooldownA1, 
	$ActionPanel/Action2/cooldownA2,
	$ActionPanel/Action3/cooldownA3,
	$ActionPanel/Action4/cooldownA4
]

func _ready():
	var current_character = combat_manager.get_current_character()
	print(turnOrderPanel)
	call_deferred("update_ui_for_current_character", current_character)
func update_turn_queue_ui(queue: Array[Character]):
	if turnOrderPanel == null:
		turnOrderPanel=$TurnOrderPanel
	for child in turnOrderPanel.get_children():
		child.queue_free()
	
	for c in queue:
		var portraitChara = TextureRect.new()
		portraitChara.texture = c.initiative_icon
		portraitChara.custom_minimum_size = Vector2(64, 64)  # optionnel, fixe une taille
		portraitChara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		turnOrderPanel.add_child(portraitChara)
		
	
func update_ui_for_current_character(character: Character):
	if skill_buttons == null:
		push_error("skill_buttons est null pour %s" % character.Charaname)
		return
	character.animate_start_Turn()
	character.sprite.modulate = Color(1.8, 1.8, 1.8)
	Charaname_panel.text = character.Charaname
	charaPortrait.texture=character.initiative_icon
	# Déconnexion de tous les anciens signaux pour éviter les doublons
	for button in skill_buttons:
		for conn in button.pressed.get_connections():
			button.pressed.disconnect(conn["callable"])

	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var skill = character.get_skill(i)
		var cooldownlabel = cooldownLabel[i]
		if skill != null:
			button.text = skill.name
			button.disabled = !skill.can_use()
			button.icon = skill.icon
			if skill.current_cooldown > 0:
				cooldownlabel.text = "%d" % [skill.current_cooldown]
			else :
				cooldownlabel.text = " "

			var index = i  # capture locale de la bonne valeur
			button.pressed.connect(
				func(): combat_manager.use_skill(index)
			)
		else:
			button.text = "—"
			button.disabled = true

func log(text):
	if log_panel==null:
		log_panel=$contexte
		log_panel.text =  text
	else:
		log_panel.text =  text
