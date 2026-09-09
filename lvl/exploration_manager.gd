extends Node2D
class_name ExplorationManager


@export var chara_explo_scene : PackedScene
@onready var Doortext = $Button/Doortext
@onready var DoorButton = $Button
@onready var slots : Array[ExplorationPosition] = []
var characters: Array[Node] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null
var selected_character: CharaExplo = null
var over_chara: CharaExplo
var move_mode: bool = false
## Duree du glissement lors d'un echange de position, alignee sur le 0.5 s
## de Move.gd en combat.
@export var swap_move_time: float = 0.5
## Vrai pendant l'animation d'echange : bloque les clics et le bouton move.
var _swapping: bool = false
@onready var viewport: Viewport = $"../SubViewportContainer/SubViewport"
@onready var donjon_map: Map = $"../SubViewportContainer/SubViewport/map"
@onready var portraits = $"../Portraits".get_children()
@onready var portrait_selector =$"../Portraits/ExploCharaselector"
var DoorNumber:int =0
var gm : GameManager
@onready var campButton: Button = $Campement
@onready var interactable =  $Interactable
@onready var menuPerso = $"../MenuPerso"
@onready var bouton_menuPerso=$"../charaPortrait2/charaPortraitButton"
@onready var NameLabel= $"../Name"
@onready var Stamina=$"../Stamina"
@onready var Horny=$"../Horny"
@onready var Guilt=$"../Guilt"
@onready var Att=$"../AttLabel"
@onready var Def =$"../DefLabel"
@onready var WillPower= $"../WillPower"
@onready var StaminaProgressBar = $"../StaminaProgressBar"
@onready var LustProgressBar =$"../LustProgressBar"
@onready var GuiltProgressBar = $"../GuiltProgressBar"
@onready var Items =$"../Items"
const SELECTOR_TEX = preload("res://UI/UI boxes/UI_combat_selector.png")
var selectorChara : Sprite2D
@onready var campTexture=$Campement/CampFire2
@onready var GoToCampement=$GoToCampement
@onready var DoorTuto=$DoorTuto
@export var showselector = true

# --- Bouton skill exploration (à AJOUTER dans la scène, voir notes en bas)
# Mets le node Button dans ta scène à : ../ExploSkillButton  (ou adapte le chemin)
@onready var explo_skill_button: Button = $"../ExploSkillButton"
@onready var explo_move_button: Button = $"../ExploSkillButtonMove"

# --- État de sélection de cible pour un skill d'exploration
var pending_explo_skill: ExplorationSkill = null
var is_selecting_explo_target: bool = false


