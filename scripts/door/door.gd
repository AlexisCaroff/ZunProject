extends Button
class_name Door
@onready var Doortext : TextureRect= $DoorText
@export var chara_explo_scene : PackedScene
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
var Game_Manager:GameManager
var timePeeking : float = 0.0
@onready var peekButton=$"../peekButton"
@onready var left_button: Button = $"../LastDoor"
@onready var right_button: Button = $"../NextDoor"
var current_index: int = -1
var connected_ids: Array = []
var peeking: bool = true
@onready var subViewportContainer= $"../SubViewportContainer"
@onready var sub_viewport : Viewport= $"../SubViewportContainer/SubViewport"
var encounter_for_this_door: CombatEncounter
@onready var embuscadeUI: TextureRect = $"../EmbuscadeUI"
var peek_scene
var ennemy_are_embushed : bool = false
var heroes_are_embushed : bool = false
@onready var viewport: Viewport = $"../SubViewportContainer2/SubViewport"
@onready var donjon_map: Map = $"../SubViewportContainer2/SubViewport/map"
@onready var portrait_selector = $"../Portraits/ExploCharaselector"
var characters: Array[CharacterData] = []
@onready var portraits = $"../Portraits".get_children()
var selected_character: CharacterData
@onready var doorRight:=$"../../DoorrDungeonHall"
@onready var doorLeft:=$"../../DoorlDungeonHall"
var locked : bool =false
@export var Blocked : bool =false
@export var keyName: String = "key1"
const lockedUI = preload("res://UI/scripts/LokedUI.tscn")
const OpenUI = preload("res://UI/scripts/OpenDoorKeyUI.tscn")
const BlockedUI= preload("res://UI/scripts/BlockedUI.tscn")
var animation: bool=false

#___________________________________________________________________________
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
@onready var Items = get_node_or_null("../Items")
@onready var kinks =$"../Kinks"
@onready var PeekBonus =$"../PeekBonus"
@onready var return_button : Button=$"../Return"

# ── Personnages presents dans la scene porte ─────────────────────────
@onready var hero_root: Node2D = $"../DoorHeroPosition"
@onready var peek_pose: Node2D = get_node_or_null("../PositionPeek")
## Duree du glissement du personnage vers la porte au peek.
@export var peek_slide_time: float = 0.45
## Temps de lecture entre l'arrivee du personnage devant la porte et
## l'ouverture de la vue de peek, qui masque toute la scene.
@export var peek_start_delay: float = 0.3
var chara_nodes: Array[CharaExplo] = []
var selected_node: CharaExplo = null
var _peek_rest_position: Vector2 = Vector2.ZERO
var _peek_rest_scale: Vector2 = Vector2.ONE
## Sprite d'origine, restaure des que le personnage repart vers sa place.
var _peek_rest_texture: Texture2D = null

# ── Panneau bas-droit : carte OU sac d'equipe ────────────────────────
@onready var map_container = get_node_or_null("../SubViewportContainer2")
@onready var contour_map = get_node_or_null("../ContourMap")
@onready var icon_map = get_node_or_null("../IconMap")
@onready var inventory_panel: DoorInventory = get_node_or_null("../InventoryPanel")
@onready var toggle_button: Button = get_node_or_null("../ToggleMapInventory")
var showing_inventory: bool = false

# ── Transition glissee entre deux portes ─────────────────────────────
## Duree du defilement du decor quand on change de porte.
@export var door_slide_time: float = 0.55

