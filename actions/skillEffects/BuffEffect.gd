extends SkillEffect
class_name BuffEffect

enum Stat {
	ATTACK,
	DEFENSE,
	SPEED,
	WILL_POWER,
	EVASION,
	OTHER,
	POISON,
	STUN,
	TAUNT,
	PRECISION,
	IMMOBILIZE,
}

@export var name = "name"
@export var uitexture: Texture2D = null

@export_enum("ATTACK", "DEFENSE", "SPEED", "WILL_POWER", "EVASION", "OTHER", "POISON", "STUN", "TAUNT", "PRECISION", "IMMOBILIZE")
var affected_stat: int = Stat.ATTACK

@export var amount: int = 5
@export var duration: int = 3
## Force sur l'échelle de buffs (cf. Buff.Tier) : AUTO la déduit de |amount|.
@export var tier: Buff.Tier = Buff.Tier.AUTO

func apply(_user: Character, target: PositionSlot) -> void:
	if target.occupant == null:
		return

	var buff := Buff.new()
	buff.stat     = affected_stat
	buff.icon     = uitexture
	buff.amount   = amount
	buff.duration = duration
	buff.name     = name
	buff.tier     = tier
	buff.description = "Modifie %s de %d pendant %d tours." % [
		Buff.Stat.keys()[affected_stat],
		amount,
		duration
	]
	target.occupant.add_buff(buff, _user)
