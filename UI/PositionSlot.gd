extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false

@onready var imageinside = $TextureRect
var is_ready: bool = false

signal slot_selected(slot: PositionSlot)

#@onready var click_button = $Button  # ou le nom de ton bouton dans le slot


func _on_click():
	print("blip"+ self.name)
	if occupant and occupant.is_targetable:
		
		emit_signal("slot_selected", self)
		

func inside() -> Character:
	if occupant == null:
		push_error("Erreur : nobody inside"+name)
	return occupant
	
func is_occupied() -> bool:
	return occupant != null
	
func _ready():

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
		





func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("blip " + self.name)
	if event is InputEventMouseButton and event.pressed:
		
		if occupant and occupant.is_targetable:
			emit_signal("slot_selected", self)


func _on_button_button_down() -> void:
		print("blip " + self.name)
