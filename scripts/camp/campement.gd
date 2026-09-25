extends Node2D
class_name Campement

@onready var background=$ZunBg
@onready var portraitCharaselect = $charaPortrait
@export var chara_Camp_scene : PackedScene
@onready var action_panel = $ActionPanel
@onready var AttLabel = $AttLabel2
@onready var DefLabel = $DefLabel2
@onready var WillPowerLabel = $WillPower2
@onready var Stamina = $Stamina2
@onready var StaminaBar: ProgressBar = $StaminaProgressBar
@onready var guilt= $Guilt2
@onready var guiltBar: ProgressBar= $GuiltProgressBar
@onready var horny = $Horny2
@onready var hornyBar: ProgressBar = $LustProgressBar
@onready var CharacterName = $Charaname
## Décalage des icônes de buff posées derrière le libellé « Buff: ».
@export var buffs_icons_nudge: Vector2 = Vector2.ZERO
var buff_row: BuffRow = null
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

var DoorNumber:int =0
var gm : GameManager
var skillused : CampSkill =null
var campPoints: int = 10
var campPointLabel 
@export var codeActionButton = "res://scripts/camp/campActionButton.gd"
var skillcampmode : bool = true
@onready var TheTente:tente =$Tente
@onready var mapButton =$MapButton
@onready var QuitmapButton = $QuittMapButton
@onready var contourMap=$ContourMap
@onready var MenuPerso = $MenuPerso
## Les deux cases d'équipement sous le portrait (UI/UICombatItem.gd).
@onready var item_slots: Array = [$Items/Item1, $Items/Item2]
@onready var MenuPersoButton=$charaPortrait2/charaPortraitButton
@onready var CharactersAffinity= [
	$CharactersPanelAffinity/chara1,
	$CharactersPanelAffinity/chara2,
	$CharactersPanelAffinity/chara3
]

func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	MenuPerso.characters = gm.characters
	load_characters_from_gamestat()
	# Comme en exploration : les icônes se collent derrière le libellé
	# « Buff: » de la scène.
	var buffs_anchor := get_node_or_null("Buffs") as Control
	if buffs_anchor != null:
		buff_row = BuffRow.create(self,
				BuffRow.position_after(buffs_anchor) + buffs_icons_nudge,
				buffs_anchor, false, 20)
	selected_chara = characters[0]
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
# -------Heal chara----------------

	for chara in characters:
		chara.characterData.current_stamina = min(chara.characterData.max_stamina, chara.characterData.current_stamina + 10)
		chara.animate_heal(10, chara)
		chara.update_display()
#--------------------------------------
	
	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource,viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	
	changeSelectedCharacter(selected_chara)
	campPointLabel = $Box2/CampPoint
	campPointLabel.text= str(campPoints)
	
	mapButton.connect("button_down",toggleshowMap)
	QuitmapButton.connect("button_down",toggleshowMap)
	MenuPersoButton.connect("button_down",showMenuPerso)
	if MenuPerso.has_signal("change_in_equipment"):
		MenuPerso.change_in_equipment.connect(_on_character_equipment_changed)
	
#func startLovescene():
	
	
func load_characters_from_gamestat():
	characters.clear()
	for i in gm.characters.size():
		var hero_data = gm.characters[i]
		var chara : CharaCamp = chara_Camp_scene.instantiate()
		chara.load_camp_chara(hero_data)
		add_child(chara)
		
		chara.camp= self

		# Placement dans le slot correspondant
		var slot_index = hero_data.Chara_position
		chara.campposition=slots[slot_index]
		chara.set_UI(slots[slot_index].get_ui())
		characters.append(chara)
		move_character_to_slot(chara, slots[slot_index])
		
		
		
func move_character_to_slot(chara: Node, slot: Node):
	if chara.get_parent():
		chara.get_parent().remove_child(chara)
	slot.add_child(chara)
	chara.global_position = slot.global_position
	chara.campposition = slot
	slot.occupant=chara
	

