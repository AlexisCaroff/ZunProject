extends SkillEffect
class_name BuffEffect

enum Stat {
	ATTACK,
	DEFENSE,
	SPEED,
	STRESS_RESIST,
	HORNY_RESIST
}

@export_enum("ATTACK", "DEFENSE", "SPEED", "STRESS_RESIST", "HORNY_RESIST")
var affected_stat: int = Stat.ATTACK

@export var amount: int = 5
@export var duration: int = 3  # en tours

func apply(user: Character, target: Character) -> void:
	var buff := Buff.new()
	buff.stat = affected_stat
	buff.amount = amount
	buff.duration = duration
	buff.name = "Bonus de %s" % Buff.Stat.keys()[affected_stat]
	buff.description = "Augmente %s de %d pendant %d tours." % [
		Buff.Stat.keys()[affected_stat],
		amount,
		duration
	]

	target.add_buff(buff)

	print("%s reçoit +%d %s pendant %d tours" % [
		target.name,
		amount,
		Buff.Stat.keys()[affected_stat],
		duration
	])
