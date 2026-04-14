extends Node2D
class_name Character

# ── Données visuelles ─────────────────────────────────────

@onready var sprite        : TextureRect   = $pivot/HerosTexture1
@onready var pivot                         = $pivot
@onready var arrow                         = $Arrow
## Marqueurs anatomiques pour les VFX — nœuds Node2D enfants de HerosTexture1



var hp_Jauge        : ProgressBar
var LustProgressBar : ProgressBar
var hornyJauge
var buff_bar        : HBoxContainer   # référence au HBoxContainer dans CharaUi
const MAX_EQUIPMENT = 2

# ── État ──────────────────────────────────────────────────
var taunted_by     : Character    = null
var taunt_duration : int          = 0
var buffs          : Array[Buff]  = []
var _current_slot  : PositionSlot = null
var CharaScale     : Vector2      = Vector2(1.0, 1.0)
var dead           : bool         = false
var buff_icons     : Array        = []
var skills         : Array[Skill] = []
var combat_manager : CombatManager = null
var dotsActions    : Array[TextureRect]

# ── VFX constants ─────────────────────────────────────────
const HornyEffectScene  := preload("res://actions/damageEffect/charmed-particules.tscn")
const DamageEffectScene := preload("res://actions/damageEffect/HitVFX.tscn")
const healEffectScene   := preload("res://actions/damageEffect/HealVFX.tscn")
const MissEffectScene   := preload("res://actions/damageEffect/miss_vfx.tscn")
const DebuffEffectScene := preload("res://actions/damageEffect/debuffVfx.tscn")
const BonkEffectScene   := preload("res://actions/damageEffect/bonkVFX.tscn")
const hornyPart         := preload("res://actions/damageEffect/horny_particules.tscn")
const stunPart          := preload("res://actions/skillEffects/FX/Scene/stun_Fx.tscn")
const buffui            := preload("res://UI/buffUi.tscn")

var StunParticule  : SkillFX
var hornyParticules

# ── Signaux ───────────────────────────────────────────────
signal target_selected()
signal skill_animation_started
signal skill_animation_finished

# ── Divers ────────────────────────────────────────────────
var is_targetable  : bool      = false
var exclamation    : TextureRect
var CharaColor                 = Color(1.0, 1.0, 1.0, 1.0)
var acte_twice     : bool      = false
var exibBonusAtt               = 0
var CharaGrab      : Character = null
var current_bark   : Bark      = null
@export var characterData : CharacterData
var current_skill  : Skill     = null
var cam            : Camera
var ShadowBackground : Sprite2D
var getattacked    : bool      = false
var attacking      : bool      = false
var turncount      : int       = 0

# ── Variables d'animation ─────────────────────────────────
var start_pos
var normal_size
var attack_pos      : Vector2
var target_pos      : Vector2
var start_target_pos: Vector2
var outline         : TextureRect


# ═══════════════════════════════════════════════════════════
#  INIT
# ═══════════════════════════════════════════════════════════

func set_current_slot(value): _current_slot = value
func get_current_slot(): return _current_slot

func _ready():
	cam = get_viewport().get_camera_2d()
	arrow.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = load("res://characters/character_outline.gdshader")
	sprite.material = mat
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	if !characterData.is_player_controlled :
		(sprite.material as ShaderMaterial).set_shader_parameter("outline_direction",  Vector2(0.0, -5.0))
	if characterData:
		
		sprite.texture     = characterData.portrait_texture
		_updateSkills(characterData.skill_resources)
	else:
		push_warning("CharacterData non assignée pour %s" % name)

	await get_tree().process_frame

	if not characterData.is_player_controlled and combat_manager.gm.teamCorrupted == false:
		sprite.flip_h   = true
	if characterData.inquisition :
		sprite.flip_h   = false
	else:
		hornyParticules = hornyPart.instantiate()
		#print("horny particules spawn for " + characterData.Charaname)
		add_child(hornyParticules)
		hornyParticules.position.y += characterData.headPosition.y
		hornyParticules.setParticulesAlpha(0.0)

	for buff in characterData.buffs:
		add_buff(buff)
	characterData.buffs.clear()
	for buff in buffs:
		buff.apply_to(self.characterData)


