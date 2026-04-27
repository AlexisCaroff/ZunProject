extends AiBrain
class_name AiBrain_MommyBoss

## True tant que Mommy n'a pas encore joué son premier tour du combat.
## Garantit que MommyGrab est toujours utilisé dès le premier tour.
var first_attack: bool = true


func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	print("Mommy Decide!")

	var base_usable_skills := owner.skills.filter(func(s): return s.can_use())
	if base_usable_skills.is_empty():
		return _fallback_attack(owner, heroes, enemies)

	var cm := owner.combat_manager

	# ══════════════════════════════════════════════════
	# 1️⃣  SPAWN SPITTER  (priorité absolue)
	#     Uniquement les spawns classiques (pas les tentacules).
	#     30 % de chance si un slot libre existe.
	# ══════════════════════════════════════════════════
	var regular_spawn_skills := base_usable_skills.filter(
		func(s): return s.Actiontype == "spawn" and not _is_tentacle_skill(s)
	)

	if not regular_spawn_skills.is_empty():
		var free_slot := _find_free_enemy_slot(cm)
		if free_slot != null and randf() < 0.3:
			print("👾 Mommy spawn un Spitter en ", free_slot.name)
			return {
				"skill": regular_spawn_skills.pick_random(),
				"target": [free_slot] as Array[PositionSlot]
			}

	# ══════════════════════════════════════════════════
	# 2️⃣  MOMMY GRAB
	#     - Premier tour : TOUJOURS utilisé (si des cibles valides existent).
	#     - Tours suivants : 50 % de chance, UNIQUEMENT s'il n'y a pas déjà
	#       une tentacule vivante en combat (= pas de personnage capturé).
	# ══════════════════════════════════════════════════
	var grab_skills := base_usable_skills.filter(func(s): return s.name == "Mommy Grab")

	if not grab_skills.is_empty():
		# Vérifie qu'aucune tentacule/grab n'est déjà actif
		var tentacle_active := _has_living_tentacle_in_combat(cm)

		if not tentacle_active:
			# Exclut les héros déjà grabbés (par sécurité, en plus de la
			# vérification tentacle_active ci-dessus).
			var valid_targets := heroes.filter(func(c: Character) -> bool:
				return not c.is_dead() \
					and not c.characterData.grab \
					and c.characterData.current_horniness < 100
			)

			if not valid_targets.is_empty():
				# Premier tour → toujours ; tours suivants → 50 %
				if first_attack or randf() < 0.5:
					var target: Character = valid_targets[randi() % valid_targets.size()]
					print("🤲 Mommy Grab sur ", target.characterData.Charaname,
						  " (premier tour : ", first_attack, ")")
					first_attack = false
					return {
						"skill": grab_skills.pick_random(),
						"target": [target._current_slot] as Array[PositionSlot]
					}

	# On s'assure que le flag premier tour est bien consommé même si le grab
	# n'a pas pu s'exécuter (cibles invalides, etc.)
	first_attack = false

	# ══════════════════════════════════════════════════
	# 3️⃣  FALLBACK → attaques normales uniquement
	#     Grab et spawn sont explicitement exclus ici.
	# ══════════════════════════════════════════════════
	return _fallback_attack(owner, heroes, enemies)


# ──────────────────────────────────────────────────────────────
#  Helpers
# ──────────────────────────────────────────────────────────────

## Renvoie true si une tentacule (CharacterTestEnemyTentacle) est encore
## vivante dans le combat, ce qui signifie qu'un personnage est capturé.
func _has_living_tentacle_in_combat(cm: CombatManager) -> bool:
	for enemy in cm.enemies:
		if is_instance_valid(enemy) \
				and not enemy.is_dead() \
				and enemy.characterData.Charaname == "Tentacle":
			return true
	return false


## Renvoie true si la skill contient un effet SkillEffectSpawnTentacle.
func _is_tentacle_skill(skill: Skill) -> bool:
	for effect in skill.effects:
		if effect is SkillEffectSpawnTentacle:
			return true
	return false


## Fallback : choisit une attaque normale en excluant grab et spawn.
## Réplique la logique de AiBrain.decide_action() avec un pool filtré.
func _fallback_attack(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var cm := owner.combat_manager

	# Pool : uniquement les skills utilisables qui ne sont ni grab ni spawn
	var attack_skills := owner.skills.filter(func(s: Skill) -> bool:
		if not s.can_use():
			return false
		if s.name == "Mommy Grab":
			return false
		if s.Actiontype == "spawn":
			return false
		if s.name == "move":
			return false
		return true
	)

	# Dernier recours : "move" si rien d'autre
	if attack_skills.is_empty():
		attack_skills = owner.skills.filter(func(s: Skill) -> bool:
			return s.can_use() and s.name == "move"
		)

	if attack_skills.is_empty():
		print("Mommy : aucune attaque disponible.")
		return {}

	var skill: Skill = attack_skills[randi() % attack_skills.size()]

	# IMPORTANT : on exclut les héros grab (.grab == true). Voir Ai_brain.gd
	# pour l'explication détaillée.
	var alive_hero_slots: Array = cm.hero_positions.filter(func(p: PositionSlot) -> bool:
		return p.is_occupied() \
			and not p.occupant.is_dead() \
			and not p.occupant.characterData.grab \
			and p.occupant.characterData.current_horniness < 100
	)
	var alive_enemy_slots: Array = cm.enemy_positions.filter(func(p: PositionSlot) -> bool:
		return p.is_occupied() and not p.occupant.is_dead()
	)

	match skill.the_target_type:
		skill.target_type.SELF:
			return {"skill": skill, "target": [owner._current_slot] as Array[PositionSlot]}
		skill.target_type.ALL_ALLY:
			return {"skill": skill, "target": alive_enemy_slots}
		skill.target_type.ALL_ENNEMY:
			return {"skill": skill, "target": alive_hero_slots}

	# Cible unique
	var possible_targets: Array[Character] = []
	match skill.the_target_type:
		skill.target_type.ALLY:
			possible_targets = enemies.filter(func(c): return not c.is_dead())
		skill.target_type.ENNEMY:
			# Exclut les héros grab : leur slot n'est plus dans hero_positions
			# et leur _current_slot pointe vers enemy_positions[4] (occupant null).
			possible_targets = heroes.filter(func(c): return not c.is_dead() \
				and not c.characterData.grab \
				and c.characterData.current_horniness < 100)

	if possible_targets.is_empty():
		return {}

	# Sécurité : taunted_by ne doit pas pointer vers une cible invalide
	var taunt_valid := owner.taunted_by != null \
		and is_instance_valid(owner.taunted_by) \
		and not owner.taunted_by.is_dead() \
		and not owner.taunted_by.characterData.grab

	var target: Character
	if taunt_valid and skill.the_target_type == skill.target_type.ENNEMY:
		target = owner.taunted_by
	else:
		target = possible_targets[randi() % possible_targets.size()]

	return {"skill": skill, "target": [target._current_slot] as Array[PositionSlot]}


## Premier slot ennemi libre hors [3] (tentacule) et [4] (grab).
func _find_free_enemy_slot(cm: CombatManager) -> PositionSlot:
	for i in range(cm.enemy_positions.size()):
		if i == 3 or i == 4:
			continue
		var slot: PositionSlot = cm.enemy_positions[i]
		if not slot.is_occupied() or (slot.occupant != null and slot.occupant.is_dead()):
			return slot
	return null
