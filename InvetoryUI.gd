extends Control

class_name InventoryUI

@export var inventory_size_x := 5
@export var inventory_size_y := 5
@export var emptySlotTexture : Texture2D
# --- Références
@onready var characters_panel = $CharactersPanel
@onready var inventory_grid = $InventoryGrid
@onready var slots_panel = $EquipmentSlots
@onready var drag_icon = $DragIcon
@onready var Selected_Chara_icon =$pivot/HerosTexture1
@onready var Charaname=$Charaname
@onready var Att=$AttLabel
@onready var Def=$DefLabel
@onready var Stamina=$Stamina
@onready var Horny=$Horny
@onready var Guilt=$Guilt
@onready var WillPower=$WillPower
@onready var ExitButton= $ExitButton
@onready var skill_buttons = [
	$ActionPanel/Action1,
	$ActionPanel/Action2,
	$ActionPanel/Action3,
	$ActionPanel/Action4,
	

]
@onready var cooldown_bars = [
		$ActionPanel/Action1/CooldownBar,
		$ActionPanel/Action2/CooldownBar,
		$ActionPanel/Action3/CooldownBar,
		$ActionPanel/Action4/CooldownBar,
		
		]
@onready var LabelAction= $LabelAction
# Instances des personnages
var characters : Array[Character]= [
	preload("res://characters/CharaHunter.tscn").instantiate(),
	preload("res://characters/CharaMystic.tscn").instantiate(),
	preload("res://characters/CharaPriest.tscn").instantiate(),
	preload("res://characters/CharaWarrior.tscn").instantiate(),
]

var selected_character : Character = null

# Inventaire (128 items max)
var inventory_items: Array[Equipment] = []


var dragged_item : Equipment = null
var dragged_slot_index : int = -1
var gm: GameManager
func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	
	create_inventory_grid()
	#inventory_items=gm.inventory
	ExitButton.connect("button_down", hideMenu)
	drag_icon.visible = false

	# inventaire vide pour l’instant
	inventory_items.resize(inventory_size_x * inventory_size_y)
	for i in range(inventory_items.size()):
		inventory_items[i] = null
	apply_character_icons()
	select_character(characters[0])
	


# --------------------------------------------------------------------
# UI CHARACTERS
# --------------------------------------------------------------------

func apply_character_icons():
	var c := 0 
	for image in characters_panel.get_children():
		image.chara =characters[c]
		image.thetexture.texture= characters[c].explorationPortrait
		c += 1

func select_character(chara:Character):
	selected_character = chara
	update_equipment_slots()
	Selected_Chara_icon.texture=chara.portrait_texture
	print (chara.name + " selected")
	for eq in chara.equipped_items:
		print(eq.name)
	Charaname.text=chara.Charaname
	Def.bbcode_enabled = true
	Att.bbcode_enabled = true
	WillPower.bbcode_enabled = true
	Att.text = "Attack: %d [color=AAAAAA] (Base %d + Bonus %d)[/color]" % [chara.attack,chara.base_attack,(chara.attack - chara.base_attack)]
	#Att.text = "Attack: %d Base %d Bonus %d" % [chara.attack, chara.base_attack, (chara.attack-chara.base_attack)]
	
	Def.text = "Defense: %d [color=AAAAAA] (Base %d + Bonus %d)[/color]" % [chara.defense,chara.base_defense,(chara.defense - chara.base_defense)]
	WillPower.text = "Willpower: %d [color=AAAAAA] (Base %d + Bonus %d)[/color]" % [chara.willpower,chara.base_willpower,(chara.willpower - chara.base_willpower)]
	Stamina.text = "Stamina: %d / %d" % [chara.current_stamina, chara.max_stamina]
	Guilt.text = "Guilt: %d / %d" % [chara.current_stress, chara.max_stress]
	Horny.text = "Horny: %d / %d" % [chara.current_horniness, chara.max_horniness]
	
	if skill_buttons == null:
		#push_error("skill_buttons est null pour %s" % character.Charaname)
		skill_buttons = [
		$ActionPanel/Action1,
		$ActionPanel/Action2,
		$ActionPanel/Action3,
		$ActionPanel/Action4,
		
		]
		cooldown_bars = [
		$ActionPanel/Action1/CooldownBar,
		$ActionPanel/Action2/CooldownBar,
		$ActionPanel/Action3/CooldownBar,
		$ActionPanel/Action4/CooldownBar,
		
		]
		return
	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		var skill = chara.get_skill(i)
		
		
		if skill != null:
			skill_buttons[i].Actiontext = skill.descriptionName + "\n" + skill.description
			button.disabled = !skill.can_use()
			button.icon = skill.icon
			skill_buttons[i].label = LabelAction
			

			var index = i  # capture locale de la bonne valeur
			
			update_cooldown_bar(cooldown_bars[i],skill)
		else:
			button.text = "—"
			button.disabled = true
	
# --------------------------------------------------------------------
# INVENTORY GRID
# --------------------------------------------------------------------

