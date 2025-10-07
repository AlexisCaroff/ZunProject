extends Resource
class_name Skill

@export var name: String = "Attaque"
@export var descriptionName: String = "Attaque"
@export var description: String = "Inflige des dégâts à un ennemi"
@export var icon: Texture2D
@export var attack_sound: AudioStream 
enum position_requirement {
	ANY,      
	FRONT,    
	BACK     
}
@export var required_position: position_requirement = position_requirement.ANY

enum target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	ALL_ENNEMY,
	FRONT_ENNEMY,
	BACK_ENNEMY,
	FRONT_ALLY,
	BACK_ALLY,
	EVERYONE
}
@export var ImageSkill : Texture2D 
@export_enum("enemy", "ally", "self", "all ally", "all ennemy", "front ennemy","back ennemy","front ally","back ally","everyone")
var the_target_type: int = target_type.ENNEMY
@export var effects: Array[SkillEffect] = []
@export var two_target_Type: bool = false 

enum second_target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	ALL_ENNEMY,
	FRONT_ENNEMY,
	BACK_ENNEMY,
	FRONT_ALLY,
	BACK_ALLY,
	EVERYONE
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy", "front ennemy","back ennemy","front ally","back ally","everyone")
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
@export var duration : float =0.3
var owner: Character
var target1 : Array[PositionSlot]
var target2 : Array[PositionSlot]


func can_use() -> bool:
	if owner == null:
		return false
	if current_cooldown > 0:
		return false
	if required_position == position_requirement.FRONT and not owner.current_slot.position_data.isFront:
		return false
	if required_position == position_requirement.BACK and owner.current_slot.position_data.isFront:
		return false
	
	return true

func use(target: PositionSlot = null, secondtarget : bool=false):
	print(owner.Charaname+ " use "+ self.name)
	target.combat_manager.stop_target_selection()
	if not can_use():
		return
	
	if !allways_hit:
		var chance = precision - target.occupant.evasion
		var rand = randi() % 100
		if rand >= chance:
			target.occupant.miss_animation(owner)
			return
	if secondtarget:
		_apply_second_effect(target)
	else:
		_apply_effect(target, effects)

func pay_cost():
	owner.current_stamina-= cost
	if cooldown > 0:
		current_cooldown = cooldown
	owner.update_ui()

func _apply_effect(target: PositionSlot, effects_array: Array[SkillEffect] = effects):
	for effect in effects_array:
		effect.apply(owner, target)

func _apply_second_effect(target2: PositionSlot):
	#print("apply second effect")
	_apply_effect(target2, second_effects)

func select_targets(combat_manager:CombatManager):
	combat_manager.ui.log("Sélectionnez une cible pour %s" % name)
	match the_target_type:
		target_type.SELF:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)
			combat_manager.current_character.set_targetable(true)

		target_type.ALLY:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		target_type.ENNEMY:
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
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		target_type.ALL_ENNEMY:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)
		target_type.BACK_ALLY:
			for ally in combat_manager.heroes:
				if !ally.current_slot.position_data.isFront:
					ally.set_targetable(true)
				else: 
					ally.set_targetable(false)

		target_type.FRONT_ALLY:
			for ally in combat_manager.heroes:
				if ally.current_slot.position_data.isFront:
					ally.set_targetable(true)
				else: 
					ally.set_targetable(false)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)
		target_type.BACK_ENNEMY:
			for enemy in combat_manager.enemies:
				if !enemy.current_slot.position_data.isFront:
					enemy.set_targetable(true)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		target_type.FRONT_ENNEMY:
			for enemy in combat_manager.enemies:
				if enemy.current_slot.position_data.isFront:
					enemy.set_targetable(true)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)
			
		target_type.EVERYONE:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
			for ally in combat_manager.heroes:
				ally.set_targetable(true)

func select_second_target(combat_manager:CombatManager):
	
	match the_second_target_type:
		second_target_type.SELF:
			var selfposition: Array[PositionSlot]
			selfposition.append(combat_manager.current_character.current_slot)
			print("affect self")
			combat_manager._on_target_selected(selfposition)

		second_target_type.ALLY:
			combat_manager.ui.log("Now select an ally")
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		second_target_type.ENNEMY:
			
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

		second_target_type.ALL_ENNEMY:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				
		second_target_type.BACK_ALLY:
			for ally in combat_manager.heroes:
				if !ally.current_slot.position_data.isFront:
					ally.set_targetable(true)

		second_target_type.FRONT_ALLY:
			for ally in combat_manager.heroes:
				if ally.current_slot.position_data.isFront:
					ally.set_targetable(true)
		second_target_type.BACK_ENNEMY:
			for enemy in combat_manager.enemies:
				if !enemy.current_slot.position_data.isFront:
					enemy.set_targetable(true)

		second_target_type.FRONT_ENNEMY:
			for enemy in combat_manager.enemies:
				if enemy.current_slot.position_data.isFront:
					enemy.set_targetable(true)

func end_turn(combat_manager):
	pay_cost()
	combat_manager.current_character.end_turn()
	#combat_manager.pending_skill = null
	combat_manager.turn_queue.append(combat_manager.current_character)
	combat_manager.next_turn()
