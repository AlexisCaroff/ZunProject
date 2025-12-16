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
				target.characterData.current_stamina = min(target.characterData.max_stamina, target.characterData.current_stamina + amount)
				target.animate_heal(amount,user)
			Stat.HORNY:
				target.characterData.current_horniness = max(0, target.characterData.current_horniness - amount)
				target.animate_heal(amount,user)
			Stat.STRESS:
				target.characterData.current_stress = max(0, target.characterData.current_stress - amount)
				target.animate_heal(amount,user)
	target.update_display()
