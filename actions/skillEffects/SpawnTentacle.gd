extends SkillEffect
class_name SkillEffectSpawnTentacle

@export var enemy_scene: PackedScene
@export var spawn_delay: float = 0.5

## Textures de la tentacule selon la cible attrappée
@export var sprite_warrior  : Texture2D
@export var sprite_mystic   : Texture2D
@export var sprite_priestess: Texture2D
@export var sprite_hunter   : Texture2D

var combatmanager: CombatManager


func apply(_user: Character, target: PositionSlot) -> void:
	combatmanager = _user.combat_manager
	if not enemy_scene:
		push_error("Aucune scène d'ennemi assignée à SkillEffectSpawnTentacle")
		return

	var tentacle_slot: PositionSlot = combatmanager.enemy_positions[3]

	# Sécurité : ne pas spawner si une tentacule vivante occupe déjà [3]
	if _has_living_tentacle(tentacle_slot):
		push_warning("SpawnTentacle : tentacule déjà vivante en [3], spawn annulé.")
		return

	_spawn_tentacle_in_slot(tentacle_slot, target.occupant, _user)


# ─────────────────────────────────────────────
#  Vérifie si une tentacule vivante est déjà en [3]
# ─────────────────────────────────────────────

func _has_living_tentacle(slot: PositionSlot) -> bool:
	if slot.occupant == null:
		return false
	var occ := slot.occupant
	# La boss elle-même peut occuper [3] entre deux invocations — ce n'est pas une tentacule
	if occ.characterData.Charaname == "Mommy" or occ.characterData.Charaname == "Mommy_Boss":
		return false
	return not occ.is_dead()


# ─────────────────────────────────────────────
#  Spawn
# ─────────────────────────────────────────────

func _spawn_tentacle_in_slot(slot: PositionSlot, grabbed_target: Character, boss: Character) -> void:
	# Libère [3] de l'occupation de la boss avant de placer la tentacule
	if slot.occupant == boss:
		slot.remove_character()

	var new_enemy: Character = enemy_scene.instantiate()
	combatmanager.add_child(new_enemy)
	new_enemy.characterData = new_enemy.characterData.duplicate(true)
	new_enemy.characterData.is_player_controlled = false
	new_enemy.combat_manager = combatmanager
	new_enemy.ShadowBackground = combatmanager.ShadowBackground
	new_enemy.name = "Tentacle"
	new_enemy.characterData.Charaname = "Tentacle"

	# ── Stats runtime ────────────────────────────────────────────────
	new_enemy.update_stats()
	new_enemy.characterData.current_stamina   = new_enemy.characterData.max_stamina
	new_enemy.characterData.current_stress    = clamp(new_enemy.characterData.current_stress,    0, new_enemy.characterData.max_stress)
	new_enemy.characterData.current_horniness = clamp(new_enemy.characterData.current_horniness, 0, new_enemy.characterData.max_horniness)

	# ── Placement tentacule en [3] ───────────────────────────────────
	new_enemy._current_slot = slot
	combatmanager.move_character_to(new_enemy, slot, 0.0)

	# ── Grab : déplace la cible vers le slot [4] ─────────────────────
	new_enemy.CharaGrab = grabbed_target
	grabbed_target._current_slot.remove_character()
	grabbed_target._current_slot = combatmanager.enemy_positions[4]
	grabbed_target.position = new_enemy.position
	grabbed_target.position.y -= 70
	grabbed_target.z_index = new_enemy.z_index - 1

	# ── Enregistrement ───────────────────────────────────────────────
	combatmanager.enemies.append(new_enemy)
	new_enemy.skill_animation_started.connect(combatmanager._on_skill_animation_started)
	new_enemy.skill_animation_finished.connect(combatmanager._on_skill_animation_finished)

	# ── Quand la tentacule meurt, la boss re-occupe [3] ──────────────
	new_enemy.tree_exiting.connect(_on_tentacle_died.bind(slot, boss))

	# ── Sprite selon la cible attrappée ─────────────────────────────
	var tex := _get_sprite_for_target(grabbed_target)
	if tex != null:
		new_enemy.characterData.portrait_texture = tex
		new_enemy.characterData.Hit_texture      = tex   # ou un hit sprite dédié si tu en as
		new_enemy.sprite.texture = tex

	# ── File de tours ────────────────────────────────────────────────
	combatmanager.turn_queue.append(new_enemy)
	combatmanager.ui.update_turn_queue_ui(combatmanager.turn_queue)
	new_enemy.update_ui()

	print("✅ Tentacle spawned in [3], grabbing: ", grabbed_target.characterData.Charaname)


func _get_sprite_for_target(target: Character) -> Texture2D:
	match target.characterData.Charaname:
		"Warrior":  return sprite_warrior
		"Mystic":   return sprite_mystic
		"Priestess":return sprite_priestess
		"Hunter":   return sprite_hunter
	return null


# ─────────────────────────────────────────────
#  Callback mort tentacule → boss re-occupe [3]
# ─────────────────────────────────────────────

func _on_tentacle_died(slot: PositionSlot, boss: Character) -> void:
	# Vérifie que la boss est encore vivante et que le slot est maintenant libre
	if not is_instance_valid(boss) or boss.is_dead():
		return
	if slot.is_occupied():
		return

	# La boss marque [3] comme sien (visuellement occupé, pas de déplacement)
	slot.occupant = boss
	print("🩸 Tentacle morte — Mommy re-occupe [3] en attendant la prochaine invocation")
