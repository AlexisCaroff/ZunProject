extends SkillEffect
class_name DamageEffect

@export var amount: int = 20
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var damage_target_stat: int = Stat.STAMINA

func apply(user: Character, target: Character) -> void:
	target.take_damage(user, damage_target_stat, amount)
