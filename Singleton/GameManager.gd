extends Node
class_name GameManager

# Déclaration explicite de la classe
class CharacterSaveData:
	var resource_path: String
	var chara_name: String
	var current_stamina: int
	var current_stress: int
	var current_horniness: int
	var position_index: int

	func _init(character: Character):
		if character.has_meta("scene_file_path"):
			resource_path = character.get_meta("scene_file_path")
		else:
			push_warning("Pas de chemin pour %s" % character.Charaname)
			resource_path = ""
		chara_name = character.Charaname
		current_stamina = character.current_stamina
		current_stress = character.current_stress
		current_horniness = character.current_horniness
		position_index = character.Chara_position

# Liste globale
var surviving_heroes: Array[CharacterSaveData] = []
