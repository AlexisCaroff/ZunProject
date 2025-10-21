extends CampEffect
class_name HealCampkill
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var heal_target_stat: int = Stat.STAMINA
@export var amount: int = 20

func apply(user: CharaCamp, target: CharaCamp):
	match heal_target_stat:
			Stat.STAMINA:
				target.current_stamina = min(target.max_stamina, target.current_stamina + amount)
				target.animate_heal(amount,user)
			Stat.HORNY:
				target.current_horny = max(0, target.current_horny - amount)
				target.animate_heal(amount,user)
			Stat.STRESS:
				target.current_stress = max(0, target.current_stress - amount)
				target.animate_heal(amount,user)
	target.update_display()