func _updateSkills(updated_skills: Array[Resource]):
	skills.clear()
	for s in updated_skills:
		if s == null:
			push_error("Une ressource de compétence est nulle dans %s" % name)
			continue
		var inst = s.duplicate()
		inst.owner = self
		var base_cd    = inst.cooldown
		var reduced_cd = max(0, base_cd - get_equipement_cooldown_reduction_for(inst))
		inst.cooldown  = reduced_cd
		skills.append(inst)


# ═══════════════════════════════════════════════════════════
#  STATS
# ═══════════════════════════════════════════════════════════

func update_stats():
	if not characterData:
		return
	if StunParticule and not characterData.stun:
		StunParticule.remove()
		StunParticule = null

	characterData.max_stamina   = characterData.base_max_stamina
	characterData.max_horniness = characterData.base_max_horniness
	characterData.max_stress    = characterData.base_max_stress
	characterData.attack        = characterData.base_attack
	characterData.defense       = characterData.base_defense
	characterData.initiative    = characterData.base_initiative
	characterData.willpower     = characterData.base_willpower
	characterData.evasion       = characterData.base_evasion
	characterData.precision     = characterData.base_precision
	characterData.immobilized   = false   # remis à false — le buff IMMOBILIZE le repose si actif

	for tag in characterData.tags:
		if tag == "sadist":
			characterData.attack += 2
		elif tag == "maso":
			characterData.evasion = max(0, characterData.evasion - 2)

	for buff in buffs:
		buff.apply_to(self.characterData)

	for eq in characterData.equipped_items:
		characterData.attack        += eq.attack_bonus
		characterData.defense       += eq.defense_bonus
		characterData.max_horniness += eq.Max_lust_bonus
		characterData.max_stamina   += eq.Max_stamina_bonus
		characterData.max_stress    += eq.Max_Guilt_bonus
		characterData.willpower     += eq.willpower_bonus
		characterData.evasion       += eq.evasion_bonus
		characterData.initiative    += eq.initiative_bonus


func get_equipement_cooldown_reduction_for(skill: Skill) -> int:
	var reduction := 0
	if not characterData:
		return reduction
	for eq in characterData.equipped_items:
		reduction += eq.global_cooldown_reduction
		if skill.name in eq.skill_specific_cooldown:
			reduction += eq.skill_specific_cooldown[skill.name]
	return reduction


func refresh_stats_from_equipment():
	characterData.attack     = characterData.base_attack
	characterData.defense    = characterData.base_defense
	characterData.willpower  = characterData.base_willpower
	characterData.evasion    = characterData.base_evasion
	characterData.initiative = characterData.base_initiative
	for eq in characterData.equipped_items:
		characterData.attack     += eq.attack_bonus
		characterData.defense    += eq.defense_bonus
		characterData.willpower  += eq.willpower_bonus
		characterData.evasion    += eq.evasion_bonus
		characterData.initiative += eq.initiative_bonus


# ═══════════════════════════════════════════════════════════
#  BUFFS
# ═══════════════════════════════════════════════════════════

func add_buff(buff: Buff):
	var new_buff = buff.duplicate()
	buffs.append(new_buff)

	# S'assure que buff_bar est résolu avant d'instancier l'icône
	if buff_bar == null and _current_slot != null and _current_slot.CharaUI != null:
		buff_bar = _current_slot.CharaUI.get_buff_bar()

	var icon = buffui.instantiate()
	if buff_bar:
		buff_bar.add_child(icon)
	buff_icons.append(icon)
	icon.updatebuff(new_buff)
	update_stats()
	print("add buff " + buff.name + " to " + characterData.Charaname)


func update_buffs() -> void:
	for i in range(buffs.size() - 1, -1, -1):
		var buff = buffs[i]
		buff.duration -= 1
		if buff.duration <= 0:
			remove_buff_at(i)
		else:
			buff_icons[i].refresh()
	# precision et immobilized sont recalculés par update_stats() via apply_to()
	update_stats()


func remove_buff_at(index: int):
	var buff = buffs[index]
	buffs.remove_at(index)
	var icon = buff_icons[index]
	buff_icons.remove_at(index)
	icon.queue_free()
	print("remove buff " + buff.name)


func get_stat(stat_enum: int) -> int:
	var base_value = 0
	match stat_enum:
		Buff.Stat.ATTACK:   base_value = characterData.base_attack
		Buff.Stat.DEFENSE:  base_value = characterData.base_defense
		Buff.Stat.SPEED:    base_value = characterData.base_initiative
		_: print("Stat inconnue : ", stat_enum)
	for buff in buffs:
		if buff.stat == stat_enum:
			base_value += buff.amount
	return base_value


