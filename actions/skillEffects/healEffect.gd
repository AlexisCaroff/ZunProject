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
				for tag in Chartarget.characterData.tags:
					if tag == "maso":
						amount+=2
				Chartarget.characterData.current_stamina = min(Chartarget.characterData.max_stamina, Chartarget.characterData.current_stamina + amount)
				Chartarget.animate_heal(amount,user)
			Stat.HORNY:
				Chartarget.characterData.current_horniness = max(0, Chartarget.characterData.current_horniness - amount)
				Chartarget.animate_heal(amount,user)
			Stat.STRESS:
				Chartarget.characterData.current_stress = max(0, Chartarget.characterData.current_stress - amount)
				Chartarget.animate_heal(amount,user)
	Chartarget.update_ui()
	print("%s soigne %s de %s à %s" % [user.characterData.Charaname, amount, heal_target_stat, Chartarget.characterData.Charaname])
