extends Control
class_name DoorInventory
# ════════════════════════════════════════════════════════════════════
#  SAC D'ÉQUIPE — panneau de la scène porte
# ════════════════════════════════════════════════════════════════════
#  Affiche gm.inventory (le sac partagé par tout le groupe) dans le coin
#  bas-droit, en alternance avec la carte du donjon. Le ré-équipement passe
#  toujours par InventoryUI (menu_Characters.tscn) — en revanche les
#  potions se boivent directement d'ici : cliquer dessus ouvre le popup de
#  confirmation et la potion part au personnage sélectionné devant la porte.
#
#  La grille est construite par code — la mise en page ne dépend que de
#  columns / cell_size, pas d'une hiérarchie de nœuds à maintenir.
# ════════════════════════════════════════════════════════════════════

const EMPTY_SLOT_TEX := preload("res://UI/UI inventory/UI_inventory_pack_frame.png")

@export var columns: int = 5
@export var rows: int = 3
@export var cell_size: Vector2 = Vector2(84, 84)
@export var cell_separation: int = 6
## Permet de boire les potions depuis ce panneau.
@export var potions_usable: bool = true

@onready var grid: GridContainer = $Grid
@onready var tooltip: Label = $Tooltip

var _cells: Array[TextureRect] = []

## Rendu par la scène hôte (Door) : à qui profite la potion.
var _target_provider: Callable = Callable()
var _popup: PotionConfirmPopup = null
var _using_potion: bool = false

## Émis après qu'une potion a été bue, pour que la porte rafraîchisse ses jauges.
signal potion_used(potion: Potion, target: CharacterData)


## La scène porte déclare ici comment trouver le personnage sélectionné :
##     inventory_panel.set_target_provider(func(): return selected_character)
func set_target_provider(provider: Callable) -> void:
	_target_provider = provider


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

		# Le compteur couvre toute la case et se cale en bas à droite. Ancré
		# sur le coin (PRESET_BOTTOM_RIGHT), le Label débordait de sa case et
		# le nombre semblait appartenir à la case voisine.
		var count := Label.new()
		count.name = "Count"
		count.set_anchors_preset(Control.PRESET_FULL_RECT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_size_override("font_size", 20)
		count.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
		count.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		count.add_theme_constant_override("outline_size", 6)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(count)

		# Bouton transparent par-dessus la case : c'est lui qui capte le clic
		# sur une potion. Il laisse passer le survol pour le tooltip.
		var btn := Button.new()
		btn.name = "Btn"
		btn.flat = true
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_cell_pressed.bind(i))
		# Le bouton recouvre la case : c'est lui qui reçoit le survol.
		btn.mouse_entered.connect(_on_cell_hovered.bind(i))
		btn.mouse_exited.connect(_on_cell_unhovered)
		cell.add_child(btn)

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
		var it := items[index]
		var label: String = it.name
		if it.number > 1:
			label += " x%d" % it.number
		if potions_usable and it is Potion:
			label += "  —  clic pour boire"
		tooltip.text = label


func _on_cell_unhovered() -> void:
	if tooltip:
		tooltip.text = ""


# ════════════════════════════════════════════════════════════════════
#  POTIONS
# ════════════════════════════════════════════════════════════════════

func _on_cell_pressed(index: int) -> void:
	if not potions_usable or _using_potion:
		return
	var items := _current_items()
	if index >= items.size():
		return
	var potion := items[index] as Potion
	if potion == null:
		return

	if is_instance_valid(_popup):
		_popup.queue_free()
		_popup = null

	var target := _selected_target()
	var can_use := true
	var reason := ""
	if target == null:
		can_use = false
		reason = "Aucun personnage sélectionné."
	elif not potion.is_usable(false):
		can_use = false
		reason = "Seulement pendant un combat."

	var anchor: Vector2 = _cells[index].global_position + Vector2(cell_size.x * 0.5, 0)
	var target_name := target.Name if target != null and target.Name != "" else "ce personnage"

	# Le popup est posé sur la scène courante (et non sur ce panneau, qui
	# n'occupe qu'un coin de l'écran) pour rester centré et cliquable.
	_popup = PotionConfirmPopup.open(
		get_tree().current_scene, potion, target_name, anchor, can_use, reason)
	_popup.confirmed.connect(func(): _use_potion(potion))


func _use_potion(potion: Potion) -> void:
	if _using_potion or potion == null:
		return
	var target := _selected_target()
	if target == null or not potion.is_usable(false):
		return

	_using_potion = true
	potion.apply_to_data(target)

	var gm := get_tree().root.get_node_or_null("GameManager") as GameManager
	if gm != null:
		gm.remove_from_inventory(potion, 1)
		refresh(gm.inventory)

	_using_potion = false
	emit_signal("potion_used", potion, target)


func _selected_target() -> CharacterData:
	if _target_provider.is_valid():
		var t = _target_provider.call()
		if t is CharacterData:
			return t
	return null
