extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false
@onready var combat_manager = $"../../CombatManager"
@onready var imageinside = $TextureRect
var selfposition: Array[PositionSlot] = []

var is_ready: bool = false

signal slot_selected(slot: PositionSlot)

#@onready var click_button = $Button  # ou le nom de ton bouton dans le slot


func inside() -> Character:
	if occupant == null:
		push_error("Erreur : nobody inside"+name)
	return occupant
	
func is_occupied() -> bool:
	return occupant != null
	
func _ready():
	selfposition.append(self)
	is_ready= true

	
func assign_character(character: Character, movetime:float):

	occupant = character
	
	if not is_ready:
		await ready
	imageinside.texture=character.initiative_icon
	character.current_slot = self
	#print(character.Charaname,"→ current_slot défini à ", self.name)
	
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
		





func _on_button_button_down() -> void:
	if occupant and occupant.is_targetable:
		var skill = combat_manager.pending_skill

		match skill.the_target_type:
			Skill.target_type.SELF:
				combat_manager._on_target_selected(selfposition)
				print("self targeted")

			Skill.target_type.ALLY:
				combat_manager._on_target_selected(selfposition)
				print("one ally targeted")

			Skill.target_type.ENNEMY:
				combat_manager._on_target_selected(selfposition)
				print("one enemy targeted")

			Skill.target_type.ALL_ALLY:

				combat_manager._on_target_selected(combat_manager.hero_positions)
				print("all allies targeted")

			Skill.target_type.ALL_ENNEMY:

				combat_manager._on_target_selected(combat_manager.enemy_positions)
				print("all enemies targeted")

func _on_button_mouse_entered() -> void:
	occupant.Selector.self_modulate= Color(1.0,1.0,1.0,0.5)


func _on_button_mouse_exited() -> void:
	occupant.Selector.self_modulate= Color(.0,1.0,1.0,0.0)
