extends Node2D
class_name Campement

@onready var background=$ZunBg
@onready var portraitCharaselect = $charaPortrait
@export var chara_Camp_scene : PackedScene
@onready var action_panel = $ActionPanel
@onready var AttLabel = $AttLabel
@onready var DefLabel = $DefLabel
@onready var Stamina = $Stamina
@onready var guilt= $Guilt
@onready var horny = $Horny
@onready var CharacterName = $Charaname
var selected_chara: CharaCamp = null
@onready var exitButton =$ExitButton
@onready var slots =$HeroPosition .get_children() # conteneur des ExploPositionSlot
var characters: Array[CharaCamp] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null

var move_mode: bool = false
@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var donjon_map: Map = $SubViewportContainer/SubViewport/map
@onready var loveimage=$Loveimage
var DoorNumber:int =0
var gm : GameManager
var skillused : CampSkill =null
var campPoints: int = 10
var campPointLabel 
@export var codeActionButton = "res://UI/campActionButton.gd"
var skillcampmode : bool = true

func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	load_characters_from_gamestat()
	selected_chara = characters[0]

	donjon_map.curentposition = donjon_map.positions[gm.current_room_Ressource.position_on_map]
	if donjon_map:
		focus_on_room(donjon_map.curentposition)
		donjon_map.move_to_position(donjon_map.curentposition)
	
	changeSelectedCharacter(selected_chara)
	campPointLabel = $CampPoint
	campPointLabel.text= str(campPoints)

func load_characters_from_gamestat():
	characters.clear()
	for i in GameState.saved_heroes_data.size():
		var hero_data = GameState.saved_heroes_data[i]
		var chara = chara_Camp_scene.instantiate()
		chara.load_from_dict(hero_data)
		add_child(chara)
		characters.append(chara)
		chara.camp= self

		# Placement dans le slot correspondant
		var slot_index = i-1
	
		move_character_to_slot(chara, slots[slot_index])
		
		
		
func move_character_to_slot(chara: Node, slot: Node):
	if chara.get_parent():
		chara.get_parent().remove_child(chara)
	slot.add_child(chara)
	chara.global_position = slot.global_position
	slot.occupant=chara
	GameState.update_hero_stat(chara.Charaname, "position", chara.current_position)

func changeSelectedCharacter(occupant:CharaCamp):
	show_chara_actions(occupant)
	updateUICharacter(occupant)
	
func updateUICharacter(character:CharaCamp):
	portraitCharaselect.texture = character.initiative_icon
	AttLabel.text = "Attaque: %d" % [character.attack]
	DefLabel.text = "Defence: %d" % [character.defense]
	Stamina.text = "Stamina: %d / %d" % [character.current_stamina, character.max_stamina]
	guilt.text = "Guilt: %d / %d" % [character.current_stress, character.max_stress]
	horny.text = "Horny: %d / %d" % [character.current_horny, character.max_horniness]
		
		
func After_camp_skill(skill: CampSkill):
	campPoints -= skill.cost
	campPointLabel.text= str(campPoints)
	for c in characters:
				if c is CharaCamp:
					c.set_targetable(false)
					c.update_display()
	skillused=null
	exitButton.visible = false
	
func clear_container(container: Node) -> void:
	for child in container.get_children():
		# queue_free() est préférable à remove_child + free pour éviter les dépendances
		if is_instance_valid(child):
			child.queue_free()
			
func show_chara_actions(chara: CharaCamp):
	selected_chara = chara

	# vide les panels
	clear_container(action_panel)

	# sécurité : pas de skills -> rien à faire
	if not chara or chara.camp_skill_resources.is_empty():
		return

	# charger ton script de bouton custom
	var action_button_script = load(codeActionButton )

	for i in range(chara.camp_skill_resources.size()):
		var skill: CampSkill = chara.camp_skill_resources[i]

		# Création d'un bouton d'action avec script custom
		var btn := Button.new()
		btn.set_script(action_button_script)

		# setup de base
		btn.flat=true
		btn.name = "Action" + str(i + 1)
		btn.tooltip_text = skill.description
		if skill.icon:
			btn.icon = skill.icon
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("focus", empty_style)
		btn.Actiontext = skill.name

		btn.pressed.connect(Callable(self, "_on_camp_skill_pressed").bindv([skill, chara]))

		action_panel.add_child(btn)

		# Création d'une ligne de cercles représentant le coût (un HBox par skill)
		var cost_row := HBoxContainer.new()
		for j in range(max(0, skill.cost)):
			var circle := TextureRect.new()
			circle.texture = preload("res://UI/cost_circle.png") # remplace par ton sprite
			circle.custom_minimum_size = Vector2(16, 16)
			cost_row.add_child(circle)
		
		
		
func _on_camp_skill_pressed(skill: CampSkill, user: CharaCamp) -> void:
	# Exemple d'utilisation simple selon le target_type
	if !skillcampmode:
		return
	skillused= skill
	match skill.target_type:
		CampSkill.TargetType.SELF:
			user.set_targetable(true)
		CampSkill.TargetType.ALLY:
			# ouvrir une UI de sélection de cible (à implémenter) ; pour l'instant on choisit le premier allié valide
			for c in characters:
				if c is CharaCamp and c != user:
					c.set_targetable(true)

		CampSkill.TargetType.ALL_ALLIES:
			var targets: Array[CharaCamp] = []
			for c in characters:
				if c is CharaCamp:
					skill.use(user, targets)
	exitButton.visible=true


func focus_on_room(room: Node2D):
	
	var target_pos = room.position
	var tween = create_tween()
	donjon_map.move_to_position(donjon_map.curentposition)
	tween.tween_property(donjon_map.camera, "position", target_pos, 0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_exit_button_button_down() -> void:
	for c in characters:
				if c is CharaCamp:
					c.set_targetable(false)
	skillused=null
	exitButton.visible = false
