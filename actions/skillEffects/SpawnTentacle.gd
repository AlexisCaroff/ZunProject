extends SkillEffect
class_name SkillEffectSpawnTentacle

@export var enemy_scene: PackedScene
@export var max_spawn: int = 1  # combien d'ennemis peuvent être spawn
@export var spawn_delay: float = 0.5
var combatmanager : CombatManager
func apply(_user: Character, target: PositionSlot) -> void:
	
	combatmanager =_user.combat_manager
	if not enemy_scene:
		push_error("Aucune scène d'ennemi assignée à SkillEffectSpawnEnemy")
		return
	
	var combat_manager = target.combat_manager
	if combat_manager == null:
		push_error("Impossible de trouver le combat_manager depuis le target slot")
		return
	

		
	_spawn_tentacle_in_slot(combatmanager.enemy_positions[3], target.occupant)



func _spawn_tentacle_in_slot(slot: PositionSlot, target:Character):
	var new_enemy:Character = enemy_scene.instantiate()
	combatmanager.add_child(new_enemy)
	new_enemy.characterData = new_enemy.characterData.duplicate(true)
	slot.assign_character(new_enemy, 0.0)
	combatmanager.enemies.append(new_enemy)
	new_enemy.characterData.is_player_controlled = false
	new_enemy.combat_manager = combatmanager  
	new_enemy.ShadowBackground=combatmanager.ShadowBackground
	new_enemy.name = "Tentacle" 
	new_enemy.characterData.Charaname=new_enemy.name 
	print("Spawned new enemy in slot: ", slot.name)
	new_enemy._current_slot=slot
	combatmanager.move_character_to(new_enemy, slot, 0.0)
	combatmanager.enemies.append(new_enemy)
	var all_characters: Array[Character] = []
	all_characters.append_array(combatmanager.heroes)
	all_characters.append_array(combatmanager.enemies)
	new_enemy.CharaGrab= target
	target._current_slot.remove_character()
	target._current_slot= combatmanager.enemy_positions[4]
	target.position = new_enemy.position
	target.position.y -= 70
	
	target.z_index = new_enemy.z_index-1 
	combatmanager.turn_queue.append(new_enemy)
	combatmanager.ui.update_turn_queue_ui(combatmanager.turn_queue)
	new_enemy.update_ui()
	
