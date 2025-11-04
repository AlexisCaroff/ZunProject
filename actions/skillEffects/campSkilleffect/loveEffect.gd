extends CampEffect
class_name CampLoveEffect

@export var name : String
@export var love_scenes := {
	"Priest+Mystic": "res://LoveScene/PriestxMystic.tscn",
	"Mystic+Hunter": "res://LoveScene/MysticxHunter.tscn",
	"Priest+Warrior": "res://LoveScene/PriestxWarrior.tscn",
	"Hunter+Warrior": "res://LoveScene/HunterxWarrior.tscn",
	"Mystic+Warrior": "res://LoveScene/WarriorxMystic.tscn",
	"Priest+Hunter": "res://LoveScene/PriestxHunter.tscn"
}

var camp
var user
var current_love_scene: Node = null
var the_tente: tente
func apply(theuser: CharaCamp, target: CharaCamp):
	user = theuser
	camp = user.camp
	if not camp:
		return
		
	the_tente=camp.TheTente
	the_tente.startlove(theuser, target)
	camp.After_camp_skill(camp.skillused)

	