func _ready():
	for child in $"../HeroPosition".get_children():
		if child is ExplorationPosition:
			slots.append(child)
	DoorButton.connect("mouse_entered",Door_over)
	DoorButton.connect("mouse_exited",Door_notover)
	DoorTuto.visible=false
	gm = get_tree().root.get_node("GameManager") as GameManager
	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	GoToCampement.visible=false
	GoToCampement.scale=Vector2(0.0,0.0)
	if gm.current_room_Ressource.CanCamp:
		campButton=$Campement
		campButton.visible=true
		#interactable.visible=false
		campButton.connect("button_down",go_to_campement)
		campButton.connect("mouse_entered",campement_over)
		campButton.connect("mouse_exited",campement_notover)
		if gm.current_room_Ressource.CampDone:
			campButton.disabled=true
			campTexture.texture=preload("res://camp_imgs/PROP_campfire_closed.png")
			campTexture.modulate= Color.DARK_GRAY
	else :
		campButton.visible=false
		#interactable.visible=true
	menuPerso.characters=gm.characters
	print ("characters atribués ")
	menuPerso.change_in_equipment.connect(_on_character_equipment_changed)
	#explo_skill_button.connect("button_down",_on_explo_skill_button_pressed)
	load_characters_from_gamestat()
	if gm.combat_just_ended:
		print("💚 Post-combat heal sur l'équipe.")
		for chara in characters:
			chara.characterData.current_stamina = min(
				chara.characterData.max_stamina,
				chara.characterData.current_stamina + 10
			)
			chara.characterData.current_horniness = max(
				0,
				chara.characterData.current_horniness - 5
			)
			chara.animate_heal(10, chara)
			chara.update_display()

		gm.combat_just_ended = false
	else:

		for chara in characters:
			chara.update_display()
	selected_character =characters[0]
	selected_character.animate_selected()
	if gm.current_room_Ressource.exploration_scene_history != null \
			and not gm.current_room_Ressource.exploration_history_played:
		print("find history Scene")
		gm.show_history_scene(gm.current_room_Ressource.exploration_scene_history)
		gm.current_room_Ressource.exploration_history_played = true

	portrait_selector.position = portraits[0].position

	bouton_menuPerso.connect("button_down", showMenuPerso)

	if donjon_map== null:
		donjon_map=$"../SubViewportContainer/SubViewport/map"
	donjon_map.focus_on_room(gm.current_room_Ressource,viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	create_selector_sprite()
	call_deferred("_init_selection")

	load_interactable()

	# --- Bouton du skill d'exploration
	if explo_skill_button != null:
		explo_skill_button.connect("button_down", _on_explo_skill_button_pressed)
		_refresh_explo_skill_button()

	# --- Bouton de deplacement (echange de position entre deux heros)
	if explo_move_button != null:
		explo_move_button.connect("button_down", _on_move_skill_button_pressed)
		_refresh_move_button()

func _init_selection():
	selectCharacter(characters[0])
	_move_selectors_to_selected()

func load_characters_from_gamestat():
	characters.clear()

	for i in gm.characters.size():
		var hero_data = gm.characters[i]
		var chara = chara_explo_scene.instantiate()
		chara.characterData = hero_data
		add_child(chara)
		chara.load_chara()
		characters.append(chara)

		# Placement dans le slot correspondant
		var slot_index = hero_data.Chara_position
		move_character_to_slot(chara, slots[slot_index])

		portraits[slot_index].set_occupant(chara)


## --- Nouvelle logique pour passer à la prochaine room ---
func go_to_next_room():

	if not gm:
		push_error("ExplorationManager: GameManager introuvable dans la scène !")
		return

	if not gm.current_room_Ressource:
		push_error("ExplorationManager: aucune room courante !")
		return

	# Récupère la liste d'IDs des rooms connectées
	var connected_ids: Array = gm.current_room_Ressource.connected_room_ids
	if connected_ids == null or connected_ids.is_empty():
		push_warning("ExplorationManager: aucune salle connectée depuis " + str(gm.current_room_Ressource.room_id))
		return

	# Vérifie DoorNumber
	if DoorNumber < 0 or DoorNumber >= connected_ids.size():
		push_error("ExplorationManager: DoorNumber invalide (%d)" % DoorNumber)
		return

	# Récupère l'ID de la room cible et résoud la ressource via le GameManager
	var next_room_id: String = connected_ids[DoorNumber]
	var next_room: RoomResource = gm.get_room_by_id(next_room_id)
	if next_room == null:
		push_error("ExplorationManager: impossible de trouver la room pour ID '%s'" % next_room_id)
		return

	print("ExplorationManager → Passage à la room suivante :", next_room.room_id)
	gm.enter_room(next_room)

func move_character_to_slot(chara: CharaExplo, slot: ExplorationPosition):

	slot.set_occupant(chara)


func _swap_characters(chara1: CharaExplo, chara2: CharaExplo) -> void:
	var slot1 = chara1.characterData.Chara_position
	var slot2 = chara2.characterData.Chara_position
	var portrait1= chara1.exploPortrait
	var portrait2= chara2.exploPortrait

	_swapping = true

	# Les deux personnages glissent EN MEME TEMPS vers la place de l'autre :
	# assign_character() est une coroutine, on ne l'attend donc pas ici, sinon
	# le second ne partirait qu'une fois le premier arrive.
	slots[slot2].assign_character(chara1, swap_move_time)
	slots[slot1].assign_character(chara2, swap_move_time)

	chara1.characterData.Chara_position = slot2
	chara2.characterData.Chara_position = slot1
	portrait2.set_occupant(chara1)
	portrait1.set_occupant(chara2)

	# Les portraits ont echange leurs occupants : les selecteurs suivent, au
	# meme rythme que les personnages.
	_move_selectors_to_selected(swap_move_time)

	await get_tree().create_timer(swap_move_time).timeout
	_swapping = false
	_refresh_move_button()


func selectCharacter(thechara: CharaExplo):
	# Les clics sont ignores tant que l'echange en cours n'est pas termine.
	if _swapping:
		return

	# --- INTERCEPTION : mode deplacement (bouton ExploSkillButtonMove)
	if move_mode:
		if thechara != null and thechara != selected_character:
			_swap_characters(thechara, selected_character)
		set_move_mode(false)
		return

	# --- INTERCEPTION : mode "choix de cible pour un skill exploration"
	if is_selecting_explo_target and pending_explo_skill != null:
		_apply_explo_skill_to_target(thechara)
		return

	thechara.animate_selected()

	var chara = thechara.characterData
	print (chara.Charaname+ " is selected")
	if !move_mode:
		selected_character.unselected()
		selected_character = thechara
		(thechara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
		# Le portrait suit le SLOT du personnage, pas son index de spawn :
		# characters.find() designait le mauvais portrait apres un echange.
		_move_selectors_to_selected()
		NameLabel.text=chara.Name
		Def.bbcode_enabled = true
		Att.bbcode_enabled = true
		WillPower.bbcode_enabled = true
		Stamina.bbcode_enabled = true
		Guilt.bbcode_enabled = true
		Horny.bbcode_enabled = true
		Att.text = "Attack: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.attack, chara.base_attack, (chara.attack - chara.base_attack)]
		Def.text = "Defense: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.defense, chara.base_defense, (chara.defense - chara.base_defense)]
		WillPower.text = "Willpower: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
		chara.willpower, chara.base_willpower, (chara.willpower - chara.base_willpower)]

		Stamina.text = "%d / %d" % [chara.current_stamina, chara.max_stamina]
		StaminaProgressBar.max_value= chara.max_stamina
		StaminaProgressBar.value=chara.current_stamina
		Guilt.text = "%d / %d" % [chara.current_stress, chara.max_stress]
		GuiltProgressBar.max_value=chara.max_stress
		GuiltProgressBar.value=chara.current_stress
		Horny.text = "%d / %d" % [chara.current_horniness, chara.max_horniness]
		LustProgressBar.max_value=chara.max_horniness
		LustProgressBar.value=chara.current_horniness
		update_equipment_icons(chara)

		# Refresh des boutons d'action (cooldown, disponibilité, etc.)
		_refresh_explo_skill_button()
		_refresh_move_button()

func update_equipment_icons(character: CharacterData):
	var slots = [
		Items.get_node("Item1"),
		Items.get_node("Item2")
	]

	for s in slots:
		s.remove_item()

	for i in range(character.equipped_items.size()):
		if i >= slots.size(): break
		var equip: Equipment = character.equipped_items[i]
		slots[i].assigne_item(equip)

func _on_character_equipment_changed(_chara: CharacterData):
	selectCharacter(selected_character)

func _on_button_button_down() -> void:
	DoorNumber = 0
	call_deferred("go_to_next_room")

func _on_button_mouse_entered() -> void:
	Doortext.scale = startsize
	Doortext.set_pivot_offset(Doortext.size / 2)

	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)

