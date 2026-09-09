extends Node
class_name GameManager

@export var donjon: DonjonResource
var room_container: Node
var current_room_Ressource: RoomResource
@export var TheRoom_we_are_in : RoomResource
@export var LastRoom_we_were_in :RoomResource
@export var last_room_Ressource: RoomResource
@export var current_room_node: Node
@export_file("*.tscn") var campement_scene_path: String = "res://lvl/campement.tscn"
var campement_node: Node = null
@onready var end =$endGame
@export var inventory: Array[Equipment] = []
@export var characters: Array[CharacterData] = []
@onready var sceneTransition = $SceneTransition
@export var start_menu_scene: PackedScene = preload("res://UI/menuBase.tscn")
@export var teamCorrupted = false
var start_menu: StartMenu = null
var game_started: bool = false
var combat_just_ended: bool = false

# ── Sauvegarde ────────────────────────────────────────────────────────
## Nature de la scène actuellement chargée, cf. les constantes SCENE_* de
## SaveManager. C'est elle qui dit au chargement quoi ré-instancier : la
## phase de GameState ne suffit pas (une porte est marquée EXPLORATION).
var current_scene_kind: String = ""
## Dernière position du pointeur d'équipe sur la mini-carte. La carte est
## ré-instanciée à chaque scène : sans cette mémoire, le pointeur repartirait
## de sa position d'origine au lieu de glisser depuis la salle précédente.
## Vector2.INF = pas encore posé, il apparaît alors sans animation.
var map_pointer_position: Vector2 = Vector2.INF
## Sauvegarde automatique dans le slot 0 à chaque changement de scène.
@export var autosave_enabled: bool = true
@onready var save_menu: SaveMenu = $SaveMenu

func _ready():
	var screen_index := 0
	
	if screen_index < DisplayServer.get_screen_count():
		DisplayServer.window_set_current_screen(screen_index)
	
	if not room_container:
		room_container = Node2D.new()
		add_child(room_container)
	
	
	# Les Resources (.tres) gardent en mémoire les mutations de la session
	# précédente. On les remet à plat AVANT de photographier l'état d'origine,
	# qui sert ensuite de base propre aux nouvelles parties et aux chargements.
	if donjon != null:
		for room: RoomResource in donjon.rooms:
			room.reset_runtime_state()
	initialize_affinities(characters)
	SaveManager.capture_pristine(self)

	if save_menu:
		save_menu.hide_menu()
	await sceneTransition.fade_in()

func spawn_start_menu():
	if start_menu_scene == null:
		push_error("❌ Start menu scene not set")
		return

	start_menu = start_menu_scene.instantiate()
	add_child(start_menu)

	start_menu.game_manager = self
	
	
func start_game():
	if game_started:
		return
 
	game_started = true
 
	# Repart de l'état d'origine des Resources (salles ET personnages) : sans
	# ça, une nouvelle partie hérite des jauges et des affinités de la précédente.
	SaveManager.restore_pristine(self)
	SaveManager.delete_slot(SaveManager.AUTO_SLOT)
	map_pointer_position = Vector2.INF
 
	await sceneTransition.fade_out()
	if start_menu and is_instance_valid(start_menu):
		start_menu.queue_free()
		start_menu = null
 
	if donjon and donjon.start_room_id != "":
		var start_room = get_room_by_id(donjon.start_room_id)
 
		if start_room:
			current_room_Ressource = start_room
			call_deferred("_enter_scene_in_current_room", start_room.exploration_scene)
		else:
			push_error("❌ Start room introuvable pour ID : " + donjon.start_room_id)
 
			
		
