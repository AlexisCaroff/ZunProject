extends Resource
class_name Buff

# Définition des stats affectables
enum Stat {
	ATTACK,
	DEFENSE,
	SPEED,
	WILL_POWER,
	EVASION,
	OTHER,
	POISON,
	STUN, 
	TAUNT
}

@export var name: String = "Buff"
@export var description: String = "Effet temporaire sur les statistiques."
@export var icon: Texture2D

@export_enum("ATTACK", "DEFENSE", "SPEED", "WILL_POWER", "EVASION","OTHER","POISON", "STUN", "TAUNT")
var stat: int = Stat.ATTACK

@export var amount: int = 1
@export var duration: int = 3

# Méthode appelée à chaque recalcul des stats
func apply_to(target: Character) -> void:
	match stat:
		Stat.ATTACK:
			target.characterData.attack += amount
		Stat.DEFENSE:
			target.characterData.defense += amount
		Stat.SPEED:
			target.characterData.initiative += amount
		Stat.WILL_POWER:
			target.characterData.willpower += amount
		Stat.EVASION:
			target.characterData.evasion +=amount
	