func process_taunt():
	if taunt_duration > 0:
		taunt_duration -= 1
		if taunt_duration <= 0:
			taunted_by = null


# ═══════════════════════════════════════════════════════════
#  UI
# ═══════════════════════════════════════════════════════════

func update_ui():
	if hp_Jauge == null and _current_slot != null:
		_current_slot.Set_CharaUI()
		hp_Jauge    = _current_slot.CharaUI.getHpbar()
		hornyJauge  = _current_slot.CharaUI.get_HornyBar()
		dotsActions = _current_slot.CharaUI.getactionpoints()
		buff_bar    = _current_slot.CharaUI.get_buff_bar()
	if not characterData:
		return
	if LustProgressBar == null:
		LustProgressBar = _current_slot.CharaUI.getLustbar()
	if hp_Jauge:
		hp_Jauge.max_value = characterData.max_stamina
		hp_Jauge.value     = characterData.current_stamina
	if hornyJauge:
		hornyJauge.self_modulate.a  = (characterData.current_horniness * 2.0) / characterData.max_horniness
		LustProgressBar.max_value   = characterData.max_horniness
		LustProgressBar.value       = characterData.current_horniness
	if hornyParticules and characterData.current_horniness >= 50.0:
		hornyParticules.setParticulesAlpha(characterData.current_horniness / 100.0)
	elif hornyParticules:
		hornyParticules.setParticulesAlpha(0.0)
	for i in range(skills.size()):
		if i < dotsActions.size():
			var dot   = dotsActions[i]
			var skill = skills[i]
			if skill.current_cooldown == 0:
				dot.modulate = Color(0.642, 0.561, 0.365)
				dot.size     = Vector2(0.1, 0.1)
			else:
				dot.modulate = Color(0.1, 0.1, 0.1)
				dot.size     = Vector2(0.5, 0.5)
	if characterData.stun:
		if StunParticule == null:
			StunParticule = stunPart.instantiate()
			add_child(StunParticule)
			StunParticule.position.y = characterData.headPosition.y
	else:
		if StunParticule != null:
			StunParticule.remove()
			StunParticule = null


# ═══════════════════════════════════════════════════════════
#  COMPÉTENCES / TOUR
# ═══════════════════════════════════════════════════════════

func get_skill(index: int) -> Skill:
	if index >= 0 and index < skills.size():
		return skills[index]
	push_error("Skill index %d out of bounds for character %s" % [index, characterData.Charaname])
	return null


func is_dead() -> bool:
	return dead


func can_act() -> bool:
	return not is_dead() and characterData \
		and characterData.current_stress    < 100 \
		and characterData.current_horniness < 100


func reduce_cooldowns() -> void:
	for skill in skills:
		if skill.current_cooldown > 0:
			skill.current_cooldown -= 1


func start_turn():
	turncount += 1
	if not characterData:
		return
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)
	print(characterData.Charaname + " start turn")
	sprite.self_modulate = Color(2.5, 2.5, 2.5, 1.0)
	var dmg      = 0
	var dmgHorny = 0
	for buff in buffs:
		if buff.name == "poison":
			dmg += buff.amount
		if buff.name == "poisonHorny":
			dmgHorny += buff.amount
	if dmg > 0:
		await take_damage(self, DamageEffect.Stat.STAMINA, dmg, false)
	elif dmgHorny > 0:
		await take_damage(self, DamageEffect.Stat.HORNY, dmgHorny, false)
	else:
		await animate_start_Turn()
	update_stats()
	combat_manager.ui.update_ui_for_current_character(self)


func end_turn():
	CharaColor = Color(1.0, 1.0, 1.0, 1.0)
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	update_buffs()
	resetVisuel()
	reduce_cooldowns()
	combat_manager.ui.update_ui_for_current_character(self)