## `skip_fade` : la scène porte enchaîne elle-même un glissement de décor
## avant d'appeler enter_room ; un fondu par-dessus casserait le raccord.
func enter_room(room: RoomResource, changedoor: bool = false, skip_fade: bool = false):
	if not changedoor:
		last_room_Ressource = current_room_Ressource
	current_room_Ressource = room
 
	# Une porte n'est pas du combat — on remet la phase à EXPLORATION.
	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	current_scene_kind = SaveManager.SCENE_DOOR

	print("🏰 Current room is ", current_room_Ressource.room_id)
	if not skip_fade:
		await sceneTransition.fade_out()
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null
 
	var scene_to_load: PackedScene = null
	if room.door_scene:
		scene_to_load = room.door_scene
		print("🔓 Load door scene : " + scene_to_load.resource_name)
 
	if scene_to_load:
		var new_scene = scene_to_load.instantiate()
		room_container.add_child(new_scene)
		current_room_node = new_scene
	if not skip_fade:
		await sceneTransition.fade_in()
 
	if room.door_scene_History != null and not room.door_history_played:
		print("📖 Door history pour ", room.room_id)
		show_history_scene(room.door_scene_History)
		room.door_history_played = true

	autosave()
 


func go_back() -> void:
	if last_room_Ressource == null:
		push_warning("go_back : aucune salle précédente enregistrée.")
		return
	if last_room_Ressource.exploration_scene == null:
		push_error("go_back : %s n'a pas d'exploration_scene." % last_room_Ressource.room_id)
		return
 
	await sceneTransition.fade_out()
 
	current_room_Ressource = last_room_Ressource
	TheRoom_we_are_in      = last_room_Ressource
 
	# On revient à de l'exploration → reset de phase.
	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	current_scene_kind = SaveManager.SCENE_EXPLORATION

	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null
 
	var new_scene = current_room_Ressource.exploration_scene.instantiate()
	room_container.add_child(new_scene)
	current_room_node = new_scene
 
	print("↩️ Retour à l'exploration de ", current_room_Ressource.room_id)
	await sceneTransition.fade_in()
	autosave()
	
	
# 🔍 Retourne une RoomResource depuis son ID
func get_room_by_id(room_id: String) -> RoomResource:
	for r in donjon.rooms:
		if r.room_id == room_id:
			return r
	return null


func go_to_connected_room(index: int):
	if not current_room_Ressource:
		push_error("❌ Current room undefined.")
		return

	if index < 0 or index >= current_room_Ressource.connected_room_ids.size():
		push_error("❌ Invalid room index")
		return

	var next_room_id = current_room_Ressource.connected_room_ids[index]
	var next_room = get_room_by_id(next_room_id)
	if not next_room:
		push_error("❌ Connected room introuvable pour ID : " + next_room_id)
		return

	enter_room(next_room)


func _enter_scene_in_current_room(scene: PackedScene, ennemy_are_embushed: bool = false, heroes_are_embushed: bool = false):
	if TheRoom_we_are_in != current_room_Ressource:
		LastRoom_we_were_in = TheRoom_we_are_in
		TheRoom_we_are_in = current_room_Ressource
	current_room_Ressource.explored = true
	var cellar := get_room_by_id("Cellar")
	if cellar != null and cellar.ennemikilled == true:
		end.visible = true

	# Détermine la phase en fonction de la scène chargée.
	var loading_combat := current_room_Ressource.combat_scene \
			and scene == current_room_Ressource.combat_scene \
			and current_room_Ressource.ennemikilled == false
	GameState.current_phase = GameStat.GamePhase.COMBAT if loading_combat else GameStat.GamePhase.EXPLORATION
	current_scene_kind = SaveManager.SCENE_COMBAT if loading_combat else SaveManager.SCENE_EXPLORATION

	await sceneTransition.fade_out()
	if scene:
		if current_room_node:
			print("old scene is ", current_room_node.name)
			print("free old room")
			current_room_node.free()
			current_room_node = null
 
		var new_scene
		if loading_combat:
			new_scene = scene.instantiate()
			var combat_manager = new_scene.find_child("CombatManager", true, false)
			if combat_manager:
				combat_manager.encounter = current_room_Ressource.encounter
				combat_manager.ennemy_are_ambushed = ennemy_are_embushed
				combat_manager.heroes_are_ambushed = heroes_are_embushed
				print("⚔️ Encounter assigned to CombatManager")
			else:
				push_error("⚠️ CombatManager introuvable dans la scène de combat")
		else:
			new_scene = current_room_Ressource.exploration_scene.instantiate()
 
		room_container.add_child(new_scene)
		current_room_node = new_scene
		print("Start new room: ", new_scene.name)
		await sceneTransition.fade_in()
	autosave()