func create_inventory_grid():
	inventory_grid.columns = inventory_size_x

	for i in range(inventory_size_x * inventory_size_y):
		var cell = create_inventory_cell(i)
		inventory_grid.add_child(cell)

func create_inventory_cell(index: int) -> Control:

	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(120, 120)
	container.add_child(icon)

	var btn = Button.new()
	btn.name = "Btn"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.size=Vector2(120, 120)
	btn.flat=true
	
	var emptyStyle = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", emptyStyle)
	
	btn.connect("pressed", func(): on_inventory_slot_pressed(index))
	container.add_child(btn)

	return container

# --------------------------------------------------------------------
# INVENTORY SLOT CLICK
# --------------------------------------------------------------------

func on_inventory_slot_pressed(index: int):
	if index < 0 or index >= inventory_items.size():
		print("Index hors limite :", index)
		return
	var item = inventory_items[index]

	if dragged_item == null:
		# Début de drag
		if item != null:
			if GameState.current_phase == GameStat.GamePhase.COMBAT:
				print( "can't in Combat")
				return
			start_drag(item, index)
			
	else:
		# Déposer l’item ici
		place_item_in_inventory(index)


# --------------------------------------------------------------------
# DRAG & DROP
# --------------------------------------------------------------------

func start_drag(item: Equipment, index: int):
	dragged_item = item
	dragged_slot_index = index

	# Mettre l’icône dans drag_icon
	drag_icon.texture = item.icon
	drag_icon.visible = true

	# Vider la slot en attendant
	inventory_items[index] = null
	update_inventory_ui()

func _process(delta):
	if dragged_item:
		drag_icon.global_position = get_global_mouse_position()

func finish_drag():
	dragged_item = null
	dragged_slot_index = -1
	drag_icon.visible = false


# --------------------------------------------------------------------
# PLACE ITEM
# --------------------------------------------------------------------

func place_item_in_inventory(index: int):
	if inventory_items[index] == null:
		inventory_items[index] = dragged_item
		finish_drag()
		update_inventory_ui()
		return

	# Si le slot était occupé, on échange :
	var temp = inventory_items[index]
	inventory_items[index] = dragged_item
	dragged_item = temp
	update_inventory_ui()


# --------------------------------------------------------------------
# EQUIPMENT SLOTS UI
# --------------------------------------------------------------------

func update_equipment_slots():

	var slots = slots_panel.get_children()

	for i in range(2):
		var icon = slots[i].get_node("Icon")
		var btn = slots[i].get_node("Btn")
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn["callable"])
		if selected_character.equipped_items.size() > i:
			var item = selected_character.equipped_items[i]
			icon.texture = item.icon
			btn.disabled = false
			btn.connect("pressed", func(): unequip(i))
			
		else:
			icon.texture = null
			btn.disabled = true


func unequip(slot_index: int):
	if GameState.current_phase == GameStat.GamePhase.COMBAT:
		return
	print ('try unequip item')
	var item = selected_character.equipped_items[slot_index]
	
	# Trouver une place dans l’inventaire
	for i in range(inventory_items.size()+1):
		
		if inventory_items[i] == null:
			inventory_items[i] = item
			selected_character.equipped_items.remove_at(slot_index)
			selected_character.update_stats()
			update_inventory_ui()
			update_equipment_slots()
			print('unequip '+ item.name)
			return


# --------------------------------------------------------------------
# DROP SUR SLOT ÉQUIPEMENT
# --------------------------------------------------------------------

func _gui_input(event):
	

	if event is InputEventMouseButton :
		# On relâche
		
		if dragged_item == null:
			return
		print(dragged_item.name+ "is try to equipe")
		try_equip_on_character()
		finish_drag()

func try_equip_on_character():

	if selected_character == null:
		return

	if selected_character.equipped_items.size() >= 2:
		
		return # Deux slots déjà remplis

	selected_character.equipped_items.append(dragged_item)
	
	update_equipment_slots()
	update_inventory_ui()


# --------------------------------------------------------------------
# UPDATE UI
# --------------------------------------------------------------------

func update_inventory_ui():
	print ("update_inventory_ui")
	for i in range(inventory_items.size()):
		var item = inventory_items[i]
		var cell = inventory_grid.get_child(i)
		var icon = cell.get_node("Icon")

		icon.texture = item.icon if item != null else emptySlotTexture
		
func hideMenu():
	self.visible=false
	
func update_cooldown_bar(container: HBoxContainer, skill):
	
	for child in container.get_children():
		child.queue_free()
	
	if skill == null:
		return

	var max_cd = skill.cooldown  # nombre de tours total
	var current_cd = skill.current_cooldown  # combien il en reste

	# Sécurité : éviter erreurs si pas défini
	if max_cd <= 0:
		return
	var charged : int = max_cd-current_cd
	for i in range(max_cd):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(5, 5)
		rect.color = Color(0.2,0.2,0.2)

		# Si ce tour est déjà "récupéré", on le met orange
		if i <= charged :
			rect.color = Color(0.64,0.56,0.36)
		container.add_child(rect)
