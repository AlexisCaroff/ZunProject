extends Control
class_name DoorInventory
# ════════════════════════════════════════════════════════════════════
#  SAC D'ÉQUIPE — panneau de la scène porte
# ════════════════════════════════════════════════════════════════════
#  Affiche gm.inventory (le sac partagé par tout le groupe) dans le coin
#  bas-droit, en alternance avec la carte du donjon. Lecture seule : le
#  ré-équipement passe toujours par InventoryUI (menu_Characters.tscn).
#
#  La grille est construite par code — la mise en page ne dépend que de
#  columns / cell_size, pas d'une hiérarchie de nœuds à maintenir.
# ════════════════════════════════════════════════════════════════════

const EMPTY_SLOT_TEX := preload("res://UI/UI inventory/UI_inventory_pack_frame.png")

@export var columns: int = 5
@export var rows: int = 3
@export var cell_size: Vector2 = Vector2(84, 84)
@export var cell_separation: int = 6

@onready var grid: GridContainer = $Grid
@onready var tooltip: Label = $Tooltip

var _cells: Array[TextureRect] = []


func _ready() -> void:
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", cell_separation)
	grid.add_theme_constant_override("v_separation", cell_separation)
	_build_cells()
	if tooltip:
		tooltip.text = ""


func _build_cells() -> void:
	for child in grid.get_children():
		child.queue_free()
	_cells.clear()

	for i in columns * rows:
		var cell := TextureRect.new()
		cell.custom_minimum_size = cell_size
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.texture = EMPTY_SLOT_TEX
		cell.mouse_filter = Control.MOUSE_FILTER_PASS

		# L'icône de l'objet se superpose au cadre vide plutôt que de le
		# remplacer : le cadre reste visible sous chaque item.
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)

		var count := Label.new()
		count.name = "Count"
		count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count.add_theme_font_size_override("font_size", 18)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(count)

		cell.mouse_entered.connect(_on_cell_hovered.bind(i))
		cell.mouse_exited.connect(_on_cell_unhovered)
		grid.add_child(cell)
		_cells.append(cell)


## Remplit la grille depuis le sac d'équipe. Les cases en trop restent vides.
func refresh(items: Array[Equipment]) -> void:
	if _cells.is_empty():
		return
	for i in _cells.size():
		var cell := _cells[i]
		var icon := cell.get_node("Icon") as TextureRect
		var count := cell.get_node("Count") as Label
		if i < items.size() and items[i] != null:
			icon.texture = items[i].icon
			count.text = str(items[i].number) if items[i].number > 1 else ""
		else:
			icon.texture = null
			count.text = ""

	if items.size() > _cells.size():
		push_warning("DoorInventory : %d objets pour %d cases — les derniers ne sont pas affichés."
				% [items.size(), _cells.size()])


func _current_items() -> Array[Equipment]:
	var gm := get_tree().root.get_node_or_null("GameManager") as GameManager
	return gm.inventory if gm != null else [] as Array[Equipment]


func _on_cell_hovered(index: int) -> void:
	if tooltip == null:
		return
	var items := _current_items()
	if index < items.size() and items[index] != null:
		tooltip.text = items[index].name


func _on_cell_unhovered() -> void:
	if tooltip:
		tooltip.text = ""
