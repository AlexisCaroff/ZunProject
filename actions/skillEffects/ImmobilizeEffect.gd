extends SkillEffect
class_name ImmobilizeEffect

## Nombre de tours pendant lesquels la cible ne peut pas se déplacer.
@export var duration: int = 1

func apply(user: Character, target: PositionSlot) -> void:
	var chara := target.occupant
	if chara == null:
		return

	chara.characterData.immobilized       = true
	chara.characterData.immobilized_turns = duration

	chara.update_ui()
	print("%s immobilise %s pour %d tour(s)" % [
		user.characterData.Charaname,
		chara.characterData.Charaname,
		duration
	])
