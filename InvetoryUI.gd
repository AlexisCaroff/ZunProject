extends Control

class_name InventoryUI

@export var inventory_size_x := 5
@export var inventory_size_y := 5
@export var emptySlotTexture : Texture2D = preload("res://UI/UI inventory/UI_inventory_pack_frame.png")

## Côté de l'icône dessinée dans une case. La case elle-même ne fait que 64 px
## (taille minimale dans la GridContainer) : l'icône déborde volontairement,
## c'est la séparation de 60 px de la grille qui recrée l'espacement visuel.
const CELL_ICON_SIZE := 120.0
## Marge du compteur de pile par rapport au coin bas-droit de l'icône.
const COUNT_INSET := Vector2(10.0, 8.0)

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
# --- Camp skill / Assist
@onready var CampsSkill = $CanvasLayer/CampsSkill
@onready var CampsSkillCooldown = $CanvasLayer/CampsSkill/CooldownBar
@onready var AssistEffect = $CanvasLayer/AssistEffect
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
# Résolus par NOM et non par chemin : l'infobulle est recâblée à l'exécution
# (cf. _setup_tooltip) et le chemin change. Chercher par nom marche aussi
# bien avant qu'après, et survit à une réorganisation dans l'éditeur.
var tooltip_name: RichTextLabel = null
var tooltip_desc: RichTextLabel = null

@export_group("Infobulle")
## Largeur fixe de l'infobulle ; la hauteur, elle, suit la longueur du texte.
@export var tooltip_width: float = 390.0
## Marge intérieure entre le cadre et le texte (horizontale, verticale).
@export var tooltip_padding: Vector2 = Vector2(22, 16)
## Épaisseur des bords du cadre conservée à l'identique quelle que soit la
## taille (découpe 9-slices de la texture).
@export var tooltip_frame_margin: int = 26
@export var tooltip_backdrop_color: Color = Color(0, 0, 0, 1)
@export_group("")

## Incrémenté à chaque affichage/masquage : une infobulle dont le tour est
## passé (souris déjà ailleurs) ne doit pas se replacer après son await.
var _tooltip_seq: int = 0


var gm: GameManager
signal change_in_equipment(character: CharacterData)

# ── Potions ─────────────────────────────────────────────────────────
## Popup de confirmation ouvert (un seul à la fois).
var _potion_popup: PotionConfirmPopup = null
## Garde-fou contre le double-clic : sans lui, deux clics rapides
## consomment deux doses pour une seule confirmation.
var _using_potion: bool = false
## Émis après qu'une potion a été bue, pour que la scène hôte rafraîchisse
## ses propres jauges (exploration, porte, combat).
signal potion_used(potion: Potion, target: CharacterData)




func _ready():

	_setup_tooltip()
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

	# --- Repositionner LabelAction sous le bouton survolé
	for btn in skill_buttons:
		if btn != null:
			btn.mouse_entered.connect(position_label_under.bind(btn))
	if CampsSkill != null:
		CampsSkill.mouse_entered.connect(position_label_under.bind(CampsSkill))


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

	# --- Camp Skill : affichage comme une action de combat ---
	if CampsSkill != null:
		if chara.camp_skill_resources.size() > 0 and chara.camp_skill_resources[0] != null:
			var camp_skill = chara.camp_skill_resources[0]
			CampsSkill.Actiontext = camp_skill.name 
			
			CampsSkill.icon = camp_skill.icon
			CampsSkill.label = LabelAction
			
		else:
			CampsSkill.Actiontext = ""
			CampsSkill.icon = null
			CampsSkill.disabled = true
			CampsSkill.label = LabelAction
			update_cooldown_bar(CampsSkillCooldown, null)

	# --- Assist : affiche la variable assist du personnage sélectionné ---
	if AssistEffect != null:
		AssistEffect.text = chara.assist

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



