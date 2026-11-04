extends AiBrain
class_name AiBrain_Support

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		return {}

	# --- 1️⃣ Cherche les alliés ennemis blessés (dans enemies)
	var weak_allies: Array = enemies.filter(func(c): return not c.is_dead() and c.characterData.current_stamina < c.characterData.max_stamina * 0.6)
	var heal_skills: Array = usable_skills.filter(func(s): return s.Actiontype == "heal")

	if not heal_skills.is_empty() and not weak_allies.is_empty():
		var heal_skill: Skill = heal_skills.pick_random()
		var Charatarget: Character = weak_allies.pick_random()
		print("%s (AI Support) soigne %s avec %s" % [owner.characterData.Charaname, Charatarget.characterData.Charaname, heal_skill.descriptionName])
		var target :Array[PositionSlot]
		target.append(Charatarget. _current_slot)
		return {
			"skill": heal_skill,
			"target": target
		}

	# --- 2️⃣ Sinon, une autre compétence. La cible suit son the_target_type
	# (choose_target) : un buff « ALLY » comme Encouragement vise l'équipe
	# de l'IA, une attaque « ENNEMY » vise les héros, à portée.
	var other_skills: Array = usable_skills.filter(func(s): return s.Actiontype != "heal" and s.name != "move")
	other_skills.shuffle()
	for s in other_skills:
		var action := choose_target(owner, s)
		if not action.is_empty():
			return action

	# --- 3️⃣ Si rien d’autre n’est possible, fallback sur le comportement par défaut
	print("%s (AI Support) n’a trouvé aucune action utile, fallback sur IA basique." % owner.characterData.Charaname)
	return super.decide_action(owner, heroes, enemies)
