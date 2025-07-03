extends Resource
class_name Skill

@export var name: String = "Attaque"
@export var descriptionName: String = "Attaque"
@export var description: String = "Inflige des dégâts à un ennemi"
@export var icon: Texture2D
enum target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	ALL_ENNEMY
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy")
var the_target_type: int = target_type.ENNEMY
@export var effects: Array[SkillEffect] = []
@export var two_target_Type: bool = false 

enum second_target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	ALL_ENNEMY
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy")
var the_second_target_type: int = second_target_type.ENNEMY
@export var second_effects: Array[SkillEffect] = []
@export var usable_when_horny: bool = false
@export var needtarget: bool = true
@export var Actiontype : String = "attack" # attack, heal, boost
@export var cost : int =0
@export var cooldown : int=2
@export var current_cooldown: int = 0
@export var precision: int = 100
@export var allways_hit: bool = false
var owner: Character
var target1 : PositionSlot
var target2 : PositionSlot

func can_use() -> bool:
	if owner == null:
		return false
	return current_cooldown == 0

func use(target: PositionSlot = null, effects_array: Array[SkillEffect] = effects):
	if not can_use():
		return
	if not allways_hit:
		var chance = precision - target.occupant.evasion
		var rand = randi() % 100
		if rand >= chance:
			target.occupant.miss_animation(owner)
			return
		
	_apply_effect(target, effects_array)

func pay_cost():
	owner.current_stamina-= cost
	if cooldown > 0:
		current_cooldown = cooldown
	owner.update_ui()

func _apply_effect(target: PositionSlot, effects_array: Array[SkillEffect] = effects):
	for effect in effects_array:
		effect.apply(owner, target)

func _apply_second_effect(target2: PositionSlot):
	_apply_effect(target2, second_effects)

func select_targets(combat_manager):
	combat_manager.ui.log("Sélectionnez une cible pour %s" % name)

	match the_target_type:
		target_type.SELF:
			combat_manager.current_character.set_targetable(true)


		target_type.ALLY:
			combat_manager.pending_skill=self
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		target_type.ENNEMY:
			combat_manager.pending_skill=self
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				if enemy.target_selected.is_connected(combat_manager._on_target_selected):
					enemy.target_selected.disconnect(combat_manager._on_target_selected)
				enemy.target_selected.connect(combat_manager._on_target_selected)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		target_type.ALL_ALLY:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				
			if two_target_Type:
				select_second_target(combat_manager)
			else:
				end_turn(combat_manager)

		target_type.ALL_ENNEMY:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
			if two_target_Type:
				select_second_target(combat_manager)
			else:
				end_turn(combat_manager)
				
func select_second_target(combat_manager):
	match the_second_target_type:



		second_target_type.SELF:
			combat_manager.current_character.set_targetable(true)


		second_target_type.ALLY:
			combat_manager.pending_skill=self
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		second_target_type.ENNEMY:
			combat_manager.pending_skill=self
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				if enemy.target_selected.is_connected(combat_manager._on_target_selected):
					enemy.target_selected.disconnect(combat_manager._on_target_selected)
				enemy.target_selected.connect(combat_manager._on_target_selected)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		second_target_type.ALL_ALLY:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				
				end_turn(combat_manager)

		second_target_type.ALL_ENNEMY:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				end_turn(combat_manager)

func end_turn(combat_manager):
	pay_cost()
	combat_manager.current_character.end_turn()
	#combat_manager.pending_skill = null
	combat_manager.next_turn()
