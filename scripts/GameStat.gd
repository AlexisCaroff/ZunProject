extends Node
class_name GameStat

# Phase de jeu
enum GamePhase { EXPLORATION, COMBAT }
var current_phase: GamePhase = GamePhase.EXPLORATION

# Équipe du joueur
var saved_heroes_data: Array = []  
# Structure d'un héros :
# {
#     "scene_path": String,
#     "name": String,
#     "stamina": int,
#     "stress": int,
#     "horniness": int,
#     "dead": bool,
#     "position": int,
#     "skills": Array[Resource]
# }

# --- Sauvegarde l'état actuel de tous les héros
func save_party_from_nodes(heroes: Array) -> void:
	saved_heroes_data.clear()
	for hero in heroes:
		if not hero is Character:
			continue
		saved_heroes_data.append({
			"scene_path": hero.scene_file_path,
			"name": hero.Charaname,
			"stamina": hero.current_stamina,
			"stress": hero.current_stress,
			"horniness": hero.current_horniness,
			"dead": hero.dead,
			"position": hero.Chara_position,
			"skills": hero.skill_resources.duplicate(true)
		})
	print("Party saved: ", saved_heroes_data)

# --- Recharge l'équipe dans les slots de la scène
func load_party_into_scene(slots: Array) -> void:
	for hero_data in saved_heroes_data:
		var scene = load(hero_data["scene_path"])
		var hero: Character = scene.instantiate()
		hero.is_player_controlled = true
		hero.Charaname = hero_data["name"]
		hero.current_stamina = hero_data["stamina"]
		hero.current_stress = hero_data["stress"]
		hero.current_horniness = hero_data["horniness"]
		hero.dead = hero_data["dead"]
		hero.skill_resources = hero_data["skills"]
		hero._updateSkills(hero.skill_resources)
		hero.update_ui()

		var pos_index = hero_data.get("position", -1)
		if pos_index >= 0 and pos_index < slots.size():
			slots[pos_index].put(hero)
