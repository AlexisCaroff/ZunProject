extends Node2D
class_name ExplorationPosition
var occupant: CharaExplo = null
@onready var explo_manager =$"../../ExplorationManager"
@onready var button =$Button
@onready var charaUI=$charaUI

func _on_button_button_down() -> void:
	if occupant != null:
		explo_manager.selectCharacter(occupant)

func _ready() -> void:
	button.connect("mouse_entered", _on_chara_hovered)
	button.connect("mouse_exited", _on_chara_unhovered)

# Le déplacement passait par un noeud "moveButton" qui n'existe pas dans
# explorationInterface.tscn : $"../../moveButton" renvoyait null et faisait
# planter _ready() puis chaque survol. Il est remplacé par le mode
# déplacement du bouton ExploSkillButtonMove (cf. ExplorationManager).
func _on_chara_hovered():
	explo_manager.over_chara = occupant

func _on_chara_unhovered():
	if explo_manager.over_chara == occupant:
		explo_manager.over_chara = null
## Placement instantane (chargement de la salle).
func set_occupant(chara : CharaExplo):
	_bind_occupant(chara)
	chara.global_position = self.global_position


## Placement anime : le personnage glisse jusqu'au slot au lieu d'y etre
## teleporte, comme PositionSlot.assign_character() en combat.
func assign_character(chara: CharaExplo, movetime: float) -> void:
	_bind_occupant(chara)
	if movetime <= 0.0:
		chara.global_position = self.global_position
		return
	var tween := get_tree().create_tween()
	tween.tween_property(chara, "global_position", self.global_position, movetime) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if is_instance_valid(chara):
		chara.global_position = self.global_position


## Rattache le personnage au slot (jauges, buff bar, profondeur). Commun aux
## deux placements ; execute AVANT le glissement, comme en combat, pour que
## l'etat logique soit a jour des le debut de l'animation.
func _bind_occupant(chara: CharaExplo) -> void:
	charaUI = $charaUI
	occupant = chara
	occupant.hornyJauge = charaUI.HornyBar
	occupant.hp_Jauge = charaUI.HPProgressBar
	occupant.LustProgressBar = charaUI.LustProgressBar
	occupant.buff_bar = charaUI.buff_bar
	occupant.CharaPosition = self
	occupant.z_index = self.z_index
	occupant.update_display()
