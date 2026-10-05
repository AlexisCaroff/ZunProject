extends SkillEffect
class_name ConditionalEffect

# ─────────────────────────────────────────────
#  Conditions disponibles
# ─────────────────────────────────────────────

enum Condition {
	TARGET_IS_STUNNED,
	TARGET_IS_IMMOBILIZED,
	TARGET_STAMINA_BELOW_HALF,   # stamina < 50 %
	TARGET_STAMINA_ABOVE_HALF,   # stamina > 50 %
	TARGET_GUILT_ABOVE_HALF,     # stress > 50 %  (guilt = stress, à remplacer si tu ajoutes le stat)
	TARGET_GUILT_BELOW_HALF,     # stress < 50 %
	TARGET_HORNY_ABOVE_HALF,     # horniness > 50 %
	TARGET_HORNY_BELOW_HALF,
	USER_IS_STUNNED,
	USER_IS_IMMOBILIZED,
	USER_STAMINA_BELOW_HALF,
	USER_STAMINA_ABOVE_HALF,
	USER_GUILT_ABOVE_HALF,
	USER_GUILT_BELOW_HALF,
	USER_HORNY_ABOVE_HALF,
	USER_HORNY_BELOW_HALF,
}

# ─────────────────────────────────────────────
#  Exports
# ─────────────────────────────────────────────

@export var condition: Condition = Condition.TARGET_IS_STUNNED

## Effet appliqué si la condition est VRAIE
@export var effect_if_true: SkillEffect

## Effet appliqué si la condition est FAUSSE (optionnel)
@export var effect_if_false: SkillEffect


# ─────────────────────────────────────────────
#  Application
# ─────────────────────────────────────────────

func apply(user: Character, target: PositionSlot) -> void:
	if _check(condition, user, target):
		if effect_if_true:
			effect_if_true.apply(user, target)
	else:
		if effect_if_false:
			effect_if_false.apply(user, target)


# ─────────────────────────────────────────────
#  Évaluation de la condition
# ─────────────────────────────────────────────

func _check(cond: Condition, user: Character, target: PositionSlot) -> bool:
	var t := target.occupant
	var u := user

	match cond:
		Condition.TARGET_IS_STUNNED:
			return t != null and t.characterData.stun

		Condition.TARGET_IS_IMMOBILIZED:
			return t != null and t.characterData.get("immobilized") == true

		Condition.TARGET_STAMINA_BELOW_HALF:
			return t != null and t.characterData.current_stamina < t.characterData.max_stamina * 0.5

		Condition.TARGET_STAMINA_ABOVE_HALF:
			return t != null and t.characterData.current_stamina > t.characterData.max_stamina * 0.5

		Condition.TARGET_GUILT_ABOVE_HALF:
			# guilt = current_stress — remplace par ton propre stat si besoin
			return t != null and t.characterData.current_stress > t.characterData.max_stress * 0.5

		Condition.TARGET_GUILT_BELOW_HALF:
			return t != null and t.characterData.current_stress < t.characterData.max_stress * 0.5

		Condition.TARGET_HORNY_ABOVE_HALF:
			return t != null and t.characterData.current_horniness > t.characterData.max_horniness * 0.5

		Condition.TARGET_HORNY_BELOW_HALF:
			return t != null and t.characterData.current_horniness < t.characterData.max_horniness * 0.5

		Condition.USER_IS_STUNNED:
			return u.characterData.stun

		Condition.USER_IS_IMMOBILIZED:
			return u.characterData.get("immobilized") == true

		Condition.USER_STAMINA_BELOW_HALF:
			return u.characterData.current_stamina < u.characterData.max_stamina * 0.5

		Condition.USER_STAMINA_ABOVE_HALF:
			return u.characterData.current_stamina > u.characterData.max_stamina * 0.5

		Condition.USER_GUILT_ABOVE_HALF:
			return u.characterData.current_stress > u.characterData.max_stress * 0.5

		Condition.USER_GUILT_BELOW_HALF:
			return u.characterData.current_stress < u.characterData.max_stress * 0.5

		Condition.USER_HORNY_ABOVE_HALF:
			return u.characterData.current_horniness > u.characterData.max_horniness * 0.5

		Condition.USER_HORNY_BELOW_HALF:
			return u.characterData.current_horniness < u.characterData.max_horniness * 0.5

	return false
