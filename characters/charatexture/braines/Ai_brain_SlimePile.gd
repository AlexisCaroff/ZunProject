extends AiBrain
class_name AiBrain_SlimePile

# ════════════════════════════════════════════════════════════════════
#  CERVEAU DE LA PILE DE SLIMES
# ════════════════════════════════════════════════════════════════════
#
#  Trois attaques, choisies selon la situation :
#   1. tant qu'un héros est avalé → digestion, une attaque à réussite
#      automatique sur lui, chaque tour (comme Tentacle squishes) ;
#   2. en première ligne → gifle de slime, ou tentative d'avalage ;
#   3. sinon → crachat de zone qui empoisonne toute l'équipe de lust.
#
#  Ce cerveau est SANS ÉTAT : CharacterData.duplicate() est superficiel,
#  donc deux piles de slimes d'un même combat partagent cette ressource.
#  Tout ce qui est propre à un individu vit sur son Character.

## Noms des compétences, tels qu'écrits dans les .tres. Exportés pour
## rester modifiables depuis l'inspecteur sans toucher au code.
@export var digest_skill_name: String = "Slime Digest"
@export var swallow_skill_name: String = "Slime Swallow"
@export var melee_skill_name: String = "Slime Slap"
@export var spray_skill_name: String = "Slime Spray"

## Seuil de PV (fraction du max) sous lequel la pile recrache sa proie.
@export var release_threshold: float = 0.5
## Probabilité de tenter un avalage quand c'est possible.
@export var swallow_chance: float = 0.5


# ─────────────────────────────────────────────────────────────
#  Réaction aux coups reçus
# ─────────────────────────────────────────────────────────────

## Appelée par Character.take_damage(). Sous le seuil de PV, la pile ne
## tient plus sa proie : elle la recrache. Couvre les deux cas demandés —
## tomber sous 50 % en encaissant, et encaisser alors qu'on y est déjà.
func on_damage_taken(owner: Character) -> void:
	if owner == null or owner.characterData == null:
		return
	if not SwallowEffect.is_holding(owner):
		return
	var maxhp: int = max(1, owner.characterData.max_stamina)
	var ratio := float(owner.characterData.current_stamina) / float(maxhp)
	if ratio < release_threshold:
		SwallowEffect.release(owner)


# ─────────────────────────────────────────────────────────────
#  Choix de l'action
# ─────────────────────────────────────────────────────────────

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var cm: CombatManager = owner.combat_manager
	if cm == null:
		return {}

	var usable := owner.skills.filter(func(s: Skill) -> bool: return s.can_use())
	if usable.is_empty():
		return {}

	# ── 1. Un héros dans le ventre → digestion ───────────────────────
	if SwallowEffect.is_holding(owner):
		var digest := _find(usable, digest_skill_name)
		if digest != null:
			return {"skill": digest, "target": [owner._current_slot] as Array[PositionSlot]}
		# Pas de digestion disponible : on évite d'avaler une deuxième proie.
		usable = usable.filter(func(s: Skill) -> bool: return s.name != swallow_skill_name)

	var targets := _alive_hero_slots(cm)
	if targets.is_empty():
		return {}

	var in_front: bool = owner._current_slot != null \
			and owner._current_slot.position_data != null \
			and owner._current_slot.position_data.isFront

	# ── 2. Au contact : avaler, sinon frapper ────────────────────────
	if in_front:
		var front_targets := targets.filter(
			func(p: PositionSlot) -> bool: return p.position_data.isFront)
		if front_targets.is_empty():
			front_targets = targets

		var swallow: Skill = null
		if not SwallowEffect.is_holding(owner):
			swallow = _find(usable, swallow_skill_name)
		var prey := _pick_swallowable(front_targets) if swallow != null else null

		if prey != null and randf() < swallow_chance:
			return {"skill": swallow, "target": [prey] as Array[PositionSlot]}

		var melee := _find(usable, melee_skill_name)
		if melee != null:
			var hit: PositionSlot = front_targets[randi() % front_targets.size()]
			return {"skill": melee, "target": [hit] as Array[PositionSlot]}

		var spray_front := _find(usable, spray_skill_name)
		if spray_front != null:
			return {"skill": spray_front, "target": targets}

		# Rien d'autre à faire au contact : on avale plutôt que de bouger.
		# Une pile en première ligne est déjà là où elle doit être.
		if prey != null:
			return {"skill": swallow, "target": [prey] as Array[PositionSlot]}
		return {}

	# ── 3. À distance : crachat de zone ──────────────────────────────
	var spray := _find(usable, spray_skill_name)
	if spray != null:
		return {"skill": spray, "target": targets}

	# ── 4. En arrière sans crachat : revenir au contact ──────────────
	# On ne retombe PAS sur AiBrain.decide_action : le pool générique
	# pourrait tirer la digestion alors qu'aucun héros n'est avalé, et
	# DamageEffectGrab planterait sur un CharaGrab nul.
	var move := _find(usable, "move")
	if move != null:
		var dest := _front_destination(cm, owner)
		if dest != null:
			return {"skill": move, "target": [dest] as Array[PositionSlot]}

	return {}


## Slot de première ligne où aller : un libre de préférence, sinon celui
## d'un allié déplaçable (Move.gd fait alors l'échange). Seuls les quatre
## vrais slots comptent — le 5e est le slot « capturé », dont l'occupant
## n'est pas déclaré alors qu'un héros avalé y est affiché.
func _front_destination(cm: CombatManager, owner: Character) -> PositionSlot:
	var pool: Array = cm.enemy_positions.slice(0, 4)
	var free := pool.filter(func(p: PositionSlot) -> bool:
		return p.position_data.isFront and not p.is_occupied())
	if not free.is_empty():
		return free[randi() % free.size()]
	var swaps := pool.filter(func(p: PositionSlot) -> bool:
		return p.position_data.isFront and p.is_occupied() \
			and p.occupant != owner and not p.occupant.is_dead() \
			and p.occupant.characterData.can_be_moved \
			and not p.occupant.characterData.immobilized \
			and not cm._is_anchored(p.occupant))
	if not swaps.is_empty():
		return swaps[randi() % swaps.size()]
	return null


# ─────────────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────────────

func _find(skills: Array, wanted: String) -> Skill:
	for s in skills:
		if s.name == wanted:
			return s
	return null


## Héros encore jouables. On exclut les capturés : leur slot est vide et
## les cibler ferait planter les effets (cf. Ai_brain.gd).
func _alive_hero_slots(cm: CombatManager) -> Array:
	return cm.hero_positions.filter(
		func(p: PositionSlot) -> bool:
			return p.is_occupied() \
				and not p.occupant.is_dead() \
				and not p.occupant.characterData.grab \
				and p.occupant.characterData.current_horniness < 100
	)


func _pick_swallowable(slots: Array) -> PositionSlot:
	var ok := slots.filter(
		func(p: PositionSlot) -> bool:
			return p.occupant != null and p.occupant.characterData.can_be_moved
	)
	if ok.is_empty():
		return null
	return ok[randi() % ok.size()]
