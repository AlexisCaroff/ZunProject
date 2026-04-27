extends Resource
class_name AiBrain

@export var name: String = "Default AI"
@export var description: String = "IA basique qui choisit une compétence aléatoire utilisable et une cible valide."

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var combat_manager = owner.combat_manager
	var ennemisPositions: Array = combat_manager.enemy_positions
	var herosPositions: Array   = combat_manager.hero_positions

	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		print("%s n'a aucune compétence utilisable." % owner.characterData.Charaname)
		return {}

	# Retire les skills spéciales du pool générique uniquement s'il reste d'autres options.
	# "spawnEnnemi" et "Mommy Grab" ne sont jamais choisis par l'IA générique.
	for skill in usable_skills.duplicate():
		if usable_skills.size() > 1 and skill.name in ["spawnEnnemi", "Mommy Grab"]:
			usable_skills.erase(skill)
	# "move" est retiré seulement s'il existe d'autres skills — il sert de dernier recours
	# quand le personnage est en mauvaise position pour toutes ses attaques.
	for skill in usable_skills.duplicate():
		if usable_skills.size() > 1 and skill.name == "move":
			usable_skills.erase(skill)

	#for skill in usable_skills:
	#	print(skill.name)

	var skill: Skill = usable_skills[randi() % usable_skills.size()]

	# ── Helpers : slots vivants uniquement ───────────────────────────
	# IMPORTANT : on exclut systématiquement les héros grab (.grab == true).
	# Un héros grab n'occupe plus son hero_slot — son _current_slot pointe
	# vers enemy_positions[4] (le "slot tentacule") qui n'a jamais d'occupant
	# assigné. Le cibler renvoie un slot avec occupant == null et fait
	# planter play_ai_turn / les effets de skill.
	var alive_hero_slots: Array = herosPositions.filter(
		func(p: PositionSlot) -> bool:
			return p.is_occupied() \
				and not p.occupant.is_dead() \
				and not p.occupant.characterData.grab \
				and p.occupant.characterData.current_horniness < 100
	)
	var alive_enemy_slots: Array = ennemisPositions.filter(
		func(p: PositionSlot) -> bool:
			return p.is_occupied() and not p.occupant.is_dead()
	)

	match skill.the_target_type:
		skill.target_type.SELF:
			var selfpositions: Array[PositionSlot] = []
			selfpositions.append(owner._current_slot)
			return {"skill": skill, "target": selfpositions}

		skill.target_type.ALL_ALLY:
			return {"skill": skill, "target": alive_enemy_slots}

		skill.target_type.ALL_ENNEMY:
			return {"skill": skill, "target": alive_hero_slots}

	# ── Move : cible un slot ennemi selon la position requise par sa skill principale ──
	if skill.name == "move":
		var move_target_slots: Array = []
		# Cherche la première skill d'attaque pour connaître la position requise
		var attack_skill: Skill = null
		for s in owner.skills:
			if s.name != "move":
				attack_skill = s
				break

		if attack_skill != null:
			match attack_skill.required_position:
				attack_skill.position_requirement.FRONT:
					move_target_slots = ennemisPositions.filter(
						func(p: PositionSlot) -> bool: return p.position_data.isFront and not p.is_occupied()
					)
				attack_skill.position_requirement.BACK:
					move_target_slots = ennemisPositions.filter(
						func(p: PositionSlot) -> bool: return not p.position_data.isFront and not p.is_occupied()
					)
				_:  # ANY
					move_target_slots = ennemisPositions.filter(
						func(p: PositionSlot) -> bool: return not p.is_occupied()
					)

		# Fallback : n'importe quel slot libre
		if move_target_slots.is_empty():
			move_target_slots = ennemisPositions.filter(func(p: PositionSlot) -> bool: return not p.is_occupied())

		if move_target_slots.is_empty():
			print("%s veut se déplacer mais aucun slot libre." % owner.characterData.Charaname)
			return {}

		var targetPos: Array[PositionSlot] = []
		targetPos.append(move_target_slots[randi() % move_target_slots.size()])
		return {"skill": skill, "target": targetPos}

	# ── Cible unique ─────────────────────────────────────────────────
	var possible_targets: Array[Character] = []
	match skill.the_target_type:
		skill.target_type.ALLY:
			possible_targets = enemies
		skill.target_type.ENNEMY:
			possible_targets = heroes

	possible_targets = possible_targets.filter(func(c): return not c.is_dead())
	possible_targets = possible_targets.filter(func(c): return c.characterData.current_horniness < 100)
	# ── Filtre les héros grab : ils ne sont plus dans leur slot d'origine
	#    et ne peuvent plus être attaqués normalement. ──
	if skill.the_target_type == skill.target_type.ENNEMY:
		possible_targets = possible_targets.filter(func(c): return not c.characterData.grab)

	# Sécurité : taunted_by ne doit pas pointer vers une cible invalide
	var taunt_valid := owner.taunted_by != null \
		and is_instance_valid(owner.taunted_by) \
		and not owner.taunted_by.is_dead() \
		and not owner.taunted_by.characterData.grab

	var target: Character = null
	if taunt_valid and skill.the_target_type == skill.target_type.ENNEMY:
		target = owner.taunted_by
	elif possible_targets.size() > 0:
		target = possible_targets[randi() % possible_targets.size()]
	else:
		# Aucune cible valide → on annule l'action plutôt que de cibler soi-même
		# (cibler owner avec une skill ENNEMY produit des comportements bizarres).
		print("%s n'a aucune cible valide pour %s." % [owner.characterData.Charaname, skill.name])
		return {}

	var targetPos: Array[PositionSlot] = []
	targetPos.append(target._current_slot)
	return {"skill": skill, "target": targetPos}
