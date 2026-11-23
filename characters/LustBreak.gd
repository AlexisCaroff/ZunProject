extends RefCounted
class_name LustBreak


#  PERTE DE CONTRÔLE À LUST MAX



## Affinité perdue par chaque allié touché envers le héros en rut.
const AFFINITY_LOSS := 10
## sadist : coup porté à un allié (base, + ATK - DEF comme une attaque).
const SADIST_DAMAGE := 10
## voyeur : gifle de l'allié qui l'a surpris (base, + ATK - DEF).
const VOYEUR_SLAP := 8
## exib / degenerate : lust infligée à chaque allié (moins sa WILL).
const EXIB_LUST := 15
const DEGENERATE_LUST := 10
## degrader : guilt infligée à chaque allié (moins sa WILL).
const DEGRADER_GUILT := 15
## jailor : chance de réussir à étourdir l'allié.
const JAILOR_STUN_CHANCE := 0.5
## maso : malus de défense (très gros debuff sur l'échelle) + provocation.
const MASO_DEF_MALUS := -20
const MASO_TAUNT_TURNS := 1

const KINKS := ["sadist", "maso", "voyeur", "exib", "degrader", "degenerate", "jailor", "captive"]


## pour le héros en rut, <KINK>_REACT pour l'allié qui réagit. {name} = nom du héros en rut.
const BARKS_FILE := "res://texts/lust_barks_%s.txt"

const BARK_READ_TIME := 1.8

## Répliques chargées, par langue : { "en": { CLÉ: texte } }.
static var _barks: Dictionary = {}


## Kinks du personnage qui ont un effet à lust max.
static func kinks_of(chara: Character) -> Array:
	var out := []
	for t in chara.characterData.tags:
		if t in KINKS and not out.has(t):
			out.append(t)
	return out


## Joue l'effet d'un kink tiré au hasard. Ne fait rien sans kink.
static func play(chara: Character, cm: CombatManager) -> void:
	if chara == null or cm == null or not chara.characterData.is_player_controlled:
		return
	var kinks := kinks_of(chara)
	if kinks.is_empty():
		return
	var kink: String = kinks.pick_random()
	print("💗 Lust break: ", chara.characterData.Charaname, " → ", kink)
	await _say(chara, line(kink.to_upper()))
	match kink:
		"sadist": await _sadist(chara, cm)
		"maso": await _maso(chara, cm)
		"voyeur": await _voyeur(chara, cm)
		"exib": await _exib(chara, cm)
		"degrader": await _degrader(chara, cm)
		"degenerate": await _degenerate(chara, cm)
		"jailor": await _jailor(chara, cm)
		"captive": await _captive(chara, cm)
	chara.update_ui()
	for h in _allies(chara, cm):
		h.update_ui()


static func _allies(chara: Character, cm: CombatManager) -> Array[Character]:
	var out: Array[Character] = []
	for h in cm.heroes:
		if h != chara and is_instance_valid(h) and not h.is_dead() \
				and not h.characterData.grab and h._current_slot != null:
			out.append(h)
	return out


static func _lose_affinity(victim: Character, culprit: Character) -> void:
	victim.reduce_affinity(culprit, AFFINITY_LOSS)


## Réplique d'un allié qui explique ce qui vient de se passer 
static func _react(speaker: Character, culprit: Character, key: String) -> void:
	if speaker == null or not is_instance_valid(speaker):
		return
	
	speaker.show_bark(line(key, culprit.characterData.Charaname), 0.0, BARK_READ_TIME)


## Texte d'une réplique dans la langue courante (repli : anglais, puis la clé).
static func line(key: String, name: String = "") -> String:
	var lang := TranslationServer.get_locale().substr(0, 2)
	var text: String = _lines(lang).get(key, "")
	if text == "":
		text = _lines("en").get(key, key)
	return text.format({"name": name})


static func _lines(lang: String) -> Dictionary:
	if not _barks.has(lang):
		_barks[lang] = _load_barks(BARKS_FILE % lang)
	return _barks[lang]



