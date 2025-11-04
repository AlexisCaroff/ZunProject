extends SkillEffect
class_name StunEffect
var Chartarget:Character
func apply(user: Character, target: PositionSlot) -> void:
	Chartarget=target.occupant
	Chartarget.stun=true
	for tag in user.tags:
		if tag == "jailor":
			if Chartarget.current_stamina <= (Chartarget.max_stamina/10):
				Chartarget.isdead()
				if Chartarget.IsDemon:
					Chartarget.combat_manager.nb_crystaleloot += 1 
	for tag in Chartarget.tags :
		if tag == "captive":
			Chartarget.current_stamina += 10
			var bigbuff := load("res://characters/kink/bigAttackBuff.tres")
			Chartarget.add_buff(bigbuff)
	for hero in Chartarget.combat_manager.heroes :
		for tag in hero.tags:
			if tag =="captive":
				hero.current_horniness+=2
	Chartarget.sprite.self_modulate=Color(1,0,0,)
