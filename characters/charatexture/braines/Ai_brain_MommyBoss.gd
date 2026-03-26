extends AiBrain
class_name AiBrain_MommyBoss

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	print("Mommy Decide!")

	var base_usable_skills := owner.skills.filter(func(s): return s.can_use())
	if base_usable_skills.is_empty():
		return super.decide_action(owner, heroes, enemies)

	var cm := owner.combat_manager

	# =========================
	# 1️⃣ SPAWN TENTACULE (prioritaire)
	#    Uniquement si [3] est libre ou occupé par la boss elle-même
	#    (pas de tentacule vivante dessus)
	# =========================
	var tentacle_slot: PositionSlot = cm.enemy_positions[3]
	var can_spawn_tentacle := _slot_free_for_tentacle(tentacle_slot, owner)

	var spawn_skills := base_usable_skills.filter(func(s): return s.Actiontype == "spawn")

	if not spawn_skills.is_empty() and randf() < 0.5:
		# Sépare les tentacules des spawns classiques selon le type d'effet
		var tentacle_skills := spawn_skills.filter(func(s): return _is_tentacle_skill(s))
		var regular_skills  := spawn_skills.filter(func(s): return not _is_tentacle_skill(s))

		# ── Tentacule : target = slot héros à attraper, spawn toujours en [3] ──
		if can_spawn_tentacle and not tentacle_skills.is_empty():
			var valid_targets := heroes.filter(func(c: Character) -> bool:
				return not c.is_dead() and c.characterData.current_horniness < 100
			)
			if not valid_targets.is_empty():
				var grab_target: Character = valid_targets[randi() % valid_targets.size()]
				print("🐙 Mommy invoque une tentacule sur ", grab_target.characterData.Charaname)
				return {
					"skill": tentacle_skills.pick_random(),
					"target": [grab_target._current_slot] as Array[PositionSlot]
				}

		# ── Spawn classique : target = slot ennemi libre ──────────────────────
		if not regular_skills.is_empty():
			var free_slot := _find_free_enemy_slot(cm)
			if free_slot != null:
				print("👾 Mommy spawn classique en ", free_slot.name)
				return {
					"skill": regular_skills.pick_random(),
					"target": [free_slot] as Array[PositionSlot]
				}

	# =========================
	# 2️⃣ MOMMY GRAB
	# =========================
	var grab_skills := base_usable_skills.filter(func(s): return s.name == "Mommy Grab")

	if not grab_skills.is_empty():
		var valid_targets := heroes.filter(func(c: Character) -> bool:
			return not c.is_dead() and c.characterData.current_horniness < 100
		)
		if not valid_targets.is_empty():
			var target: Character = valid_targets[randi() % valid_targets.size()]
			print("🤲 Mommy FORCES Grab on ", target.characterData.Charaname)
			return {
				"skill": grab_skills.pick_random(),
				"target": [target._current_slot] as Array[PositionSlot]
			}

	# =========================
	# 3️⃣ FALLBACK
	# =========================
	return super.decide_action(owner, heroes, enemies)


# ─────────────────────────────────────────────
#  [3] est disponible si : vide, ou occupé par la boss elle-même
#  (entre deux tentacules), mais PAS par une tentacule vivante
# ─────────────────────────────────────────────

## Vrai si la skill contient un effet SpawnTentacle
func _is_tentacle_skill(skill: Skill) -> bool:
	for effect in skill.effects:
		if effect is SkillEffectSpawnTentacle:
			return true
	return false


## Premier slot ennemi libre hors [3] (réservé tentacule) et [4] (réservé grab)
func _find_free_enemy_slot(cm: CombatManager) -> PositionSlot:
	for i in range(cm.enemy_positions.size()):
		if i == 3 or i == 4:
			continue
		var slot: PositionSlot = cm.enemy_positions[i]
		if not slot.is_occupied() or (slot.occupant != null and slot.occupant.is_dead()):
			return slot
	return null


func _slot_free_for_tentacle(slot: PositionSlot, boss: Character) -> bool:
	if not slot.is_occupied():
		return true
	var occ := slot.occupant
	# La boss occupe [3] entre deux invocations : c'est OK pour spawner
	if occ == boss:
		return true
	# Une tentacule vivante est déjà là
	return occ.is_dead()
