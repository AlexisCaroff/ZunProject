extends Node2D
class_name Campement

@onready var background=$ZunBg
@onready var portraitCharaselect = $charaPortrait
@export var chara_Camp_scene : PackedScene
@onready var action_panel = $ActionPanel
@onready var AttLabel = $AttLabel2
@onready var DefLabel = $DefLabel2
@onready var WillPowerLabel = $WillPower2
@onready var Stamina = $Stamina2
@onready var StaminaBar: ProgressBar = $StaminaProgressBar
@onready var guilt= $Guilt2
@onready var guiltBar: ProgressBar= $GuiltProgressBar
@onready var horny = $Horny2
@onready var hornyBar: ProgressBar = $LustProgressBar
@onready var CharacterName = $Charaname
## « Kinks : … » derrière le nom (cf. UI/kinks_label.gd).
var kinks_line: RichTextLabel = null
## Décalage des icônes de buff posées derrière le libellé « Buff: ».
@export var buffs_icons_nudge: Vector2 = Vector2.ZERO
var buff_row: BuffRow = null
var selected_chara: CharaCamp = null
@onready var exitButton =$ExitButton
@onready var slots =$HeroPosition .get_children() # conteneur des ExploPositionSlot
var characters: Array[CharaCamp] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null

var move_mode: bool = false
@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var donjon_map: Map = $SubViewportContainer/SubViewport/map

var DoorNumber:int =0
var gm : GameManager
var skillused : CampSkill =null
var campPoints: int = 10
## Stamina rendue à chaque héros en quittant le camp, si des points de camp
## ont été dépensés.
@export var exit_stamina_gain: int = 10
## Temps laissé au gain de stamina pour s'afficher avant la sortie (s).
@export var exit_feedback_delay: float = 1.2
var _start_camp_points: int = 10
var _leaving := false
var campPointLabel 
@export var codeActionButton = "res://scripts/camp/campActionButton.gd"
var skillcampmode : bool = true
@onready var TheTente:tente =$Tente
@onready var mapButton =$MapButton
@onready var QuitmapButton = $QuittMapButton
@onready var contourMap=$ContourMap
@onready var MenuPerso = $MenuPerso
## Les deux cases d'équipement sous le portrait (UI/UICombatItem.gd).
@onready var item_slots: Array = [$Items/Item1, $Items/Item2]
@onready var MenuPersoButton=$charaPortrait2/charaPortraitButton
@onready var CharactersAffinity= [
	$CharactersPanelAffinity/chara1,
	$CharactersPanelAffinity/chara2,
	$CharactersPanelAffinity/chara3
]