func play_ai_turn(heroes: Array, enemies: Array):
	if not characterData or characterData.ai_brain == null:
		push_error("Aucun AiBrain assigné à %s" % name)
		return

	var decision = characterData.ai_brain.decide_action(self, heroes, enemies)
	if decision.is_empty():
		print("no decision")
		resetVisuel()
		return

	current_skill = decision["skill"]
	combat_manager.ui.log(characterData.Charaname + " use " + current_skill.descriptionName)

	var targetPositions: Array[PositionSlot] = []
	for t in decision.get("target", []):
		if t is PositionSlot:
			targetPositions.append(t)

	combat_manager.pending_skill = current_skill
	current_skill.owner          = self
	await get_tree().create_timer(0.5).timeout

	# ── 1. Animation d'abord ─────────────────────────────────
	var target_chars: Array[Character] = []
	for slot: PositionSlot in targetPositions:
		if slot.occupant != null:
			target_chars.append(slot.occupant)

	if not target_chars.is_empty() and current_skill.name != "move":
		await animate_attack(target_chars, current_skill)

	# ── 2. Effets après ──────────────────────────────────────
	for thetarget in targetPositions:
		targetPositions[0] = await current_skill.use(thetarget)

	await combat_manager.flush_startSkills_affinity_reaction()

	for slot in targetPositions:
		if slot.occupant:
			slot.occupant.update_ui()
	update_buffs()
	resetVisuel()


# ═══════════════════════════════════════════════════════════
#  CIBLAGE
# ═══════════════════════════════════════════════════════════

func set_targetable(state: bool):
	is_targetable  = state
	arrow.visible  = state
	if state:
		sprite.modulate      = Color(1, 1, 1)
		sprite.self_modulate = Color(2.5, 2.5, 2.5, 1.0)
	else:
		sprite.modulate      = Color(0.5, 0.5, 0.5)
		sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func _input_event(_viewport, event, _shape_idx):
	if is_targetable and event is InputEventMouseButton and event.pressed:
		emit_signal("target_selected", self)


func select_as_target():
	print("Cible sélectionnée : ", self.name)
	combat_manager.select_target(self)
	arrow.visible = false


# ═══════════════════════════════════════════════════════════
#  AFFECTATION / MORT
# ═══════════════════════════════════════════════════════════

func surprised():
	if characterData:
		characterData.stun = true
	exclamation = TextureRect.new()
	exclamation.texture             = preload("res://UI/exclamation.png")
	exclamation.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	exclamation.custom_minimum_size = Vector2(32, 32)
	exclamation.position            = Vector2(0, -164)
	add_child(exclamation)


func isdead():
	dead = true
	print(characterData.Charaname + " is dead")


func take_damage(source: Character, stat: int, amount: int, typeMagic: bool, skillused: Skill = null) -> void:
	var damage := 0
	for buff in buffs:
		if buff.name == "Target":
			combat_manager.pending_skill.reducecost = buff.amount
	sprite.texture = characterData.Hit_texture

	match stat:
		DamageEffect.Stat.STAMINA:
			for tag in characterData.tags:
				if tag == "maso":
					var littlebuff := load("res://characters/kink/littleattackbuff.tres")
					add_buff(littlebuff)
					characterData.current_horniness = max(0, characterData.current_horniness + 2)
			if source != self:
				for tag in source.characterData.tags:
					if tag == "sadist":
						source.characterData.current_horniness = max(0, source.characterData.current_horniness + 2)
					if tag == "degrader":
						source.characterData.current_horniness = max(0, source.characterData.current_horniness + floor(characterData.current_stress / 2))
				damage = max(0, (amount + source.characterData.attack) - characterData.defense)
				print(self.name + " take " + str(damage) + " damage from " + source.name)
			else:
				damage = amount
			for eq in characterData.equipped_items:
				eq.on_receive_attack(self, source, damage)
			if characterData.current_stamina > 0:
				characterData.current_stamina = clamp(characterData.current_stamina - damage, 0, characterData.max_stamina)
				if characterData.current_stamina == 0 and characterData.isOneshot:
					isdead()
			else:
				if characterData.IsDemon and typeMagic:
					combat_manager.nb_crystaleloot += 1
				isdead()
			if dead:
				animate_bonk()
			else:
				await animate_take_damage(damage, source)

		DamageEffect.Stat.HORNY:
			damage = amount
			if source == self:
				characterData.current_horniness = max(0, characterData.current_horniness + damage)
			else:
				damage = max(0, amount - characterData.willpower)
				characterData.current_horniness = max(0, characterData.current_horniness + damage)
			for eq in characterData.equipped_items:
				eq.on_receive_attack(self, source, damage)
			await animate_get_horny(damage, source)
			update_ui()

		DamageEffect.Stat.STRESS:
			for tag in characterData.tags:
				if tag == "exib":
					amount -= 2
					await take_damage(self, DamageEffect.Stat.STAMINA, 2, false)
					characterData.attack -= exibBonusAtt
					exibBonusAtt          = floor(characterData.current_stress / 10)
					characterData.attack += exibBonusAtt
				if tag == "degenerate":
					var usedSkills: Array[Skill] = []
					for skill in skills:
						if skill.current_cooldown > 0:
							usedSkills.append(skill)
					if not usedSkills.is_empty():
						usedSkills.pick_random().current_cooldown -= 1
					characterData.current_horniness = max(0, characterData.current_horniness + 2)
			damage = max(0, amount - characterData.willpower)
			characterData.current_stress = max(0, characterData.current_stress + damage)

	shake_camera(20.0)
	update_ui()


