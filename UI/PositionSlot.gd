extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false
var combat_manager 
@onready var imageinside = $TextureRect
var selfposition: Array[PositionSlot] = []

var is_ready: bool = false

signal slot_selected(slot: PositionSlot)

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
	if GameState.current_phase == GameStat.GamePhase.COMBAT:
		combat_manager = $"../../CombatManager"

func assign_character(character: Character, movetime:float):
	occupant = character
	occupant.CharaScale = position_data.scale
	if not is_ready:
		await ready
	imageinside.texture=character.initiative_icon
	character.current_slot = self
	#print(character.Charaname,"→ current_slot défini à ", self.name)
	var tween2 = get_tree().create_tween()
	var tween = get_tree().create_tween()
	tween.tween_property(character, "global_position", global_position, movetime)
	tween2.tween_property(character, "scale", position_data.scale, movetime)
	await tween.finished
	await tween2.finished
	character.CharaScale= position_data.scale
	character.set_scale(position_data.scale)
	
	if position_data.buff:
		position_data.buff.apply(character, character)

func remove_character():
	if occupant:
		occupant.resetVisuel()
		occupant = null
		

func _on_button_button_down() -> void:
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

func _on_button_mouse_entered() -> void:
	if occupant == null:
		return
	combat_manager.ui.update_ui_for_current_character(occupant)
	if combat_manager.pending_skill:
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.ALLY:
						if occupant.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.FRONT_ALLY:
						if occupant.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.FRONT_ENNEMY:
						if !occupant.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.BACK_ALLY:
						occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.BACK_ENNEMY:
						if !occupant.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.ENNEMY:
						if !occupant.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.ALL_ALLY:
						for chara in combat_manager.hero_positions:
							if chara.occupant !=null:
								chara.occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.ALL_ENNEMY:
						for chara in combat_manager.enemy_positions:
							if chara.occupant !=null:
								chara.occupant.Selector.self_modulate.a=1.0
	else :
		occupant.Selector.self_modulate.a= 1.0
	


func _on_button_mouse_exited() -> void:
	
	if occupant == null:
		return
	combat_manager.ui.update_ui_for_current_character(combat_manager.current_character)
	occupant.Selector.self_modulate.a= 0.0
	if combat_manager.pending_skill:
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.ALL_ALLY:
						for chara in combat_manager.hero_positions:
							chara.occupant.Selector.self_modulate.a= 0.0
					Skill.target_type.ALL_ENNEMY:
						for chara in combat_manager.enemy_positions:
							if chara.occupant !=null:
								chara.occupant.Selector.self_modulate.a= 0.0
