extends Control
class_name Victory_UI
@onready var itemsContainer = $VictoryBox/HBoxContainer
@onready var continue_button = $ContinueButton
@export var item_ui_scene: PackedScene = preload("res://UI/item_ui.tscn")
## Carte d'affinité gagnée (posée par CombatManager._show_victory).
var pending_card: AffinityCard = null

func showLoot(items: Array[Equipment], gm:GameManager):
	for i in min(gm.characters.size(), $HBoxContainer.get_child_count()):
		var chara = gm.characters[i]
		for key in chara.affinity:
				chara.affinity[key] += 5
		var portrait_rect: TextureRect = $HBoxContainer.get_child(i).get_node("chara")
		portrait_rect.texture = chara.explorationPortrait
		portrait_rect.visible=true
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
		
		gm.add_to_inventory(item)

	# Carte d'affinité gagnée : montrée après le butin, puis mise en main.
	if pending_card != null:
		var slot := Control.new()
		slot.custom_minimum_size = CardView.SIZE * 0.45
		var view := CardView.make(pending_card, 0.45)
		slot.add_child(view)
		itemsContainer.add_child(slot)
		view.modulate.a = 0.0
		view.create_tween().tween_property(view, "modulate:a", 1.0, 0.3)
		gm.add_card(pending_card)
		pending_card = null



	
var _continuing: bool = false

func _on_continue_pressed() -> void:
	# Un seul passage : un second clic (ou un clic qui traverse le dialogue
	# post-combat) relançait la suite en double.
	if _continuing:
		return
	_continuing = true
	continue_button.disabled = true
	GameState.current_phase = GameStat.GamePhase.EXPLORATION

	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	if not gm or not gm.current_room_Ressource:
		push_error("GameManager introuvable ou current_room vide")
		return
	# La salle du combat, figée AVANT le dialogue : la suite ne doit pas
	# dépendre de ce qui a pu changer pendant qu'il s'affichait.
	var combat_room: RoomResource = gm.current_room_Ressource
	print("🏁 Victoire dans ", combat_room.room_id, " → suite : ",
			combat_room.after_combat_room_id if combat_room.after_combat_room_id != "" else "exploration")

	
	if gm.current_room_Ressource.Post_combat_scene_History != null \
			and not gm.current_room_Ressource.post_combat_history_played:
		gm.current_room_Ressource.post_combat_history_played = true
		var history = gm.current_room_Ressource.Post_combat_scene_History
		var overlay = gm.show_history_scene(history)

	
		await overlay.history_finished

	# Combat du tutoriel : pas d'exploration, on enchaîne sur la porte de la
	# salle suivante (Hall1). changedoor = true : le « retour » de cette
	# porte reste la salle d'avant le combat (l'entrée du donjon).
	var next_id: String = combat_room.after_combat_room_id
	if next_id != "":
		var next_room := gm.get_room_by_id(next_id)
		if next_room:
			gm.enter_room(next_room, true)
			return

	if gm.current_room_Ressource.exploration_scene:
		call_deferred("_enter_exploration_scene", gm)
	else:
		push_error("Pas de scene exploration définie pour cette salle")
func _enter_exploration_scene(gm: GameManager) -> void:
	gm._enter_scene_in_current_room(gm.current_room_Ressource.exploration_scene)