# ═══════════════════════════════════════════════════════════
#  AFFINITÉS
# ═══════════════════════════════════════════════════════════

func play_affinity_reaction(bark_text: String) -> void:
	emit_signal("skill_animation_started")
	await animate_start_Turn()
	await show_bark(bark_text)
	emit_signal("skill_animation_finished")


func show_bark(text: String):
	if not characterData or characterData.bark_scene == null:
		return
	if current_bark and is_instance_valid(current_bark):
		current_bark.queue_free()
	current_bark = characterData.bark_scene.instantiate()
	add_child(current_bark)
	current_bark.set_text(text)
	current_bark.position = Vector2(-60, -240)
	await get_tree().create_timer(2.0).timeout
func show_outline():
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", true)

func hide_outline():
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)

func slur():
	if characterData:
		show_bark(characterData.taunts.pick_random())


func add_affinity(target: Character, amount: int):
	var key := target.characterData.Charaname
	if characterData.affinity.has(key):
		characterData.affinity[key] = clampi(characterData.affinity[key] + amount, 0, 100)


func reduce_affinity(target: Character, amount: int):
	add_affinity(target, -amount)


func get_affinity(target: Character) -> int:
	var key := target.characterData.Charaname
	if characterData.affinity.has(key):
		return characterData.affinity[key]
	return 0


# ═══════════════════════════════════════════════════════════
#  VISUEL / RESET
# ═══════════════════════════════════════════════════════════

func resetVisuel():
	sprite.modulate = CharaColor
	if _current_slot and not attacking and not getattacked:
		self.z_index         = _current_slot.z_index
		self.global_position = _current_slot.global_position
		self.scale           = CharaScale
	if characterData and characterData.current_stamina > 0 and not attacking and not getattacked:
		sprite.texture   = characterData.portrait_texture
	if characterData and characterData.current_stamina == 0:
		sprite.texture   = characterData.dead_portrait_texture
	if characterData.current_stamina > 0:
		modulate = Color(1.0, 1.0, 1.0)
	update_ui()


func shake_camera(strength := 5.0):
	if cam and cam.has_method("shake"):
		cam.shake(strength)


# ═══════════════════════════════════════════════════════════
#  ANIMATIONS
# ═══════════════════════════════════════════════════════════

func animate_start_Turn():
	emit_signal("skill_animation_started")
	var tween      := create_tween() as Tween
	CharaScale      = _current_slot.position_data.scale if _current_slot else CharaScale
	var norm_size   = CharaScale
	var big_size    = Vector2(norm_size.x * 1.1, norm_size.y * 1.3)
	tween.tween_property(self, "scale", big_size,  0.2).set_delay(0.2)
	tween.tween_property(self, "scale", norm_size, 0.2)
	await tween.finished
	emit_signal("skill_animation_finished")


func animate_get_horny(damage: int, source: Character = null):
	emit_signal("skill_animation_started")
	sprite.texture       = characterData.Hit_texture
	var effect_instance  = HornyEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -30)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage)
	if source == self:
		var tween    := create_tween() as Tween
		var norm_size = CharaScale
		var big_size  = Vector2(norm_size.x * 1.1, norm_size.y * 1.3)
		tween.tween_property(self, "scale", big_size,  0.2)
		tween.tween_property(self, "scale", norm_size, 0.2)
		await tween.finished
		sprite.texture = characterData.portrait_texture
	emit_signal("skill_animation_finished")


