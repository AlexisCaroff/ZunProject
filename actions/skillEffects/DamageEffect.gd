extends SkillEffect
class_name DamageEffect

@export var amount: int = 20
enum Stat {
	STAMINA,
	HORNY,
	STRESS
}
@export_enum("STAMINA", "HORNY", "STRESS")
var damage_target_stat: int = Stat.STAMINA

func apply(user: Character, target: Character) -> void:
	var damage = 0
	match damage_target_stat:
		Stat.STAMINA:
			if target.current_stamina>0:
				damage= max (0,(amount+user.attack)-target.defense)
				target.current_stamina = min(target.max_stamina, target.current_stamina - damage)
				target.current_stamina = max(0,target.current_stamina)
				if target.current_stamina==0:
					target.sprite.self_modulate=Color(0.8,0.1,0.1,)
			else:
				target.dead = true
				target.sprite.texture  = target.dead_portrait_texture
				target.Selector.texture = target.dead_portrait_texture
			print("%s current stamina is %d" % [target.name, target.current_stamina])
		Stat.HORNY:
			damage= max (0,amount-target.willpower)
			print("%s inflige %d de dégâts à %s" % [user.name, damage, target.name])
			target.current_horniness = max(0, target.current_horniness - damage)
		Stat.STRESS:
			damage= max (0,amount-target.willpower)
			print("%s inflige %d de dégâts à %s" % [user.name, damage, target.name])
			target.current_stress =  max(0, target.current_stress - damage)
			
	target.update_ui()
