extends Resource
class_name Skill

@export var name: String = "Attaque"
@export var descriptionName: String = "Attaque"
@export var description: String = "Inflige des dégâts à un ennemi"
@export var icon: Texture2D
@export var attack_sound: AudioStream
@export var barkSkill:= ""
enum position_requirement {
	ANY,
	FRONT,
	BACK
}
@export var required_position: position_requirement = position_requirement.ANY
@export var range: int = 3  # 1 = courte, 2 = moyenne, 3 = longue
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
	EVERYONE,
	EVERY_OTHER,
	EVERYONE_ALL,
	ALL_ALLY_AND_ENNEMY_FRONT
}
@export var ImageSkill : Texture2D
@export_enum("enemy", "ally", "self", "all ally", "all ennemy", "front ennemy","back ennemy","front ally","back ally","everyone","every other","everyone all","all ally and ennemy front")
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
	EVERYONE,
	EVERY_OTHER,
	EVERYONE_ALL,
	ALL_ALLY_AND_ENNEMY_FRONT
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy", "front ennemy","back ennemy","front ally","back ally","everyone","every other","everyone all","all ally and ennemy front")
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
@export var tags: Array[String] = []
var combatManager : CombatManager
var reducecost : int=0
var skill_effect_overridden := false
@export var is_contact: bool = false
@export var distance_contact:float = 0.0
@export var effect : PackedScene
@export var caster_effect_scene: PackedScene
## Scène VFX instanciée en enfant de chaque CIBLE au moment de l'impact
@export var target_effect_scene: PackedScene

enum EffectAnchor { NONE, HEAD, TORSO }
## Point d'ancrage du VFX du lanceur
@export var caster_effect_anchor: EffectAnchor = EffectAnchor.NONE
## Point d'ancrage du VFX de la cible
@export var target_effect_anchor: EffectAnchor = EffectAnchor.TORSO
@export var is_beneficial: bool = false
@export var skip_target_return_anim: bool = false

func can_use() -> bool:
	if owner == null:
		return false
	if current_cooldown > 0:
		return false
	if required_position == position_requirement.FRONT and not owner._current_slot.position_data.isFront:
		return false
	if required_position == position_requirement.BACK and owner._current_slot.position_data.isFront:
		return false

	# Portée : un skill ennemi de portée 1 est inutilisable depuis le back
	var targets_enemy := the_target_type in [
		target_type.ENNEMY, target_type.ALL_ENNEMY,
		target_type.FRONT_ENNEMY, target_type.BACK_ENNEMY
	]
	if targets_enemy and range == 1 and not owner._current_slot.position_data.isFront:
		return false

	return true

func use(target: PositionSlot = null, secondtarget: bool = false) -> PositionSlot:
	owner.current_skill = self

	if combatManager:
		combatManager.ui.log(owner.characterData.Charaname + " uses " + descriptionName)

	for eq in owner.characterData.equipped_items:
		eq.on_skill_use(owner, self, target.occupant)

	if target == null:
		return null

	if target.occupant != null:



		target.combat_manager.stop_target_selection()

		if not can_use():
			return target

		if allways_hit == false:
			for tag in owner.characterData.tags:
				if tag == "voyeur":
					precision += 5

			var effective_precision := precision + (owner.characterData.precision - 100)
			var chance := effective_precision - target.occupant.characterData.evasion
			var rand := randi() % 100

			if rand >= chance:
				target.occupant.miss_animation(owner)
					# ✅ Enregistre la cible comme ratée
				if owner and owner.has_method("_missed_targets"):
					pass
				owner._missed_targets.append(target.occupant)
				return target

		if secondtarget:
			target = await _apply_second_effect(target)
		else:
			target = await _apply_effect(target, effects)

	else:
		target.combat_manager.stop_target_selection()

		if secondtarget:
			target = await _apply_second_effect(target)
		else:
			target = await _apply_effect(target, effects)

	return target
func pay_cost():
	owner.characterData.current_stamina-= cost
	if cooldown > 0:
		current_cooldown = max(cooldown-reducecost,0)
		reducecost =0
	owner.update_ui()