func animate_take_damage(damage: int, source: Character, _usedSkill: Skill = null):
	emit_signal("skill_animation_started")
	await get_tree().create_timer(0.2).timeout
	if characterData.current_stamina > 0:
		sprite.texture = characterData.Hit_texture
	var effect_instance = DamageEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(50, -140)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage, Color(1, 0.4, 0.3))
	await get_tree().create_timer(0.5).timeout
	if source == self and characterData.current_stamina > 0:
		sprite.texture = characterData.portrait_texture
	emit_signal("skill_animation_finished")


func animate_heal(damage: int, _source: Character, color = null):
	emit_signal("skill_animation_started")
	var delay = 0.5
	await get_tree().create_timer(0.2).timeout
	if _source.characterData.Charaname == "Mystic":
		delay = 1.0
	var effect_instance = healEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(100, -240)
	if effect_instance.has_method("setup"):
		effect_instance.setup(damage, color)
	emit_signal("skill_animation_finished")


func DebuffAnim(text):
	emit_signal("skill_animation_started")
	var effect_instance = DebuffEffectScene.instantiate()
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = global_position + Vector2(0, -210)
	if effect_instance.has_method("setup"):
		effect_instance.setup(text)
	emit_signal("skill_animation_finished")


func miss_animation(_target: Character):
	emit_signal("skill_animation_started")
	var miss_instance = MissEffectScene.instantiate()
	get_tree().current_scene.add_child(miss_instance)
	miss_instance.global_position = global_position + Vector2(0, -140)
	if miss_instance.has_method("setup"):
		miss_instance.setup()
	var start_pose = position
	var esquiv_pose = start_pose + Vector2(-100, 0)
	var tween := create_tween() as Tween
	tween.tween_property(self, "position", esquiv_pose, 0.0)
	tween.tween_property(self, "position", start_pose,  0.2).set_delay(0.2)
	await tween.finished
	emit_signal("skill_animation_finished")


func animate_bonk():
	emit_signal("skill_animation_started")
	if not characterData.IsDemon:
		var effect_instance = BonkEffectScene.instantiate()
		get_tree().current_scene.add_child(effect_instance)
		effect_instance.global_position = global_position + Vector2(0, -30)
		if effect_instance.has_method("setup"):
			effect_instance.setup(0)
	emit_signal("skill_animation_finished")


# ═══════════════════════════════════════════════════════════
#  ANIMATE_ATTACK  (skill + cibles multiples)
# ═══════════════════════════════════════════════════════════

## Retourne la position globale du marqueur anatomique demandé
func _get_effect_anchor_pos(anchor: int) -> Vector2:
	var offset: Vector2
	if anchor == Skill.EffectAnchor.HEAD:
		offset = characterData.headPosition
	elif anchor == Skill.EffectAnchor.TORSO:
		offset = characterData.torso_Position
	else:
		return global_position
	return global_position + offset * scale


## Spawn un VFX sur ce personnage à l'ancrage demandé
func _spawn_vfx(scene: PackedScene, anchor: int) -> void:
	if scene == null:
		return
	var vfx := scene.instantiate()
	add_child(vfx)
	if !characterData.is_player_controlled:
		vfx.scale.x =-1
	vfx.global_position = _get_effect_anchor_pos(anchor)


## Spawn le VFX cible sur un Character donné
func _spawn_vfx_on_target(tgt: Character) -> void:
	if current_skill.target_effect_scene == null:
		return
	var vfx := current_skill.target_effect_scene.instantiate()
	tgt.add_child(vfx)
	if tgt.characterData.is_player_controlled:
		vfx.scale.x =-1
	vfx.global_position = tgt._get_effect_anchor_pos(current_skill.target_effect_anchor)


## Vrai si la skill cible des alliés
func _skill_targets_ally() -> bool:
	var t := current_skill.the_target_type
	return t in [
		Skill.target_type.ALLY,
		Skill.target_type.FRONT_ALLY,
		Skill.target_type.BACK_ALLY,
		Skill.target_type.ALL_ALLY,
	]


# ──────────────────────────────────────────────────────────
#  animate_attack
#  targets : Array[Character]
#  skill   : Skill  (gère textures, VFX, durée)
# ──────────────────────────────────────────────────────────