func changeSelectedCharacter(occupant:CharaCamp):
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	show_chara_actions(occupant)
	updateUICharacter(occupant.characterData)
	occupant.animate_selected()
	
## Redessine la ligne des buffs ; appelé aussi par CharaCamp.add_buff quand
## une action de camp en ajoute un au personnage affiché.
func refresh_buffs(character: CharacterData) -> void:
	if buff_row != null:
		buff_row.show_for(character)


## Même remplissage qu'en exploration (exploration_manager.gd).
func update_equipment_icons(character: CharacterData) -> void:
	for slot in item_slots:
		slot.remove_item()
	for i in range(min(character.equipped_items.size(), item_slots.size())):
		item_slots[i].assigne_item(character.equipped_items[i])


## Équipement modifié depuis le menu personnage : on redessine la fiche du
## héros affiché (les stats bougent avec l'objet).
func _on_character_equipment_changed(_chara: CharacterData) -> void:
	if selected_chara != null:
		updateUICharacter(selected_chara.characterData)


## Appelé par les portraits d'affinité du panneau du haut
## (CharaIventoryUI.gd) : sélectionne le héros correspondant dans le camp.
func select_character(chara: CharacterData) -> void:
	for c in characters:
		if c.characterData == chara:
			changeSelectedCharacter(c)
			return


func updateUICharacter(character:CharacterData):
	portraitCharaselect.texture = character.explorationPortrait
	CharacterName.text = character.Name
	# Même présentation qu'en exploration : l'icône dit la stat, le libellé
	# ne porte que la valeur.
	AttLabel.text = " %d" % character.attack
	DefLabel.text = " %d" % character.defense
	WillPowerLabel.text = " %d" % character.willpower
	Stamina.text = "%d / %d" % [character.current_stamina, character.max_stamina]
	StaminaBar.max_value = character.max_stamina
	StaminaBar.value=character.current_stamina
	guilt.text = "%d / %d" % [character.current_stress, character.max_stress]
	guiltBar.max_value=character.max_stress
	guiltBar.value=character.current_stress
	horny.text = "%d / %d" % [character.current_horniness, character.max_horniness]
	hornyBar.max_value = character.max_horniness
	hornyBar.value =character.current_horniness
	refresh_buffs(character)
	update_equipment_icons(character)
	
	var other_members : Array = []
	for c in characters:
		if c.characterData != character:
			other_members.append(c)
	for i in range(CharactersAffinity.size()):
		var slot = CharactersAffinity[i]

		if i < other_members.size():
			var target = other_members[i]
			
			# Récupération de la RichTextLabel
			var rtl : RichTextLabel = slot.get_node("Textaffinity")
			rtl.bbcode_enabled = true
			
			
			# Affinité (valeur)
			var value := 0
			if character.affinity.has(target.characterData.Charaname):
				value = character.affinity[target.characterData.Charaname]
			slot.set_chara(target.characterData, value)
		

			
			rtl.text = target.characterData.Name

			slot.visible = true

		else:
			slot.visible = false
	
	
	
	selected_chara.update_display()
	MenuPerso.select_character(MenuPerso.selected_character)
	
func After_camp_skill(skill: CampSkill):
	campPoints -= skill.cost
	
	campPointLabel.text= str(campPoints)
	for c in characters:
				if c is CharaCamp:
					c.set_targetable(false)
					c.update_display()
	skill.used =true
	skillused=null
	exitButton.visible = false
	
	
	
func noCharacterSelected():
	return
		
		
func clear_container(container: Node) -> void:
	for child in container.get_children():
		# queue_free() est préférable à remove_child + free pour éviter les dépendances
		if is_instance_valid(child):
			child.queue_free()
			
