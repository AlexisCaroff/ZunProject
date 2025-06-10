extends Node2D
class_name PositionSlot

@export var position_data: PositionData

var occupant: Character = null

func is_occupied() -> bool:
	return occupant != null
	

func assign_character(character: Character, movetime:float):
	#if occupant:
	#	occupant.current_slot = null
	occupant = character
	
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