func animate_attack(targets: Array, skill: Skill) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("enabled", false)
	if targets.is_empty():
		emit_signal("skill_animation_finished")
		return

	current_skill  = skill
	var multi      := targets.size() > 1
	var target     : Character = targets[0]
	var cm         := combat_manager

	emit_signal("skill_animation_started")
	attacking        = true
	if buff_bar: buff_bar.visible = false

	# ── Positions de scène (Node2D dans la scène de combat) ──
	var hero_P   : Vector2 = cm.hero_skillP.global_position
	var hero_P2  : Vector2 = cm.hero_skillP2.global_position
	var hero_P3  : Vector2 = cm.hero_skillP3.global_position
	var enemy_P  : Vector2 = cm.enemy_skillP.global_position
	var enemy_P2 : Vector2 = cm.enemy_skillP2.global_position
	var enemy_P3 : Vector2 = cm.enemy_skillP3.global_position #position help allie

	# ── Position du caster ───────────────────────────────────
	# Contact → P (proche de la cible) | Distance → P3 (position arrière)
	var caster_dest : Vector2
	if current_skill.is_contact:
		caster_dest = hero_P if characterData.is_player_controlled else enemy_P
	else:
		caster_dest = hero_P3 if characterData.is_player_controlled else enemy_P3
	normal_size = scale
	var big_size : Vector2 = normal_size * 2.0

	# ── Position cible (cible unique seulement) ──────────────
	var ally_skill := _skill_targets_ally()
	var target_dests : Dictionary = {}   # Character → Vector2

	if not multi:
		for tgt: Character in targets:
			if tgt.buff_bar: tgt.buff_bar.visible = false
			tgt.getattacked      = true
			var dest: Vector2
			# Les cibles vont toujours en P2, qu'elles soient alliées ou ennemies
			if tgt.characterData.is_player_controlled:
				dest = hero_P2
			else:
				dest = enemy_P2
			target_dests[tgt] = dest
	else:
		for tgt: Character in targets:
			if tgt.buff_bar: tgt.buff_bar.visible = false
			tgt.getattacked      = true
			

	# ── Textures ─────────────────────────────────────────────
	sprite.texture = current_skill.ImageSkill
	var has_heal := current_skill.effects.any(func(e): return e is HealEffect)
	var show_hit  := not has_heal and not current_skill.is_beneficial
	if show_hit:
		for tgt: Character in targets:
			if tgt != self and tgt.characterData.current_stamina > 0:
				tgt.sprite.texture = tgt.characterData.Hit_texture

	# ── VFX caster ───────────────────────────────────────────
	_spawn_vfx(current_skill.caster_effect_scene, current_skill.caster_effect_anchor)

	# ── Mise en place ─────────────────────────────────────────
	z_index         = 20
	self.modulate.a = 0.0

	# Contact  → téléport hors écran puis tween vers P
	# Distance → téléport sur P (hors écran) puis tween vers P3
	if current_skill.is_contact:
		if characterData.is_player_controlled:
			position = Vector2(-300, caster_dest.y)
		else:
			position = Vector2(2300, caster_dest.y)
	else:
		# P est hors écran, on y téléporte sans transition
		var offscreen : Vector2 = hero_P if characterData.is_player_controlled else enemy_P
		position = offscreen

	var cam_zoom_big := Vector2(cam.baseZoom * 1.1)
	const T_SETUP    := 0.15

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self,            "position",   caster_dest,   T_SETUP)
	tween.parallel().tween_property(self,            "scale",      big_size,      0.0)
	tween.parallel().tween_property(self,            "modulate:a", 1.0,           T_SETUP)
	tween.parallel().tween_property(ShadowBackground,"modulate:a", 1.0,           T_SETUP)
	tween.parallel().tween_property(cam,             "zoom",       cam_zoom_big,  T_SETUP)

	# Déplace la caméra vers la zone de confrontation
	var cam_target_pos = cam.position
	if not target.characterData.is_player_controlled:
		cam_target_pos.x += 90
	else:
		cam_target_pos.x -= 90
	if current_skill.is_contact:
		tween.parallel().tween_property(cam, "position", cam_target_pos, T_SETUP)

	for tgt: Character in targets:
		tgt.modulate.a = 0.0
		tgt.z_index    = 20
		
		if target_dests.has(tgt):
			if tgt.characterData.Charaname=="Spitter":
				target_dests[tgt].y-=60
			tween.parallel().tween_property(tgt, "position",   target_dests[tgt], T_SETUP)
			tween.parallel().tween_property(tgt, "scale",      big_size,          T_SETUP)
		tween.parallel().tween_property(tgt, "modulate:a", 1.0, T_SETUP)

	# ── Animation d'attaque ───────────────────────────────────
	tween.tween_interval(0.1)

	if current_skill.is_contact:
		# Avance au contact
		var contact_dest : Vector2
		if not multi:
			var td  : Vector2 = target_dests.get(target, target.position)
			var dir := (td - caster_dest).normalized()
			contact_dest = td + dir * -current_skill.distance_contact
		else:
			var mid := Vector2.ZERO
			for tgt: Character in targets:
				mid += tgt.position
				if tgt.characterData.Charaname=="Spitter":
					mid.y+=60
			mid /= targets.size()
			var dir := (mid - caster_dest).normalized()
			contact_dest = mid + dir * -current_skill.distance_contact
			
		tween.tween_property(self, "position", contact_dest, 0.18)
	else:
		# Aller-retour sur place
		var nudge := caster_dest + (Vector2(60, 0) if characterData.is_player_controlled else Vector2(-60, 0))
		tween.tween_property(self, "position", nudge,        0.12)
		tween.tween_property(self, "position", caster_dest,  0.10)

	# ── Impact ───────────────────────────────────────────────
	tween.tween_callback(_on_attack.bind(targets))
	await tween.finished


