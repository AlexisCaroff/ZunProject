extends SkillEffect
class_name DamageEffect

@export var MagicDMG: bool = false
@export var amount: int = 20
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var damage_target_stat: int = Stat.STAMINA
var Chartarget:Character


func apply(user: Character, target: PositionSlot) -> void:
	Chartarget = target.occupant
	if Chartarget != null:
		# Copie locale : la ressource est partagee par tous les lancers du
		# skill, modifier `amount` divisait les degats a chaque coup sur un demon.
		var final_amount: int = amount
		if Chartarget.characterData.IsDemon && MagicDMG:
			final_amount = amount*2

		if Chartarget.characterData.IsDemon && !MagicDMG:
			final_amount = int(amount/2.0)
		Chartarget.take_damage(user, damage_target_stat, final_amount,MagicDMG)
