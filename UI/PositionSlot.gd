extends Node2D
class_name PositionSlot

@export var position_data: PositionData
@export var enemy_scene: PackedScene
var occupant: Character = null
@export var spawner : bool= false
var combat_manager 
@onready var imageinside = $TextureRect
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
	
	if GameState.current_phase == GameStat.GamePhase.COMBAT:
		combat_manager = $"../../CombatManager"

func Set_CharaUI():
	CharaUI = $"charaCombatUI"

func assign_character(character: Character, movetime:float):
	await get_tree().process_frame
	shadow.modulate.a =0.349
	occupant = character
	occupant.CharaScale = position_data.scale
	if CharaUI == null : 
		CharaUI = $"charaCombatUI"
		print("charaUI is null")
	occupant.hornyJauge =CharaUI.HornyBar
	occupant.hp_Jauge=CharaUI.HPProgressBar
	
	occupant.dotsActions = CharaUI.actionpoints
	occupant.z_index=self.z_index
	if occupant.characterData.is_player_controlled==false:
		for actionpoint in CharaUI.actionpoints:
			actionpoint.visible=false
		CharaUI.TheHornyBar.visible=false
		
	#print("chara assigned to position")
	if not is_ready:
		await ready
	
	character._current_slot = self
	#print(character.Charaname,"→ current_slot défini à ", self.name)

	var tween = get_tree().create_tween()
	tween.parallel().tween_property(character, "global_position", self.global_position, movetime).set_delay(0.2)
	tween.parallel().tween_property(character, "scale", position_data.scale, movetime).set_delay(0.2)
	await tween.finished

	character.CharaScale= position_data.scale
	character.global_position=self.global_position
	character.set_scale(position_data.scale)
	
	if position_data.buff:
		position_data.buff.apply(character, character)
	CharaUI.visible=true

	shadow.modulate.a =0.3
	
func remove_character():
	if occupant:
		occupant.resetVisuel()
		occupant = null
	CharaUI.visible=false
	shadow.modulate.a =0.1
		

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
	combat_manager.ui.update_ui_for_overed_character(occupant)
	if combat_manager.pending_skill:
		var skill = combat_manager.pending_skill
		match combat_manager.combat_state:
			combat_manager.CombatState.SELECTING_FIRST_TARGET:
				match skill.the_target_type:
					Skill.target_type.ALLY:
						if occupant.characterData.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.FRONT_ALLY:
						if occupant.characterData.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.FRONT_ENNEMY:
						if !occupant.characterData.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.BACK_ALLY:
						occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.BACK_ENNEMY:
						if !occupant.characterData.is_player_controlled:
							occupant.Selector.self_modulate.a= 1.0
					Skill.target_type.ENNEMY:
						if !occupant.characterData.is_player_controlled:
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
