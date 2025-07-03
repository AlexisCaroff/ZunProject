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
var Chartarget:Character


func apply(user: Character, target: PositionSlot) -> void:
	Chartarget = target.occupant
	match heal_target_stat:
			Stat.STAMINA:
				Chartarget.current_stamina = min(Chartarget.max_stamina, Chartarget.current_stamina + amount)
			Stat.HORNY:
				Chartarget.current_horniness = max(0, Chartarget.current_horniness - amount)
			Stat.STRESS:
				Chartarget.current_stress = max(0, Chartarget.current_stress - amount)
	Chartarget.update_ui()
	print("%s soigne %s de %s à %s" % [user.name, amount, heal_target_stat, Chartarget.name])
