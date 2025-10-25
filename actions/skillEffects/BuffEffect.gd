extends SkillEffect
class_name BuffEffect

enum Stat {
	ATTACK,
	DEFENSE,
	SPEED,
	STRESS_RESIST,
	HORNY_RESIST
}
@export var name = "name" 
@export var uitexture: Texture2D = null
@export_enum("ATTACK", "DEFENSE", "SPEED", "STRESS_RESIST", "HORNY_RESIST")
var affected_stat: int = Stat.ATTACK

@export var amount: int = 5
@export var duration: int = 3  # en tours

func apply(user: Character, target: PositionSlot) -> void:
	var buff := Buff.new()
	buff.stat = affected_stat
	buff.icon=uitexture
	buff.amount = amount
	buff.duration = duration
	buff.name = name
	buff.description = "Augmente %s de %d pendant %d tours." % [
		Buff.Stat.keys()[affected_stat],
		amount,
		duration
	]
	if target.occupant != null:
		target.occupant.add_buff(buff)

		print("%s reçoit +%d %s pendant %d tours" % [
			target.name,
			amount,
			Buff.Stat.keys()[affected_stat],
			duration
		])
