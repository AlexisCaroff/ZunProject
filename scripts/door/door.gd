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

# ── Fiche du personnage sélectionné (portrait + objets, comme en combat) ──
# Tous optionnels : door53 et BlockeddoorSalon2 ont leur propre copie de
# l'interface, sans ces nœuds.
@onready var chara_portrait: TextureRect = get_node_or_null("../charaPortrait")
@onready var prev_chara_button: Button = get_node_or_null("../PrevCharacter")
@onready var next_chara_button: Button = get_node_or_null("../NextCharacter")
@onready var item_slots: Array = [get_node_or_null("../Items/Item1"), get_node_or_null("../Items/Item2")]
## Vrai quand la scène a la présentation « exploration » des stats (icônes
## épée / bouclier / volonté) : les libellés ne portent alors que la valeur.
@onready var compact_stats: bool = get_node_or_null("../AttackIcon") != null

# ── Personnages presents dans la scene porte ─────────────────────────
@onready var hero_root: Node2D = $"../DoorHeroPosition"
@onready var peek_pose: Node2D = get_node_or_null("../PositionPeek")
## Duree du glissement du personnage vers la porte au peek.
@export var peek_slide_time: float = 0.45
## Temps de lecture entre l'arrivee du personnage devant la porte et
## l'ouverture de la vue de peek, qui masque toute la scene.
@export var peek_start_delay: float = 0.8
## Petit zoom sur la porte pendant que le personnage s'en approche avant le
## peek, puis dézoom au retour. 1 = pas de zoom.
@export var peek_zoom: float = 1.15
@export var peek_zoom_time: float = 0.6
## Fondu des boutons de la scène quand on change de porte (flèches).
@export var buttons_fade_time: float = 0.2
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
## Boutons carte / sac côte à côte (cf. UI/map_bag_buttons.gd).
var map_bag_buttons: Dictionary = {}

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

# ── Ligne « Buffs : » de la fiche personnage ─────────────────────────
# Meme composant que l'exploration (cf. UI/buff_row.gd), construit par
# code. Si la scene contient un libelle nomme "Buffs", les icones se posent
# automatiquement derriere son texte ; sinon la ligne ecrit son propre titre.
## Coin haut-gauche de la ligne quand la scene n'a pas de libelle "Buffs".
@export var buffs_row_position: Vector2 = Vector2(1061, 1010)
## Decalage a appliquer aux icones posees derriere le libelle "Buffs".
@export var buffs_icons_nudge: Vector2 = Vector2.ZERO
var buff_row: BuffRow = null

