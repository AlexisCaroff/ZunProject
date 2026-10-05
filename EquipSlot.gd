extends Control
class_name EquipSlot

var index: int
var character: Character
var equipement:Equipment
var inventory_ui
@onready var icon: TextureRect = $Icon
@onready var btn: Button = $Btn

func _ready():
	inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
	btn.gui_input.connect(_on_gui_input)
	btn.pressed.connect(_on_click)
	update_slot()


func update_slot():
	if character and character.equipped_items.size() > index:
		var eq = character.equipped_items[index]
		icon.texture = eq.icon
		equipement=eq
	else:
		icon.texture = null


func _on_click():
	# On enlève l'objet si le joueur clique dessus
	if character.equipped_items[index] != null:
		inventory_ui.add_item_to_inventory(character.equipped_items[index])
		character.equipped_items[index] = null
		update_slot()
		


func _on_gui_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
		var eq = character.equipped_items[index]
		if eq:
			_start_drag(eq)


func _start_drag(item: Equipment):
	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.size = Vector2(64, 64)

	get_viewport().gui_start_drag(item, preview, self)


func can_drop_data(pos, data):
	return data is Equipment


func drop_data(pos, data):
	# Déplacer l’ancien équipement dans l’inventaire
	if character.equipped_items.size() <= index:
		character.equipped_items.resize(index + 1)

	var old = character.equipped_items[index]
	if old != null:
		inventory_ui.add_item_to_inventory(old)

	character.equipped_items[index] = data
	update_slot()
	inventory_ui.remove_from_other_slot(data, self)
	character.update_stats()
