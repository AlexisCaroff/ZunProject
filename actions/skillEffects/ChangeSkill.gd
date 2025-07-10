extends SkillEffect
class_name ChangeSkill

@export var updated_skills: Array[Resource]


func apply(user: Character, target: PositionSlot) -> void:
	user._updateSkills(updated_skills)
