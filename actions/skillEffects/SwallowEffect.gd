extends SkillEffect
class_name SwallowEffect

# ════════════════════════════════════════════════════════════════════
#  AVALER UN HÉROS
# ════════════════════════════════════════════════════════════════════
#
#  Même principe que la capture par tentacule (cf. SpawnTentacle.gd),
#  en plus simple : l'ennemi garde le héros dans son ventre au lieu
#  d'invoquer une créature pour le tenir.
#
#  Le héros capturé :
#   - passe en characterData.grab = true → CombatManager saute son tour
#     et l'IA cesse de le cibler ;
#   - quitte son slot de héros, qui redevient libre ;
#   - est parqué sur enemy_positions[GRAB_SLOT], le slot de rétention déjà
#     utilisé par les tentacules, et rendu invisible.
#
#  Le dévoreur mémorise sa proie dans CharaGrab — c'est ce champ que lit
#  DamageEffectGrab pour la frapper automatiquement chaque tour, et c'est
#  lui que CombatManager._check_victory relit pour libérer le héros si le
#  dévoreur meurt.

## Slot ennemi servant de « ventre ». Identique à celui des tentacules.
const GRAB_SLOT := 4

## Texture prise par le dévoreur tant qu'il retient un héros.
@export var full_texture: Texture2D
## Texture de dégât à utiliser tant qu'il est plein (optionnelle).
@export var full_hit_texture: Texture2D


func apply(user: Character, target: PositionSlot) -> void:
	if user == null or target == null:
		return
	swallow(user, target.occupant, full_texture, full_hit_texture)


# ─────────────────────────────────────────────────────────────
#  API statique — appelable depuis un cerveau d'IA
# ─────────────────────────────────────────────────────────────

## Vrai si `devourer` retient encore un héros vivant.
static func is_holding(devourer: Character) -> bool:
	if devourer == null or devourer.CharaGrab == null:
		return false
	if not is_instance_valid(devourer.CharaGrab):
		return false
	return devourer.CharaGrab.characterData.grab


## Avale `prey`. Sans effet si le dévoreur est déjà plein, si la proie est
## morte, déjà capturée, ou marquée can_be_moved = false.
static func swallow(devourer: Character, prey: Character,
		full_tex: Texture2D = null, full_hit_tex: Texture2D = null) -> bool:
	if devourer == null or prey == null:
		return false
	if not is_instance_valid(prey) or prey.is_dead():
		return false
	if is_holding(devourer):
		return false
	if prey.characterData.grab:
		return false
	if not prey.characterData.can_be_moved:
		return false

	var cm: CombatManager = devourer.combat_manager
	if cm == null:
		return false

	# Mémorise la place d'origine pour l'y remettre en priorité au relâchement.
	var home := -1
	for i in cm.hero_positions.size():
		if cm.hero_positions[i] == prey._current_slot:
			home = i
			break
	prey.set_meta("swallow_origin_index", home)

	# Libère le slot de héros : les alliés peuvent avancer dessus.
	if prey._current_slot != null:
		prey._current_slot.remove_character()

	# Parque la proie dans le ventre.
	if GRAB_SLOT < cm.enemy_positions.size():
		prey._current_slot = cm.enemy_positions[GRAB_SLOT]
	prey.global_position = devourer.global_position
	prey.z_index = devourer.z_index - 1
	prey.visible = false
	prey.characterData.grab = true

	devourer.CharaGrab = prey

	# Le dévoreur prend son apparence « pleine ».
	if full_tex != null:
		devourer.set_meta("swallow_idle_texture", devourer.characterData.portrait_texture)
		devourer.characterData.portrait_texture = full_tex
		if devourer.sprite != null:
			devourer.sprite.texture = full_tex
	if full_hit_tex != null:
		devourer.set_meta("swallow_hit_texture", devourer.characterData.Hit_texture)
		devourer.characterData.Hit_texture = full_hit_tex

	if cm.ui != null:
		cm.ui.log("%s swallows %s" % [
			devourer.characterData.Charaname, prey.characterData.Charaname])
	print("🫧 ", devourer.characterData.Charaname, " avale ", prey.characterData.Charaname)
	return true


## Recrache le héros retenu : il reprend une place libre parmi les
## positions de héros (la sienne en priorité). Renvoie false si le dévoreur
## ne retenait personne.
static func release(devourer: Character) -> bool:
	if devourer == null or devourer.CharaGrab == null:
		return false

	var prey: Character = devourer.CharaGrab
	devourer.CharaGrab = null

	# Le dévoreur redevient « vide », même si la proie n'est plus valide.
	_restore_appearance(devourer)

	if not is_instance_valid(prey):
		return false

	var cm: CombatManager = devourer.combat_manager
	if prey._current_slot != null:
		prey._current_slot.remove_character()
	prey.characterData.grab = false
	prey.visible = true

	if cm == null:
		return true

	var chosen: PositionSlot = null
	var home := -1
	if prey.has_meta("swallow_origin_index"):
		home = int(prey.get_meta("swallow_origin_index"))
		prey.remove_meta("swallow_origin_index")
	if home >= 0 and home < cm.hero_positions.size() \
			and not cm.hero_positions[home].is_occupied():
		chosen = cm.hero_positions[home]
	else:
		for pos: PositionSlot in cm.hero_positions:
			if not pos.is_occupied():
				chosen = pos
				break

	if chosen != null:
		prey.global_position = devourer.global_position
		chosen.assign_character(prey, 0.4)
	else:
		push_warning("SwallowEffect : aucune place libre pour relâcher %s."
				% prey.characterData.Charaname)

	if cm.ui != null:
		cm.ui.log("%s spits out %s" % [
			devourer.characterData.Charaname, prey.characterData.Charaname])
	print("💦 ", devourer.characterData.Charaname, " relâche ", prey.characterData.Charaname)
	prey.update_ui()
	return true


static func _restore_appearance(devourer: Character) -> void:
	if devourer.has_meta("swallow_idle_texture"):
		var tex = devourer.get_meta("swallow_idle_texture")
		devourer.remove_meta("swallow_idle_texture")
		if tex != null:
			devourer.characterData.portrait_texture = tex
			if devourer.sprite != null and not devourer.is_dead():
				devourer.sprite.texture = tex
	if devourer.has_meta("swallow_hit_texture"):
		var tex2 = devourer.get_meta("swallow_hit_texture")
		devourer.remove_meta("swallow_hit_texture")
		if tex2 != null:
			devourer.characterData.Hit_texture = tex2
