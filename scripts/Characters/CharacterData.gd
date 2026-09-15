extends Resource
class_name CharacterData
@export var headPosition: Vector2= Vector2(1.0,-310.0)
@export var torso_Position  : Vector2  = Vector2(0.0,0.0)
@export var portrait_texture: Texture2D
@export var explorationPortrait:Texture2D
@export var dead_portrait_texture: Texture2D
@export var Hit_texture: Texture2D
@export var initiative_icon: Texture2D
@export var Dialogue_texture: Texture2D
@export var textureCamp: Texture2D
## Sprite affiché pendant que le personnage est posté devant la porte en
## mode peek. Null = on garde le sprite courant.
@export var peek_texture: Texture2D

@export var Name : String = "name"
@export var Charaname: String = "Classe"
@export var IsDemon: bool = false
@export var size : String= "average"

# ════════════════════════════════════════════════════════════════════
#  GENRE & ATTIRANCE
# ════════════════════════════════════════════════════════════════════
#  `presentation` est FIXE : elle se règle à la main dans l'inspecteur et
#  ne se tire jamais au sort, parce que les scènes d'amour sont dessinées
#  avec des corps précis.
#
#  `attracted_to_*` est TIRÉ au début de chaque partie par le menu
#  TasteRollMenu (res://UI/taste_roll_menu.tscn). Au moins l'un des deux
#  est vrai : personne n'est attiré par rien.
#
#  Deux personnages peuvent coucher ensemble si l'attirance est
#  RÉCIPROQUE — voir is_compatible_with().
# ════════════════════════════════════════════════════════════════════

enum Presentation { FEMININE, MASCULINE, ANDROGYNOUS }

## Comment ce personnage est perçu par les autres. À régler par personnage
## dans l'inspecteur ; ANDROGYNOUS séduit les deux camps.
@export var presentation: Presentation = Presentation.FEMININE

@export_group("Attirance (tirée en début de partie)")
@export var attracted_to_feminine: bool = true
@export var attracted_to_masculine: bool = false
@export_group("")

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
@export var base_precision: int = 100
var precision: int = 100        # recalculé chaque update_stats

@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var evasion: int = 5
@export var initiative: int = 1
@export var peek :int =0
@export var equipped_items: Array[Equipment] = []



#etat
@export var stun : bool = false
@export var grab : bool  = false
@export var Chara_position:int = 0 


# --- Jauges
@export var max_stamina: int = 100
@export var max_stress: int = 100
@export var max_horniness: int = 100

@export var current_stamina: int = 100
@export var current_stress: int = 0
@export var current_horniness: int = 0

@export var isOneshot : bool= false

@export var skill_resources: Array[Resource] = []

@export var exploration_skill_resources: Array[ExplorationSkill] = []
# --- Tags (type, classe, etc.)
@export var tags: Array[String] = []
@export var assist: String = ""
#combat

# --- Contrôle
@export var is_player_controlled: bool = true
@export var ai_brain: AiBrain
@export var can_be_moved : bool = true

@export var min_durationIddle: float = 0.6
@export var max_durationIddle: float = 1.0
@export var min_scale: float = 0.95
@export var max_scale: float = 1.0
@export var corruption: int = 0

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
@export var reaction := [
	"",
	"",
	""
]
@export var affinityReaction := [
	"",
	"",
	""
]
var buffs: Array[Buff] = []
var current_bark: Bark = null
@export var corrupted: bool  = false
@export var inquisition :bool  = false
@export var immobilized: bool  = false
@export var immobilized_turns: int = 0


# ════════════════════════════════════════════════════════════════════
#  ATTIRANCE — API
# ════════════════════════════════════════════════════════════════════

## Ce personnage est-il attiré par `other` ? Sens unique.
func is_attracted_to(other: CharacterData) -> bool:
	if other == null:
		return false
	match other.presentation:
		Presentation.FEMININE:
			return attracted_to_feminine
		Presentation.MASCULINE:
			return attracted_to_masculine
		Presentation.ANDROGYNOUS:
			return attracted_to_feminine or attracted_to_masculine
	return false


## Attirance réciproque : la condition pour une scène d'amour.
func is_compatible_with(other: CharacterData) -> bool:
	if other == null or other == self:
		return false
	return is_attracted_to(other) and other.is_attracted_to(self)


## Applique un tirage. Garantit qu'au moins une des deux attirances est
## vraie — un personnage attiré par rien serait injouable côté romance.
func set_taste(feminine: bool, masculine: bool) -> void:
	if not feminine and not masculine:
		feminine = true
	attracted_to_feminine = feminine
	attracted_to_masculine = masculine


## Tire une attirance au sort. `bi_chance` est la probabilité d'être
## attiré par les deux ; le reste se partage à parts égales.
func roll_taste(bi_chance: float = 0.25) -> void:
	if randf() < bi_chance:
		set_taste(true, true)
	elif randf() < 0.5:
		set_taste(true, false)
	else:
		set_taste(false, true)


## Libellé court, pour les tooltips et le journal.
func taste_label() -> String:
	if attracted_to_feminine and attracted_to_masculine:
		return "Bi"
	if attracted_to_feminine:
		return "Feminine attracted"
	if attracted_to_masculine:
		return "Masculine attracted"
	return "—"
