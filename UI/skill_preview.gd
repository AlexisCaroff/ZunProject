extends RefCounted
class_name SkillPreview

# ════════════════════════════════════════════════════════════════════
#  APERÇU D'UNE CAPACITÉ AU-DESSUS DES CIBLES
# ════════════════════════════════════════════════════════════════════
#  Pendant le choix de la cible, survoler un personnage ciblable affiche
#  au-dessus de sa tête (de toutes les cibles pour une capacité de zone) :
#      chance de toucher, dégâts / soins chiffrés, buffs et états.
#  Les chiffres reprennent les règles de Skill.use() et des SkillEffect
#  (Character.take_damage, HealEffect…) SANS rien modifier : c'est une
#  simulation, aucun effet n'est appliqué.
#  Appelé par PositionSlot (survol) ; nettoyé par CombatManager
#  .stop_target_selection().

const STAT_HOVER := preload("res://UI/stat_hover.gd")
const META := "skill_preview_bubble"
const FONT_SIZE := 20

const C_HIT := "#ffe08a"
const C_DMG := "#ff6b6b"
const C_LUST := "#ff7ad9"
const C_GUILT := "#b98cff"
const C_HEAL := "#7dff9b"
const C_BUFF := "#8fd3ff"
const C_DEBUFF := "#ffa26b"

const BUFF_LABEL := ["ATK", "DEF", "INIT", "WILL", "EVA", "", "Poison", "Stun",
		"Taunt", "PREC", "Immobilized"]


## Bulles sur `targets` pour la capacité en cours de ciblage.
static func show_for(cm: Node, targets: Array) -> void:
	clear(cm)
	var skill: Skill = cm.pending_skill
	var caster: Character = cm.current_character
	if skill == null or caster == null:
		return
	var second: bool = cm.combat_state == cm.CombatState.SELECTING_SECOND_TARGET
	var effects: Array = skill.second_effects if second else skill.effects
	for t in targets:
		if t is Character and is_instance_valid(t) and t.characterData != null:
			var lines := describe(skill, caster, t, effects)
			if not lines.is_empty():
				_show_bubble(t, lines)


## Retire toutes les bulles du combat.
static func clear(cm: Node) -> void:
	if cm == null:
		return
	for list in [cm.heroes, cm.enemies]:
		for c in list:
			if is_instance_valid(c) and c.has_meta(META):
				var b = c.get_meta(META)
				if is_instance_valid(b):
					b.queue_free()
				c.remove_meta(META)


## Lignes BBCode décrivant l'effet de `skill` lancé par `caster` sur `target`.
static func describe(skill: Skill, caster: Character, target: Character,
		effects: Array) -> Array[String]:
	var lines: Array[String] = []
	var chance := hit_chance(skill, caster, target)
	if chance >= 0:
		lines.append("[color=%s]%d%% to hit[/color]" % [C_HIT, chance])
	for e in effects:
		_describe_effect(e, caster, target, lines)
	# Deux effets peuvent poser le même état (taunt + buff TAUNT) : une ligne.
	var unique: Array[String] = []
	for l in lines:
		if not l in unique:
			unique.append(l)
	return unique


## Chance de toucher en %, ou -1 si la capacité touche toujours (cf.
## Skill.use : le jet porte sur toute cible occupée).
static func hit_chance(skill: Skill, caster: Character, target: Character) -> int:
	if skill.allways_hit:
		return -1
	var precision := skill.precision
	if "voyeur" in caster.characterData.tags:
		precision += 5
	var effective := precision + (caster.characterData.precision - 100)
	return clampi(effective - target.characterData.evasion, 0, 100)