func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	MenuPerso.characters = gm.characters
	load_characters_from_gamestat()
	# Comme en exploration : les icônes se collent derrière le libellé
	# « Buff: » de la scène.
	var buffs_anchor := get_node_or_null("Buffs") as Control
	if buffs_anchor != null:
		buff_row = BuffRow.create(self,
				BuffRow.position_after(buffs_anchor) + buffs_icons_nudge,
				buffs_anchor, false, 20)
	selected_chara = characters[0]
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
	# Plus de soin à l'arrivée : la stamina se regagne en quittant le camp,
	# et seulement si des points de camp ont été dépensés (cf. _leave_camp).
	_start_camp_points = campPoints
	
	if donjon_map:
		donjon_map.focus_on_room(gm.current_room_Ressource,viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	
	changeSelectedCharacter(selected_chara)
	campPointLabel = $Box2/CampPoint
	campPointLabel.text= str(campPoints)
	
	MenuPersoButton.connect("button_down",showMenuPerso)
	if MenuPerso.has_signal("change_in_equipment"):
		MenuPerso.change_in_equipment.connect(_on_character_equipment_changed)
	_setup_bottom_hud()
	if gm.tutorial_once("camp_first"):
		_first_camp_intro()


const CAMP_FIRST_DIALOGUE := "res://dialogue/tuto/campFirst.tres"

## Première entrée au camp de la partie : dialogue de l'équipe, puis le
## didacticiel du camp (intro4, nœud Intro2 de la scène).
func _first_camp_intro() -> void:
	var res := load(CAMP_FIRST_DIALOGUE) as HistoryScene
	if res != null:
		var overlay := gm.show_history_scene(res)
		await overlay.history_finished
	var tuto := get_node_or_null("Intro2") as CanvasItem
	if tuto != null and is_inside_tree():
		tuto.visible = true
	
#func startLovescene():
	
	
func load_characters_from_gamestat():
	characters.clear()
	for i in gm.characters.size():
		var hero_data = gm.characters[i]
		var chara : CharaCamp = chara_Camp_scene.instantiate()
		chara.load_camp_chara(hero_data)
		add_child(chara)
		
		chara.camp= self

		# Placement dans le slot correspondant
		var slot_index = hero_data.Chara_position
		chara.campposition=slots[slot_index]
		chara.set_UI(slots[slot_index].get_ui())
		characters.append(chara)
		move_character_to_slot(chara, slots[slot_index])
		
		
		
func move_character_to_slot(chara: Node, slot: Node):
	if chara.get_parent():
		chara.get_parent().remove_child(chara)
	slot.add_child(chara)
	chara.global_position = slot.global_position
	chara.campposition = slot
	slot.occupant=chara
	

func changeSelectedCharacter(occupant:CharaCamp):
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	show_chara_actions(occupant)
	updateUICharacter(occupant.characterData)
	occupant.animate_selected()
	if card_hand != null:
		card_hand.refresh_state()


# ════════════════════════════════════════════════════════════════════
#  CARTES D'AFFINITÉ (UI/cards/card_hand.gd)
# ════════════════════════════════════════════════════════════════════
#  Le personnage sélectionné joue la carte : on la glisse sur la cible.

# ════════════════════════════════════════════════════════════════════
#  COIN BAS-DROIT : même présentation qu'en exploration
# ════════════════════════════════════════════════════════════════════
#  Petite carte, sac d'équipe et cartes d'affinité se partagent la zone ;
#  boutons carte / sac / fiche personnage / cartes alignés au-dessus.
#  Construit en code (positions de l'exploration) : l'ancienne grande carte
#  plein écran et son bouton de fermeture ne servent plus.

const HUD_RECT := Rect2(1223, 776, 679, 292)
const BAG_ICON := preload("res://UI/UI inventory/UI_inventory_button_bag.png")
const MAP_ICON := preload("res://UI/UI boxes/UI_button_map_on.png")
const ITEM_BOX := preload("res://UI/UI boxes/UI_combat_itembox.png")
const MENU_ICON := preload("res://UI/UI boxes/charaIcon.png")

var card_hand: CardHand = null
var inventory_panel: DoorInventory = null
var map_bag_buttons: Dictionary = {}
## Vue affichée dans le coin : "map", "bag" ou "cards".
var hud_view := "cards"


func _setup_bottom_hud() -> void:
	# ── Petite carte (comme l'exploration) ──
	# Même placement de départ que l'exploration ; HudFrame la recale
	# ensuite sur le rectangle commun (carte, sac, cartes).
	var map_box := $SubViewportContainer as Control
	viewport.size = Vector2i(690, 271)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if donjon_map:
		donjon_map.position = Vector2(218, 140)
		donjon_map.scale = Vector2(0.4, 0.4)
	mapButton.visible = false
	QuitmapButton.visible = false

	# ── Boutons carte / sac (même bouton que l'exploration, dédoublé) ──
	var toggle := Button.new()
	toggle.name = "ToggleMapInventory"
	toggle.flat = true
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.offset_left = 1790
	toggle.offset_top = 719
	toggle.offset_right = 1894
	toggle.offset_bottom = 823
	toggle.z_as_relative = false
	toggle.z_index = 10
	var icon := Sprite2D.new()
	icon.name = "IconBag"
	icon.position = Vector2(52, 52)
	icon.scale = Vector2(0.35, 0.35)
	icon.texture = BAG_ICON
	var box := Sprite2D.new()
	box.texture = ITEM_BOX
	box.show_behind_parent = true
	box.position = Vector2(1.99515, 4.85217)
	box.scale = Vector2(2.21487, 2.26929)
	icon.add_child(box)
	toggle.add_child(icon)
	add_child(toggle)
	map_bag_buttons = MapBagButtons.split(toggle, MAP_ICON, BAG_ICON, 88.0)
	map_bag_buttons.map.pressed.connect(_show_hud.bind("map"))
	map_bag_buttons.bag.pressed.connect(_show_hud.bind("bag"))

	# ── Sac d'équipe ──
	inventory_panel = DoorInventory.create_panel(HUD_RECT)
	inventory_panel.columns = 7
	inventory_panel.cell_size = Vector2(72, 72)
	inventory_panel.cell_separation = 4
	inventory_panel.visible = false
	add_child(inventory_panel)
	inventory_panel.set_target_provider(func():
		return selected_chara.characterData if selected_chara != null else null)
	inventory_panel.potion_used.connect(func(_p, _t): _refresh_after_bag())
	inventory_panel.item_equipped.connect(func(_i, _t): _refresh_after_bag())
	if not gm.inventory_changed.is_connected(_on_bag_changed):
		gm.inventory_changed.connect(_on_bag_changed)

	# ── Fiche personnages, à gauche du sac (comme à la porte) ──
	var bag := map_bag_buttons.bag as Control
	var menu_btn := Button.new()
	menu_btn.name = "ButtonMenuPerso"
	menu_btn.flat = true
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.tooltip_text = "Characters"
	menu_btn.offset_left = toggle.offset_left - 176.0
	menu_btn.offset_top = toggle.offset_top
	menu_btn.offset_right = toggle.offset_right - 176.0
	menu_btn.offset_bottom = toggle.offset_bottom
	menu_btn.z_as_relative = false
	menu_btn.z_index = 10
	var micon := Sprite2D.new()
	micon.texture = MENU_ICON
	micon.position = Vector2(52, 52)
	micon.scale = Vector2.ONE * (56.0 / float(MENU_ICON.get_width()))
	menu_btn.add_child(micon)
	MapBagButtons.ensure_box(menu_btn)
	MapBagButtons.add_hover(menu_btn)
	menu_btn.pressed.connect(showMenuPerso)
	add_child(menu_btn)
	var old_menu := get_node_or_null("charaPortrait2") as CanvasItem
	if old_menu != null:
		old_menu.visible = false

	# ── Cartes d'affinité : ouvertes par défaut, c'est ici qu'elles se jouent ──
	card_hand = CardHand.install_hud(self, [map_bag_buttons.map, bag, menu_btn],
			inventory_panel, true)
	card_hand.visible = true
	HudFrame.install(self, HUD_RECT, map_box, contourMap, inventory_panel,
			[map_bag_buttons.map, bag, menu_btn, card_hand.toggle_button])
	card_hand.refusal = card_refusal
	card_hand.card_dropped.connect(_on_card_dropped)
	card_hand.opened_changed.connect(func(open: bool):
		if open:
			_show_hud("cards")
		elif hud_view == "cards":
			_show_hud("map"))
	_show_hud("cards")


func _show_hud(view: String) -> void:
	hud_view = view
	var map_box := $SubViewportContainer as CanvasItem
	map_box.visible = view == "map"
	contourMap.visible = view == "map"
	if inventory_panel != null:
		inventory_panel.visible = view == "bag"
		if view == "bag":
			inventory_panel.refresh(gm.inventory)
	if view != "cards" and card_hand != null:
		card_hand.close()
	if not map_bag_buttons.is_empty():
		map_bag_buttons.map.modulate = MapBagButtons.ACTIVE if view == "map" else MapBagButtons.INACTIVE
		map_bag_buttons.bag.modulate = MapBagButtons.ACTIVE if view == "bag" else MapBagButtons.INACTIVE


func _on_bag_changed(_item = null) -> void:
	if hud_view == "bag" and inventory_panel != null:
		inventory_panel.refresh(gm.inventory)


## Potion bue ou objet équipé depuis le sac : jauges et fiche à jour.
func _refresh_after_bag() -> void:
	for c in characters:
		if c is CharaCamp:
			c.update_display()
	if selected_chara != null:
		updateUICharacter(selected_chara.characterData)
		update_equipment_icons(selected_chara.characterData)


## Pourquoi `user` ne peut pas jouer `card` maintenant ("" = possible).
func card_refusal(card: AffinityCard, user: CharaCamp = null) -> String:
	if user == null:
		user = selected_chara
	if user == null:
		return "Select a character first."
	if not card.can_be_played_by(user.characterData):
		return "Only the %s can play this card." % card.user_name
	if card.cost > campPoints:
		return "Not enough camp points."
	return ""


func _on_card_dropped(card: AffinityCard) -> void:
	var target := _chara_under_mouse()
	if target == null:
		return   # lâchée dans le vide : rien ne se passe
	play_card(card, target)


func _chara_under_mouse() -> CharaCamp:
	for c in characters:
		if not (c is CharaCamp) or not is_instance_valid(c):
			continue
		var spr = c.sprite
		if spr is Control:
			if (spr as Control).get_global_rect().has_point(spr.get_global_mouse_position()):
				return c
		elif spr is Sprite2D:
			if (spr as Sprite2D).get_rect().has_point(spr.get_local_mouse_position()):
				return c
	return null


## Joue `card` : le personnage sélectionné en est l'auteur, `target` est le
## personnage sur lequel la carte a été déposée.
func play_card(card: AffinityCard, target: CharaCamp) -> void:
	var user := selected_chara
	var why := card_refusal(card, user)
	if why != "":
		if user != null:
			user.say(why)
		return
	var targets: Array[CharaCamp] = []
	match card.target:
		AffinityCard.Target.SELF:
			targets = [user]
		AffinityCard.Target.OTHER_ALLY:
			if target == user:
				user.say("I should play this on someone else.")
				return
			targets = [target]
		AffinityCard.Target.ANY_ALLY:
			targets = [target]
		AffinityCard.Target.OTHERS:
			for c in characters:
				if c is CharaCamp and c != user:
					targets.append(c)
		_:
			for c in characters:
				if c is CharaCamp:
					targets.append(c)

	# Comme une capacité de camp : on sort les occupants de la tente.
	if not TheTente.twoInside.is_empty():
		TheTente.loved_one_go_out()
	if TheTente.somoneInside != null:
		TheTente.masturbin_go_out()

	mark_camp_used()
	campPoints -= card.cost
	campPointLabel.text = str(campPoints)
	gm.remove_card(card)
	user.animate_selected()
	for effect in card.effects:
		if effect == null:
			continue
		for t in targets:
			effect.apply(user, t)
	for c in characters:
		if c is CharaCamp:
			c.update_display()
	updateUICharacter(selected_chara.characterData)
	refresh_buffs(selected_chara.characterData)
	if MenuPerso.selected_character != null:
		MenuPerso.select_character(MenuPerso.selected_character)
	card_hand.refresh_state()
	
## Redessine la ligne des buffs ; appelé aussi par CharaCamp.add_buff quand
## une action de camp en ajoute un au personnage affiché.
func refresh_buffs(character: CharacterData) -> void:
	if buff_row != null:
		buff_row.show_for(character)


## Même remplissage qu'en exploration (exploration_manager.gd).
func update_equipment_icons(character: CharacterData) -> void:
	for slot in item_slots:
		slot.remove_item()
	for i in range(min(character.equipped_items.size(), item_slots.size())):
		item_slots[i].assigne_item(character.equipped_items[i])


## Équipement modifié depuis le menu personnage : on redessine la fiche du
## héros affiché (les stats bougent avec l'objet).
func _on_character_equipment_changed(_chara: CharacterData) -> void:
	if selected_chara != null:
		updateUICharacter(selected_chara.characterData)


## Appelé par les portraits d'affinité du panneau du haut
## (CharaIventoryUI.gd) : sélectionne le héros correspondant dans le camp.
func select_character(chara: CharacterData) -> void:
	for c in characters:
		if c.characterData == chara:
			changeSelectedCharacter(c)
			return


func updateUICharacter(character:CharacterData):
	portraitCharaselect.texture = character.explorationPortrait
	CharacterName.text = character.Name
	if kinks_line == null:
		kinks_line = KinksLabel.after_name(CharacterName)
	KinksLabel.show_for(kinks_line, character)
	# Même présentation qu'en exploration : l'icône dit la stat, le libellé
	# ne porte que la valeur.
	character.recompute_stats()
	AttLabel.text = " %d" % character.attack
	DefLabel.text = " %d" % character.defense
	WillPowerLabel.text = " %d" % character.willpower
	Stamina.text = "%d / %d" % [character.current_stamina, character.max_stamina]
	StaminaBar.max_value = character.max_stamina
	StaminaBar.value=character.current_stamina
	guilt.text = "%d / %d" % [character.current_stress, character.max_stress]
	guiltBar.max_value=character.max_stress
	guiltBar.value=character.current_stress
	horny.text = "%d / %d" % [character.current_horniness, character.max_horniness]
	hornyBar.max_value = character.max_horniness
	hornyBar.value =character.current_horniness
	refresh_buffs(character)
	update_equipment_icons(character)
	
	var other_members : Array = []
	for c in characters:
		if c.characterData != character:
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
			if character.affinity.has(target.characterData.Charaname):
				value = character.affinity[target.characterData.Charaname]
			slot.set_chara(target.characterData, value)
		

			
			rtl.text = target.characterData.Name

			slot.visible = true

		else:
			slot.visible = false
	
	
	
	selected_chara.update_display()
	MenuPerso.select_character(MenuPerso.selected_character)
	
## Le campement de la salle n'est consommé qu'ici, à la première capacité
## utilisée : on peut entrer puis ressortir gratuitement tant qu'on n'a rien
## fait (mauvais clic sur le feu de camp).
func mark_camp_used() -> void:
	if gm != null and gm.current_room_Ressource != null:
		gm.current_room_Ressource.CampDone = true


func After_camp_skill(skill: CampSkill):
	campPoints -= skill.cost
	
	campPointLabel.text= str(campPoints)
	for c in characters:
				if c is CharaCamp:
					c.set_targetable(false)
					c.update_display()
	skill.used =true
	skillused=null
	exitButton.visible = false
	
	
	
func noCharacterSelected():
	return
		
		
func clear_container(container: Node) -> void:
	for child in container.get_children():
		# queue_free() est préférable à remove_child + free pour éviter les dépendances
		if is_instance_valid(child):
			child.queue_free()
			
func show_chara_actions(thechara: CharaCamp):
	var chara = thechara.characterData 
	selected_chara = thechara
	(selected_chara.sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
	# vide les panels
	clear_container(action_panel)

	# sécurité : pas de skills -> rien à faire
	if not chara or chara.camp_skill_resources.is_empty():
		return

	# charger ton script de bouton custom
	var action_button_script = load(codeActionButton )

	for i in range(chara.camp_skill_resources.size()):
		var skill: CampSkill = thechara.camp_skills[i]

		# Création d'un bouton d'action avec script custom
		var btn := Button.new()
		btn.set_script(action_button_script)

		# setup de base
		btn.flat=true
		btn.name = "Action" + str(i + 1)
		btn.tooltip_text = skill.description
		if skill.icon:
			btn.icon = skill.icon
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("focus", empty_style)
		# Même bouton qu'en combat : 90 px, icône étirée au bouton, contour
		# du shader prêt à s'allumer.
		btn.custom_minimum_size= Vector2(90,90)
		btn.size=Vector2(90,90)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var mat := ShaderMaterial.new()
		mat.shader = load("res://characters/character_outline.gdshader")
		mat.set_shader_parameter("enabled", false)
		mat.set_shader_parameter("outline_direction", Vector2.ZERO)
		btn.material = mat
		btn.Actiontext = skill.name
		if skill.cost>campPoints:
			btn.disabled=true
		if skill.used && not skill.name== "Dialogue":
			btn.disabled=true
		btn.pressed.connect(Callable(self, "_on_camp_skill_pressed").bindv([skill, thechara]))

		action_panel.add_child(btn)

		
		
		
## Vrai si ce camp skill mene a une scene d'amour : c'est le seul cas ou
## l'attirance filtre les cibles.
func _skill_is_romantic(skill: CampSkill) -> bool:
	if skill == null:
		return false
	for effect in skill.effects:
		if effect is CampLoveEffect:
			return true
	return false


## Affinité minimale (du lanceur envers la cible) pour une action d'amour.
## 0 = aucune condition d'affinité, seule l'attirance compte.
@export var love_min_affinity: int = 0


## Raison pour laquelle `target` refuse une action d'amour de `user`, dite
## par `target` ; "" si rien ne s'y oppose.
func love_refusal(user: CharaCamp, target: CharaCamp) -> String:
	var u: CharacterData = user.characterData
	var t: CharacterData = target.characterData
	if not t.is_attracted_to(u):
		return "Sorry, I'm not into %s." % _kind_plural(u)
	if not u.is_attracted_to(t):
		return "%s isn't into %s like me." % [u.Name, _kind_plural(t)]
	if love_min_affinity > 0 and int(u.affinity.get(t.Charaname, 0)) < love_min_affinity:
		return "We're not close enough yet."
	return ""


func _kind_plural(c: CharacterData) -> String:
	match c.presentation:
		CharacterData.Presentation.FEMININE:
			return "women"
		CharacterData.Presentation.MASCULINE:
			return "men"
	return "people like you"


## Clic sur un personnage que l'action d'amour en cours ne peut pas viser :
## il explique pourquoi dans une bulle (cf. CampPosition).
func show_love_refusal(target: CharaCamp) -> bool:
	# exitButton visible = on est bien en train de choisir une cible.
	if skillused == null or not exitButton.visible or not _skill_is_romantic(skillused) \
			or selected_chara == null or target == selected_chara:
		return false
	var reason := love_refusal(selected_chara, target)
	if reason == "":
		return false
	target.say(reason)
	return true


func _on_camp_skill_pressed(skill: CampSkill, user: CharaCamp) -> void:
	# Exemple d'utilisation simple selon le target_type
	
	if !skillcampmode:
		return
	if skill.cost>campPoints:
		return
	if not TheTente.twoInside.is_empty(): 
		TheTente.loved_one_go_out()
	if TheTente.somoneInside != null:
		TheTente.masturbin_go_out()
	skillused= skill
	match skill.target_type:
		CampSkill.TargetType.SELF:
			user.set_targetable(true)
		CampSkill.TargetType.ALLY:
			# ouvrir une UI de sélection de cible (à implémenter) ; pour l'instant on choisit le premier allié valide
			# Un skill romantique ne peut viser que les allies dont l'attirance
			# est reciproque (tiree en debut de partie par TasteRollMenu).
			var romantic := _skill_is_romantic(skill)
			for c in characters:
				if c is CharaCamp and c != user:
					if romantic and love_refusal(user, c) != "":
						continue
					c.set_targetable(true)

		CampSkill.TargetType.ALL_ALLIES:
			var targets: Array[CharaCamp] = characters
			skill.use(user, targets)
			print ("use skill on ", )
	exitButton.visible=true
	

func endcamp():
	
	
	
	# Ces lignes appelaient GameState.save_party_from_camp() / save_finished,
	# qui n'ont jamais existé sur GameStat : la sortie du camp plantait.
	# L'état du party vit dans les CharacterData, déjà à jour ici ; la
	# sauvegarde est prise en charge par l'autosave de return_to_exploration().
	if SaveManager.is_busy():
		push_warning("Sauvegarde déjà en cours…")
		return

	GameState.current_phase = GameStat.GamePhase.EXPLORATION
	await get_tree().process_frame

	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	if gm == null or gm.current_room_Ressource == null:
		push_error("GameManager introuvable ou current_room vide")
		return
	if gm.current_room_Ressource.exploration_scene == null:
		push_error("Pas de scene exploration définie pour cette salle")
		return
	# Un seul chargement : l'ancien code appelait _enter_scene_in_current_room()
	# ET return_to_exploration(), ce qui instanciait la salle deux fois.
	gm.return_to_exploration()
func focus_on_room(room: Node2D):
	
	var target_pos = room.position
	var tween = create_tween()
	donjon_map.move_to_position(donjon_map.curentposition)
	tween.tween_property(donjon_map.camera, "position", target_pos, 0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_exit_button_button_down() -> void:
	for c in characters:
				if c is CharaCamp:
					c.set_targetable(false)
	skillused=null
	exitButton.visible = false

func _on_button_button_down() -> void:
	_leave_camp()


## Sortie du camp. Si des points de camp ont été dépensés, chaque héros
## regagne de la stamina et on laisse le temps de voir le gain avant de
## partir ; sinon la sortie est immédiate (et gratuite, cf. mark_camp_used).
func _leave_camp() -> void:
	if _leaving:
		return
	_leaving = true
	if campPoints < _start_camp_points and exit_stamina_gain > 0:
		for chara in characters:
			if not (chara is CharaCamp):
				continue
			var cd: CharacterData = chara.characterData
			cd.current_stamina = min(cd.max_stamina, cd.current_stamina + exit_stamina_gain)
			chara.animate_heal(exit_stamina_gain, chara)
			chara.update_display()
		if selected_chara != null:
			updateUICharacter(selected_chara.characterData)
		await get_tree().create_timer(exit_feedback_delay).timeout
	gm.return_to_exploration()
func toggleshowMap():
	var subviewport=$SubViewportContainer
	subviewport.visible= !subviewport.visible
	QuitmapButton.visible = !QuitmapButton.visible
	contourMap.visible= !contourMap.visible
func showMenuPerso():
	MenuPerso.visible=true
