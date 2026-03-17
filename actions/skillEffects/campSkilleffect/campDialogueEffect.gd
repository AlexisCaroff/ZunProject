extends CampEffect
class_name CampDialogueEffect

@export var name: String
@export_file("*.txt") var dialoguePriest: String
@export_file("*.txt") var dialogueMystic: String
@export_file("*.txt") var dialogueHunter: String
@export_file("*.txt") var dialogueWarrior: String

func apply(user: CharaCamp, target: CharaCamp):
	var camp = user.camp
	if not camp:
		return

	for chara in camp.characters:
		chara.set_targetable(false)

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

	target.characterData.affinity[user.characterData.Charaname] += 20
	user.characterData.affinity[target.characterData.Charaname] += 20

	# load_dialogue détecte automatiquement les participants et configure le layout
	dialogue_manager.load_dialogue(file_path)
	dialogue_manager.start_dialogue()

	dialogue_manager.dialogue_finished.connect(
		func(): camp.After_camp_skill(user.camp.skillused),
		CONNECT_ONE_SHOT
	)
