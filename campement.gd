extends Node2D
class_name Campement

@onready var background=$ZunBg
@onready var portraitCharaselect = $charaPortrait
@export var chara_Camp_scene : PackedScene
@onready var action_panel = $ActionPanel

var selected_chara: CharaCamp = null

@onready var slots =$HeroPosition .get_children() # conteneur des ExploPositionSlot
var characters: Array[CharaCamp] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null

var move_mode: bool = false
@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var donjon_map: Map = $SubViewportContainer/SubViewport/map
var DoorNumber:int =0
var gm : GameManager

func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	load_characters_from_gamestat()
	selected_chara = characters[0]
	portraitCharaselect.texture = characters[0].initiative_icon
	
	if donjon_map:
		donjon_map.curentposition=donjon_map.positions[gm.current_room_Ressource.position_on_map]
		focus_on_room(donjon_map.curentposition)
	show_chara_actions(selected_chara)

func load_characters_from_gamestat():
	characters.clear()
	for i in GameState.saved_heroes_data.size():
		var hero_data = GameState.saved_heroes_data[i]
		var chara = chara_Camp_scene.instantiate()
		chara.load_from_dict(hero_data)
		add_child(chara)
		characters.append(chara)

		# Placement dans le slot correspondant
		var slot_index = i-1
		move_character_to_slot(chara, slots[slot_index])
		
		
		
func move_character_to_slot(chara: Node, slot: Node):
	if chara.get_parent():
		chara.get_parent().remove_child(chara)
	slot.add_child(chara)
	chara.global_position = slot.global_position
	GameState.update_hero_stat(chara.Charaname, "position", chara.current_position)

func use_camp_skill(skill: CampSkill, user: CharaCamp, targets: Array[CharaCamp]):
	if skill.cost > user.camp_points:
		#can't feedback
		return
	user.camp_points -= skill.cost
	skill.use(user, targets)
	#update_ui()
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

	for i in range(chara.camp_skill_resources.size()):
		var skill: CampSkill = chara.camp_skill_resources[i]

		# Création d'un bouton d'action
		var btn := Button.new()
		btn.text = skill.name
		btn.name = "Action" + str(i + 1)
		btn.tooltip_text = skill.description
		if skill.icon:
			btn.icon = skill.icon

		# Connexion : on bind skill et chara comme arguments (évite les problèmes de closure)
		# connect prend un Callable et une Array d'arguments
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
	match skill.target_type:
		CampSkill.TargetType.SELF:
			skill.use(user, [user])
		CampSkill.TargetType.ALLY:
			# ouvrir une UI de sélection de cible (à implémenter) ; pour l'instant on choisit le premier allié valide
			var target: CharaCamp = null
			for c in characters:
				if c is CharaCamp and c != user:
					target = c
					break
			if target:
				skill.use(user, [target])
		CampSkill.TargetType.ALL_ALLIES:
			var targets: Array[CharaCamp] = []
			for c in characters:
				if c is CharaCamp:
					targets.append(c)
			skill.use(user, targets)

	# mettre à jour l'affichage après application
	for c in characters:
		if c is CharaCamp:
			c.update_display()
func focus_on_room(room: Node2D):
	var vp_size: Vector2 = viewport.size
	var target_pos = room.position
	var tween = create_tween()
	tween.tween_property(donjon_map.camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
