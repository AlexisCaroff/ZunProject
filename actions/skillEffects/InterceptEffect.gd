extends SkillEffect
class_name InterceptEffect

# ════════════════════════════════════════════════════════════════════
#  S'INTERPOSER DEVANT UN ALLIÉ
# ════════════════════════════════════════════════════════════════════
#
#  Le lanceur se place devant la cible : pendant `duration` tours, les
#  attaques SIMPLES que l'adversaire dirige contre elle sont redirigées
#  sur le lanceur. La redirection elle-même vit dans Skill.use() —
#  cf. Skill._redirect_to_protector().
#
#  Volontairement limité aux attaques à cible unique (the_target_type
#  ENNEMY côté attaquant) : sur une attaque de zone, le protecteur est
#  déjà dans la liste des cibles, il la prendrait deux fois.
#
#  L'état vit sur le PROTECTEUR (`protecting` + `protect_turns`), pas sur
#  le protégé : c'est le protecteur qui joue son tour à coup sûr, donc son
#  end_turn() fait descendre le compteur de façon fiable, même si le
#  protégé est étourdi, capturé ou trop excité pour agir.

## Nombre de tours pendant lesquels le lanceur s'interpose.
@export var duration: int = 2


func apply(user: Character, target: PositionSlot) -> void:
	if user == null or target == null:
		return
	var ally: Character = target.occupant
	if ally == null or ally == user:
		return
	if not is_instance_valid(ally) or ally.is_dead():
		return

	user.protecting = ally
	user.protect_turns = duration

	var cm: CombatManager = user.combat_manager
	if cm != null and cm.ui != null:
		cm.ui.log("%s shields %s" % [
			user.characterData.Charaname, ally.characterData.Charaname])
	print("🛡️ ", user.characterData.Charaname, " s'interpose devant ",
			ally.characterData.Charaname, " pour ", duration, " tours")


## Renvoie le protecteur valide de `victim` parmi `allies`, ou null.
## Utilisé par Skill.use() pour rediriger un coup.
static func protector_of(victim: Character, allies: Array) -> Character:
	if victim == null or not is_instance_valid(victim):
		return null
	for a in allies:
		if a == null or not is_instance_valid(a):
			continue
		if a == victim:
			continue
		if a.protecting != victim or a.protect_turns <= 0:
			continue
		if a.is_dead() or a.characterData == null:
			continue
		# Un protecteur capturé, étourdi ou hors de sa case ne couvre plus
		# personne.
		if a.characterData.grab or a.characterData.current_stamina <= 0:
			continue
		if a._current_slot == null or a._current_slot.occupant != a:
			continue
		return a
	return null
