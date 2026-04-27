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

@export_file("*.txt") var dialoguePriest: String
@export_file("*.txt") var dialogueMystic: String
@export_file("*.txt") var dialogueHunter: String
@export_file("*.txt") var dialogueWarrior: String
var camp
var user
var current_love_scene: Node = null
var the_tente: tente
func apply(theuser: CharaCamp, target: CharaCamp):
	user = theuser
	camp = user.camp
	if not camp:
		return
		
	
	var file_path := ""
	match target.characterData.Charaname:
		"Priestess": file_path = dialoguePriest
		"Mystic":    file_path = dialogueMystic
		"Hunter":    file_path = dialogueHunter
		"Warrior":   file_path = dialogueWarrior
		_:
			print("Aucun dialogue défini pour ", target.characterData.Charaname)
			return

	var dialogue_manager: DialogueManager = camp.get_node_or_null("DialogueManager")
	if not dialogue_manager or file_path == "":
		return



	# load_dialogue détecte automatiquement les participants et configure le layout
	dialogue_manager.load_dialogue(file_path)
	dialogue_manager.start_dialogue()

	dialogue_manager.dialogue_finished.connect(
		func(): afterdialog(target),
		CONNECT_ONE_SHOT
	)
	

func afterdialog(target):
	the_tente=camp.TheTente
	the_tente.startlove(user, target)
	target.characterData.affinity[user.characterData.Charaname] += 20
	user.characterData.affinity[target.characterData.Charaname] += 20
	camp.After_camp_skill(user.camp.skillused)