# --------------------------------------------------------------------
# POSITIONNEMENT DU LABEL D'ACTION SOUS LE BOUTON SURVOLÉ
# --------------------------------------------------------------------
func position_label_under(button: Control):
	if LabelAction == null or button == null:
		return
	# Forcer le recalcul de la taille au cas où le texte vient d'être changé
	await get_tree().process_frame

	var btn_rect : Rect2 = button.get_global_rect()
	var label_size : Vector2 = LabelAction.size

	# Centrer horizontalement sous le bouton, et le placer juste en dessous
	var target_pos : Vector2 = Vector2(
		btn_rect.position.x + btn_rect.size.x * 0.5 - label_size.x * 0.5,
		btn_rect.position.y + btn_rect.size.y + 8
	)

	# Empêcher le label de sortir de l'écran
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	target_pos.x = clamp(target_pos.x, 0, viewport_size.x - label_size.x)
	target_pos.y = clamp(target_pos.y, 0, viewport_size.y - label_size.y)

	LabelAction.global_position = target_pos


func create_inventory_grid():
	inventory_grid.columns = inventory_size_x

	for i in range(inventory_size_x * inventory_size_y):
		var cell = create_inventory_cell(i)
		inventory_grid.add_child(cell)
	#print ("inventory gride created for " +str(inventory_size_x))

