extends SkillEffect
class_name StunEffect

func apply(user: Character, target: Character) -> void:
	target.stun=true
	target.sprite.self_modulate=Color(1,0,0,)
