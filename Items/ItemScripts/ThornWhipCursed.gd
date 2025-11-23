extends Equipment
class_name ThornWhipCursed


@export var horny_increase: int = 15
@export var buff: Buff  # icône du buff d’attaque

func on_skill_use(user: Character, skill: Skill, target: Character):
	# Vérifie que c’est la Priestess qui utilise Whip
	if user.Charaname != "Priestess":
		return

	if skill.name != "Whip":
		return

	# Vérifie que la cible est un allié
	if not target.is_player_controlled:
		return

	# 🔥 Le fouet MAUDIT inverse le heal horny :
	target.current_horniness += horny_increase
	target.current_horniness = clamp(target.current_horniness, 0, target.max_horniness)

	# 🔥 Supprimer l’effet normal (le heal horny)
	if "skill_effect_overridden" in skill:
		skill.skill_effect_overridden = true

	# 💥 Appliquer le buff d’attaque via ton système :
	

	target.add_buff(buff)