func _apply_effect(target: PositionSlot, effects_array: Array[SkillEffect] = effects) -> PositionSlot:
	var heallovedOnesTrigger: bool = false

	if !combatManager:
		combatManager = owner.combat_manager

	for theeffect in effects_array:
		if theeffect is DamageEffect:
			var Hunter_value: int = owner.characterData.affinity.get("Hunter", 0)
			var Priestess_value: int = target.occupant.characterData.affinity.get("Priestess", 0)
			var warrior_value: int = target.occupant.characterData.affinity.get("Warrior", 0)

			if Hunter_value > 50:
				var Hunter = combatManager.get_hero_by_name("Hunter")
				if Hunter and randf() < 0.3:
					var buff_ref := load("res://characters/kink/littleattackbuff.tres")
					var owner_ref := owner  # capture locale pour le Callable
					combatManager.queue_startSkills_affinity_reaction(func():
						await Hunter.play_affinity_reaction("there ! target that spot ! " + owner_ref.characterData.Name + " !")
						owner_ref.add_buff(buff_ref)
					)

			if warrior_value > 50:
				var warrior = combatManager.get_hero_by_name("Warrior")
				if warrior and randf() < 0.3:
					var target_name := target.occupant.characterData.Name
					combatManager.queue_startSkills_affinity_reaction(func():
						await warrior.play_affinity_reaction("look out " + target_name + " !")
						  # retarget si nécessaire
					)
				target = warrior.get_current_slot()

			if Priestess_value > 50:
				var Priestess = combatManager.get_hero_by_name("Priestess")
				if Priestess:
					heallovedOnesTrigger = true
	await combatManager.flush_startSkills_affinity_reaction()
	# Application des effets normaux — inchangée
	if not skill_effect_overridden:
		for tag in owner.characterData.tags:
			if tag == "degrader" and target != owner._current_slot:
				target.occupant.characterData.current_stress += 2
		for effecttoapply in effects_array:
			effecttoapply.apply(owner, target)

	# Priestess en file après les dégâts
	if heallovedOnesTrigger and randf() < 0.5:
		var Priestess = combatManager.get_hero_by_name("Priestess")
		var target_ref := target
		combatManager.queue_endTurn_affinity_reaction(func():
			await Priestess.play_affinity_reaction("May Zun shine on " + target_ref.occupant.characterData.Charaname + " !")
			target_ref.occupant.characterData.current_stamina += 10
			await target_ref.occupant.animate_heal(10, Priestess)
		)
		heallovedOnesTrigger= false

	# Mystic en file en dernier
	var Mystic_value: int = owner.characterData.affinity.get("Mystic", 0)
	if Mystic_value > 50:
		var Mystic = combatManager.get_hero_by_name("Mystic")
		if Mystic and randf() < 0.3:
			var skill_ref := self
			combatManager.queue_endTurn_affinity_reaction(func():
				await Mystic.play_affinity_reaction(" Sprites please aid " + skill_ref.owner.characterData.Name + " !")
				if skill_ref.current_cooldown > 0:
					skill_ref.current_cooldown -= 1
			)

	return target
func _apply_second_effect(thetarget2: PositionSlot)-> PositionSlot:
	#print("apply second effect")
	thetarget2 = await _apply_effect(thetarget2, second_effects)
	return thetarget2

func select_targets(combat_manager:CombatManager):
	owner.current_skill=self
	combatManager=combat_manager
	combat_manager.ui.log("Select a target for %s" % descriptionName)
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
			var caster_is_front: bool = owner._current_slot.position_data.isFront
			for enemy in combat_manager.enemies:
				var enemy_is_front: bool = enemy._current_slot.position_data.isFront
				var reachable: bool = _can_reach_enemy(caster_is_front, enemy_is_front)
				if reachable:
					enemy.set_targetable(true)
					if enemy.target_selected.is_connected(combat_manager._on_target_selected):
						enemy.target_selected.disconnect(combat_manager._on_target_selected)
					enemy.target_selected.connect(combat_manager._on_target_selected)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		target_type.ALL_ALLY:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)

		target_type.ALL_ENNEMY:
			var caster_is_front: bool = owner._current_slot.position_data.isFront
			for enemy in combat_manager.enemies:
				var enemy_is_front: bool = enemy._current_slot.position_data.isFront
				enemy.set_targetable(_can_reach_enemy(caster_is_front, enemy_is_front))
			for ally in combat_manager.heroes:
				ally.set_targetable(false)
		target_type.BACK_ALLY:
			for ally in combat_manager.heroes:
				if !ally._current_slot.position_data.isFront:
					ally.set_targetable(true)
				else:
					ally.set_targetable(false)

		target_type.FRONT_ALLY:
			for ally in combat_manager.heroes:
				if ally._current_slot.position_data.isFront:
					ally.set_targetable(true)
				else:
					ally.set_targetable(false)
			for enemy in combat_manager.enemies:
				enemy.set_targetable(false)
		target_type.BACK_ENNEMY:
			for enemy in combat_manager.enemies:
				if !enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		target_type.FRONT_ENNEMY:
			for enemy in combat_manager.enemies:
				if enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(false)

		target_type.EVERYONE:
			var caster_is_front: bool = owner._current_slot.position_data.isFront
			for enemy in combat_manager.enemies:
				var enemy_is_front: bool = enemy._current_slot.position_data.isFront
				var reachable: bool = _can_reach_enemy(caster_is_front, enemy_is_front)
				if reachable:
					enemy.set_targetable(true)
					if enemy.target_selected.is_connected(combat_manager._on_target_selected):
						enemy.target_selected.disconnect(combat_manager._on_target_selected)
					enemy.target_selected.connect(combat_manager._on_target_selected)
				else:
					enemy.set_targetable(false)
			for ally in combat_manager.heroes:
				ally.set_targetable(true)

		# --- NOUVEAU : un parmi tous les autres (≠ self) ---
		target_type.EVERY_OTHER:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				if enemy.target_selected.is_connected(combat_manager._on_target_selected):
					enemy.target_selected.disconnect(combat_manager._on_target_selected)
				enemy.target_selected.connect(combat_manager._on_target_selected)
			for ally in combat_manager.heroes:
				if ally == owner:
					ally.set_targetable(false)
				else:
					ally.set_targetable(true)
					if ally.target_selected.is_connected(combat_manager._on_target_selected):
						ally.target_selected.disconnect(combat_manager._on_target_selected)
					ally.target_selected.connect(combat_manager._on_target_selected)

		# --- NOUVEAU : tous les alliés + tous les ennemis (effet de groupe) ---
		target_type.EVERYONE_ALL:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
			for ally in combat_manager.heroes:
				ally.set_targetable(true)

		# --- NOUVEAU : 1 cible parmi TOUS les alliés OU les ennemis FRONT ---
		target_type.ALL_ALLY_AND_ENNEMY_FRONT:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				if enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)
					if enemy.target_selected.is_connected(combat_manager._on_target_selected):
						enemy.target_selected.disconnect(combat_manager._on_target_selected)
					enemy.target_selected.connect(combat_manager._on_target_selected)
				else:
					enemy.set_targetable(false)