# ── Mode deplacement : echanger deux heros de place ──────────────────
@onready var move_button: Button = get_node_or_null("../DoorSkillButtonMove")
## Duree du glissement lors d'un echange, alignee sur l'exploration.
@export var swap_move_time: float = 0.5
var move_mode: bool = false
var _swapping: bool = false
## Duree du fondu de retour, une fois la nouvelle porte en place. Le fondu
## AU NOIR, lui, dure aussi longtemps que le defilement : les deux tournent
## ensemble (cf. _slide_to_room).
@export var door_fade_time: float = 0.25
var _sliding: bool = false
func _ready():
	GameState.current_phase = GameStat.GamePhase.DOOR
	Game_Manager = get_tree().root.get_node("GameManager") 
	if Game_Manager.current_room_Ressource.door_scene_History != null and not Game_Manager.current_room_Ressource.door_history_played:
		print("find history Scene")
		Game_Manager.show_history_scene(Game_Manager.current_room_Ressource.door_scene_History)
		Game_Manager.current_room_Ressource.door_history_played =true
	characters=Game_Manager.characters
	peek_scene = load("res://UI/peekScene.tscn").instantiate()
	sub_viewport.add_child(peek_scene)
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("focus_visible", empty)
	#print("next room ready")
	#print(GameManager.current_room_Ressource.resource_name)
	if Game_Manager.current_room_Ressource.encounter != null and Game_Manager.current_room_Ressource.ennemikilled ==false :
		encounter_for_this_door= Game_Manager.current_room_Ressource.encounter
	locked = Game_Manager.current_room_Ressource.locked
	keyName = Game_Manager.current_room_Ressource.keyName
	if Game_Manager.last_room_Ressource :
		if Game_Manager.last_room_Ressource.connected_room_ids.size()>1:
			connected_ids = Game_Manager.last_room_Ressource.connected_room_ids.duplicate()
			if connected_ids.is_empty():
				push_warning("⚠️ Aucune room connectée depuis " + str(Game_Manager.last_room_Ressource.room_id))
				left_button.disabled = true
				right_button.disabled = true
				return

			# Trouve l'index de la room actuelle dans cette liste
			current_index = connected_ids.find(Game_Manager.current_room_Ressource.room_id)
			if current_index == -1:
				current_index = 0  # fallback si jamais l'id n'existe pas
				print("⚠️ current_room non trouvée dans connected_room_ids, utilisation de l'index 0")

			# Connecte les boutons
			left_button.pressed.connect(_on_left_pressed)
			right_button.pressed.connect(_on_right_pressed)
		else :
			left_button.disabled=true
			left_button.modulate.a = 0.2
			right_button.disabled=true
			right_button.modulate.a = 0.2
	else :
		left_button.disabled=true
		left_button.modulate.a = 0.2
		right_button.disabled=true
		right_button.modulate.a = 0.2
		
	 
	# Fallback : cherche le bouton par nom si pas assigné dans l'inspecteur.
	if return_button == null:
		return_button = find_child("ReturnButton", true, false) as Button
	if return_button == null:
		return_button = find_child("Return", true, false) as Button
 
	if return_button == null:
		push_warning("door.gd : bouton 'Return' introuvable — assigne-le dans l'inspecteur.")
	else:
		if not return_button.pressed.is_connected(_on_return_pressed):
			return_button.pressed.connect(_on_return_pressed)
 
 
	
	
	await get_tree().process_frame  # attendre que la frame d'instanciation soit finie
	load_chara()
		
	if donjon_map:
		donjon_map.focus_door(Game_Manager.current_room_Ressource, viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	_setup_map_inventory_toggle()
	if move_button != null:
		move_button.pressed.connect(_on_move_button_pressed)
	selectCharacter(characters[0])

func load_chara():
	for i in characters.size():
		var chara: CharacterData = characters[i]
		# Le portrait ET la silhouette suivent la formation choisie en
		# exploration, comme en combat.
		var slot_index: int = clamp(chara.Chara_position, 0, 3)
		portraits[slot_index].set_occupant(chara)
		_spawn_chara_node(chara, slot_index)


## Pose une silhouette d'exploration a l'echelle reduite du slot porte.
## Seul load_chara() est appele : update_display() a besoin des jauges
## portees par le charaUI d'un ExplorationPosition, absent ici.
func _spawn_chara_node(data: CharacterData, slot_index: int) -> void:
	if chara_explo_scene == null or hero_root == null:
		return
	# Resolu par nom, pas par index d'enfant : les silhouettes sont elles aussi
	# ajoutees sous hero_root, get_children() melangerait marqueurs et persos.
	var slot := hero_root.get_node_or_null("position%d" % (slot_index + 1)) as Node2D
	if slot == null:
		push_warning("Scene porte : slot position%d introuvable." % (slot_index + 1))
		return
	var node: CharaExplo = chara_explo_scene.instantiate()
	node.characterData = data
	hero_root.add_child(node)
	node.load_chara()
	node.position = slot.position
	node.scale = slot.scale
	node.z_index = slot.z_index
	chara_nodes.append(node)

	# Cliquer la silhouette selectionne le personnage, comme son portrait.
	# Le bouton vit sur le slot et non sur la silhouette : celle-ci s'avance
	# vers la porte pendant le peek, la zone cliquable doit rester en place.
	var button := slot.get_node_or_null("Button") as Button
	if button != null:
		button.pressed.connect(selectCharacter.bind(data))


func _chara_node_for(data: CharacterData) -> CharaExplo:
	for n in chara_nodes:
		if is_instance_valid(n) and n.characterData == data:
			return n
	return null


## Portrait affichant ce personnage. On le cherche par occupant plutot que
## par index dans `characters` : les deux divergent des que le joueur a
## reordonne la formation en exploration.
func _portrait_for(data: CharacterData) -> Node:
	for p in portraits:
		if p.get("occupant") == data:
			return p
	return null
			
			
func _on_mouse_exited() -> void:
	Doortext.scale = big_size	
	Doortext.set_pivot_offset(Doortext.size/ 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)



func _on_mouse_entered() -> void:
	Doortext.scale = startsize 	
	Doortext.set_pivot_offset(Doortext.size / 2)


	if current_tween:
		current_tween.kill()


	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)
	



