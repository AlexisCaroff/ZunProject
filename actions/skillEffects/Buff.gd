extends Resource
class_name Buff

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
	PRECISION,    # modifie characterData.precision (base 100)
	IMMOBILIZE,   # pose characterData.immobilized = true
}

@export var name: String = "Buff"
@export var description: String = "Effet temporaire sur les statistiques."
@export var icon: Texture2D

@export_enum("ATTACK", "DEFENSE", "SPEED", "WILL_POWER", "EVASION", "OTHER", "POISON", "STUN", "TAUNT", "PRECISION", "IMMOBILIZE")
var stat: int = Stat.ATTACK

@export var amount: int = 1
@export var duration: int = 3

func apply_to(target: CharacterData) -> void:
	match stat:
		Stat.ATTACK:
			target.attack += amount
		Stat.DEFENSE:
			target.defense += amount
		Stat.SPEED:
			target.initiative += amount
		Stat.WILL_POWER:
			target.willpower += amount
		Stat.EVASION:
			target.evasion += amount
		Stat.PRECISION:
			# amount négatif = malus (ex: -30), positif = bonus
			target.precision += amount
		Stat.IMMOBILIZE:
			# amount ignoré — le flag suffit
			target.immobilized = true
