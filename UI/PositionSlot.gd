extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false
var combat_manager
@onready var  button: Button = $Button
var selfposition: Array[PositionSlot] = []
@onready var CharaUI = $"charaCombatUI"
@onready var shadow =$"TextureRect2"

var is_ready: bool = false



#@onready var click_button = $Button  # ou le nom de ton bouton dans le slot


func inside() -> Character:
	if occupant == null:
		push_error("Erreur : nobody inside"+name)
	return occupant

func is_occupied() -> bool:
	return occupant != null

func _ready():
	selfposition.append(self)
	is_ready= true
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.connect("mouse_entered",_on_button_mouse_entered )
	button.connect("mouse_exited",_on_button_mouse_exited )
	button.connect("button_down",_on_button_button_down)
	if GameState.current_phase == GameStat.GamePhase.COMBAT:
		combat_manager = $"../../CombatManager"

func Set_CharaUI():
	CharaUI = $"charaCombatUI"

func assign_character(character: Character, movetime:float):
	# Lu AVANT l'attente : move_character_to réécrit _current_slot tout de suite.
	var old_slot: PositionSlot = character._current_slot
	await get_tree().process_frame
	if not is_instance_valid(character):
		return
	shadow.modulate.a =0.349
	occupant = character
	# L'ancienne position ne doit plus afficher la barre de ce personnage.
	if old_slot != null and old_slot != self and is_instance_valid(old_slot) 			and old_slot.occupant == character:
		old_slot.release()
	occupant.CharaScale = position_data.scale
	if CharaUI == null :
		CharaUI = $"charaCombatUI"
		print("charaUI is null")
	occupant.hornyJauge =CharaUI.HornyBar
	occupant.hp_Jauge=CharaUI.HPProgressBar
	occupant.LustProgressBar=CharaUI.LustProgressBar
	occupant.attach_buff_bar(CharaUI.get_buff_bar())
	if occupant.characterData.is_player_controlled and combat_manager != null \
			and combat_manager.get("lust_hidden") == true:
		combat_manager.set_chara_ui_lust_visible(CharaUI, false)

	occupant.dotsActions = CharaUI.actionpoints
	occupant.z_index=self.z_index
	if occupant.characterData.is_player_controlled==false:
		for actionpoint in CharaUI.actionpoints:
			actionpoint.visible=false
		CharaUI.TheHornyBar.visible=false
		CharaUI.LustProgressBar.visible=false
		CharaUI.LustProgressBarSeparator.visible=false

	#print("chara assigned to position")
	if not is_ready:
		await ready

	character._current_slot = self
	# Les jauges de cette position montraient l'occupant précédent : on les
	# remplit avec celui qui arrive (après un échange, chacun les siennes).
	character.update_ui()
	#print(character.Charaname,"→ current_slot défini à ", self.name)

	var tween = get_tree().create_tween()
	tween.parallel().tween_property(character, "global_position", self.global_position, movetime).set_delay(0.2)
	tween.parallel().tween_property(character, "scale", position_data.scale, movetime).set_delay(0.2)
	await tween.finished
	if not is_instance_valid(character):
		return
	if character != null:
		character.CharaScale= position_data.scale
		character.global_position=self.global_position
		character.set_scale(position_data.scale)

	if position_data.buff:
		position_data.buff.apply(character, character)
	# Pendant le trajet, le personnage a pu repartir ailleurs ou mourir.
	if occupant == character and not character.dead:
		CharaUI.visible=true

	shadow.modulate.a =0.3

## Libère la position sans toucher au personnage (il est déjà ailleurs).
func release() -> void:
	occupant = null
	if CharaUI != null:
		CharaUI.visible = false
	shadow.modulate.a = 0.1


## Filet de sécurité : une position n'affiche une barre de vie que si elle
## est réellement occupée par un personnage vivant qui s'y trouve encore.
func _hide_stale_ui() -> void:
	if CharaUI == null or not CharaUI.visible:
		return
	if occupant != null and not is_instance_valid(occupant):
		occupant = null
	if occupant == null:
		CharaUI.visible = false
		return
	if occupant.dead:
		release()
		return
	# Mommy occupe deux positions : seule la première est son _current_slot.
	if occupant._current_slot != self and not combat_manager._is_anchored(occupant):
		release()


func remove_character():
	if occupant:
		occupant.resetVisuel()
		occupant = null
	CharaUI.visible=false
	shadow.modulate.a =0.1