func go_to_campement():
	await sceneTransition.fade_out()
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

	GameState.current_phase = GameStat.GamePhase.CAMP
	current_scene_kind = SaveManager.SCENE_CAMP
	var campement_scene: PackedScene = load(campement_scene_path)
	campement_node = campement_scene.instantiate()
	room_container.add_child(campement_node)
	await sceneTransition.fade_in()
	autosave()

func return_to_exploration():
	await sceneTransition.fade_out()
 
	# Sortie du camp = retour en exploration.
	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	current_scene_kind = SaveManager.SCENE_EXPLORATION

	if campement_node and is_instance_valid(campement_node):
		campement_node.queue_free()
		campement_node = null
 
	var scene_to_load: PackedScene = null
	if current_room_Ressource and current_room_Ressource.exploration_scene:
		scene_to_load = current_room_Ressource.exploration_scene
 
	if scene_to_load:
		var new_scene = scene_to_load.instantiate()
		room_container.add_child(new_scene)
		current_room_node = new_scene
		var exploManager = new_scene.get_node("ExplorationManager") as ExplorationManager

	await sceneTransition.fade_in()
	autosave()

#------------------------------------------------------
signal inventory_changed
## Charge une scène arbitraire hors du flux salle-par-salle (branches du boss).
## Pas d'autosave ici : la scène chargée n'est pas celle référencée par la
## RoomResource, un chargement rejouerait donc le combat de la salle depuis son
## intro — ce qui reste cohérent, mais ne mérite pas d'écraser l'autosave.
func load_scene_direct(scene: PackedScene, encounter: CombatEncounter = null) -> void:
	current_scene_kind = SaveManager.SCENE_COMBAT
	await sceneTransition.fade_out()
 
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.free()
		current_room_node = null
 
	var new_scene = scene.instantiate()
 
	# Si un encounter est fourni, on le passe au CombatManager de la scène
	if encounter != null:
		var combat_manager = new_scene.find_child("CombatManager", true, false)
		if combat_manager:
			combat_manager.encounter = encounter
		else:
			push_error("load_scene_direct : CombatManager introuvable dans la scène.")
 
	room_container.add_child(new_scene)
	current_room_node = new_scene
	await sceneTransition.fade_in()
	
func add_to_inventory(item: Equipment):
	inventory.append(item)
	emit_signal("inventory_changed", item)
	print ("add "+ item.name+" to inventory")
	for i in inventory:
		print ( i.name + " is in Inventory GM ")

func initialize_affinities(thecharacters: Array[CharacterData]):
	for chara in thecharacters:
		chara.affinity = {}
		for other in thecharacters:
			if other != chara:
				chara.affinity[other.Charaname] = 0
	
func show_history_scene(history_res: HistoryScene) -> Node:
	var overlay_scene := preload("res://scripts/History/history.tscn")
	var overlay := overlay_scene.instantiate()

	overlay.history_scene = history_res
	get_tree().current_scene.add_child(overlay)

	return overlay
func show_Animatic_scene(Anim: Animatic, cam: Camera) -> Node:
	var Animatic_scene := preload("res://animatic/animatic_scene.tscn")
	var overlay := Animatic_scene.instantiate()
	
	overlay.animatic = Anim
	#overlay.cam=cam
	get_tree().current_scene.add_child(overlay)

	return overlay


# ════════════════════════════════════════════════════════════════════
#  SAUVEGARDE / CHARGEMENT
# ════════════════════════════════════════════════════════════════════