static func _load_barks(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	while not f.eof_reached():
		var l := f.get_line().strip_edges()
		if l == "" or l.begins_with("#"):
			continue
		var eq := l.find("=")
		if eq <= 0:
			continue
		out[l.substr(0, eq).strip_edges()] = l.substr(eq + 1).strip_edges()
	return out



static func _say(speaker: Character, text: String) -> void:
	await speaker.show_bark(text, -1.0, BARK_READ_TIME)


static func _pick(list: Array) -> Character:
	return list.pick_random() if not list.is_empty() else null


## sadist : frappe un allié au hasard.
static func _sadist(chara: Character, cm: CombatManager) -> void:
	var allies := _allies(chara, cm)
	if allies.is_empty():
		return
	var victim: Character = allies.pick_random()
	cm.ui.log("%s attacks %s!" % [chara.characterData.Charaname, victim.characterData.Charaname])
	await victim.take_damage(chara, DamageEffect.Stat.STAMINA, SADIST_DAMAGE, false)
	_lose_affinity(victim, chara)
	await _react(victim, chara, "SADIST_REACT")


## maso : baisse sa garde et provoque tous les ennemis.
static func _maso(chara: Character, cm: CombatManager) -> void:
	var b := Buff.new()
	b.name = "Begging"
	b.stat = Buff.Stat.DEFENSE
	b.amount = MASO_DEF_MALUS
	b.icon = load("res://UI/debuffAtt.png")
	chara.add_buff(b, chara)
	for e in cm.enemies:
		if is_instance_valid(e) and not e.is_dead():
			e.taunted_by = chara
			e.taunt_duration = MASO_TAUNT_TURNS
	cm.ui.log("%s lowers their guard and taunts every enemy" % chara.characterData.Charaname)
	for h in _allies(chara, cm):
		_lose_affinity(h, chara)
	await _react(_pick(_allies(chara, cm)), chara, "MASO_REACT")


## voyeur : les alliés le surprennent et l'un d'eux le gifle.
static func _voyeur(chara: Character, cm: CombatManager) -> void:
	var allies := _allies(chara, cm)
	if allies.is_empty():
		return
	for h in allies:
		_lose_affinity(h, chara)
	var slapper: Character = allies.pick_random()
	cm.ui.log("%s catches %s peeking!" % [slapper.characterData.Charaname, chara.characterData.Charaname])
	await chara.take_damage(slapper, DamageEffect.Stat.STAMINA, VOYEUR_SLAP, false)
	await _react(slapper, chara, "VOYEUR_REACT")


## exib : se dénude, les allié sont horny
static func _exib(chara: Character, cm: CombatManager) -> void:
	chara.lust_pose_texture = chara.characterData.get("naked_texture")
	chara.resetVisuel()
	cm.ui.log("%s strips naked!" % chara.characterData.Charaname)
	for h in _allies(chara, cm):
		await h.take_damage(chara, DamageEffect.Stat.HORNY, EXIB_LUST, false)
		_lose_affinity(h, chara)
	await _react(_pick(_allies(chara, cm)), chara, "EXIB_REACT")


## degrader : guilt les alliés .
static func _degrader(chara: Character, cm: CombatManager) -> void:
	cm.ui.log("%s insults the party" % chara.characterData.Charaname)
	for h in _allies(chara, cm):
		await h.take_damage(chara, DamageEffect.Stat.STRESS, DEGRADER_GUILT, false)
		_lose_affinity(h, chara)
	await _react(_pick(_allies(chara, cm)), chara, "DEGRADER_REACT")


## degenerate : se masturbe (sprite gardée tant qu'il est à lust max ?) a remplacer par anim
static func _degenerate(chara: Character, cm: CombatManager) -> void:
	chara.lust_pose_texture = chara.characterData.get("masturbate_texture")
	chara.resetVisuel()
	cm.ui.log("%s can't keep their hands to themselves..." % chara.characterData.Charaname)
	for h in _allies(chara, cm):
		await h.take_damage(chara, DamageEffect.Stat.HORNY, DEGENERATE_LUST, false)
		_lose_affinity(h, chara)
	await _react(_pick(_allies(chara, cm)), chara, "DEGENERATE_REACT")


## jailor : tente stun allié.
static func _jailor(chara: Character, cm: CombatManager) -> void:
	var allies := _allies(chara, cm)
	if allies.is_empty():
		return
	var victim: Character = allies.pick_random()
	_lose_affinity(victim, chara)
	if randf() < JAILOR_STUN_CHANCE:
		victim.characterData.stun = true
		cm.ui.log("%s ties up %s!" % [chara.characterData.Charaname, victim.characterData.Charaname])
		await victim.animate_take_damage(0, chara)
		await _react(victim, chara, "JAILOR_REACT_SUCCESS")
	else:
		cm.ui.log("%s tries to tie up %s, who breaks free" % [chara.characterData.Charaname, victim.characterData.Charaname])
		await _react(victim, chara, "JAILOR_REACT_FAIL")


## captive : le prochain coup ennemi le capture (cf. Character.take_damage).
static func _captive(chara: Character, cm: CombatManager) -> void:
	chara.captive_exposed = true
	cm.ui.log("%s offers themselves to the enemy..." % chara.characterData.Charaname)
	await _react(_pick(_allies(chara, cm)), chara, "CAPTIVE_REACT")