func _ready():
	GameState.current_phase = GameStat.GamePhase.DOOR
	_ready_msec = Time.get_ticks_msec()
	Game_Manager = get_tree().root.get_node("GameManager")
	var door_dialogue: Node = null
	if Game_Manager.current_room_Ressource.door_scene_History != null and not Game_Manager.current_room_Ressource.door_history_played:
		print("find history Scene")
		door_dialogue = Game_Manager.show_history_scene(Game_Manager.current_room_Ressource.door_scene_History)
		Game_Manager.current_room_Ressource.door_history_played =true
	# Didacticiel porte / peek (intro2) : à la première porte de la partie.
	# Il est dessiné au-dessus du HUD (et donc des dialogues) : on attend
	# que le dialogue de la porte soit refermé pour l'afficher.
	var door_tuto := get_node_or_null("../Intro2") as CanvasItem
	if door_tuto != null and Game_Manager.tutorial_once("door"):
		_show_tuto_after(door_tuto, door_dialogue)
	characters=Game_Manager.characters
	# Etat de repos identique a celui laisse par _on_mouse_exited (pivot au
	# centre, echelle startsize) : sans ca le texte « saute » au premier survol.
	_center_door_text()
	Doortext.resized.connect(_center_door_text)
	Doortext.scale = startsize
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
	_setup_portrait_column()
	_setup_stat_hover()
		
	if donjon_map:
		donjon_map.focus_door(Game_Manager.current_room_Ressource, viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	_setup_map_inventory_toggle()
	_setup_character_menu()   # après : il se range à côté du bouton sac
	_setup_cards()            # après : il se range à côté du bouton fiche
	_setup_buff_row()
	if move_button != null:
		move_button.pressed.connect(_on_move_button_pressed)
	# Cases d'objet SOUS la vue de peek (SubViewportContainer, z 10) : leur
	# conteneur Items est à 8, un z propre de 8 les montait à 16. Réglé ici
	# plutôt que dans la scène, qu'une sauvegarde de l'éditeur peut écraser.
	for slot in item_slots:
		if slot != null:
			slot.z_index = 0
	if prev_chara_button != null:
		prev_chara_button.pressed.connect(_cycle_character.bind(-1))
	if next_chara_button != null:
		next_chara_button.pressed.connect(_cycle_character.bind(1))
	selectCharacter(characters[0])


func _on_unequip_requested(item: Equipment) -> void:
	if selected_character == null:
		return
	_unequip_item(item, selected_character)
	# selectCharacter() ferait un échange en mode déplacement.
	if move_mode:
		set_move_mode(false)
	selectCharacter(selected_character)
	if showing_inventory and inventory_panel != null and Game_Manager != null:
		inventory_panel.refresh(Game_Manager.inventory)


## Clic sur un objet des cases sous le portrait : il retourne dans le sac
## d'équipe. add_to_inventory() prévient aussi le menu personnage, qui range
## l'objet dans sa grille.
func _unequip_item(item: Equipment, chara: CharacterData) -> void:
	if chara == null or item == null:
		return
	var idx := chara.equipped_items.find(item)
	if idx < 0:
		return
	chara.equipped_items.remove_at(idx)
	var gm_node := get_tree().root.get_node_or_null("GameManager") as GameManager
	if gm_node != null:
		gm_node.add_to_inventory(item)
	DoorInventory.recompute_stats(chara)


# ── Colonne de portraits (charaPortraitFrame1..4) : clic = sélection ──
## Composant de la colonne de portraits (préchargé : pas de dépendance au
## cache des class_name).
const PORTRAIT_COLUMN := preload("res://UI/portrait_column.gd")
var portrait_entries: Array = []
var _ready_msec: int = 0

func _show_tuto_after(tuto: CanvasItem, dialogue: Node) -> void:
	if dialogue != null and is_instance_valid(dialogue):
		await dialogue.history_finished
	if is_instance_valid(tuto):
		tuto.visible = true


# ── Survol des stats (même composant qu'en exploration) ──
const STAT_HOVER := preload("res://UI/stat_hover.gd")

func _setup_stat_hover() -> void:
	if not compact_stats:
		return
	var hover = STAT_HOVER.new(get_parent())
	for p in [["../AttackIcon", Att, "attack"], ["../DefenceIcon", Def, "defense"],
			["../WillPowerIcon", WillPower, "willpower"]]:
		hover.attach(get_node_or_null(p[0]), p[1], _stat_text.bind(p[2]))


func _stat_text(stat: String) -> String:
	return selected_character.stat_tooltip(stat) if selected_character != null else ""


# ── Menu personnages : bouton rangé avec sac et carte, menu créé par code ──
const MENU_SCENE := preload("res://menu_Characters.tscn")
const MENU_ICON := preload("res://UI/UI boxes/charaIcon.png")
var menu_perso: Node = null

func _setup_character_menu() -> void:
	var bag := map_bag_buttons.get("bag") as Control
	if bag == null:
		return
	menu_perso = MENU_SCENE.instantiate()
	menu_perso.name = "MenuPerso"
	menu_perso.characters = Game_Manager.characters
	get_parent().add_child(menu_perso)
	if menu_perso.has_method("hideMenu"):
		menu_perso.hideMenu()
	if menu_perso.has_signal("change_in_equipment"):
		menu_perso.change_in_equipment.connect(func(_c): _refresh_selected())
	if menu_perso.has_signal("potion_used"):
		menu_perso.potion_used.connect(func(_p, _t): _refresh_selected())

	# Bouton : même taille, même cadre et même écart que sac / carte.
	var btn := Button.new()
	btn.name = "ButtonMenuPerso"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.tooltip_text = "Characters"
	btn.z_index = bag.z_index
	var w := bag.offset_right - bag.offset_left
	var h := bag.offset_bottom - bag.offset_top
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = bag.offset_left - 88.0
	btn.offset_right = btn.offset_left + w
	btn.offset_top = bag.offset_top
	btn.offset_bottom = bag.offset_top + h
	var icon := Sprite2D.new()
	icon.name = "IconMenu"
	icon.texture = MENU_ICON
	icon.position = Vector2(w, h) * 0.5
	icon.scale = Vector2.ONE * (56.0 / float(MENU_ICON.get_width()))
	btn.add_child(icon)
	MapBagButtons.ensure_box(btn)
	MapBagButtons.add_hover(btn)
	btn.pressed.connect(func():
		if is_instance_valid(menu_perso) and menu_perso.has_method("showMenu"):
			menu_perso.select_character(selected_character)
			menu_perso.showMenu())
	get_parent().add_child(btn)
	MapBagButtons.track_menu(btn, menu_perso)


## Cartes d'affinité : consultables ici, jouables seulement au camp.
var card_hand: CardHand = null

func _setup_cards() -> void:
	if map_bag_buttons.is_empty():
		return
	card_hand = CardHand.install_hud(get_parent(),
			[map_bag_buttons.map, map_bag_buttons.bag, get_parent().get_node_or_null("ButtonMenuPerso")],
			inventory_panel)
	map_bag_buttons.map.pressed.connect(card_hand.close)
	map_bag_buttons.bag.pressed.connect(card_hand.close)
	# Carte, sac et cartes : même rectangle, même cadre. Boutons au rang 9 :
	# au-dessus des menus, sous la vue de peek (z 10).
	HudFrame.install(get_parent(), HudFrame.rect_of(inventory_panel), map_container,
			contour_map, inventory_panel, [map_bag_buttons.map, map_bag_buttons.bag,
			get_parent().get_node_or_null("ButtonMenuPerso"), card_hand.toggle_button])


## Équipement ou potion modifiés depuis le menu : la fiche se redessine.
func _refresh_selected() -> void:
	if selected_character == null:
		return
	if move_mode:
		set_move_mode(false)
	selectCharacter(selected_character)


func _setup_portrait_column() -> void:
	var frames: Array = []
	for i in 4:
		frames.append(get_node_or_null("../charaPortraitFrame%d" % (i + 1)))
	if frames.all(func(f): return f == null):
		return
	portrait_entries = PORTRAIT_COLUMN.build(frames, _on_portrait_frame_clicked)
	_refresh_portrait_column()


## Cadre i = position i de la formation. En mode déplacement, selectCharacter
## fait l'échange, comme un clic sur la silhouette.
func _on_portrait_frame_clicked(slot_index: int) -> void:
	for c in characters:
		if c.Chara_position == slot_index:
			selectCharacter(c)
			return


func _refresh_portrait_column() -> void:
	if portrait_entries.is_empty():
		return
	var by_slot: Array = [null, null, null, null]
	for c in characters:
		by_slot[clampi(c.Chara_position, 0, 3)] = c
	PORTRAIT_COLUMN.refresh(portrait_entries, by_slot, selected_character)


## Flèches de part et d'autre du portrait : personnage suivant / précédent,
## dans l'ordre de la formation (celui des silhouettes à l'écran).
func _cycle_character(step: int) -> void:
	if _swapping or characters.is_empty():
		return
	# Une flèche n'est pas une cible d'échange : on sort du mode déplacement.
	if move_mode:
		set_move_mode(false)
	var order: Array[CharacterData] = characters.duplicate()
	order.sort_custom(func(a, b): return a.Chara_position < b.Chara_position)
	var i := order.find(selected_character)
	if i == -1:
		i = 0
	selectCharacter(order[(i + step + order.size()) % order.size()])


## Même remplissage qu'en exploration et au camp.
func _update_equipment_icons(chara: CharacterData) -> void:
	for slot in item_slots:
		if slot != null:
			slot.remove_item()
			if not slot.unequip_requested.is_connected(_on_unequip_requested):
				slot.unequip_requested.connect(_on_unequip_requested)
	var i := 0
	for slot in item_slots:
		if slot == null:
			continue
		if i >= chara.equipped_items.size():
			break
		slot.assigne_item(chara.equipped_items[i])
		i += 1


## Pose les icones de buff dans le panneau du bas. Si la scene porte deja un
## libelle nomme "Buffs", elles se collent derriere son texte et aucun titre
## n'est ecrit ; sinon la ligne dessine son propre « Buffs : ».
func _setup_buff_row() -> void:
	var host := get_parent()
	if host == null:
		return
	var anchor := host.get_node_or_null("Buffs") as Control
	if anchor != null:
		buff_row = BuffRow.create(host,
				BuffRow.position_after(anchor) + buffs_icons_nudge,
				anchor, false)
	else:
		buff_row = BuffRow.create(host, buffs_row_position, PeekBonus, true)

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
			
			
func _center_door_text() -> void:
	Doortext.pivot_offset = Doortext.size / 2


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
			await _play_enter_animation()
		else:
			var UILocked = lockedUI.instantiate()
			add_child(UILocked )
			UILocked.position+= Vector2(150,150)
			animation = false
			disabled=false
	

## Zoom sur la porte pendant son ouverture, puis passage dans la salle.
## Même durée pour l'ouverture, le zoom et le fondu : tout part ensemble.
@export var enter_zoom: float = 1.5
@export var enter_time: float = 1.5


## Entrée (bouton ENTER) ou embuscade pendant le peek. Si la vue de peek est
## ouverte, on la referme d'abord : l'ouverture de la porte doit se voir.
func _play_enter_animation() -> void:
	_close_peek_view()
	var cam := _door_camera()
	if doorLeft:
		open_door(enter_time)
	Game_Manager.sceneTransition.fade_out(enter_time)
	if cam != null:
		# Cible : le centre du bouton ENTER, c'est-à-dire la porte elle-même.
		var target := global_position + size * 0.5
		target.y -= 40
		await cam.zoom_to_position(target, cam.baseZoom.x * enter_zoom, enter_time)
	else:
		await get_tree().create_timer(enter_time).timeout
	call_deferred("_advance_in_room")


## Ferme la vue de peek comme le bouton de sortie (lvl/buttonexitepeek.gd),
## sans faire revenir le personnage ni dézoomer : on enchaîne sur l'entrée.
func _close_peek_view() -> void:
	if not peeking and not subViewportContainer.visible:
		return
	peeking = false
	subViewportContainer.visible = false
	sub_viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var exit_peek := get_node_or_null("../ExitPeek") as CanvasItem
	if exit_peek != null:
		exit_peek.visible = false
	var pose1 := get_node_or_null("../pose1") as Node2D
	if pose1 != null:
		position = pose1.position
	# La caméra est remise au cadrage normal à l'ouverture du peek ; on
	# repart de là pour le zoom d'entrée.
	_peek_zoom_snap(false)


func _advance_in_room():
	# La caméra active (celle du GameManager) survit au changement de scène :
	# on annule le zoom d'entrée tant que l'écran est noir, sinon le combat
	# ou l'exploration s'ouvriraient zoomés.
	var cam := _door_camera()
	if cam != null:
		cam.reset(0.0)
	
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
	# La salle derrière la porte est entrevue : à demi révélée sur la carte.
	Game_Manager.current_room_Ressource.peeked = true
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
	await _play_enter_animation()
	
	
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
		if chara_portrait != null:
			chara_portrait.texture = chara.explorationPortrait
		_refresh_portrait_column()
		_update_equipment_icons(chara)
		if compact_stats:
			# Présentation exploration / camp : l'icône dit la stat.
			for pair in [[Att, "attack"], [Def, "defense"], [WillPower, "willpower"]]:
				var lbl: RichTextLabel = pair[0]
				lbl.text = " %d" % chara.stat_breakdown(pair[1]).total
		else:
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
		if buff_row != null:
			buff_row.show_for(chara)
		
		
		
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
	# Le bouton Retour est une large bande au milieu de l'écran : les clics
	# qui font avancer un dialogue ou ferment un tutoriel ne doivent pas le
	# déclencher (retour involontaire à la salle précédente).
	if _screen_busy():
		print("🔙 Retour ignoré (dialogue ou tutoriel à l'écran)")
		return
	print("🔙 Retour vers ", Game_Manager.last_room_Ressource.room_id if Game_Manager.last_room_Ressource else "?")
	Game_Manager.go_back()


func _screen_busy() -> bool:
	if Time.get_ticks_msec() - _ready_msec < 800:
		return true
	if GameState.Pause:
		return true
	var tuto := get_node_or_null("../Intro2") as CanvasItem
	if tuto != null and tuto.visible:
		return true
	for c in Game_Manager.get_children():
		if c is HistorySceneOverlay:
			return true
	return false


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
	# Le zoom démarre avec le pas du personnage et dure jusqu'au peek.
	_peek_zoom_in()
	await _tween_chara(selected_node, target_pos, selected_node.scale)

	# Une fois EN PLACE devant la porte, le personnage prend sa pose de peek.
	# Le sprite reste ainsi pendant la pause de lecture puis toute la duree du
	# peek, jusqu'au premier pas du retour (cf. on_peek_exit).
	if is_instance_valid(selected_node) and selected_node.characterData.peek_texture != null:
		selected_node.sprite.texture = selected_node.characterData.peek_texture

	if peek_start_delay > 0.0:
		await get_tree().create_timer(peek_start_delay).timeout
	# La vue de peek recouvre l'écran mais vit dans la scène : la caméra doit
	# être revenue à la normale avant qu'elle n'apparaisse, sinon elle serait
	# zoomée elle aussi. Le saut est invisible, la vue s'ouvre dans la foulée.
	_peek_zoom_snap(false)


func on_peek_exit() -> void:
	if selected_node == null or not is_instance_valid(selected_node):
		return
	# Le sprite d'origine revient AVANT le glissement : le personnage doit
	# avoir repris sa posture normale des qu'il commence a regagner sa place.
	if _peek_rest_texture != null:
		selected_node.sprite.texture = _peek_rest_texture
		_peek_rest_texture = null
	# Sortie du peek : on repart du cadrage zoomé et on dézoome doucement,
	# pendant que le personnage regagne sa place.
	_peek_zoom_snap(true)
	var cam := _door_camera()
	if cam != null:
		cam.reset(peek_zoom_time)
	await _tween_chara(selected_node, _peek_rest_position, _peek_rest_scale)


## Caméra du zoom de peek : celle qui est déjà active dans la scène, la même
## que les autres zooms. On ne change pas la caméra active.
func _door_camera() -> Camera:
	return get_viewport().get_camera_2d() as Camera


## Cadrage zoomé : entre le centre de l'écran et la porte, pour garder les
## personnages en vue tout en rapprochant la porte.
func _peek_zoom_target() -> Vector2:
	var cam := _door_camera()
	var door_center := global_position + size * 0.5
	return cam.base_position.lerp(door_center, 0.5)


func _peek_zoom_in() -> void:
	var cam := _door_camera()
	if cam == null or peek_zoom <= 1.0:
		return
	cam.zoom_to_position(_peek_zoom_target(), cam.baseZoom.x * peek_zoom, peek_zoom_time)


## Place la caméra d'un coup : cadrage zoomé (true) ou normal (false).
func _peek_zoom_snap(zoomed: bool) -> void:
	var cam := _door_camera()
	if cam == null or peek_zoom <= 1.0:
		return
	if zoomed:
		cam.position = _peek_zoom_target()
		cam.zoom = cam.baseZoom * peek_zoom
	else:
		cam.position = cam.base_position
		cam.zoom = cam.baseZoom


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
	# Le sac doit savoir a qui profitent les potions bues depuis ici, et la
	# fiche du personnage doit se rafraichir juste apres. Ce cablage ne
	# depend pas du bouton de bascule : on le fait avant d'en sortir.
	if inventory_panel != null:
		inventory_panel.set_target_provider(func(): return selected_character)
		if not inventory_panel.potion_used.is_connected(_on_potion_used):
			inventory_panel.potion_used.connect(_on_potion_used)
		# Objet équipé depuis le sac : même rafraîchissement de la fiche.
		if not inventory_panel.item_equipped.is_connected(_on_potion_used):
			inventory_panel.item_equipped.connect(_on_potion_used)

	if toggle_button == null:
		return
	map_bag_buttons = MapBagButtons.split(toggle_button, null, null, 88.0)
	# L'ancien fond (IconMap) est une icône de carte AVEC son cadre : il ne
	# peut servir qu'à un bouton. On le retire et chaque bouton reçoit son
	# propre cadre, comme en exploration.
	if icon_map != null:
		icon_map.visible = false
	MapBagButtons.ensure_box(map_bag_buttons.map)
	MapBagButtons.ensure_box(map_bag_buttons.bag)
	# Sous la vue de peek (SubViewportContainer, z 10), au-dessus du sac (z 8).
	map_bag_buttons.map.z_index = 9
	map_bag_buttons.bag.z_index = 9
	map_bag_buttons.map.pressed.connect(_show_inventory.bind(false))
	map_bag_buttons.bag.pressed.connect(_show_inventory.bind(true))
	_apply_map_inventory_view()


func _show_inventory(on: bool) -> void:
	showing_inventory = on
	_apply_map_inventory_view()


## Une potion vient d'etre bue depuis le sac : la fiche du personnage est
## resynchronisee. On n'appelle PAS update_display() sur la silhouette : dans
## la scene porte elle n'a pas de charaUI, donc pas de jauges a mettre a jour.
func _on_potion_used(_potion, target: CharacterData) -> void:
	if selected_character == target:
		# selectCharacter reecrit tous les labels et toutes les jauges.
		var keep_move := move_mode
		move_mode = false
		selectCharacter(target)
		move_mode = keep_move


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
	if inventory_panel:
		inventory_panel.visible = showing_inventory
		if showing_inventory and Game_Manager != null:
			inventory_panel.refresh(Game_Manager.inventory)
	MapBagButtons.set_active(map_bag_buttons, showing_inventory)


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
	_fade_out_scene_buttons()

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


## Boutons de la scène (ENTER, peek, flèches, retour) effacés en fondu au
## début du glissement vers une autre porte : la porte suivante arrive avec
## les siens.
func _fade_out_scene_buttons() -> void:
	var items: Array = [Doortext, peekButton, left_button, right_button, return_button]
	var tween := create_tween().set_parallel(true)
	for item in items:
		if item is CanvasItem and is_instance_valid(item):
			tween.tween_property(item, "modulate:a", 0.0, buttons_fade_time)


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
	_refresh_portrait_column()

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
