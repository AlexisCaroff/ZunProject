extends AiBrain
class_name AiBrain_MommyBoss

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	print("Mommy Decide!")

	var base_usable_skills := owner.skills.filter(func(s): return s.can_use())
	if base_usable_skills.is_empty():
		return super.decide_action(owner, heroes, enemies)

	var cm := owner.combat_manager
	var enemy_positions := cm.enemy_positions

	# =========================
	# 1️⃣ SPAWN LOGIC (prioritaire)
	# =========================
	var valid_slot: PositionSlot = null
	for slot in enemy_positions:
		if not slot.is_occupied():
			if slot != cm.enemy_positions[4]:
				valid_slot = slot
				break
		elif slot.occupant != null and slot.occupant.is_dead():
			if slot != cm.enemy_positions[4]:
				valid_slot = slot
				break

	var spawn_skills := base_usable_skills.filter(
		func(s): return s.Actiontype == "spawn"
	)

	if valid_slot != null and not spawn_skills.is_empty():
		# ta logique de proba éventuelle ici
		if randf() < 0.5:
			print("👶 Mommy chooses spawn")
			var target_positions: Array[PositionSlot] = [valid_slot]
			return {
				"skill": spawn_skills.pick_random(),
				"target": target_positions
			}

	# =========================
	# 2️⃣ MOMMY GRAB FORCÉ
	# =========================
	var grab_skills := base_usable_skills.filter(
		func(s): return s.name == "Mommy Grab"
	)

	if not grab_skills.is_empty():
		print("🤲 Mommy FORCES Grab")

		# 👉 utilise la logique STANDARD pour la cible
		var action := super.decide_action(owner, heroes, enemies)

		# ⚠️ Sécurité : si l’AI standard ne choisit pas Grab
		if action.has("skill") and action.skill.name != "Mommy Grab":
			action.skill = grab_skills.pick_random()

		return action

	# =========================
	# 3️⃣ FALLBACK
	# =========================
	return super.decide_action(owner, heroes, enemies)