func _on_button_mouse_exited() -> void:
	Doortext.scale = big_size
	Doortext.set_pivot_offset(Doortext.size / 2)
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)

## Ancien bouton "move" apparaissant au survol (scene exploration35 heritee).
## Redirige vers le mode deplacement du bouton ExploSkillButtonMove.
func _on_move_button_button_down() -> void:
	_on_move_skill_button_pressed()


func _on_button_2_button_down() -> void:
	DoorNumber = 1
	call_deferred("go_to_next_room")


func go_to_campement() -> void:
	gm.current_room_Ressource.CampDone=true
	gm.go_to_campement()

func sortie_du_camp():
	for chara in characters:
		chara.current_stamina = min(chara.max_stamina, chara.current_stamina + 10)
		chara.animate_heal(10, chara)
		chara.update_display()

func showMenuPerso():
	menuPerso.showMenu()

func create_selector_sprite():
	var sprite := Sprite2D.new()
	sprite.texture = SELECTOR_TEX
	add_child(sprite)
	selectorChara=sprite
	selectorChara.scale= Vector2(0.9,1.1)
	selectorChara.offset.y =-4.0
	selectorChara.z_index = 3
	if !showselector:
		selectorChara.modulate.a=0.0
func campement_over():
	if !gm.current_room_Ressource.CampDone:
		GoToCampement.scale= Vector2(0.0,0.0)
		GoToCampement.visible=true
		var tween : Tween = create_tween()

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(GoToCampement,"scale",Vector2(1.0,1.0),0.3).set_delay(0.3)
func campement_notover():
	GoToCampement.visible=false
