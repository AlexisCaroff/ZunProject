class_name Move
extends SkillEffect

var Chartarget:Character

func apply(user: Character, target: PositionSlot) -> void:
	# Si l'utilisateur est immobilisé, il ne peut cibler que sa propre position.
	# Move.gd reçoit la cible déjà choisie — si ce n'est pas le slot du user, on annule.
	if user.characterData.get("immobilized") == true:
		if target != user._current_slot:
			print("%s est immobilisé — déplacement annulé." % user.characterData.Charaname)
			return
 
	var Chartarget := target.occupant
	if Chartarget == null:
		return
	if Chartarget.characterData.immobilized:
		if target != user._current_slot:
			print("%s est immobilisé — déplacement annulé." % user.characterData.Charaname)
			return
	if !Chartarget.characterData.can_be_moved:
		return
 
	var cm = user.combat_manager
	print("Move %s to %s position" % [user.characterData.Charaname, Chartarget.characterData.Charaname])
 
	var user_slot = user._current_slot
	if Chartarget._current_slot == null:
		return
 
	if Chartarget._current_slot.is_occupied():
		cm.swap_characters(Chartarget._current_slot, user_slot, 1.7)
		user.update_ui()
		Chartarget.update_ui()
	else:
		cm.move_character_to(Chartarget, user_slot, 0.7)
		Chartarget.update_ui()
	
