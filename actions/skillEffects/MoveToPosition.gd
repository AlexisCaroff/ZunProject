class_name MoveToPositionEffect
extends SkillEffect

@export var target_index: int

func apply(user: Character, target: Character):
	var cm = user.combat_manager
	var slots = cm.get_positions(target.is_player_controlled)

	if target_index < 0 or target_index >= slots.size():
		push_warning("Index de position cible invalide.")
		return

	var target_slot = slots[target_index]

	if target_slot.occupant == target:
		return

	if target_slot.is_occupied():
		var target_current_slot = target.current_slot
		if target_current_slot == null:
			push_error("Le personnage cible n'a pas de slot assigné.")
			return
		cm.swap_characters(target_current_slot, target_slot,1.7)
	else:
		cm.move_character_to(target, target_slot,1.7)

	