func Door_over():
	DoorTuto.scale= Vector2(0.0,0.0)
	DoorTuto.visible=true
	var tween : Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(DoorTuto,"scale",Vector2(1.0,1.0),0.3).set_delay(0.8)
func Door_notover():
	DoorTuto.visible=false

func load_interactable():
	var room := gm.current_room_Ressource
	if room.interactable == null:
		print("no interactable in this room")
		return

	var obj := room.interactable.scene.instantiate()
	obj.data = room.interactable
	# Donne au coffre la référence vers SA salle, pour qu'il puisse
	# persister son état (ouvert/utilisé) après son queue_free().
	obj.room = room
	interactable.add_child(obj)


# --------------------------------------------------------------------
# MODE DEPLACEMENT (bouton ExploSkillButtonMove)
# --------------------------------------------------------------------

## Recale les deux selecteurs (portrait en haut, marqueur au sol) sur le
## personnage selectionne, en passant par son portrait et son slot courants
## plutot que par son index dans `characters`.
## `movetime` > 0 fait glisser les selecteurs au lieu de les teleporter.
func _move_selectors_to_selected(movetime: float = 0.0) -> void:
	if selected_character == null:
		return

	var portrait_target: Vector2 = portrait_selector.position
	if selected_character.exploPortrait != null:
		portrait_target = selected_character.exploPortrait.position

	var has_ground_target: bool = selectorChara != null and selected_character.CharaPosition != null
	var ground_target: Vector2 = Vector2.ZERO
	if has_ground_target:
		ground_target = selected_character.CharaPosition.charaUI.global_position
		ground_target.y += 45

	if movetime <= 0.0:
		portrait_selector.position = portrait_target
		if has_ground_target:
			selectorChara.position = ground_target
		return

	var tween := create_tween()
	tween.parallel().tween_property(portrait_selector, "position", portrait_target, movetime) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if has_ground_target:
		tween.parallel().tween_property(selectorChara, "position", ground_target, movetime) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Grise le bouton quand aucun personnage n'est selectionne ou que celui-ci ne
## peut pas etre deplace, et signale visuellement le mode actif.
func _refresh_move_button() -> void:
	if explo_move_button == null:
		return
	var usable: bool = selected_character != null \
			and selected_character.characterData != null \
			and selected_character.characterData.can_be_moved
	explo_move_button.disabled = not usable or _swapping
	explo_move_button.modulate = Color(1.4, 1.0, 0.6) if move_mode else Color.WHITE


## Bascule le mode deplacement : une fleche apparait au-dessus de chaque
## personnage NON selectionne. Cliquer sur l'un d'eux (sur la scene ou sur son
## portrait) echange sa position avec celle du personnage selectionne.
func set_move_mode(on: bool) -> void:
	move_mode = on
	for c in characters:
		if c != null:
			c.set_move_target(on and c != selected_character)
	_refresh_move_button()


func _on_move_skill_button_pressed() -> void:
	if selected_character == null:
		return
	if move_mode:
		set_move_mode(false)
		return
	if selected_character.characterData != null and not selected_character.characterData.can_be_moved:
		print("%s ne peut pas etre deplace." % selected_character.characterData.Charaname)
		return

	# Le mode deplacement et le ciblage de skill s'excluent.
	if is_selecting_explo_target:
		is_selecting_explo_target = false
		pending_explo_skill = null
		_highlight_explo_targets(false)
		if selected_character.sprite.material is ShaderMaterial:
			(selected_character.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)

	set_move_mode(true)


# --------------------------------------------------------------------
# SKILL D'EXPLORATION (lust -> guilt, etc.)
# --------------------------------------------------------------------

## Met à jour l'icône / l'état disabled du bouton skill en fonction du
## personnage sélectionné et de son cooldown.
## Sprite2D d'icône posée dans la scène sous le bouton de skill. C'est elle
## qu'on met à jour — voir _refresh_explo_skill_button().
func _skill_button_icon() -> Sprite2D:
	if explo_skill_button == null:
		return null
	for child in explo_skill_button.get_children():
		if child is Sprite2D:
			return child
	return null


