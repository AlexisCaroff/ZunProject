extends CampEffect
class_name BuffCampskill
@export var thebuffs: Array[Buff]

func apply(_user: CharaCamp, target: CharaCamp):
	for eachbuff in thebuffs:
		target.add_buff(eachbuff)
	