func create_inventory_cell(index: int) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)

	# Cadre de case vide, toujours présent : l'objet se superpose par-dessus au
	# lieu de le remplacer, donc la grille reste lisible même pleine.
	var bg = TextureRect.new()
	bg.name = "Bg"
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.custom_minimum_size = Vector2(CELL_ICON_SIZE, CELL_ICON_SIZE)
	bg.texture = emptySlotTexture
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(CELL_ICON_SIZE, CELL_ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Compteur de pile, affiché en bas à droite de l'icône pour les potions.
	#
	# La case ne mesure que 64x64 alors que l'icône en fait 120 et déborde :
	# ancrer le label en bas à droite de la case le projetait à 64 + 76 = 140 px,
	# soit une colonne plus loin et une ligne plus bas. On le cale donc sur le
	# coin haut-gauche avec des offsets qui recouvrent l'icône, et c'est
	# l'alignement du texte qui le pousse dans le coin bas-droit.
	var count = Label.new()
	count.name = "Count"
	count.set_anchors_preset(Control.PRESET_TOP_LEFT)
	count.offset_left = 0.0
	count.offset_top = 0.0
	count.offset_right = CELL_ICON_SIZE - COUNT_INSET.x
	count.offset_bottom = CELL_ICON_SIZE - COUNT_INSET.y
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_font_size_override("font_size", 22)
	count.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	count.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	count.add_theme_constant_override("outline_size", 6)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.text = ""
	container.add_child(count)

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
	print("Inventory click | phase=", GameState.current_phase)
	var item = inventory_items[index]

	if dragged_item == null:
		# Début de drag
		if item != null:
			# Une potion ne se traîne pas : elle se boit. Clic = confirmation.
			if item is Potion:
				ask_use_potion(index)
				return
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
	if item == null:
		return
	# La pile existe déjà dans la grille : rien à placer, juste le compteur
	# à rafraîchir (gm.add_to_inventory a déjà incrémenté `number`).
	if inventory_items.has(item):
		update_inventory_ui()
		return

	for idx in range(inventory_items.size()):
		if inventory_items[idx] == null:
			inventory_items[idx] = item
			print("add item ", item.name)
			break

	update_inventory_ui()


# ════════════════════════════════════════════════════════════════════
#  POTIONS
# ════════════════════════════════════════════════════════════════════

## Ouvre le popup de confirmation au niveau de la case cliquée.
func ask_use_potion(index: int) -> void:
	if _using_potion:
		return
	var potion := inventory_items[index] as Potion
	if potion == null:
		return

	# Un seul popup à la fois.
	if is_instance_valid(_potion_popup):
		_potion_popup.queue_free()
		_potion_popup = null

	hide_tooltip()

	var in_combat := _is_combat_phase()
	var target := _potion_target()
	var reason := ""
	var can_use := true

	if target == null:
		can_use = false
		reason = "No character selected."
	elif not potion.is_usable(in_combat):
		can_use = false
		reason = "Not during combat." if in_combat else "Only during combat."
	elif in_combat and not _combat_turn_is_usable():
		can_use = false
		reason = "Wait for your turn."

	var cell := inventory_grid.get_child(index) as Control
	var anchor: Vector2 = cell.global_position + Vector2(60, 40)
	var target_name := target.Name if target != null and target.Name != "" else "this character"

	_potion_popup = PotionConfirmPopup.open(
		canvasLayer, potion, target_name, anchor, can_use, reason, self)
	_potion_popup.confirmed.connect(func(): use_potion(index))


## Consomme réellement la potion de la case `index`.
func use_potion(index: int) -> void:
	if _using_potion:
		return
	if index < 0 or index >= inventory_items.size():
		return
	var potion := inventory_items[index] as Potion
	if potion == null:
		return

	var in_combat := _is_combat_phase()
	if not potion.is_usable(in_combat):
		return

	var target := _potion_target()
	if target == null:
		return

	_using_potion = true

	# ── Application de l'effet ──────────────────────────────────────
	var combat_chara := _combat_character_for(target)
	if combat_chara != null:
		potion.apply_to_character(combat_chara)
	else:
		potion.apply_to_data(target)
		_animate_explo_target(target, potion)

	_play_potion_sound(potion)

	# ── Retrait de l'inventaire ─────────────────────────────────────
	var emptied := gm.remove_from_inventory(potion, 1)
	if emptied:
		inventory_items[index] = null
	update_inventory_ui()

	# ── Rafraîchissement des affichages ─────────────────────────────
	# select_character() recalcule les stats depuis base + équipement +
	# characterData.buffs. En combat les buffs vivent sur le Character, pas
	# sur la CharacterData : on laisse donc le Character réécrire ses stats
	# juste après, sinon le bonus qu'on vient de poser serait effacé.
	select_character(target)
	if combat_chara != null:
		combat_chara.update_stats()
		combat_chara.update_ui()

	emit_signal("potion_used", potion, target)

	_using_potion = false

	# ── En combat, boire coûte le tour ──────────────────────────────
	if combat_chara != null and potion.ends_turn_in_combat:
		var cm := _combat_manager()
		if cm != null and cm.current_character == combat_chara:
			hideMenu()
			var combat_ui = cm.ui
			if combat_ui != null and combat_ui.has_method("disableActionButton"):
				combat_ui.disableActionButton()
			await cm.end_currentChara_Turn()


# ── Contexte : combat ou non ────────────────────────────────────────

func _is_combat_phase() -> bool:
	return GameState.current_phase == GameStat.GamePhase.COMBAT


func _combat_manager() -> CombatManager:
	return get_tree().get_first_node_in_group("combat_manager") as CombatManager


## En combat la potion va au personnage dont c'est le tour ; sinon au
## personnage affiché dans le menu.
func _potion_target() -> CharacterData:
	if _is_combat_phase():
		var cm := _combat_manager()
		if cm != null and cm.current_character != null \
				and cm.current_character.characterData.is_player_controlled:
			return cm.current_character.characterData
	return selected_character


## Le Character de combat correspondant à cette CharacterData, s'il y en a un.
func _combat_character_for(cd: CharacterData) -> Character:
	var cm := _combat_manager()
	if cm == null:
		return null
	for hero in cm.heroes:
		if hero.characterData == cd:
			return hero
	return null


## Vrai si on peut agir : c'est le tour d'un héros joueur et aucune
## animation n'est en cours.
func _combat_turn_is_usable() -> bool:
	var cm := _combat_manager()
	if cm == null:
		return false
	if cm.current_character == null:
		return false
	if not cm.current_character.characterData.is_player_controlled:
		return false
	return not cm.is_animation_playing()


## Le son de la gorgée. L'AudioManager ne gère que la musique : on passe
## par un lecteur jetable, libéré tout seul à la fin du son.
func _play_potion_sound(potion: Potion) -> void:
	if potion.use_sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = potion.use_sound
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Hors combat, joue le VFX de soin sur le héros correspondant dans la
## scène d'exploration (si elle est là) et rafraîchit son affichage.
func _animate_explo_target(cd: CharacterData, potion: Potion) -> void:
	for node in get_tree().get_nodes_in_group("chara_explo"):
		var chara := node as CharaExplo
		if chara == null or chara.characterData != cd:
			continue
		if potion.heal_stamina > 0:
			chara.animate_heal(potion.heal_stamina, chara)
		# Dans la scène porte, la silhouette n'a pas de jauges (pas de
		# charaUI d'ExplorationPosition) : update_display() y planterait.
		if chara.hp_Jauge != null:
			chara.update_display()
		return
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

	var item: Equipment = selected_character.equipped_items[slot_index]

	# ── Sync avec gm.inventory (le master persistant) ──
	# On ajoute directement (pas via gm.add_to_inventory) pour éviter
	# que le signal inventory_changed ne déclenche un addItemToInventory()
	# qui ajouterait une 2e fois dans inventory_items.
	if not gm.inventory.has(item):
		gm.inventory.append(item)

	# ── Place dans le grid local ──
	for i in range(inventory_items.size()):
		if inventory_items[i] == null:
			inventory_items[i] = item
			selected_character.equipped_items.remove_at(slot_index)
			update_inventory_ui()
			update_equipment_slots()
			return

	# ── Fallback : aucune place dans le grid (improbable mais safe) ──
	# L'item reste dans gm.inventory. On retire quand même de equipped.
	selected_character.equipped_items.remove_at(slot_index)
	update_equipment_slots()
	select_character(selected_character)

# --------------------------------------------------------------------
# DROP SUR SLOT ÉQUIPEMENT
# --------------------------------------------------------------------

func _input(event):
	if event is InputEventMouseButton:
		if dragged_item == null:
			return

		var equipped := await  try_equip_on_character()

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

	# Une potion se boit, elle ne s'équipe pas.
	if dragged_item is Potion:
		return false

	if selected_character.equipped_items.size() >= 2:
		return false

	selected_character.equipped_items.append(dragged_item)

	# Sécurité : ne pas faire remove_at(-1) si l'item n'est pas dans
	# gm.inventory (peut arriver si la sync était cassée à un moment).
	var idx := gm.inventory.find(dragged_item)

	if idx >= 0:
		gm.inventory.remove_at(idx)


	await get_tree().create_timer(0.01).timeout
	update_equipment_slots()
	update_inventory_ui()
	select_character(selected_character)
	return true

func update_inventory_ui():

	for i in range(inventory_items.size()):
		var item = inventory_items[i]
		var cell = inventory_grid.get_child(i)
		var icon = cell.get_node("Icon")

		# Le cadre de case ("Bg") reste affiché en permanence : on ne remplit
		# plus que la couche du dessus, qui est vide quand la case l'est.
		icon.texture = item.icon if item != null else null

		# Compteur de pile (potions surtout, mais valable pour tout objet
		# dont `number` dépasse 1 — l'or par exemple).
		var count = cell.get_node_or_null("Count")
		if count != null:
			count.text = "x%d" % item.number if item != null and item.number > 1 else ""
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
	# Un chargement de partie émet le signal avec null : on reconstruit alors
	# toute la grille depuis gm.inventory plutôt que d'ajouter une case.
	if item == null:
		_rebuild_from_gm()
		return
	addItemToInventory(item)


## Resynchronise la grille sur gm.inventory (chargement de sauvegarde).
func _rebuild_from_gm() -> void:
	for i in range(inventory_items.size()):
		inventory_items[i] = null
	for it in gm.inventory:
		if it != null:
			addItemToInventory(it)
	update_inventory_ui()


# ════════════════════════════════════════════════════════════════════
#  INFOBULLE — mise en place
# ════════════════════════════════════════════════════════════════════
#  Dans la scène, ToolTipPanel est un PanelContainer de taille figée dont
#  le fond est un Sprite2D à l'échelle figée : ni l'un ni l'autre ne suit
#  la longueur du texte.
#
#  On le recâble ici, à l'exécution, plutôt que dans le .tscn : Godot
#  réécrit le fichier de scène depuis sa copie mémoire dès qu'elle est
#  ouverte dans l'éditeur, une modification faite hors éditeur serait donc
#  perdue à la sauvegarde suivante. Le faire en code le met à l'abri.
#
#  Structure obtenue :
#      ToolTipPanel
#        ├ Backdrop (ColorRect)      le fond opaque
#        ├ Frame    (NinePatchRect)  le cadre, bords d'épaisseur constante
#        └ Margin   (MarginContainer)
#           └ VBoxContainer          les libellés d'origine, inchangés
# ════════════════════════════════════════════════════════════════════

func _setup_tooltip() -> void:
	if tooltip_panel == null:
		return

	# Par nom : marche avec la structure d'origine comme avec la nouvelle.
	tooltip_name = tooltip_panel.find_child("ToolTipName", true, false) as RichTextLabel
	tooltip_desc = tooltip_panel.find_child("ToolTipDesc", true, false) as RichTextLabel

	_make_labels_grow(tooltip_name)
	_make_labels_grow(tooltip_desc)

	# Déjà recâblé (rechargement de scène, ou structure faite à la main).
	if tooltip_panel.has_node("Margin"):
		return

	var vbox := tooltip_panel.get_node_or_null("VBoxContainer") as Control
	if vbox == null:
		push_warning("InventoryUI : VBoxContainer de l'infobulle introuvable, taille non adaptative.")
		return

	# Le cadre d'origine est un Sprite2D : on lui emprunte sa texture, puis
	# on l'efface au profit du NinePatchRect.
	var frame_tex: Texture2D = null
	var old_box := tooltip_panel.get_node_or_null("UiConvoBox3") as Sprite2D
	if old_box != null:
		frame_tex = old_box.texture
		old_box.visible = false

	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = tooltip_backdrop_color
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(backdrop)
	tooltip_panel.move_child(backdrop, 0)

	if frame_tex != null:
		var frame := NinePatchRect.new()
		frame.name = "Frame"
		frame.texture = frame_tex
		frame.patch_margin_left = tooltip_frame_margin
		frame.patch_margin_top = tooltip_frame_margin
		frame.patch_margin_right = tooltip_frame_margin
		frame.patch_margin_bottom = tooltip_frame_margin
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip_panel.add_child(frame)
		tooltip_panel.move_child(frame, 1)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(tooltip_padding.x))
	margin.add_theme_constant_override("margin_right", int(tooltip_padding.x))
	margin.add_theme_constant_override("margin_top", int(tooltip_padding.y))
	margin.add_theme_constant_override("margin_bottom", int(tooltip_padding.y))
	tooltip_panel.add_child(margin)

	# Le VBox de la scène est déplacé tel quel sous la marge : polices,
	# alignements et couleurs réglés dans l'éditeur sont conservés.
	tooltip_panel.remove_child(vbox)
	margin.add_child(vbox)


