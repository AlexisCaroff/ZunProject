extends Control
class_name ItemSlot

var item: Equipment = null
var inventory_ui
@onready var icon: TextureRect = $Icon
@onready var btn: Button = $Btn

func _ready():
	inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
	btn.pressed.connect(_on_pressed)
	btn.gui_input.connect(_on_gui_input)
	update_slot()


# 🔹 Mise à jour visuelle
func update_slot():
	if item:
		icon.texture = item.icon
	else:
		icon.texture = null


# 🔹 Clic (si tu veux un tooltip ou inspect item)
func _on_pressed():
	if item:
		inventory_ui.inspect_item(item, self)


# 🔹 Drag start
func _on_gui_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
		if item != null:
			_start_drag()


func _start_drag():
	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.size = Vector2(64, 64)

	get_viewport().gui_start_drag(item, preview, self)


# 🔹 Drop support
func can_drop_data(pos, data):
	return data is Equipment

func drop_data(pos, data):
	if item == null:
		item = data
		update_slot()
		inventory_ui.remove_from_other_slot(data, self)
