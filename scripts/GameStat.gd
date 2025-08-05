extends Node
class_name GameStat

enum GamePhase { EXPLORATION, COMBAT }
var current_phase: GamePhase = GamePhase.COMBAT

var saved_heroes_data: Array = []

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
			"skills": hero.skill_resources.duplicate(true),


			# Nouvelles données de textures
			"portrait_texture_path": hero.portrait_texture.resource_path,
			"dead_portrait_texture_path": hero.dead_portrait_texture.resource_path,
			"initiative_icon_path": hero.initiative_icon.resource_path
		})
	#print("Party saved: ", saved_heroes_data)
func update_hero_stat(name: String, stat_key: String, value):
	for hero in saved_heroes_data:
		if hero["name"] == name:
			hero[stat_key] = value
			print("change "+name + " "+ stat_key + str(value))
			return
# --- Recharge l'équipe dans les slots de la scène
func load_party_into_combat(slots: Array) -> void:
	for hero_data in saved_heroes_data:
		var scene = load(hero_data["scene_path"])
		var hero: Character = scene.instantiate()
		hero.is_player_controlled = true
		hero.Charaname = hero_data["name"]
		hero.current_stamina = hero_data["stamina"]
		hero.current_stress = hero_data["stress"]
		hero.current_horniness = hero_data["horniness"]
		hero.dead = hero_data["dead"]
		hero.Chara_position = hero_data["position"]
		hero.skill_resources = hero_data["skills"]
		hero._updateSkills(hero.skill_resources)
		hero.update_ui()

		var pos_index = hero_data.get("position", -1)
		if pos_index >= 0 and pos_index < slots.size():
			slots[pos_index].put(hero)
