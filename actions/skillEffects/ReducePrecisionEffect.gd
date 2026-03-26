extends SkillEffect
class_name ReducePrecisionEffect

## Réduction de précision appliquée à la cible (valeur positive = malus)
## ex: 30 → la cible perd 30 de précision
@export var amount: int = 30

## Nombre de tours
@export var duration: int = 2

func apply(user: Character, target: PositionSlot) -> void:
	var chara := target.occupant
	if chara == null:
		return

	chara.characterData.precision_modifier -= amount
	chara.characterData.precision_modifier_turns = max(
		chara.characterData.precision_modifier_turns,
		duration
	)

	chara.update_ui()
	print("%s réduit la précision de %s de %d pour %d tour(s)" % [
		user.characterData.Charaname,
		chara.characterData.Charaname,
		amount,
		duration
	])
