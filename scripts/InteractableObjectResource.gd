extends Resource
class_name InteractableObjectResource

@export var scene: PackedScene              # Scène visuelle de l'objet
@export var dialogue_file: String = "res://dialogue/dialogueTeste.txt"  # res://dialogues/altar.txt
@export var choice_1: InteractableChoice
@export var choice_2: InteractableChoice

## Coffre piégé : un slime peut s'y cacher (cf. GameManager.roll_chest_traps).
##  NEVER  : jamais piégé (objet qui n'est pas un coffre, coffre scénarisé…)
##  RANDOM : tiré au sort en début de partie, dans les limites du donjon
##  ALWAYS : toujours piégé
enum TrapMode { NEVER, RANDOM, ALWAYS }
@export var trap_mode: TrapMode = TrapMode.NEVER
