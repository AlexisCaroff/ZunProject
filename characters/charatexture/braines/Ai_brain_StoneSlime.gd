extends AiBrain
class_name AiBrain_StoneSlime

# ════════════════════════════════════════════════════════════════════
#  CERVEAU DU STONE SLIME
# ════════════════════════════════════════════════════════════════════
#
#  Un tank. Ses priorités, dans l'ordre :
#   1. rejoindre la première ligne s'il en a été délogé ;
#   2. se durcir (Stone Skin) tant que le buff n'est pas actif ;
#   3. s'interposer devant un allié encore à découvert (Stone Wall) ;
#   4. charger le héros en face.
#
#  Un cerveau dédié est nécessaire : Stone Skin et Stone Wall sont
#  utilisables depuis n'importe quelle case, donc l'AiBrain générique
#  retirerait « move » du pool et le Stone Slime ne remonterait jamais au
#  contact (contrairement au Thug, qui n'a qu'une attaque FRONT).
#
#  Ce cerveau est SANS ÉTAT : CharacterData.duplicate() est superficiel,
#  deux Stone Slimes d'un même combat partagent cette ressource.

@export var charge_skill_name: String = "Stone Charge"
@export var guard_skill_name: String = "Stone Skin"
@export var intercept_skill_name: String = "Stone Wall"
@export var move_skill_name: String = "move"

## Probabilité de s'interposer quand un allié est encore à découvert.
@export_range(0.0, 1.0, 0.05) var intercept_chance: float = 0.6


func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var cm: CombatManager = owner.combat_manager
	if cm == null:
		return {}

	var usable := owner.skills.filter(func(s: Skill) -> bool: return s.can_use())
	if usable.is_empty():
		return {}

	var in_front: bool = owner._current_slot != null \
			and owner._current_slot.position_data != null \
			and owner._current_slot.position_data.isFront

	# ── 1. Il veut la première ligne ─────────────────────────────────
	if not in_front:
		var move := _find(usable, move_skill_name)
		var free_front := cm.enemy_positions.filter(
			func(p: PositionSlot) -> bool:
				return p.position_data != null \
					and p.position_data.isFront \
					and not p.is_occupied()
		)
		if move != null and not free_front.is_empty():
			var dest: PositionSlot = free_front[randi() % free_front.size()]
			return {"skill": move, "target": [dest] as Array[PositionSlot]}

	# ── 2. Se durcir tant que le buff n'est pas posé ─────────────────
	var guard := _find(usable, guard_skill_name)
	if guard != null and not _has_buff(owner, guard_skill_name):
		return {"skill": guard, "target": [owner._current_slot] as Array[PositionSlot]}

	# ── 3. S'interposer devant un allié encore à découvert ───────────
	var wall := _find(usable, intercept_skill_name)
	if wall != null and randf() < intercept_chance:
		var ward := _pick_ally_to_shield(cm, owner)
		if ward != null:
			return {"skill": wall, "target": [ward] as Array[PositionSlot]}

	# ── 4. Charger ───────────────────────────────────────────────────
	var targets := _alive_hero_slots(cm)
	var charge := _find(usable, charge_skill_name)
	if charge != null and not targets.is_empty():
		var front_targets := targets.filter(
			func(p: PositionSlot) -> bool: return p.position_data.isFront)
		if front_targets.is_empty():
			front_targets = targets
		var hit: PositionSlot = front_targets[randi() % front_targets.size()]
		return {"skill": charge, "target": [hit] as Array[PositionSlot]}

	# ── 5. Dernier recours : avancer, ou s'interposer quand même ─────
	if wall != null:
		var ward2 := _pick_ally_to_shield(cm, owner)
		if ward2 != null:
			return {"skill": wall, "target": [ward2] as Array[PositionSlot]}

	var move2 := _find(usable, move_skill_name)
	if move2 != null:
		var free := cm.enemy_positions.filter(
			func(p: PositionSlot) -> bool: return not p.is_occupied())
		if not free.is_empty():
			var dest2: PositionSlot = free[randi() % free.size()]
			return {"skill": move2, "target": [dest2] as Array[PositionSlot]}

	return {}


# ─────────────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────────────

func _find(skills: Array, wanted: String) -> Skill:
	for s in skills:
		if s.name == wanted:
			return s
	return null


func _has_buff(c: Character, buff_name: String) -> bool:
	for b in c.buffs:
		if b != null and b.name == buff_name:
			return true
	return false


func _alive_hero_slots(cm: CombatManager) -> Array:
	return cm.hero_positions.filter(
		func(p: PositionSlot) -> bool:
			return p.is_occupied() \
				and not p.occupant.is_dead() \
				and not p.occupant.characterData.grab \
				and p.occupant.characterData.current_horniness < 100
	)


## Un allié vivant, autre que soi, que personne ne protège encore. On
## préfère l'arrière : c'est là que sont les fragiles.
func _pick_ally_to_shield(cm: CombatManager, owner: Character) -> PositionSlot:
	var candidates := cm.enemy_positions.filter(
		func(p: PositionSlot) -> bool:
			if not p.is_occupied() or p.occupant == owner:
				return false
			if p.occupant.is_dead():
				return false
			return InterceptEffect.protector_of(p.occupant, cm.enemies) == null
	)
	if candidates.is_empty():
		return null

	var back := candidates.filter(
		func(p: PositionSlot) -> bool:
			return p.position_data != null and not p.position_data.isFront)
	if not back.is_empty():
		return back[randi() % back.size()]
	return candidates[randi() % candidates.size()]