func _on_button_down() -> void:
	if animation:
		return
	if !animation:
		animation=true
		disabled = true
		var keyfound: bool = false
		for item in Game_Manager.inventory:
			if item.name == keyName:
				keyfound = true
				locked = false
				Game_Manager.inventory.erase(item)
				Game_Manager.current_room_Ressource.locked=false
				break
				
		if keyfound:
			var UIOpen= OpenUI.instantiate()
			add_child(UIOpen )
			UIOpen.position+= Vector2(150,150)
		if Blocked:
			var UIBlocked= BlockedUI.instantiate()
			add_child(UIBlocked )
			UIBlocked.position+= Vector2(150,150)
			animation = false
			disabled=false
		if !locked:
			
			var cam : Camera =$"../Camera2D"
			var pose = cam.base_position
			pose.y -=120
			
			if doorLeft:
				open_door(1.5)
			Game_Manager.sceneTransition.fade_out(1.5)
			await cam.zoom_to_position(pose,2.0,1.0 )
			
			call_deferred("_advance_in_room")
		else:
			var UILocked = lockedUI.instantiate()
			add_child(UILocked )
			UILocked.position+= Vector2(150,150)
			animation = false
			disabled=false
	

func _advance_in_room():
	
	GameState.current_phase = GameStat.GamePhase.COMBAT
	if not Game_Manager.current_room_Ressource:
		push_error("No current_room defined in GameManager")
		return
	
	var room = Game_Manager.current_room_Ressource
	var scene_to_load: PackedScene = null

	# priorité combat → sinon exploration
	if room.combat_scene and room.encounter:
		scene_to_load = room.combat_scene
		
	elif room.exploration_scene:
		scene_to_load = room.exploration_scene
	else:
		push_error("Room has no valid scene after door")
		return

	# Demander au GameManager d'entrer dans la bonne scène
	Game_Manager._enter_scene_in_current_room(scene_to_load,ennemy_are_embushed,heroes_are_embushed)