static func _describe_effect(e, caster: Character, target: Character,
		lines: Array[String]) -> void:
	if e == null:
		return
	var td: CharacterData = target.characterData
	if e is DamageEffect:
		var amount: int = _demon_scaled(e.amount, e.MagicDMG, td)
		lines.append(_damage_line(e.damage_target_stat, amount, caster, target))
	elif e is HealEffect:
		var amount: int = e.amount
		if e.heal_target_stat == HealEffect.Stat.STAMINA and "maso" in td.tags:
			amount += 2
		lines.append(_heal_line(e.heal_target_stat, amount))
	elif e is PainAndAbsolution:
		if td.is_player_controlled:
			lines.append(_heal_line(e.heal_target_stat, e.healamount))
		else:
			var inner: int = _demon_scaled(e.DMGamount, e.MagicDMG, td) \
					+ caster.characterData.base_attack - td.base_defense
			lines.append(_damage_line(e.damage_target_stat, inner, caster, target))
	elif e is BuffEffect:
		lines.append(_buff_ladder_line(e, target))
	elif e is ReducePrecisionEffect:
		lines.append("[color=%s]PREC -%d (%s)[/color]" % [C_DEBUFF, e.amount, _turns(e.duration)])
	elif e is StunEffect:
		lines.append("[color=%s]Stun[/color]" % C_DEBUFF)
	elif e is ImmobilizeEffect:
		lines.append("[color=%s]Immobilized (%s)[/color]" % [C_DEBUFF, _turns(e.duration)])
	elif e is SkillEffect_Taunt:
		lines.append("[color=%s]Taunt (%s)[/color]" % [C_DEBUFF, _turns(e.duration)])
	elif e is ConditionalEffect:
		var branch = e.effect_if_true if e._check(e.condition, caster, target._current_slot) \
				else e.effect_if_false
		_describe_effect(branch, caster, target, lines)
	elif e.has_method("preview_text"):
		# Point d'extension : un effet peut décrire lui-même son aperçu.
		var txt: String = e.preview_text(caster, target)
		if txt != "":
			lines.append(txt)


## Bonus / malus des démons (DamageEffect, PainAndAbsolution).
static func _demon_scaled(amount: int, magic: bool, td: CharacterData) -> int:
	if not td.IsDemon:
		return amount
	return amount * 2 if magic else int(amount / 2.0)


## Même calcul que Character.take_damage.
static func _damage_line(stat: int, amount: int, caster: Character, target: Character) -> String:
	var td := target.characterData
	match stat:
		DamageEffect.Stat.HORNY:
			var lust := amount if caster == target else maxi(0, amount - td.willpower)
			return "[color=%s]+%d lust[/color]" % [C_LUST, lust]
		DamageEffect.Stat.STRESS:
			return "[color=%s]+%d guilt[/color]" % [C_GUILT, maxi(0, amount - td.willpower)]
	var dmg := amount if caster == target \
			else maxi(0, amount + caster.characterData.attack - td.defense)
	return "[color=%s]-%d stamina[/color]" % [C_DMG, dmg]


static func _heal_line(stat: int, amount: int) -> String:
	match stat:
		HealEffect.Stat.HORNY:
			return "[color=%s]-%d lust[/color]" % [C_HEAL, amount]
		HealEffect.Stat.STRESS:
			return "[color=%s]-%d guilt[/color]" % [C_HEAL, amount]
	return "[color=%s]+%d stamina[/color]" % [C_HEAL, amount]


static func _buff_line(stat: int, amount: int, duration: int) -> String:
	var label: String = BUFF_LABEL[stat] if stat < BUFF_LABEL.size() else ""
	var color := C_BUFF if amount >= 0 else C_DEBUFF
	if label == "":
		return "[color=%s]%+d (%s)[/color]" % [color, amount, _turns(duration)]
	if stat in [BuffEffect.Stat.STUN, BuffEffect.Stat.TAUNT, BuffEffect.Stat.IMMOBILIZE]:
		return "[color=%s]%s (%s)[/color]" % [C_DEBUFF, label, _turns(duration)]
	if stat == BuffEffect.Stat.POISON:
		return "[color=%s]Poison %d (%s)[/color]" % [C_DEBUFF, amount, _turns(duration)]
	return "[color=%s]%s %+d (%s)[/color]" % [color, label, amount, _turns(duration)]


