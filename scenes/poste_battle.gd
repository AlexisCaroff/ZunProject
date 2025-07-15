extends Control  # ou Control, selon le cas

@onready var hero_container = $HeroPosition # un Node2D vide pour placer les héros
@onready var positions: Array[PositionSlot] = [
	$HeroPosition/position1,
	$HeroPosition/position2,
	$HeroPosition/position4,
	$HeroPosition/position3,
]

func _ready():
	for saved_data in Game_Manager.surviving_heroes:
		var scene = load(saved_data.resource_path)
		var hero: Character = scene.instantiate()
		hero.set_meta("scene_file_path", saved_data.resource_path)  # utile pour plus tard

		hero.Charaname = saved_data.chara_name
		hero.current_stamina = saved_data.current_stamina
		hero.current_stress = saved_data.current_stress
		hero.current_horniness = saved_data.current_horniness
		hero.Chara_position = saved_data.position_index

		hero_container.add_child(hero)

		# Optionnel : le placer dans une PositionSlot
		if saved_data.position_index < positions.size():
			var slot = positions[saved_data.position_index]
			slot.assign_character(hero, 0.0)  # ou 0.5 si tu veux une animation
