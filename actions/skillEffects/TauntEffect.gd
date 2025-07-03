extends SkillEffect
class_name SkillEffect_Taunt
var Chartarget:Character
@export var duration: int = 1  # nombre de tours pendant lesquels la cible est provoquée

func apply(source: Character, target: PositionSlot):
	Chartarget = target.occupant
	
	if Chartarget == null:
		return

	Chartarget.taunted_by = source
	Chartarget.taunt_duration = duration

	
		
