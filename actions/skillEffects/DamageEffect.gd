extends SkillEffect
class_name DamageEffect

@export var psyDMG: bool = false
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
	if Chartarget.IsDemon && psyDMG:
		amount= amount*2
	Chartarget.take_damage(user, damage_target_stat, amount)
