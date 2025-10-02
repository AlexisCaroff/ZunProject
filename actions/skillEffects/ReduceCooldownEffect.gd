extends SkillEffect
class_name ReduceCooldownEffect
var Chartarget:Character
@export var amount: int = 2

func apply(user: Character, target: PositionSlot) -> void:
	
	Chartarget=target.occupant
	
	for skill in Chartarget.skills:
		skill.current_cooldown = max(0, skill.current_cooldown - amount)
		print("Cooldown  %s pour %s réduit" % [skill.name, Chartarget.Charaname])
