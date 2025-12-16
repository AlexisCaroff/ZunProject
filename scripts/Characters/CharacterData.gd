extends Resource
class_name CharacterData

@export var portrait_texture: Texture2D
@export var explorationPortrait:Texture2D
@export var dead_portrait_texture: Texture2D
@export var Hit_texture: Texture2D
@export var initiative_icon: Texture2D
@export var Dialogue_texture: Texture2D
@export var textureCamp: Texture2D
@export var Name : String = "name"
@export var Charaname: String = "Classe"
@export var IsDemon: bool = false
# ---- Affinity
@export var affinity: Dictionary[String, int] = {}
# --- Stats de combat
@export var base_max_stamina: int = 100
@export var base_max_stress: int = 100
@export var base_max_horniness: int = 100

@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_willpower: int = 5
@export var base_initiative: int = 1
@export var base_evasion: int = 5
@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var evasion: int = 5
@export var initiative: int = 1
@export var peek :int =0
@export var equipped_items: Array[Equipment] = []



#etat
@export var stun : bool = false

@export var Chara_position:int = 0 


# --- Jauges
@export var max_stamina: int = 100
@export var max_stress: int = 100
@export var max_horniness: int = 100

@export var current_stamina: int = 100
@export var current_stress: int = 0
@export var current_horniness: int = 0



@export var skill_resources: Array[Resource] = []
# --- Tags (type, classe, etc.)
@export var tags: Array[String] = []
#combat

# --- Contrôle
@export var is_player_controlled: bool = true
@export var ai_brain: AiBrain
@export var can_be_moved : bool = true

@export var min_durationIddle: float = 0.6
@export var max_durationIddle: float = 1.0
@export var min_scale: float = 0.95
@export var max_scale: float = 1.0


var acte_twice : bool =false
@export var camp_skill_resources: Array[CampSkill] = []
@export var bark_scene: PackedScene = preload("res://UI/bark.tscn")
@export var taunts := [
	"Is that all you've got?",
	"Try harder!",
	"Pathetic!",
	"You're wide open!",
	"You fight like a wet noodle!",
	"Oops! Did that hurt?",
	
]
var buffs: Array[Buff] = []
var current_bark: Bark = null
