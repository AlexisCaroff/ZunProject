extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false
@onready var button = $Button
@onready var imageinside = $TextureRect

func inside() -> Character:
	if occupant == null:
		push_error("Erreur : nobody inside"+name)
	return occupant
	
func is_occupied() -> bool:
	return occupant != null
	
func _ready():
	print("%s ready, enemy_scene = %s" % [name, str(enemy_scene)])
	if spawner:
		spawn_enemy_if_needed($"../../CombatManager")
	
func assign_character(character: Character, movetime:float):
	if occupant:
		occupant.current_slot = null
	occupant = character
	#imageinside.texture=character.portrait_texture
	character.current_slot = self
	print("%s assigné à %s" % [character.name, name])
	var tween = get_tree().create_tween()
	tween.tween_property(character, "global_position", global_position, movetime)
	
	await tween.finished
	character.CharaScale= position_data.scale
	character.set_scale(position_data.scale)
	

	if position_data.buff:
		position_data.buff.apply(character, character)

func remove_character():
	if occupant:
		occupant.resetVisuel()
		occupant = null
		
func spawn_enemy_if_needed(combat_manager: CombatManager):
	print("try in %s, enemy_scene = %s" % [name, str(enemy_scene)])
	if enemy_scene:
		var enemy: Character = enemy_scene.instantiate()
		enemy.combat_manager = combat_manager
		get_tree().get_root().add_child(enemy)
		combat_manager.enemies.append(enemy)
		print("try spawn")
		assign_character(enemy, 4.0)