## Un RichTextLabel ne grandit avec son texte que s'il a le droit de le
## couper (autowrap) et de se dimensionner dessus (fit_content).
func _make_labels_grow(label: RichTextLabel) -> void:
	if label == null:
		return
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_tooltip(item: Equipment, cell_position: Vector2):
	if item == null:
		hide_tooltip()
		return
	# Si la scène n'expose pas les libellés attendus, on n'affiche rien
	# plutôt que de planter sur une référence nulle.
	if tooltip_name == null or tooltip_desc == null:
		return

	_tooltip_seq += 1
	tooltip_name.text = item.name

	# Les potions décrivent leurs effets, pas des bonus d'équipement.
	if item is Potion:
		var potion := item as Potion
		tooltip_desc.bbcode_enabled = true
		var txt := ""
		if potion.description != "":
			txt += "[i]%s[/i]\n" % potion.description
		txt += potion.effects_bbcode()
		txt += "\n[color=888888][i]Click to drink[/i][/color]"
		tooltip_desc.text = txt
		tooltip_panel.visible = true
		_fit_and_place_tooltip(cell_position)
		return



	# Construit les stats dynamiquement
	var stats := ""
	if item.attack_bonus != 0:
		stats += "[color=FF6666]    Attaque: +%d[/color]\n" % item.attack_bonus
	if item.defense_bonus != 0:
		stats += "[color=6699FF]    Défense: +%d[/color]\n" % item.defense_bonus
	if item.willpower_bonus != 0:
		stats += "[color=CC99FF]    Volonté: +%d[/color]\n" % item.willpower_bonus
	if item.evasion_bonus != 0:
		stats += "[color=99FFCC]    Esquive: +%d[/color]\n" % item.evasion_bonus
	if item.initiative_bonus != 0:
		stats += "[color=FFFF66]    Initiative: +%d[/color]\n" % item.initiative_bonus
	if item.Max_stamina_bonus != 0:
		stats += "[color=FF9966]    Stamina max: +%d[/color]\n" % item.Max_stamina_bonus
	if item.Max_lust_bonus != 0:
		stats += "[color=FF66AA]    Lust max: +%d[/color]\n" % item.Max_lust_bonus
	if item.Max_Guilt_bonus != 0:
		stats += "[color=AAAAAA]    Stress max: +%d[/color]\n" % item.Max_Guilt_bonus

	tooltip_desc.bbcode_enabled = true
	# La description ET les stats. L'ancienne ligne était un ternaire mal
	# parenthésé ("  " + desc if desc else "" + stats) : dès qu'un objet avait
	# une description, ses bonus disparaissaient de l'infobulle.
	var desc := ""
	if item.description != "":
		desc = "[i]%s[/i]\n" % item.description
	tooltip_desc.text = desc + stats

	tooltip_panel.visible = true
	_fit_and_place_tooltip(cell_position)

