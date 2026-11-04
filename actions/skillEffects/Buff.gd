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
## Bonus « pour les N prochains combats » (cartes d'affinité) : nombre de
## combats restants. 0 = buff ordinaire, compté en tours.
@export var fights_left: int = 0

# ════════════════════════════════════════════════════════════════════
#  ÉCHELLE DE BUFFS
# ════════════════════════════════════════════════════════════════════
#  En combat, chaque statistique (et chaque poison) a UNE échelle signée :
#  niveaux 1..5 → +1, +3, +6, +10, +15 (ou -1 … -15 pour un debuff).
#  Un buff fait monter l'échelle selon sa force (cf. strength()) ; elle perd
#  un niveau à la fin du tour du personnage, sauf si c'est lui-même qui
#  vient de la monter pendant ce tour. Les états binaires (stun, taunt,
#  immobilisé, marque…) ne s'empilent pas : seul le dernier est gardé.

const LADDER: Array[int] = [1, 3, 6, 10, 15]
const MAX_LEVEL := 5
const POISON_NAMES: Array[String] = ["poison", "poisonHorny"]
const LADDER_STATS: Array[int] = [Stat.ATTACK, Stat.DEFENSE, Stat.SPEED,
		Stat.WILL_POWER, Stat.EVASION, Stat.PRECISION]

enum Tier { AUTO, NORMAL, BIG, VERY_BIG }
## Force du buff. AUTO la déduit de |amount| (≤5 normal, ≤10 gros, au-delà
## très gros). Normal : niveau 2 ou +1 niveau. Gros : niveau 2 ou +2.
## Très gros : niveau 3 ou +3.
@export var tier: Tier = Tier.AUTO

## Niveau signé sur l'échelle (buffs empilables uniquement). amount suit.
var level: int = 0
## Monté par le personnage sur lui-même pendant son tour : ne baisse pas à
## la fin de ce tour-là.
var fresh: bool = false


func is_poison() -> bool:
	return name in POISON_NAMES


## Vrai pour les buffs qui s'empilent sur une échelle (stats + poisons).
## Les bonus « N prochains combats » restent des bonus fixes.
func is_ladder() -> bool:
	if fights_left > 0:
		return false
	if is_poison():
		return amount != 0
	return stat in LADDER_STATS and amount != 0


## Une échelle par statistique, et une par type de poison.
func ladder_key() -> String:
	return "poison:" + name if is_poison() else "stat:%d" % stat


## Un seul état binaire de chaque sorte : stun, taunt et immobilisation par
## statistique, les autres (marque, icônes…) par nom.
func binary_key() -> String:
	if stat in [Stat.STUN, Stat.TAUNT, Stat.IMMOBILIZE]:
		return "stat:%d" % stat
	return "name:" + name


func strength() -> int:
	if tier != Tier.AUTO:
		return int(tier)
	var a: int = abs(amount)
	if a <= 5:
		return Tier.NORMAL
	if a <= 10:
		return Tier.BIG
	return Tier.VERY_BIG


## +1 pour un buff, -1 pour un debuff. Un poison monte toujours son échelle.
func direction() -> int:
	if is_poison():
		return 1
	return 1 if amount > 0 else -1


static func value_for(lvl: int) -> int:
	if lvl == 0:
		return 0
	return signi(lvl) * LADDER[clampi(absi(lvl), 1, MAX_LEVEL) - 1]


## Niveau d'arrivée quand un buff de force `power` et de sens `dir` touche une
## échelle au niveau `current`.
static func next_level(current: int, dir: int, power: int) -> int:
	if current == 0:
		return dir * (3 if power >= Tier.VERY_BIG else 2)
	return clampi(current + dir * power, -MAX_LEVEL, MAX_LEVEL)


func set_level(lvl: int) -> void:
	level = clampi(lvl, -MAX_LEVEL, MAX_LEVEL)
	amount = value_for(level)


## Échelle en BBCode, le palier atteint mis en avant.
func ladder_bbcode() -> String:
	var col := "#e070ff" if is_poison() else ("#ffffff" if level > 0 else "#ff7a6b")
	var parts: Array[String] = []
	for i in MAX_LEVEL:
		var v: int = LADDER[i] * (1 if level > 0 else -1)
		var txt := ("%d" % v) if is_poison() else ("%+d" % v)
		if i + 1 == absi(level):
			parts.append("[color=%s][b][u]%s[/u][/b][/color]" % [col, txt])
		elif i + 1 < absi(level):
			parts.append("[color=%s]%s[/color]" % [col, txt])
		else:
			parts.append("[color=#6b6359]%s[/color]" % txt)
	return "  ".join(parts)

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
