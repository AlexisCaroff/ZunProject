extends SkillEffect
class_name SkillEffectSpawnEnemy

@export var enemy_scene: PackedScene
@export var max_spawn: int = 1  # combien d'ennemis peuvent être spawn
@export var spawn_delay: float = 0.5

func apply(user: Character, target: PositionSlot) -> void:
	if not enemy_scene:
		push_error("Aucune scène d'ennemi assignée à SkillEffectSpawnEnemy")
		return
	
	var combat_manager = target.combat_manager
	if combat_manager == null:
		push_error("Impossible de trouver le combat_manager depuis le target slot")
		return
	
	# Chercher les slots ennemis disponibles
	var empty_slots: Array[PositionSlot] = []
	for slot in combat_manager.enemy_positions:
		if not slot.is_occupied():
			empty_slots.append(slot)
	
	if empty_slots.is_empty():
		print("Aucun slot libre pour spawn un ennemi")
		return
	
	var spawn_count = min(max_spawn, empty_slots.size())
	
	for i in range(spawn_count):
		var slot = empty_slots[i]
		_spawn_enemy_in_slot(slot)



func _spawn_enemy_in_slot(slot: PositionSlot):
	var new_enemy = enemy_scene.instantiate()
	slot.add_child(new_enemy)
	slot.assign_character(new_enemy, 0.5)
	new_enemy.is_player_controlled = false
	new_enemy.combat_manager = slot.combat_manager
	new_enemy.name = "Spawned_" + str(randi() % 1000)
	print("Spawned new enemy in slot: ", slot.name)
