extends Resource
class_name Animatic

## Liste ordonnée des frames
@export var frames: Array[AnimaticFrame]

## Durée du fondu enchaîné en secondes
@export var fade_duration: float = 1.0

## Durée d'affichage de la dernière frame après la fin de son audio
@export var final_hold_time: float = 2.0

## Si true, avance automatiquement quand l'audio est fini (sinon attend un clic)
@export var auto_advance: bool = true