func startpeeking():
	peek_scene.door = self
	donjon_map.peek_next_Room(Game_Manager.current_room_Ressource, viewport)
	peek_scene.set_encounter(encounter_for_this_door)
	GameState.current_phase = GameStat.GamePhase.PEEK
		

func stop_peekink():
	peeking = false

func check_detection() -> void:
	# On lance une boucle tant que peek est vrai
	ennemy_are_embushed = true
	
	await get_tree().create_timer(.2).timeout
	
	if peeking:
		var rand = randi_range(1, 100)
		print("Jet de détection :", rand)
		if rand > 70:
			print("Tu es repéré ! Combat déclenché.")
			peeking = false 
			heroes_are_embushed = true
			ennemy_are_embushed = false
			_start_combat()
			# on stoppe la boucle si le combat démarre
			return
		check_detection()
func get_ambushed():
	heroes_are_embushed = true
	ennemy_are_embushed = false
	_start_combat()
	
func win_ambush():
	heroes_are_embushed = false
	ennemy_are_embushed = true
	_start_combat()
	
	
func _start_combat():
	if heroes_are_embushed:
		embuscadeUI.texture = encounter_for_this_door.imageEmbuscade
		embuscadeUI.visible = true
	await get_tree().create_timer(1.0).timeout
	subViewportContainer.visible=false
	var cam : Camera =$"../Camera2D"
	var pose = cam.base_position
	pose.y -=120
	if doorLeft:
		open_door(1.5)
	Game_Manager.sceneTransition.fade_out(1.5)
	await cam.zoom_to_position(pose,2.0,1.0 )
	call_deferred("_advance_in_room")
	
	
func _on_left_pressed():
	if connected_ids.is_empty() or _sliding:
		return
	current_index = (current_index - 1 + connected_ids.size()) % connected_ids.size()
	_go_to_connected_room(current_index, -1)


func _on_right_pressed():
	if connected_ids.is_empty() or _sliding:
		return
	current_index = (current_index + 1) % connected_ids.size()
	_go_to_connected_room(current_index, 1)


func _go_to_connected_room(index: int, direction: int = 0):
	if not Game_Manager:
		return
	if index < 0 or index >= connected_ids.size():
		push_error("Index de room invalide : %d" % index)
		return

	var target_id = connected_ids[index]
	var next_room = Game_Manager.get_room_by_id(target_id)
	if not next_room:
		push_error("Impossible de trouver la room pour ID : %s" % target_id)
		return

	print("🚪 Door → Passage à la room suivante :", next_room.room_id)
	if direction != 0 and next_room.door_scene != null:
		_slide_to_room(next_room, direction)
		return
	Game_Manager.enter_room(next_room, true)
	
