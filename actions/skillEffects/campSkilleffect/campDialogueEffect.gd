extends CampEffect
class_name CampDialogueEffect

@export var name : String
@export_file("*.txt") var dialoguePriest : String
@export_file("*.txt") var dialogueMystic : String
@export_file("*.txt") var dialogueHunter : String
@export_file("*.txt") var dialogueWarrior : String

func apply(user: CharaCamp, target: CharaCamp):
	var camp = user.camp
	if not camp:
		return

	var file_path := ""

	# Choix du texte en fonction de la classe ou du nom du target
	match target.Charaname:
		"Priest":  file_path = dialoguePriest
		"Mystic":  file_path = dialogueMystic
		"Hunter":  file_path = dialogueHunter
		"Warrior": file_path = dialogueWarrior
		_: 
			print("⚠️ Aucun dialogue défini pour ", target.Charaname)
			return


	var dialogue_manager: DialogueManager = camp.get_node_or_null("DialogueManager")


	
	if dialogue_manager and file_path != "":
			dialogue_manager.load_dialogue(file_path)
			dialogue_manager.start_dialogue()

		
			dialogue_manager.dialogue_finished.connect(func():
				camp.After_camp_skill(user.camp.skillused),
				CONNECT_ONE_SHOT
			)
