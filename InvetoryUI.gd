extends Control

class_name InventoryUI

@export var inventory_size_x := 5
@export var inventory_size_y := 5
@export var emptySlotTexture : Texture2D = preload("res://UI/emptyItemSlot.png")
# --- Références
@onready var startMenuButton = $CanvasLayer/ButtonMenu
@onready var canvasLayer = $CanvasLayer
@onready var inventory_grid = $CanvasLayer/InventoryGrid
@onready var slots_panel = $CanvasLayer/EquipmentSlots
@onready var drag_icon = $CanvasLayer/DragIcon
@onready var Selected_Chara_icon =$CanvasLayer/pivot/HerosTexture1
@onready var Charaname=$CanvasLayer/Charaname
@onready var Att=$CanvasLayer/AttLabel
@onready var Def=$CanvasLayer/DefLabel
@onready var Stamina=$CanvasLayer/Stamina
@onready var Horny=$CanvasLayer/Horny
@onready var Guilt=$CanvasLayer/Guilt
@onready var WillPower=$CanvasLayer/WillPower
@onready var ExitButton= $CanvasLayer/ExitButton
@onready var CharactersPanelAffinity= $CanvasLayer/CharactersPanelAffinity
@onready var CharactersAffinity= [
	$CanvasLayer/CharactersPanelAffinity/chara1,
	$CanvasLayer/CharactersPanelAffinity/chara2,
	$CanvasLayer/CharactersPanelAffinity/chara3
]
@onready var skill_buttons = [
	$CanvasLayer/ActionPanel/Action1,
	$CanvasLayer/ActionPanel/Action2,
	$CanvasLayer/ActionPanel/Action3,
	$CanvasLayer/ActionPanel/Action4,
]
@onready var cooldown_bars = [
		$CanvasLayer/ActionPanel/Action1/CooldownBar,
		$CanvasLayer/ActionPanel/Action2/CooldownBar,
		$CanvasLayer/ActionPanel/Action3/CooldownBar,
		$CanvasLayer/ActionPanel/Action4/CooldownBar,
		]
@onready var ButtonCharacter1=$CanvasLayer/ButtonCharacter1
@onready var ButtonCharacter2=$CanvasLayer/ButtonCharacter2
@onready var LabelAction= $CanvasLayer/LabelAction
@onready var StaminaProgressBar=$CanvasLayer/StaminaProgressBar
@onready var LustProgressBar=$CanvasLayer/LustProgressBar
@onready var GuiltProgressBar=$CanvasLayer/GuiltProgressBar
@onready var KinksList=$CanvasLayer/KinksList
# Instances des personnages
var characters : Array[CharacterData]= [
	
]
var current_character_index : int = 0
var selected_character : CharacterData = null

# Inventaire (128 items max)
var inventory_items: Array[Equipment] = []


var dragged_item : Equipment = null
var dragged_slot_index : int = -1

@onready var tooltip_panel = $CanvasLayer/ToolTipPanel
@onready var tooltip_name = $CanvasLayer/ToolTipPanel/VBoxContainer/ToolTipName
@onready var tooltip_desc = $CanvasLayer/ToolTipPanel/VBoxContainer/ToolTipDesc


var gm: GameManager
signal change_in_equipment(character: CharacterData)





func _ready():
	
	gm = get_tree().root.get_node("GameManager") as GameManager
	hideMenu()
	gm.inventory_changed.connect(_on_inventory_changed)
	startMenuButton.connect("button_down", startmenu)
	create_inventory_grid()
	
	ExitButton.connect("button_down", hideMenu)
	drag_icon.visible = false
	var theinventory = inventory_items.duplicate()
	
	inventory_items.resize(inventory_size_x * inventory_size_y)
	
	for i in range(inventory_items.size()):
		inventory_items[i] = null
		
	for i in gm.inventory:
		if i != null:
			print (i.name + " is in Game manager inventory")
			addItemToInventory(i)
	

		
	if characters.is_empty():
		characters=gm.characters
	select_character(characters[0])
	ButtonCharacter1.connect("button_down",nextChara)
	ButtonCharacter2.connect("button_down",lastChara)
	update_inventory_ui()


# --------------------------------------------------------------------
# UI CHARACTERS
# --------------------------------------------------------------------
func nextChara():
	if characters.is_empty():
		return
	
	current_character_index = (current_character_index + 1) % characters.size()
	select_character(characters[current_character_index])
	
func lastChara():
	if characters.is_empty():
		return

	current_character_index = (current_character_index - 1 + characters.size()) % characters.size()
	select_character(characters[current_character_index])

func select_character_by_index(index: int):
	#print (index)
	current_character_index = clamp(index, 0, characters.size() - 1)
	var chara = characters[current_character_index]
	select_character(chara)


