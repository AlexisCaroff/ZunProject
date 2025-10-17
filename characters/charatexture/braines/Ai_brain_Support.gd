extends AiBrain
class_name AiBrain_Support

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		return {}

	# Cherche un allié blessé (donc dans heroes, pas enemies)
	var weak_allies = heroes.filter(func(c): return c.current_stamina < c.max_stamina * 0.5)
	var heal_skills = usable_skills.filter(func(s): return s.Actiontype == "heal")

	if not heal_skills.is_empty() and not weak_allies.is_empty():
		return {
			"skill": heal_skills.pick_random(),
			"target": weak_allies.pick_random()
		}

	# Sinon, comportement de base
	return super.decide_action(owner, heroes, enemies)
