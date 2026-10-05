class_name RoomResource
extends Resource

@export var room_id: String = ""   # identifiant unique de la salle
@export var position_on_map: int
@export var door_scene: PackedScene
@export var Blocked_door_scene: PackedScene
@export var door_scene_History: HistoryScene
@export var before_combat_Animatic_scene: Animatic
@export var before_combat_scene_History: HistoryScene
@export var combat_scene: PackedScene
@export var Post_combat_scene_History: HistoryScene
@export var exploration_scene: PackedScene
@export var exploration_scene_history: HistoryScene
@export var encounter: Resource  # Encounter.tres
@export var CanCamp: bool = false
@export var connected_room_ids: Array[String] = []
@export var blocked_room_ids: Array[String] = []
@export var explored: bool = false
@export var ennemikilled: bool = false
@export var CampDone: bool = false
@export var interactable: InteractableObjectResource
@export var keyName: String = ""
@export var locked: bool = false
var connected_rooms: Array[String]

# ════════════════════════════════════════════════════════════════════
#  ÉTAT PERSISTANT DE LA SALLE
#  Ces flags survivent au queue_free() de la scène et sont restaurés
#  au prochain chargement. Ne pas les exposer comme @export sauf si
#  tu veux pouvoir pré-régler une salle déjà "vue" dans l'inspecteur.
# ════════════════════════════════════════════════════════════════════

## True une fois que l'historyScene de l'exploration a été lue.
var exploration_history_played: bool = false
## Idem pour les autres histories (ajoute selon tes besoins).
var door_history_played: bool = false
var before_combat_history_played: bool = false
var post_combat_history_played: bool = false

## True quand le joueur a déjà interagi avec l'objet de la salle
## (coffre fouillé, etc.) → bouton disabled au prochain chargement.
var interactable_used: bool = false
## True si l'interaction a fait passer le sprite à l'état "ouvert".
var interactable_opened: bool = false


## Reset complet de l'état runtime — à appeler au début d'une nouvelle
## partie (sinon les flags persistent entre runs en éditeur car les
## Resources restent en mémoire).
func reset_runtime_state() -> void:
	explored = false
	ennemikilled = false
	CampDone = false
	exploration_history_played = false
	door_history_played = false
	before_combat_history_played = false
	post_combat_history_played = false
	interactable_used = false
	interactable_opened = false
