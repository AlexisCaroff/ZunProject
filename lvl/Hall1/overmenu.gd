extends ColorRect
## Panneau « fiche personnage » du coin bas-droit du combat. Il partage le
## coin avec la carte et le sac d'équipe : ui_combat.gd règle lequel des
## trois est affiché, et garde les trois boutons au-dessus de tout (leur
## profondeur n'est plus modifiée ici — la passer à -1 les cachait sous le
## sac).
@onready var buttonChara =  $"../ContourMap/ButtonCharainfo"
@onready var buttonMap = $"../ContourMap/ButtonMap"

func _ready() -> void:
	buttonChara.connect("button_down",showChara)
	buttonMap.connect("button_down",showMap)

func showChara():
	self.visible = true

func showMap():
	self.visible=false