func select_second_target(combat_manager:CombatManager):

	match the_second_target_type:
		second_target_type.SELF:
			var selfposition: Array[PositionSlot]
			selfposition.append(combat_manager.current_character._current_slot)
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
			combat_manager.ui.log("Now select an ennemy to target")
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
			combat_manager.ui.log("Now select an ally")
			for ally in combat_manager.heroes:
				if !ally._current_slot.position_data.isFront:
					ally.set_targetable(true)

		second_target_type.FRONT_ALLY:
			combat_manager.ui.log("Now select an ally")
			for ally in combat_manager.heroes:
				if ally._current_slot.position_data.isFront:
					ally.set_targetable(true)
		second_target_type.BACK_ENNEMY:
			combat_manager.ui.log("Now select an ennemy to target")
			for enemy in combat_manager.enemies:
				if !enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)

		second_target_type.FRONT_ENNEMY:
			combat_manager.ui.log("Now select an ennemy to target")
			for enemy in combat_manager.enemies:
				if enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)

		# --- NOUVEAUX (second target) ---
		second_target_type.EVERY_OTHER:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
				if enemy.target_selected.is_connected(combat_manager._on_target_selected):
					enemy.target_selected.disconnect(combat_manager._on_target_selected)
				enemy.target_selected.connect(combat_manager._on_target_selected)
			for ally in combat_manager.heroes:
				if ally == owner:
					ally.set_targetable(false)
				else:
					ally.set_targetable(true)
					if ally.target_selected.is_connected(combat_manager._on_target_selected):
						ally.target_selected.disconnect(combat_manager._on_target_selected)
					ally.target_selected.connect(combat_manager._on_target_selected)

		second_target_type.EVERYONE_ALL:
			for enemy in combat_manager.enemies:
				enemy.set_targetable(true)
			for ally in combat_manager.heroes:
				ally.set_targetable(true)

		second_target_type.ALL_ALLY_AND_ENNEMY_FRONT:
			for ally in combat_manager.heroes:
				ally.set_targetable(true)
				if ally.target_selected.is_connected(combat_manager._on_target_selected):
					ally.target_selected.disconnect(combat_manager._on_target_selected)
				ally.target_selected.connect(combat_manager._on_target_selected)
			for enemy in combat_manager.enemies:
				if enemy._current_slot.position_data.isFront:
					enemy.set_targetable(true)
					if enemy.target_selected.is_connected(combat_manager._on_target_selected):
						enemy.target_selected.disconnect(combat_manager._on_target_selected)
					enemy.target_selected.connect(combat_manager._on_target_selected)
				else:
					enemy.set_targetable(false)

func end_turn(combat_manager):
	pay_cost()
	combat_manager.current_character.end_turn()
	#combat_manager.pending_skill = null
	combat_manager.turn_queue.append(combat_manager.current_character)
	combat_manager.next_turn()

func has_tag(tag: String) -> bool:
	return tag in tags
func _can_reach_enemy(caster_is_front: bool, target_is_front: bool) -> bool:
	match range:
		1:
			# Portée 1 : seulement depuis front, seulement front ennemis
			return caster_is_front and target_is_front
		2:
			if caster_is_front:
				return true           # Front atteint tout
			else:
				return target_is_front  # Back atteint seulement les fronts ennemis
		3:
			return true               # Portée maximale, toujours accessible
		_:
			return true