func startmenu():
	gm.spawn_start_menu()
	gm.current_room_node.queue_free()

func hide_tooltip():
	_tooltip_seq += 1
	tooltip_panel.visible = false


## Redimensionne l'infobulle sur son contenu, puis la place.
## La largeur est fixe (tooltip_width) et les RichTextLabel sont en
## `fit_content` + autowrap : leur hauteur minimale suit donc le texte, et
## remettre `size.y` à 0 ramène le panneau pile à cette hauteur minimale —
## c'est ce qui le fait aussi bien grandir que rapetisser.
func _fit_and_place_tooltip(near: Vector2) -> void:
	var seq := _tooltip_seq

	# Largeur d'abord : c'est elle qui décide où le texte se coupe, donc la
	# hauteur qu'il faudra. On laisse ensuite passer une frame pour que les
	# labels recalculent leur hauteur avec cette largeur.
	tooltip_panel.size = Vector2(tooltip_width, 0.0)
	await get_tree().process_frame

	# La souris est peut-être déjà repartie ailleurs entre-temps.
	if seq != _tooltip_seq or not is_instance_valid(tooltip_panel):
		return

	tooltip_panel.size = Vector2(tooltip_width, 0.0)
	_reposition_tooltip(near)


func _reposition_tooltip(near: Vector2):
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tp_size: Vector2 = tooltip_panel.size
	var margin := 12.0
	var pos: Vector2 = near + Vector2(-16, 0)

	# Déborde à droite → passer à gauche du slot.
	# 136 = largeur slot (120) + marge (16).
	if pos.x + tp_size.x > viewport_size.x - margin:
		pos.x = near.x - tp_size.x - 136

	# Rabat dans l'écran. Le clamp porte sur la taille RÉELLE du panneau :
	# maintenant qu'il grandit avec le texte, une longue description ne doit
	# pas sortir par le bas.
	pos.x = clamp(pos.x, margin, max(margin, viewport_size.x - tp_size.x - margin))
	pos.y = clamp(pos.y, margin, max(margin, viewport_size.y - tp_size.y - margin))

	tooltip_panel.global_position = pos
