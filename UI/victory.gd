extends Control

@onready var itemsContainer = $VictoryBox/HBoxContainer
@onready var continue_button = $ContinueButton
@export var item_ui_scene: PackedScene = preload("res://UI/item_ui.tscn")

func showLoot(items: Array[Item]):
	if itemsContainer == null:
		itemsContainer = $VictoryBox/HBoxContainer
		continue_button =$ContinueButton
	continue_button.pressed.connect(_on_continue_pressed)
	
	for child in itemsContainer.get_children():
		if is_instance_valid(child):
			child.queue_free()
			
	
	for item in items:
		if item == null:
			continue
		var item_ui = item_ui_scene.instantiate()
		item_ui.setObject(item.icon, item.name)
		itemsContainer.add_child(item_ui)
		await item_ui.animation_finished
		
		
func _on_continue_pressed() -> void:

	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	if GameState.saveRunning==true :
		await GameState.save_finished
	
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	if gm and gm.current_room_Ressource:
		if gm.current_room_Ressource.exploration_scene:
			gm._enter_scene_in_current_room(gm.current_room_Ressource.exploration_scene)
		else:
			push_error("Pas de scene exploration définie pour cette salle")
	else:
		push_error("GameManager introuvable ou current_room vide")
	