func select_character(chara:CharacterData):
	selected_character = chara
	update_equipment_slots()
	Selected_Chara_icon.texture=chara.Dialogue_texture
	#print (chara.Charaname + " selected")
	#for eq in chara.equipped_items:
		#print(eq.name)
	KinksList.bbcode_enabled = true
	KinksList.text = ""
	chara.max_stamina = chara.base_max_stamina
	chara.max_horniness = chara.base_max_horniness
	chara.max_stress = chara.base_max_stress

	chara.attack = chara.base_attack
	chara.defense = chara.base_defense
	chara.initiative = chara.base_initiative
	chara.willpower = chara.base_willpower
	chara.evasion = chara.base_evasion
	
	for eq in chara.equipped_items:
		
		chara.attack += eq.attack_bonus
		chara.defense += eq.defense_bonus
		chara.max_horniness += eq.Max_lust_bonus
		chara.max_stamina += eq.Max_stamina_bonus
		chara.max_stress += eq.Max_Guilt_bonus 
		chara.willpower += eq.willpower_bonus
		chara.evasion += eq.evasion_bonus
		chara.initiative += eq.initiative_bonus 
	
	for buff in chara.buffs:
		buff.apply_to(chara)
	
	for tag in chara.tags:
		KinksList.text += tag + "\n"
	Charaname.text=chara.Charaname
	Def.bbcode_enabled = true
	Att.bbcode_enabled = true
	WillPower.bbcode_enabled = true
	Stamina.bbcode_enabled = true
	Guilt.bbcode_enabled = true
	Horny.bbcode_enabled = true
	Att.text = "Attack: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
	chara.attack, chara.base_attack, (chara.attack - chara.base_attack)]
	Def.text = "Defense: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
	chara.defense, chara.base_defense, (chara.defense - chara.base_defense)]
	WillPower.text = "Willpower: %d [color=AAAAAA] [i](Base %d + Bonus %d)[/i][/color]" % [
	chara.willpower, chara.base_willpower, (chara.willpower - chara.base_willpower)]
	
	Stamina.text = "%d / %d" % [chara.current_stamina, chara.max_stamina]
	StaminaProgressBar.max_value= chara.max_stamina
	StaminaProgressBar.value=chara.current_stamina
	Guilt.text = "%d / %d" % [chara.current_stress, chara.max_stress]
	GuiltProgressBar.max_value=chara.max_stress
	GuiltProgressBar.value=chara.current_stress
	Horny.text = "%d / %d" % [chara.current_horniness, chara.max_horniness]
	LustProgressBar.max_value=chara.max_horniness
	LustProgressBar.value=chara.current_horniness
	
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
		CharactersAffinity= [
		$CharactersPanelAffinity/chara1,
		$CharactersPanelAffinity/chara2,
		$CharactersPanelAffinity/chara3
		]
	
	for i in range(skill_buttons.size()):
		var button = skill_buttons[i]
		
		var skill = chara.skill_resources[i]
		
		
		if skill != null:
			skill_buttons[i].Actiontext = skill.descriptionName + "\n" + skill.description
			button.disabled = skill.can_use()
			button.icon = skill.icon
			skill_buttons[i].label = LabelAction
			


			
			update_cooldown_bar(cooldown_bars[i],skill)
		else:
			button.text = "—"
			button.disabled = true
	var other_members : Array = []
	for c in characters:
		if c != chara:
			other_members.append(c)
	for i in range(CharactersAffinity.size()):
		var slot = CharactersAffinity[i]

		if i < other_members.size():
			var target = other_members[i]

			# Récupération de la RichTextLabel
			var rtl : RichTextLabel = slot.get_node("Textaffinity")
			rtl.bbcode_enabled = true
			
			
			# Affinité (valeur)
			var value := 0
			if chara.affinity.has(target.Charaname):
				value = chara.affinity[target.Charaname]
			slot.set_chara(target, value)
		

			
			rtl.text = target.Charaname

			slot.visible = true

		else:
			slot.visible = false
			 


func create_inventory_grid():
	inventory_grid.columns = inventory_size_x

	for i in range(inventory_size_x * inventory_size_y):
		var cell = create_inventory_cell(i)
		inventory_grid.add_child(cell)
	#print ("inventory gride created for " +str(inventory_size_x))

func create_inventory_cell(index: int) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(120, 120)
	container.add_child(icon)

	var btn = Button.new()
	btn.name = "Btn"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.size = Vector2(120, 120)
	btn.flat = true
	
	var emptyStyle = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", emptyStyle)
	
	btn.connect("pressed", func(): on_inventory_slot_pressed(index))
	

	btn.mouse_entered.connect(func(): _on_slot_hovered(index))
	btn.mouse_exited.connect(func(): hide_tooltip())
	
	container.add_child(btn)
	return container

func _on_slot_hovered(index: int):
	var item = inventory_items[index]
	var cell = inventory_grid.get_child(index)
	show_tooltip(item, cell.global_position + Vector2(120, 0))

