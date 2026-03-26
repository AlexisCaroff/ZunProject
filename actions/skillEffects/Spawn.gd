extends SkillEffect
class_name SkillEffectSpawnEnemy

@export var enemy_scene: PackedScene
@export var max_spawn: int = 1
@export var spawn_delay: float = 0.5

var combatmanager: CombatManager

func apply(_user: Character, target: PositionSlot) -> void:
	combatmanager = _user.combat_manager
	if not enemy_scene:
		push_error("Aucune scène d'ennemi assignée à SkillEffectSpawnEnemy")
		return
	if target.combat_manager == null:
		push_error("Impossible de trouver le combat_manager depuis le target slot")
		return

	_spawn_enemy_in_slot(target)


func _spawn_enemy_in_slot(slot: PositionSlot) -> void:
	var new_enemy: Character = enemy_scene.instantiate()
	combatmanager.add_child(new_enemy)
	new_enemy.characterData = new_enemy.characterData.duplicate(true)
	new_enemy.characterData.is_player_controlled = false
	new_enemy.combat_manager = combatmanager
	new_enemy.ShadowBackground = combatmanager.ShadowBackground
	new_enemy.name = "Spawned_" + str(randi() % 1000)
	new_enemy.characterData.Charaname = new_enemy.name

	# ── Stats runtime ────────────────────────────────────────────────
	new_enemy.update_stats()
	new_enemy.characterData.current_stamina   = new_enemy.characterData.max_stamina
	new_enemy.characterData.current_stress    = clamp(new_enemy.characterData.current_stress,    0, new_enemy.characterData.max_stress)
	new_enemy.characterData.current_horniness = clamp(new_enemy.characterData.current_horniness, 0, new_enemy.characterData.max_horniness)

	# ── Placement ───────────────────────────────────────────────────
	new_enemy._current_slot = slot
	combatmanager.move_character_to(new_enemy, slot, 0.0)

	# ── Enregistrement — UNE seule fois ─────────────────────────────
	combatmanager.enemies.append(new_enemy)

	# ── Connexion des signaux animation (indispensable !) ────────────
	new_enemy.skill_animation_started.connect(combatmanager._on_skill_animation_started)
	new_enemy.skill_animation_finished.connect(combatmanager._on_skill_animation_finished)

	# ── File de tours ────────────────────────────────────────────────
	combatmanager.turn_queue.append(new_enemy)
	combatmanager.ui.update_turn_queue_ui(combatmanager.turn_queue)
	new_enemy.update_ui()

	print("✅ Spawned: ", new_enemy.name, " in slot: ", slot.name)
