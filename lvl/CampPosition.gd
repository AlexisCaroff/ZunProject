extends Node2D
class_name CampPosition
var occupant : CharaCamp
@onready var campement = $"../.."
var skill : CampSkill
var selfoccupant :  Array[CharaCamp]
@onready var button =$Button
@onready var ui=$charaCombatUI
func _ready() -> void:
	button.connect("mouse_entered",over)
	button.connect("mouse_exited",out)
func _on_button_button_down() -> void:
	if occupant.targetable:
		skill= campement.skillused
		
		selfoccupant.clear()
		selfoccupant.append(occupant)
		match skill.target_type:
			CampSkill.TargetType.SELF:
				skill.use(campement.selected_chara,selfoccupant)
			CampSkill.TargetType.ALLY:
				skill.use(campement.selected_chara,selfoccupant)
		campement.noCharacterSelected()
		campement.exitButton.visible=false
	else :
		campement.changeSelectedCharacter(occupant)
func get_ui()-> CharaUi:
	print("send " + ui.name)
	ui=$charaCombatUI
	return ui

func over():
	
	occupant.Selector.visible = true
func out():
	occupant.Selector.visible = false
