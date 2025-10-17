extends SkillEffect
class_name PainAndAbsolution

@export var MagicDMG: bool = false
@export var DMGamount: int = 20
@export var healamount: int = 20
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var damage_target_stat: int = Stat.STAMINA
enum healStat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var heal_target_stat: int = healStat.STAMINA
var Chartarget:Character


func apply(user: Character, target: PositionSlot) -> void:
	Chartarget = target.occupant
	if Chartarget.is_player_controlled:
		match heal_target_stat:
			healStat.STAMINA:
				Chartarget.animate_heal(healamount,user)
				Chartarget.current_stamina = min(Chartarget.max_stamina, Chartarget.current_stamina + healamount)
			healStat.HORNY:
				Chartarget.animate_heal(healamount,user, Color.PURPLE)
				Chartarget.current_horniness = max(0, Chartarget.current_horniness - healamount)
			healStat.STRESS:
				Chartarget.animate_heal(healamount,user)
				Chartarget.current_stress = max(0, Chartarget.current_stress - healamount)
		Chartarget.update_ui()
	else:
		if Chartarget.IsDemon && MagicDMG:
			DMGamount= DMGamount*2
		if Chartarget.IsDemon && !MagicDMG:
			DMGamount= DMGamount/2.0
		Chartarget.take_damage(user, damage_target_stat, DMGamount+user.base_attack-Chartarget.base_defense,MagicDMG)
