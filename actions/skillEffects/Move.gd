class_name Move
extends SkillEffect

var Chartarget:Character

func apply(user: Character, target: PositionSlot):
	Chartarget=target.occupant
	if !Chartarget.characterData.can_be_moved:
		return
	var cm = user.combat_manager
	var slots = cm.get_positions(Chartarget.characterData.is_player_controlled)
	print("Move "+user.characterData.Charaname+" to "+Chartarget.characterData.Charaname+" position")

	var user_slot = user._current_slot

	if Chartarget._current_slot==null:
		return
		
	if Chartarget._current_slot.is_occupied():
		
		var target_current_slot = Chartarget._current_slot
		if target_current_slot == null:
			push_error("Le personnage cible n'a pas de slot assigné.")
			return
		cm.swap_characters(target_current_slot, user_slot, 1.7)
		user.update_ui()
		Chartarget.update_ui()
		
	else:
		cm.move_character_to(Chartarget, user_slot,.7)
		Chartarget.update_ui()
		
	