## Sauvegarde automatique, appelée à la fin de chaque transition de scène.
func autosave() -> void:
	if not autosave_enabled or not game_started:
		return
	SaveManager.save_to_slot(SaveManager.AUTO_SLOT, self)


## Sauvegarde manuelle dans un slot choisi par le joueur.
func save_to_slot(slot: int) -> bool:
	return SaveManager.save_to_slot(slot, self)


## Restaure une partie et charge la scène correspondante.
## Le combat éventuellement en cours au moment de la sauvegarde est rejoué
## depuis son début : seul l'état persistant (party, inventaire, donjon) est
## restitué, jamais le déroulé d'un tour.
func load_game(slot: int) -> bool:
	var data: Dictionary = SaveManager.read_slot(slot)
	if data.is_empty():
		push_error("❌ Slot %d vide ou illisible." % slot)
		SaveManager.load_finished.emit(slot, false)
		return false

	if save_menu:
		save_menu.hide_menu()

	# On repart de l'état d'origine pour que tout ce que la sauvegarde ne
	# couvre pas (partie en cours, run précédent) soit effacé.
	SaveManager.restore_pristine(self)
	if not SaveManager.apply_state(data, self):
		push_error("❌ Chargement du slot %d impossible." % slot)
		SaveManager.load_finished.emit(slot, false)
		return false

	game_started = true
	combat_just_ended = false
	# Le pointeur se repose directement sur la salle chargée, sans traverser
	# la carte depuis là où il était avant le chargement.
	map_pointer_position = Vector2.INF

	await sceneTransition.fade_out()
	if start_menu and is_instance_valid(start_menu):
		start_menu.queue_free()
		start_menu = null
	if campement_node and is_instance_valid(campement_node):
		campement_node.queue_free()
		campement_node = null
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null
	await get_tree().process_frame

	_restore_scene(str(data.get("scene_kind", SaveManager.SCENE_EXPLORATION)))
	print("📂 Partie chargée depuis le slot %d" % slot)
	SaveManager.load_finished.emit(slot, true)
	return true


## Ré-instancie la scène correspondant à la nature enregistrée. Chaque branche
## délègue aux fonctions de transition existantes pour garder un seul chemin de
## câblage (encounter du CombatManager, fades, phase de jeu).
func _restore_scene(kind: String) -> void:
	if current_room_Ressource == null:
		push_warning("Chargement : salle inconnue, repli sur la salle de départ.")
		current_room_Ressource = get_room_by_id(donjon.start_room_id) if donjon else null
		if current_room_Ressource == null:
			push_error("❌ Impossible de restaurer une salle.")
			await sceneTransition.fade_in()
			return

	var room := current_room_Ressource
	if kind == SaveManager.SCENE_CAMP:
		if room.CanCamp:
			await go_to_campement()
			return
		push_warning("Chargement : camp impossible dans %s, repli sur l'exploration." % room.room_id)

	elif kind == SaveManager.SCENE_DOOR:
		if room.door_scene:
			# changedoor=true pour ne pas écraser la salle précédente
			# restaurée depuis la sauvegarde.
			await enter_room(room, true)
			return
		push_warning("Chargement : %s n'a pas de door_scene, repli sur l'exploration." % room.room_id)

	elif kind == SaveManager.SCENE_COMBAT:
		if room.combat_scene and not room.ennemikilled:
			await _enter_scene_in_current_room(room.combat_scene)
			return
		# Combat déjà gagné entre-temps : on retombe sur l'exploration.

	if room.exploration_scene == null:
		push_error("❌ %s n'a pas d'exploration_scene, chargement impossible." % room.room_id)
		await sceneTransition.fade_in()
		return
	await _enter_scene_in_current_room(room.exploration_scene)


## Ouvre l'écran de sauvegarde (bouton du GameManager).
func open_save_menu() -> void:
	if save_menu:
		save_menu.open(SaveMenu.Mode.SAVE)


## Ouvre l'écran de chargement (menu principal).
func open_load_menu() -> void:
	if save_menu:
		save_menu.open(SaveMenu.Mode.LOAD)
