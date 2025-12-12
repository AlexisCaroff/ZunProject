extends Equipment
class_name SilkGloves
@export var malusHorny: int = 1
func on_skill_use(user: Character, skill: Skill, _target: Character):
	if skill.name != "move":
		user.take_damage(user,1,malusHorny,false)
