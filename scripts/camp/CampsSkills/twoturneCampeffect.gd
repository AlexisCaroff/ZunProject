extends CampEffect
class_name Acte_twice
@export var icon : Buff
func apply(_user: CharaCamp, target: CharaCamp):
	target.characterData.acte_twice=true
	target.add_buff(icon)
