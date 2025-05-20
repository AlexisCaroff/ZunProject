extends SkillEffect
class_name ReduceCooldownEffect

@export var amount: int = 2

func apply(user: Character, target: Character) -> void:
	for skill in target.skills:
		skill.current_cooldown = max(0, skill.current_cooldown - amount)
	print("Cooldown réduit de %d pour %s" % [amount, target.name])