func _refresh_explo_skill_button() -> void:
	if explo_skill_button == null:
		return

	# L'icône était affichée DEUX FOIS : par la Sprite2D de la scène (texture du
	# fouet en dur, centrée et à l'échelle 0.83) et par Button.icon assigné ici
	# avec la même texture, mais dessinée à sa taille native et au placement du
	# thème. On ne garde que la Sprite2D : elle suit le personnage sélectionné
	# et s'aligne sur l'icône du bouton de déplacement, juste en dessous.
	explo_skill_button.icon = null
	var icon_sprite := _skill_button_icon()

	var skill: ExplorationSkill = null
	if selected_character != null:
		var skills: Array = selected_character.characterData.exploration_skill_resources
		if not skills.is_empty() and skills[0] != null:
			skill = skills[0]

	if skill == null:
		explo_skill_button.disabled = true
		if icon_sprite != null:
			icon_sprite.visible = false
		return

	if icon_sprite != null:
		icon_sprite.texture = skill.icon
		icon_sprite.visible = skill.icon != null
	explo_skill_button.disabled = not skill.can_use(selected_character.characterData)


## Quand l'utilisateur clique sur le bouton de skill : entre en mode
## "sélection de cible". Le prochain clic sur un portrait/chara sera
## interprété comme une cible (voir selectCharacter()).
func _on_explo_skill_button_pressed() -> void:
	if selected_character == null:
		return
	var skills: Array = selected_character.characterData.exploration_skill_resources
	if skills.is_empty() or skills[0] == null:
		return

	var skill: ExplorationSkill = skills[0]
	if not skill.can_use(selected_character.characterData):
		print("Skill non utilisable (cooldown ou pas assez de Lust)")
		return

	set_move_mode(false)
	pending_explo_skill = skill

	# Si le skill ne cible que le caster, on l'applique direct
	if skill.target_type == ExplorationSkill.TargetType.SELF:
		_apply_explo_skill_to_target(selected_character)
		return

	is_selecting_explo_target = true
	print("Sélectionne une cible pour le skill : ", skill.descriptionName)
	# Feedback visuel sur les portraits/charas ciblables (optionnel)
	_highlight_explo_targets(true)


## Active/désactive un feedback visuel sur les cibles potentielles.
func _highlight_explo_targets(on: bool) -> void:
	for c in characters:
		if c == null:
			continue
		# Petit pulse via le shader d'outline existant
		var mat := c.sprite.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("enabled", on)


## Applique réellement le skill : animations caster + target, puis effet.
func _apply_explo_skill_to_target(target: CharaExplo) -> void:
	var caster: CharaExplo = selected_character
	var skill: ExplorationSkill = pending_explo_skill

	# Fin du mode sélection
	is_selecting_explo_target = false
	pending_explo_skill = null
	_highlight_explo_targets(false)
	# Remet le outline sur le selected
	if caster != null and caster.sprite.material is ShaderMaterial:
		(caster.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)

	if skill == null or caster == null or target == null:
		return

	# Vérifie le ciblage
	match skill.target_type:
		ExplorationSkill.TargetType.SELF:
			if target != caster:
				target = caster
		ExplorationSkill.TargetType.ALLY:
			# n'importe quel allié, y compris soi → OK
			pass
		ExplorationSkill.TargetType.ANY:
			pass

	# Animation du lanceur
	caster.skill_animation_finished.connect(
		func(): target.animate_explo_skill_target(skill, caster),
		CONNECT_ONE_SHOT
	)

	# On lance l'anim du caster SANS await — elle continue son cours,
	# et au moment où elle émet le signal, l'anim de la cible se lance en parallèle.
	caster.animate_explo_skill_cast(skill, target)

	# Effet logique
	skill.apply_effect(caster, target)

	# Refresh visuel
	caster.update_display()
	if target != caster:
		target.update_display()

	# Refresh des stats à l'écran si le caster est encore le selected
	if selected_character == caster:
		# Re-sync les jauges/labels via selectCharacter (sans casser l'outline)
		_refresh_stats_display(caster.characterData)
	_refresh_explo_skill_button()


## Mise à jour des labels/jauges sans repasser par toute la logique de selectCharacter.
func _refresh_stats_display(chara: CharacterData) -> void:
	Stamina.text = "%d / %d" % [chara.current_stamina, chara.max_stamina]
	StaminaProgressBar.max_value = chara.max_stamina
	StaminaProgressBar.value = chara.current_stamina
	Guilt.text = "%d / %d" % [chara.current_stress, chara.max_stress]
	GuiltProgressBar.max_value = chara.max_stress
	GuiltProgressBar.value = chara.current_stress
	Horny.text = "%d / %d" % [chara.current_horniness, chara.max_horniness]
	LustProgressBar.max_value = chara.max_horniness
	LustProgressBar.value = chara.current_horniness