## Vrai si la capacité contient un déplacement (Move) : elle peut alors
## viser une position alliée vide, pas seulement échanger avec un allié.
static func skill_moves(skill: Skill) -> bool:
	if skill == null:
		return false
	for e in skill.effects:
		if e is Move:
			return true
	return false


## Position alliée vide que le héros actif peut rejoindre avec Move.
func is_empty_move_target() -> bool:
	if occupant != null or combat_manager == null or not is_instance_valid(combat_manager):
		return false
	if combat_manager.combat_state != combat_manager.CombatState.SELECTING_FIRST_TARGET:
		return false
	var skill: Skill = combat_manager.pending_skill
	if not skill_moves(skill) or not skill.can_use():
		return false
	if not combat_manager.hero_positions.has(self):
		return false
	var cur: Character = combat_manager.current_character
	if cur == null or not cur.characterData.is_player_controlled or cur.is_dead():
		return false
	if cur.characterData.get("immobilized") == true:
		return false
	return not combat_manager.is_animation_playing()


# Surbrillance de l'ombre des positions vides atteignables.
var _move_hint := false
var _hovered := false

func _process(_delta: float) -> void:
	if combat_manager == null or not is_instance_valid(combat_manager):
		return
	_hide_stale_ui()
	var hint := is_empty_move_target()
	if hint:
		shadow.modulate = Color(1.0, 0.85, 0.4, 0.85 if _hovered else 0.45)
	elif _move_hint and occupant == null:
		shadow.modulate = Color(1, 1, 1, 0.1)
	_move_hint = hint


func _on_button_button_down() -> void:
	if is_empty_move_target():
		combat_manager._on_target_selected(selfposition)
		return
	if occupant and occupant.is_targetable:
		print("clic")
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.SELF:
						combat_manager._on_target_selected(selfposition)
						print("self targeted")

					Skill.target_type.ALLY:
						combat_manager._on_target_selected(selfposition)
						print("one ally targeted")

					Skill.target_type.ENNEMY:
						combat_manager._on_target_selected(selfposition)
						print("one enemy targeted")

					Skill.target_type.ALL_ALLY:
						combat_manager._on_target_selected(combat_manager.hero_positions)
						print("all allies targeted")

					Skill.target_type.ALL_ENNEMY:
						combat_manager._on_target_selected(combat_manager.enemy_positions)
						print("all enemies targeted")
					Skill.target_type.BACK_ENNEMY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.FRONT_ENNEMY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.BACK_ALLY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.FRONT_ALLY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.EVERYONE:
						combat_manager._on_target_selected(selfposition)

					# --- NOUVEAUX ---
					Skill.target_type.EVERY_OTHER:
						combat_manager._on_target_selected(selfposition)
						print("one other targeted")
					Skill.target_type.EVERYONE_ALL:
						var all_positions: Array[PositionSlot] = []
						all_positions.append_array(combat_manager.hero_positions)
						all_positions.append_array(combat_manager.enemy_positions)
						combat_manager._on_target_selected(all_positions)
						print("everyone all targeted")
					Skill.target_type.ALL_ALLY_AND_ENNEMY_FRONT:
						combat_manager._on_target_selected(selfposition)
						print("one front (ally or enemy) targeted")

			combat_manager.CombatState.SELECTING_SECOND_TARGET:
				match skill.the_second_target_type:
					Skill.second_target_type.SELF:
						combat_manager._on_target_selected(selfposition)
						print("2 self targeted")

					Skill.second_target_type.ALLY:
						combat_manager._on_target_selected(selfposition)
						print("2 one ally targeted")

					Skill.second_target_type.ENNEMY:
						combat_manager._on_target_selected(selfposition)
						print("2 one enemy targeted")

					Skill.second_target_type.ALL_ALLY:
						combat_manager._on_target_selected(combat_manager.hero_positions)
						print("2 all allies targeted")

					Skill.second_target_type.ALL_ENNEMY:
						combat_manager._on_target_selected(combat_manager.enemy_positions)
						print("2 all enemies targeted")
					Skill.second_target_type.BACK_ENNEMY:
						combat_manager._on_target_selected(selfposition)
					Skill.second_target_type.FRONT_ENNEMY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.BACK_ALLY:
						combat_manager._on_target_selected(selfposition)
					Skill.target_type.FRONT_ALLY:
						combat_manager._on_target_selected(selfposition)
					Skill.second_target_type.EVERYONE:
						combat_manager._on_target_selected(selfposition)

					# --- NOUVEAUX (second target) ---
					Skill.second_target_type.EVERY_OTHER:
						combat_manager._on_target_selected(selfposition)
					Skill.second_target_type.EVERYONE_ALL:
						var all_positions2: Array[PositionSlot] = []
						all_positions2.append_array(combat_manager.hero_positions)
						all_positions2.append_array(combat_manager.enemy_positions)
						combat_manager._on_target_selected(all_positions2)
					Skill.second_target_type.ALL_ALLY_AND_ENNEMY_FRONT:
						combat_manager._on_target_selected(selfposition)