func show_chara_actions(thechara: CharaCamp):
	var chara = thechara.characterData 
	selected_chara = thechara
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
	# vide les panels
	clear_container(action_panel)

	# sécurité : pas de skills -> rien à faire
	if not chara or chara.camp_skill_resources.is_empty():
		return

	# charger ton script de bouton custom
	var action_button_script = load(codeActionButton )

	for i in range(chara.camp_skill_resources.size()):
		var skill: CampSkill = thechara.camp_skills[i]

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
		# Même bouton qu'en combat : 90 px, icône étirée au bouton, contour
		# du shader prêt à s'allumer.
		btn.custom_minimum_size= Vector2(90,90)
		btn.size=Vector2(90,90)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var mat := ShaderMaterial.new()
		mat.shader = load("res://characters/character_outline.gdshader")
		mat.set_shader_parameter("enabled", false)
		mat.set_shader_parameter("outline_direction", Vector2.ZERO)
		btn.material = mat
		btn.Actiontext = skill.name
		if skill.cost>campPoints:
			btn.disabled=true
		if skill.used && not skill.name== "Dialogue":
			btn.disabled=true
		btn.pressed.connect(Callable(self, "_on_camp_skill_pressed").bindv([skill, thechara]))

		action_panel.add_child(btn)

		
		
		
## Vrai si ce camp skill mene a une scene d'amour : c'est le seul cas ou
## l'attirance filtre les cibles.
func _skill_is_romantic(skill: CampSkill) -> bool:
	if skill == null:
		return false
	for effect in skill.effects:
		if effect is CampLoveEffect:
			return true
	return false


func _on_camp_skill_pressed(skill: CampSkill, user: CharaCamp) -> void:
	# Exemple d'utilisation simple selon le target_type
	
	if !skillcampmode:
		return
	if skill.cost>campPoints:
		return
	if not TheTente.twoInside.is_empty(): 
		TheTente.loved_one_go_out()
	if TheTente.somoneInside != null:
		TheTente.masturbin_go_out()
	skillused= skill
	match skill.target_type:
		CampSkill.TargetType.SELF:
			user.set_targetable(true)
		CampSkill.TargetType.ALLY:
			# ouvrir une UI de sélection de cible (à implémenter) ; pour l'instant on choisit le premier allié valide
			# Un skill romantique ne peut viser que les allies dont l'attirance
			# est reciproque (tiree en debut de partie par TasteRollMenu).
			var romantic := _skill_is_romantic(skill)
			for c in characters:
				if c is CharaCamp and c != user:
					if romantic and not user.characterData.is_compatible_with(c.characterData):
						continue
					c.set_targetable(true)

		CampSkill.TargetType.ALL_ALLIES:
			var targets: Array[CharaCamp] = characters
			skill.use(user, targets)
			print ("use skill on ", )
	exitButton.visible=true
	

func endcamp():
	
	
	
	# Ces lignes appelaient GameState.save_party_from_camp() / save_finished,
	# qui n'ont jamais existé sur GameStat : la sortie du camp plantait.
	# L'état du party vit dans les CharacterData, déjà à jour ici ; la
	# sauvegarde est prise en charge par l'autosave de return_to_exploration().
	if SaveManager.is_busy():
		push_warning("Sauvegarde déjà en cours…")
		return

	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	await get_tree().process_frame

	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	if gm == null or gm.current_room_Ressource == null:
		push_error("GameManager introuvable ou current_room vide")
		return
	if gm.current_room_Ressource.exploration_scene == null:
		push_error("Pas de scene exploration définie pour cette salle")
		return
	# Un seul chargement : l'ancien code appelait _enter_scene_in_current_room()
	# ET return_to_exploration(), ce qui instanciait la salle deux fois.
	gm.return_to_exploration()
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

func _on_button_button_down() -> void:

	gm.return_to_exploration()
func toggleshowMap():
	var subviewport=$SubViewportContainer
	subviewport.visible= !subviewport.visible
	QuitmapButton.visible = !QuitmapButton.visible
	contourMap.visible= !contourMap.visible
func showMenuPerso():
	MenuPerso.visible=true
