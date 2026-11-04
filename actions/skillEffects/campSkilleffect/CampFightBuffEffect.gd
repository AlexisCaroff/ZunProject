extends CampEffect
class_name FightBuffCampEffect

# Bonus de stat pour les `fights` prochains combats (cf.
# CharacterData.fight_buffs, rejoués par Character._ready et décomptés à la
# fin de chaque combat par CombatManager).
# `weakest_only` : seul le membre le plus faible de l'équipe dans cette stat
# en profite (entraînement, « sparring »).

@export_enum("ATTACK", "DEFENSE", "SPEED", "WILL_POWER", "EVASION") var stat: int = Buff.Stat.ATTACK
@export var amount: int = 2
@export var fights: int = 2
@export var weakest_only: bool = false
@export var icon: Texture2D

const _FIELD := {0: "attack", 1: "defense", 2: "initiative", 3: "willpower", 4: "evasion"}
const _LABEL := {0: "ATK", 1: "DEF", 2: "INIT", 3: "WILL", 4: "EVA"}


func apply(_user: CharaCamp, target: CharaCamp):
	if target == null:
		return
	if weakest_only and not _is_weakest(target):
		return
	var b := Buff.new()
	b.name = "Camp: %s %+d" % [_LABEL.get(stat, "?"), amount]
	b.description = "For the next %d fights." % fights
	b.stat = stat
	b.amount = amount
	b.duration = 999
	b.fights_left = fights
	b.icon = icon
	target.characterData.fight_buffs.append(b)
	target.say("%s %+d (%d fights)" % [_LABEL.get(stat, "?"), amount, fights], 2.0)
	if target.camp != null and target.camp.get("selected_chara") == target:
		target.camp.refresh_buffs(target.characterData)


func _is_weakest(target: CharaCamp) -> bool:
	var field: String = _FIELD.get(stat, "attack")
	var mine := int(target.characterData.get(field))
	if target.camp == null:
		return true
	for c in target.camp.characters:
		if c is CharaCamp and c != target and int(c.characterData.get(field)) < mine:
			return false
	return true