func _on_button_mouse_entered() -> void:
	_hovered = true
	if occupant == null:
		return
	combat_manager.ui.update_ui_for_overed_character(occupant)
	if combat_manager.pending_skill:
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.ALLY:
						if occupant.characterData.is_player_controlled:
							occupant.Higlight()
					Skill.target_type.FRONT_ALLY:
						if occupant.characterData.is_player_controlled:
							occupant.Higlight()
					Skill.target_type.FRONT_ENNEMY:
						if !occupant.characterData.is_player_controlled:
							occupant.Higlight()
					Skill.target_type.BACK_ALLY:
						occupant.Higlight()
					Skill.target_type.BACK_ENNEMY:
						if !occupant.characterData.is_player_controlled:
							occupant.Higlight()
					Skill.target_type.ENNEMY:
						if !occupant.characterData.is_player_controlled:
							occupant.Higlight()
					Skill.target_type.ALL_ALLY:
						for chara in combat_manager.hero_positions:
							if chara.occupant != null:
								chara.occupant.Higlight()
					Skill.target_type.ALL_ENNEMY:
						for chara in combat_manager.enemy_positions:
							if chara.occupant != null:
								chara.occupant.Higlight()

					# --- NOUVEAUX ---
					Skill.target_type.EVERY_OTHER:
						# Tout le monde sauf le lanceur
						if occupant != combat_manager.current_character:
							occupant.Higlight()
					Skill.target_type.EVERYONE_ALL:
						# Hover sur quelqu'un = highlight de TOUT le monde
						for chara in combat_manager.hero_positions:
							if chara.occupant != null:
								chara.occupant.Higlight()
						for chara in combat_manager.enemy_positions:
							if chara.occupant != null:
								chara.occupant.Higlight()
					Skill.target_type.ALL_ALLY_AND_ENNEMY_FRONT:
						# Tous les alliés OU un ennemi en FRONT
						if occupant.characterData.is_player_controlled:
							occupant.Higlight()
						elif occupant._current_slot != null \
								and occupant._current_slot.position_data.isFront:
							occupant.Higlight()
	else :
		occupant.Higlight()
	_show_skill_preview()


## Aperçu de la capacité en cours de ciblage au-dessus des cibles qu'un clic
## ici toucherait (toutes pour une capacité de zone, cf. _on_button_button_down).
func _show_skill_preview() -> void:
	if not occupant.is_targetable or combat_manager.pending_skill == null:
		return
	var skill: Skill = combat_manager.pending_skill
	var group := -1
	match combat_manager.combat_state:
		combat_manager.CombatState.SELECTING_FIRST_TARGET:
			group = skill.the_target_type
		combat_manager.CombatState.SELECTING_SECOND_TARGET:
			group = skill.the_second_target_type
		_:
			return
	var slots: Array = [self]
	match group:
		Skill.target_type.ALL_ALLY:
			slots = combat_manager.hero_positions
		Skill.target_type.ALL_ENNEMY:
			slots = combat_manager.enemy_positions
		Skill.target_type.EVERYONE_ALL:
			slots = combat_manager.hero_positions + combat_manager.enemy_positions
	var targets: Array = []
	for slot in slots:
		if slot != null and slot.occupant != null:
			targets.append(slot.occupant)
	SkillPreview.show_for(combat_manager, targets)


func _on_button_mouse_exited() -> void:
	_hovered = false
	if occupant == null:
		return

	SkillPreview.clear(combat_manager)
	occupant.resetHighlight()
	if combat_manager.pending_skill:
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.ALL_ALLY:
						for chara in combat_manager.hero_positions:
							if chara.occupant != null:
								chara.occupant.resetHighlight()
					Skill.target_type.ALL_ENNEMY:
						for chara in combat_manager.enemy_positions:
							if chara.occupant != null:
								chara.occupant.resetHighlight()

					# --- NOUVEAU : reset le highlight de groupe ---
					Skill.target_type.EVERYONE_ALL:
						for chara in combat_manager.hero_positions:
							if chara.occupant != null:
								chara.occupant.resetHighlight()
						for chara in combat_manager.enemy_positions:
							if chara.occupant != null:
								chara.occupant.resetHighlight()
