extends Node
class_name GameStat

enum GamePhase { EXPLORATION, COMBAT, CAMP }
var current_phase: GamePhase = GamePhase.EXPLORATION
var saveRunning :bool = false
var saved_heroes_data: Array = []
signal save_finished

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
			"camp_skills": hero.camp_skill_resources.duplicate(true),  
			"buffs": hero.buffs.duplicate(true),
			"acte_twice":hero.acte_twice,

			# Nouvelles données de textures
			"portrait_texture_path": hero.portrait_texture.resource_path,
			"dead_portrait_texture_path": hero.dead_portrait_texture.resource_path,
			"initiative_icon_path": hero.initiative_icon.resource_path
		})
		print(hero.Charaname + "is saved")
	#print("Party saved: ", saved_heroes_data)
	emit_signal("save_finished")
	saveRunning = false


func update_hero_stat(name: String, stat_key: String, value):
	for hero in saved_heroes_data:
		if hero["name"] == name:
			hero[stat_key] = value
			print("change "+name + " "+ stat_key + str(value))
			return


# --- Recharge l'équipe dans les slots de la scène de combat
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
		if hero_data.has("buffs"):
			for buff in hero_data["buffs"]:
				hero.add_buff(buff)

		if hero_data.has("camp_skills"):
			hero.camp_skill_resources = hero_data["camp_skills"]
		hero.acte_twice = hero_data["acte_twice"]

		hero.update_ui()

		var pos_index = hero_data.get("position", -1)
		if pos_index >= 0 and pos_index < slots.size():
			slots[pos_index].put(hero)


# --- Recharge l'équipe pour le campement
func load_party_into_camp(slots: Array, chara_scene: PackedScene) -> Array:
	var camp_chars: Array = []
	for hero_data in saved_heroes_data:
		var chara: CharaCamp = chara_scene.instantiate()
		chara.load_from_dict(hero_data)

		# 👇 injecter les CampSkills sauvegardés
		if hero_data.has("camp_skills"):
			chara.camp_skill_resources = hero_data["camp_skills"]

		# placer dans un slot visuel
		if slots.size() > 0:
			var slot = slots[camp_chars.size() % slots.size()]
			slot.add_child(chara)
			chara.global_position = slot.global_position

		camp_chars.append(chara)

	return camp_chars
	
func save_party_from_camp(camp_chars: Array[CharaCamp]) -> void:
	if saveRunning:
		push_warning("Sauvegarde déjà en cours")
		return

	saveRunning = true

	for chara in camp_chars:
		if not chara is CharaCamp:
			continue

		# Recherche du héros correspondant dans saved_heroes_data
		var found := false
		for hero_data in saved_heroes_data:
			if hero_data["name"] == chara.Charaname:
				# Met à jour uniquement les champs pertinents
				hero_data["stamina"] = chara.current_stamina
				hero_data["stress"] = chara.current_stress
				hero_data["horniness"] = chara.current_horny
				hero_data["buffs"] = chara.buffs.duplicate(true)
				hero_data["camp_skills"] = chara.camp_skill_resources.duplicate(true)
				hero_data["acte_twice"] = chara.acte_twice
				hero_data["position"] = chara.current_position

				found = true
				print("✅ Camp data updated for: " + chara.Charaname)
				break

		if not found:
			push_warning("Héros " + chara.Charaname + " non trouvé dans saved_heroes_data !")

	saveRunning = false
	emit_signal("save_finished")