func on_inventory_slot_pressed(index: int):
	#if index < 0 or index >= inventory_items.size():
	#	print("Index hors limite :", index)
	#	return
	var item = inventory_items[index]

	if dragged_item == null:
		# Début de drag
		if item != null:
			if GameState.current_phase == GameStat.GamePhase.COMBAT:
				#print( "can't in Combat")
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

func _process(_delta):
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
	

func addItemToInventory(item: Equipment):
	for idx in range(inventory_items.size()):
		if inventory_items[idx] == null:
			inventory_items[idx] = item
			print("add item ", item.name)
			break
	
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
	#print ('try unequip item')
	var item = selected_character.equipped_items[slot_index]
	
	# Trouver une place dans l’inventaire
	for i in range(inventory_items.size()+1):
		
		if inventory_items[i] == null:
			inventory_items[i] = item
			selected_character.equipped_items.remove_at(slot_index)
		
			update_inventory_ui()
			update_equipment_slots()
			#print('unequip '+ item.name)
			return
	
	select_character(selected_character)

# --------------------------------------------------------------------
# DROP SUR SLOT ÉQUIPEMENT
# --------------------------------------------------------------------

func _input(event):
	if event is InputEventMouseButton:
		if dragged_item == null:
			return

		var equipped := try_equip_on_character()

		if not equipped:
			# remettre l’objet là où il était
			if dragged_slot_index >= 0:
				inventory_items[dragged_slot_index] = dragged_item
			else:
				addItemToInventory(dragged_item)

		finish_drag()
		update_inventory_ui()

func try_equip_on_character() -> bool:
	if selected_character == null:
		return false

	if selected_character.equipped_items.size() >= 2:
		return false

	selected_character.equipped_items.append(dragged_item)
	update_equipment_slots()
	update_inventory_ui()
	select_character(selected_character)
	return true



func update_inventory_ui():

	for i in range(inventory_items.size()):
		var item = inventory_items[i]
		var cell = inventory_grid.get_child(i)
		var icon = cell.get_node("Icon")

		icon.texture = item.icon if item != null else emptySlotTexture
	emit_signal("change_in_equipment", selected_character)
	
func hideMenu():
	canvasLayer.visible=false
func showMenu():
	canvasLayer.visible=true
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
func _on_inventory_changed(item: Equipment):
	addItemToInventory(item)
func show_tooltip(item: Equipment, cell_position: Vector2):
	if item == null:
		hide_tooltip()
		return
	
	tooltip_name.text = item.name
	
	
	
	# Construit les stats dynamiquement
	var stats := ""
	if item.attack_bonus != 0:
		stats += "[color=FF6666]  ⚔ Attaque: +%d[/color]\n" % item.attack_bonus
	if item.defense_bonus != 0:
		stats += "[color=6699FF]  🛡 Défense: +%d[/color]\n" % item.defense_bonus
	if item.willpower_bonus != 0:
		stats += "[color=CC99FF]  ✦ Volonté: +%d[/color]\n" % item.willpower_bonus
	if item.evasion_bonus != 0:
		stats += "[color=99FFCC]  ◎ Esquive: +%d[/color]\n" % item.evasion_bonus
	if item.initiative_bonus != 0:
		stats += "[color=FFFF66]  ⚡ Initiative: +%d[/color]\n" % item.initiative_bonus
	if item.Max_stamina_bonus != 0:
		stats += "[color=FF9966]  ♥ Stamina max: +%d[/color]\n" % item.Max_stamina_bonus
	if item.Max_lust_bonus != 0:
		stats += "[color=FF66AA]  ♦ Lust max: +%d[/color]\n" % item.Max_lust_bonus
	if item.Max_Guilt_bonus != 0:
		stats += "[color=AAAAAA]  ● Stress max: +%d[/color]\n" % item.Max_Guilt_bonus

	tooltip_desc.bbcode_enabled = true
	tooltip_desc.text = "  " + item.description if item.get("description") else "" + stats
	
	tooltip_panel.visible = true
	_reposition_tooltip(cell_position)

func startmenu():
	gm.spawn_start_menu()
	gm.current_room_node.queue_free()

func hide_tooltip():
	tooltip_panel.visible = false

func _reposition_tooltip(near: Vector2):
	
	
	var viewport_size = get_viewport().get_visible_rect().size
	var tp_size = tooltip_panel.size
	var pos = near + Vector2(-16, 0)
	
	# Déborde à droite → passer à gauche du slot
	if pos.x + tp_size.x+500 > viewport_size.x:
		pos.x = near.x - tp_size.x - 136  # 136 = largeur slot (120) + marge (16)
		print("repo")
	
	# Déborde en bas → remonter
	if pos.y + tp_size.y > viewport_size.y:
		pos.y = viewport_size.y - tp_size.y - 8
	
	# Déborde en haut (si tooltip très grand)
	if pos.y < 0:
		pos.y = 8
	
	tooltip_panel.global_position = pos
