extends SkillEffect
class_name StunEffect
var Chartarget:Character
func apply(user: Character, target: PositionSlot) -> void:
	Chartarget=target.occupant
	Chartarget.stun=true
	Chartarget.sprite.self_modulate=Color(1,0,0,)
