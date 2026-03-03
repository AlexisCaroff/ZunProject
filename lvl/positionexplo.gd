extends Node2D
class_name ExplorationPosition
var occupant: CharaExplo = null
@onready var explo_manager =$"../../ExplorationManager"
@onready var button =$Button
@onready var movebutton =$"../../moveButton"
@onready var charaUI=$charaUI

func _on_button_button_down() -> void:
	explo_manager.selectCharacter(occupant)
	
func _ready() -> void:
	button.connect("mouse_entered", showMove)
	button.connect("mouse_exited", hideMove)
	movebutton.visible=false
	
func showMove():
	if !explo_manager.move_mode:
		movebutton.position= Vector2(self.global_position.x-40, (self.global_position.y-340) )
		movebutton.visible=true
	explo_manager.over_chara = occupant
func hideMove():
	movebutton.visible=false
func set_occupant(chara : CharaExplo):
	occupant = chara
	occupant.hornyJauge=charaUI.HornyBar
	occupant.hp_Jauge = charaUI.HPProgressBar
	chara.global_position = self.global_position
	occupant.CharaPosition=self
	occupant.z_index=self.z_index
	occupant.update_display()
	print ("set "+occupant.characterData.Charaname)
