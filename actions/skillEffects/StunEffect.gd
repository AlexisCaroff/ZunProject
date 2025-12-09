extends SkillEffect
class_name StunEffect
var Chartarget:Character
func apply(user: Character, target: PositionSlot) -> void:
	Chartarget=target.occupant
	Chartarget.characterData.stun=true
	for tag in user.characterData.tags:
		if tag == "jailor":
			if Chartarget.characterData.current_stamina <= (Chartarget.characterData.max_stamina/10):
				Chartarget.isdead()
				if Chartarget.characterData.IsDemon:
					Chartarget.combat_manager.nb_crystaleloot += 1 
	for tag in Chartarget.characterData.tags :
		if tag == "captive":
			Chartarget.characterData.current_stamina += 10
			var bigbuff := load("res://characters/kink/bigAttackBuff.tres")
			Chartarget.add_buff(bigbuff)
	for hero in Chartarget.combat_manager.heroes :
		for tag in hero.characterData.tags:
			if tag =="captive":
				hero.characterData.current_horniness+=2
	Chartarget.sprite.self_modulate=Color(1,0,0,)