func selectCharacter(chara: CharacterData):
		# Les clics sont ignores tant que l'echange en cours n'est pas termine.
		if _swapping:
			return

		# --- INTERCEPTION : mode deplacement (bouton DoorSkillButtonMove)
		if move_mode:
			var target := _chara_node_for(chara)
			if target != null and target != selected_node:
				_swap_characters(target, selected_node)
			set_move_mode(false)
			return

		selected_character = chara
		if selected_node != null and is_instance_valid(selected_node):
			selected_node.unselected()
		selected_node = _chara_node_for(chara)
		if selected_node != null and selected_node.sprite.material is ShaderMaterial:
			(selected_node.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
		var portrait := _portrait_for(chara)
		if portrait != null:
			portrait_selector.position = portrait.position
		_refresh_move_button()
		NameLabel.text=chara.Name
		Def.bbcode_enabled = true
		Att.bbcode_enabled = true
		WillPower.bbcode_enabled = true
		Stamina.bbcode_enabled = true
		Guilt.bbcode_enabled = true
		Horny.bbcode_enabled = true
		PeekBonus.bbcode_enabled = true
		kinks.bbcode_enabled = true
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
		PeekBonus.text = "Peek Bonus: %d [color=AAAAAA] " %[		chara.peek]
		# Les kinks sont les tags du personnage (cf. InventoryUI.select_character).
		if chara.tags.is_empty():
			kinks.text = "Kinks: [color=AAAAAA][i]none[/i][/color]"
		else:
			kinks.text = "Kinks: %s" % ", ".join(chara.tags)
		
		
		
func open_door(duration:float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	var targetScale =doorLeft.scale.y*0.2
	tween.parallel().tween_property(Doortext, "modulate:a",0.0 , 0.3)
	tween.parallel().tween_property(peekButton, "modulate:a",0.0 , 0.3)
	tween.parallel().tween_property(embuscadeUI, "modulate:a",0.0 , 0.3)
	tween.parallel().tween_property(doorLeft, "scale:y",targetScale , duration)
	tween.parallel().tween_property(doorRight, "scale:y",targetScale , duration)
	tween.parallel().tween_property(doorRight, "skew",0.2 , duration)
	tween.parallel().tween_property(doorLeft, "skew",-0.2 , duration)
	
func _on_return_pressed() -> void:
	if Game_Manager == null:
		return
	Game_Manager.go_back()


# ════════════════════════════════════════════════════════════════════
#  PEEK — le personnage selectionne s'avance vers la porte
# ════════════════════════════════════════════════════════════════════

## Avance le personnage selectionne jusqu'a PositionPeek, puis marque une
## pause avant de rendre la main : sans elle, la vue de peek s'ouvre par-dessus
## et le glissement passe inapercu. A attendre depuis Doorpeek.
func on_peek_enter() -> void:
	if selected_node == null or not is_instance_valid(selected_node) or peek_pose == null:
		return
	set_move_mode(false)
	_peek_rest_position = selected_node.position
	_peek_rest_scale = selected_node.scale
	_peek_rest_texture = selected_node.sprite.texture
	# PositionPeek vit dans l'espace de la scene porte, les silhouettes dans
	# celui de DoorHeroPosition : on convertit plutot que de supposer les deux
	# reperes alignes. L'echelle n'est pas touchee — le marqueur n'en porte pas,
	# l'appliquer ferait bondir le personnage a la taille d'exploration.
	var target_pos: Vector2 = hero_root.to_local(peek_pose.global_position)
	await _tween_chara(selected_node, target_pos, selected_node.scale)

	# Une fois EN PLACE devant la porte, le personnage prend sa pose de peek.
	# Le sprite reste ainsi pendant la pause de lecture puis toute la duree du
	# peek, jusqu'au premier pas du retour (cf. on_peek_exit).
	if is_instance_valid(selected_node) and selected_node.characterData.peek_texture != null:
		selected_node.sprite.texture = selected_node.characterData.peek_texture

	if peek_start_delay > 0.0:
		await get_tree().create_timer(peek_start_delay).timeout


func on_peek_exit() -> void:
	if selected_node == null or not is_instance_valid(selected_node):
		return
	# Le sprite d'origine revient AVANT le glissement : le personnage doit
	# avoir repris sa posture normale des qu'il commence a regagner sa place.
	if _peek_rest_texture != null:
		selected_node.sprite.texture = _peek_rest_texture
		_peek_rest_texture = null
	await _tween_chara(selected_node, _peek_rest_position, _peek_rest_scale)


## `duration` < 0 = celle du peek ; l'echange de places passe la sienne.
func _tween_chara(node: CharaExplo, pos: Vector2, sc: Vector2, duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = peek_slide_time
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(node, "position", pos, duration)
	tween.parallel().tween_property(node, "scale", sc, duration)
	await tween.finished


# ════════════════════════════════════════════════════════════════════
#  PANNEAU BAS-DROIT — carte OU sac d'equipe
# ════════════════════════════════════════════════════════════════════

func _setup_map_inventory_toggle() -> void:
	if toggle_button == null:
		return
	toggle_button.pressed.connect(_on_toggle_map_inventory)
	_apply_map_inventory_view()


func _on_toggle_map_inventory() -> void:
	showing_inventory = not showing_inventory
	_apply_map_inventory_view()


## La carte et le sac occupent le meme coin : l'un cache l'autre. L'icone du
## bouton montre la vue vers laquelle on basculera.
func _apply_map_inventory_view() -> void:
	if map_container:
		map_container.visible = not showing_inventory
	if contour_map:
		contour_map.visible = not showing_inventory
	if icon_map:
		icon_map.visible = not showing_inventory
	if inventory_panel:
		inventory_panel.visible = showing_inventory
		if showing_inventory and Game_Manager != null:
			inventory_panel.refresh(Game_Manager.inventory)
	if toggle_button:
		var bag = toggle_button.get_node_or_null("IconBag")
		var mp = toggle_button.get_node_or_null("IconMapToggle")
		if bag:
			bag.visible = not showing_inventory
		if mp:
			mp.visible = showing_inventory


# ════════════════════════════════════════════════════════════════════
#  TRANSITION GLISSEE ENTRE DEUX PORTES
# ════════════════════════════════════════════════════════════════════

## Fait defiler le decor et le bloc porte pendant que l'UI (portraits, stats,
## carte, boutons) reste en place, puis charge la salle suivante SANS fondu :
## le decor entrant est deja a sa place finale, le raccord est invisible.
## direction = 1 (bouton droit) fait entrer la salle suivante par la droite.
func _slide_to_room(next_room: RoomResource, direction: int) -> void:
	if _sliding:
		return
	_sliding = true
	left_button.disabled = true
	right_button.disabled = true

	var ui_root: Node = get_parent()            # instance doorInstance
	var outer: Node = ui_root.get_parent()      # racine de la scene porte
	# Largeur de reference du projet, pas celle de la fenetre : les scenes
	# portes sont dessinees en coordonnees absolues 1920x1080 et le projet
	# n'a pas de mode d'etirement.
	var width: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)

	# Decor de la salle suivante : on instancie sa scene porte et on jette son
	# UI, pour ne garder que le fond et les battants.
	var next_outer: Node = next_room.door_scene.instantiate()
	var next_ui := _find_door_ui(next_outer)
	if next_ui != null:
		next_ui.free()
	outer.get_parent().add_child(next_outer)
	outer.get_parent().move_child(next_outer, outer.get_index())
	next_outer.position = Vector2(direction * width, 0)

	# Ce qui defile : tout le decor de la salle courante, plus le bloc porte
	# (le battant cliquable et le bouton peek vivent dans l'UI mais font
	# visuellement partie de la porte).
	var movers: Array = []
	for child in outer.get_children():
		if child != ui_root:
			movers.append(child)
	movers.append(self)
	if peekButton:
		movers.append(peekButton)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for m in movers:
		tween.parallel().tween_property(m, "position",
				m.position - Vector2(direction * width, 0), door_slide_time)
	tween.parallel().tween_property(next_outer, "position", Vector2.ZERO, door_slide_time)
	# Le fondu au noir monte EN MEME TEMPS que le decor defile : meme duree,
	# lances ensemble. L'ecran est donc noir a l'instant precis ou la vraie
	# scene remplace la copie allegee du decor entrant.
	Game_Manager.sceneTransition.fade_out(door_slide_time)
	await tween.finished

	# queue_free est differe en fin de frame : la nouvelle scene est ajoutee
	# avant, donc il n'y a pas de frame vide entre les deux.
	next_outer.queue_free()
	Game_Manager.enter_room(next_room, true, true)
	# Sans await : enter_room vient de mettre CE noeud en file de suppression,
	# reprendre la coroutine apres coup travaillerait sur une instance liberee.
	Game_Manager.sceneTransition.fade_in(door_fade_time)


## L'instance de doorInstance dans une scene porte : c'est la seule a porter un
## noeud "peekButton". Les scenes portes n'ont pas toutes la meme structure de
## decor, donc on ne peut pas se fier a un nom de noeud fixe.
func _find_door_ui(root: Node) -> Node:
	for child in root.get_children():
		if child.find_child("peekButton", true, false) != null:
			return child
	return null


# ════════════════════════════════════════════════════════════════════
#  MODE DEPLACEMENT — echanger deux heros de place
# ════════════════════════════════════════════════════════════════════
#  Meme principe qu'en exploration (ExplorationManager.set_move_mode) : une
#  fleche apparait au-dessus de chaque hero NON selectionne, cliquer l'un
#  d'eux — silhouette ou portrait — echange sa place avec le selectionne.
#  La formation ainsi obtenue est celle reprise par le combat suivant.
# ════════════════════════════════════════════════════════════════════

## Marqueur de slot, resolu par nom : les silhouettes sont elles aussi
## enfants de hero_root, un acces par index melangerait les deux.
func _slot_marker(slot_index: int) -> Node2D:
	if hero_root == null:
		return null
	return hero_root.get_node_or_null("position%d" % (slot_index + 1)) as Node2D


## Portrait occupant une position de la formation. `portraits` contient les 4
## DoorPortrait suivis de ExploCharaselector, d'ou la borne.
func _portrait_for_slot(slot_index: int) -> Node:
	if slot_index < 0 or slot_index >= 4 or slot_index >= portraits.size():
		return null
	return portraits[slot_index]


func _refresh_move_button() -> void:
	if move_button == null:
		return
	var usable: bool = selected_character != null and selected_character.can_be_moved
	move_button.disabled = (not usable) or _swapping
	move_button.modulate = Color(1.4, 1.0, 0.6) if move_mode else Color.WHITE


## Bascule le mode : fleche au-dessus de chaque hero non selectionne.
func set_move_mode(on: bool) -> void:
	move_mode = on
	for n in chara_nodes:
		if is_instance_valid(n):
			n.set_move_target(on and n != selected_node)
	_refresh_move_button()


func _on_move_button_pressed() -> void:
	if selected_node == null or _swapping:
		return
	if move_mode:
		set_move_mode(false)
		return
	if selected_character != null and not selected_character.can_be_moved:
		print("%s ne peut pas etre deplace." % selected_character.Charaname)
		return
	set_move_mode(true)


## Echange les deux heros de slot : silhouettes, portraits et Chara_position.
func _swap_characters(a: CharaExplo, b: CharaExplo) -> void:
	if _swapping or a == null or b == null:
		return
	var slot_a: int = a.characterData.Chara_position
	var slot_b: int = b.characterData.Chara_position
	var marker_a := _slot_marker(slot_a)
	var marker_b := _slot_marker(slot_b)
	if marker_a == null or marker_b == null:
		push_warning("Scene porte : slot introuvable, echange annule.")
		return

	_swapping = true
	_refresh_move_button()

	# Les deux glissent en meme temps : _tween_chara est une coroutine, on ne
	# l'attend donc pas ici, sinon le second ne partirait qu'a l'arrivee du premier.
	_tween_chara(a, marker_b.position, marker_b.scale, swap_move_time)
	_tween_chara(b, marker_a.position, marker_a.scale, swap_move_time)
	a.z_index = marker_b.z_index
	b.z_index = marker_a.z_index

	a.characterData.Chara_position = slot_b
	b.characterData.Chara_position = slot_a

	var portrait_a := _portrait_for_slot(slot_a)
	var portrait_b := _portrait_for_slot(slot_b)
	if portrait_a != null:
		portrait_a.set_occupant(b.characterData)
	if portrait_b != null:
		portrait_b.set_occupant(a.characterData)

	# Le portrait du selectionne a change de place : le selecteur suit.
	var portrait := _portrait_for(selected_character)
	if portrait != null:
		portrait_selector.position = portrait.position

	await get_tree().create_timer(swap_move_time).timeout
	_swapping = false
	_refresh_move_button()
