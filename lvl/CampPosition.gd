extends Node2D
var occupant : CharaCamp
@onready var campement = $"../.."
var skill : CampSkill
var selfoccupant :  Array[CharaCamp]


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
	else :
		campement.changeSelectedCharacter(occupant)

		