## Buff empilable : palier actuel de la cible → palier après le buff
## (cf. Buff.next_level). Les états binaires gardent l'ancien affichage.
static func _buff_ladder_line(e: BuffEffect, target: Character) -> String:
	var b := Buff.new()
	b.stat = e.affected_stat
	b.amount = e.amount
	b.name = e.name
	b.tier = e.tier
	if not b.is_ladder():
		return _buff_line(e.affected_stat, e.amount, e.duration)
	var cur := 0
	for x in target.buffs:
		if x != null and x.is_ladder() and x.ladder_key() == b.ladder_key():
			cur = x.level
	var nxt := Buff.next_level(cur, b.direction(), b.strength())
	var label := ""
	var fmt := "%+d"
	if b.is_poison():
		label = "Lust poison" if b.name == "poisonHorny" else "Poison"
		fmt = "%d"
	else:
		label = BUFF_LABEL[b.stat] if b.stat < BUFF_LABEL.size() else ""
	var color := C_DEBUFF if (b.is_poison() or b.direction() < 0) else "#ffffff"
	var after := fmt % Buff.value_for(nxt)
	if cur == 0:
		return "[color=%s]%s %s[/color]" % [color, label, after]
	return "[color=%s]%s %s → %s[/color]" % [color, label, fmt % Buff.value_for(cur), after]


static func _turns(n: int) -> String:
	return "%d turn%s" % [n, "" if n == 1 else "s"]


# ── Bulle ─────────────────────────────────────────────────────────────

static func _show_bubble(target: Character, lines: Array[String]) -> void:
	var bubble := PanelContainer.new()
	bubble.name = "SkillPreview"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := STAT_HOVER.bubble_style()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bubble.add_theme_stylebox_override("panel", style)
	# Hors du repère du personnage (échelle, retournement des ennemis) :
	# coordonnées du canvas, au-dessus de tout le combat.
	bubble.top_level = true
	bubble.z_as_relative = false
	bubble.z_index = 50

	var text := RichTextLabel.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.bbcode_enabled = true
	text.fit_content = true
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.scroll_active = false
	text.add_theme_font_override("normal_font", STAT_HOVER.FONT)
	text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	text.text = "[center]%s[/center]" % "\n".join(lines)
	bubble.add_child(text)

	bubble.modulate.a = 0.0
	target.add_child(bubble)
	target.set_meta(META, bubble)
	# Taille du texte connue après une passe de mise en page.
	await target.get_tree().process_frame
	if not is_instance_valid(bubble):
		return
	bubble.reset_size()
	var head := _head_point(target)
	bubble.global_position = head - Vector2(bubble.size.x * 0.5, bubble.size.y + 12.0)
	STAT_HOVER.pop_in(bubble)


## Haut de la tête : marqueur headPosition s'il est réglé, sinon le haut de
## l'image du personnage.
static func _head_point(target: Character) -> Vector2:
	var cd := target.characterData
	var rect: Rect2 = target.sprite.get_global_rect() if target.sprite != null \
			else Rect2(target.global_position, Vector2.ZERO)
	var top := Vector2(rect.get_center().x, rect.position.y)
	if cd.headPosition != Vector2.ZERO:
		var p: Vector2 = target._get_effect_anchor_pos(Skill.EffectAnchor.HEAD)
		top = Vector2(p.x, p.y - 40.0)
	# Au-dessus de la flèche de ciblage, sans la cacher.
	var arrow := target.get("arrow") as Sprite2D
	if arrow != null and arrow.visible and arrow.texture != null:
		# get_rect tient compte de l'offset du sprite ; marge pour son rebond.
		var r := arrow.get_global_transform() * arrow.get_rect()
		top.y = minf(top.y, r.position.y - 16.0)
	return top