func _on_attack(targets: Array) -> void:
	# VFX sur chaque cible
	for tgt: Character in targets:
		_spawn_vfx_on_target(tgt)

	# Pause pendant la durée définie par la skill
	await get_tree().create_timer(current_skill.duration).timeout

	# ── Retour aux positions d'origine ───────────────────────
	# Si skip_target_return_anim est activé (ex: MoveToPosition gère le déplacement),
	# on ne tweene pas le retour des personnages — seulement caméra et shadow.
	const T_BACK := 0.25
	var ret := create_tween()
	ret.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Le caster revient toujours à son slot
	ret.parallel().tween_property(self, "position", _current_slot.global_position,     T_BACK)
	ret.parallel().tween_property(self, "scale",    _current_slot.position_data.scale, T_BACK)

	# Les targets : scale remise mais position gérée par MoveToPosition si skip activé
	for tgt: Character in targets:
		if tgt._current_slot:
			ret.parallel().tween_property(tgt, "scale", tgt._current_slot.position_data.scale, T_BACK)
			if not current_skill.skip_target_return_anim:
				ret.parallel().tween_property(tgt, "position", tgt._current_slot.global_position, T_BACK)

	# Caméra et shadow reviennent toujours
	ret.parallel().tween_property(ShadowBackground, "modulate:a", 0.0,             T_BACK)
	ret.parallel().tween_property(cam,              "zoom",       cam.baseZoom,     T_BACK)
	ret.parallel().tween_property(cam,              "position",   Vector2(960, 540), T_BACK)

	await ret.finished
	after_skilluse(targets)


func after_skilluse(targets: Array) -> void:
	attacking        = false
	if buff_bar: buff_bar.visible = true
	sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Reset caster
	sprite.texture = characterData.portrait_texture
	if _current_slot:
		z_index = _current_slot.z_index
		# scale déjà remis par le tween dans _on_attack

	# Callbacks équipements (on passe la première cible pour compatibilité)
	for tag in characterData.tags:
		if tag == "degrader":
			slur()
	var first_target : Character = targets[0] if not targets.is_empty() else self
	for eq in characterData.equipped_items:
		eq.after_skill_use(self, current_skill, first_target)

	# Reset cibles
	for tgt: Character in targets:
		tgt.getattacked      = false
		if tgt.buff_bar: tgt.buff_bar.visible = true
		if tgt._current_slot:
			tgt.z_index = tgt._current_slot.z_index
			tgt.scale   = tgt._current_slot.position_data.scale
		if tgt.characterData.current_stamina > 0:
			tgt.sprite.texture   = tgt.characterData.portrait_texture

	emit_signal("skill_animation_finished")

func Higlight():
	sprite.self_modulate= Color(2.5,2.5,2.5,1.0)
func resetHighlight():
	sprite.self_modulate= Color(1.0,1.0,1.0,1.0)
