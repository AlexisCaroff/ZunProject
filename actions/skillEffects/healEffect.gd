extends SkillEffect
class_name HealEffect
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var heal_target_stat: int = Stat.STAMINA
@export var amount: int = 20

func apply(user: Character, target: Character) -> void:
	match heal_target_stat:
			Stat.STAMINA:
				target.current_stamina = min(target.max_stamina, target.current_stamina + amount)
			Stat.HORNY:
				target.current_horniness = max(0, target.current_horniness - amount)
			Stat.STRESS:
				target.current_stress = max(0, target.current_stress - amount)
	target.update_ui()
	print("%s soigne %s de %s à %s" % [user.name, amount, heal_target_stat, target.name])
