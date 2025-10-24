extends CampEffect
class_name Acte_twice
@export var icon : Buff
func apply(user: CharaCamp, target: CharaCamp):
	target.acte_twice=true
	target.add_buff(icon)
