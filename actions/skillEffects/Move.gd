class_name Move
extends SkillEffect
func apply(user: Character, target: Character):
	var cm = user.combat_manager
	var slots = cm.get_positions(target.is_player_controlled)


	var user_slot = user.current_slot

	if target.current_slot==null:
		return
		
	if target.current_slot.is_occupied():
		
		var target_current_slot = target.current_slot
		if target_current_slot == null:
			push_error("Le personnage cible n'a pas de slot assigné.")
			return
		cm.swap_characters(target_current_slot, user_slot, 1.7)
		
	else:
		cm.move_character_to(target, user_slot,.7)

	
