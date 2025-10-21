extends AiBrain
class_name AiBrain_MommyBoss

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		return {}

	var enemy_positions = owner.combat_manager.enemy_positions
	if enemy_positions == null or enemy_positions.is_empty():
		push_error("⚠️ Aucune position d'ennemi trouvée pour le summoner.")
		return super.decide_action(owner, heroes, enemies)

	# 🔍 Cherche une position libre OU avec un ennemi mort
	var valid_slot: PositionSlot = null
	for slot in enemy_positions:
		if not slot.is_occupied():
			valid_slot = slot
			break
		elif slot.occupant != null and slot.occupant.is_dead:
			valid_slot = slot
			break

	# 🎯 Sélectionne les skills de type 'spawn'
	var spawn_skills = usable_skills.filter(func(s): return s.Actiontype == "spawn")

	# Si un skill de spawn est dispo ET qu’une position est libre ou contient un mort → on l’utilise
	if not spawn_skills.is_empty() and valid_slot != null:
		print ("try to spawn")
		return {
			"skill": spawn_skills.pick_random(),
			"target": valid_slot
		}

	# Sinon comportement normal
	return super.decide_action(owner, heroes, enemies)
