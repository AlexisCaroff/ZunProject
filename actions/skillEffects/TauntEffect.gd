extends SkillEffect
class_name SkillEffect_Taunt

@export var duration: int = 1  # nombre de tours pendant lesquels la cible est provoquée

func apply(source: Character, target: Character):
	if target == null:
		return

	target.taunted_by = source
	target.taunt_duration = duration

	
		
