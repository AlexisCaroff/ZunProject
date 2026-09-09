extends Node


# ════════════════════════════════════════════════════════════════════
#  SAUVEGARDE / CHARGEMENT
# ════════════════════════════════════════════════════════════════════
#  L'état de jeu vit dans des Resources (.tres) mutées en mémoire :
#  CharacterData (jauges, affinités, équipement), RoomResource (flags de
#  progression), Equipment. Ce manager extrait cet état runtime vers du
#  JSON et le ré-applique au chargement.
#
#  Slots :
#    0      → sauvegarde automatique, écrasée à chaque changement de scène
#    1..3   → slots manuels choisis par le joueur
#
#  Écriture atomique : on écrit un .tmp, on le relit pour contrôle, on
#  bascule l'ancien fichier en .bak puis on renomme le .tmp. Un fichier
#  corrompu ou une coupure en cours d'écriture retombe donc toujours sur
#  la version précédente.
#
#  Le chargement restaure l'état AU DÉBUT de la scène courante : un combat
#  sauvegardé en cours est rejoué depuis son premier tour.
# ════════════════════════════════════════════════════════════════════

const SAVE_VERSION := 1

const AUTO_SLOT         := 0
const FIRST_MANUAL_SLOT := 1
const LAST_MANUAL_SLOT  := 3
const SLOT_COUNT        := 4

# Nature de la scène chargée au moment de la sauvegarde.
const SCENE_DOOR        := "door"
const SCENE_EXPLORATION := "exploration"
const SCENE_COMBAT      := "combat"
const SCENE_CAMP        := "camp"

signal save_started(slot: int)
signal save_finished(slot: int, success: bool)
signal load_finished(slot: int, success: bool)

## État d'origine des .tres, capturé une fois au démarrage. Sert à repartir
## d'une base propre pour une nouvelle partie comme pour un chargement —
## sans lui, les Resources gardent en mémoire les mutations de la partie
## précédente (jauges, affinités, salles explorées).
var _pristine: Dictionary = {}
var _busy: bool = false


# ════════════════════════════════════════════════════════════════════
#  CHEMINS
# ════════════════════════════════════════════════════════════════════

func save_path(slot: int) -> String:
	return "user://save_%d.json" % slot

func backup_path(slot: int) -> String:
	return "user://save_%d.bak.json" % slot

func _tmp_path(slot: int) -> String:
	return "user://save_%d.tmp.json" % slot


# ════════════════════════════════════════════════════════════════════
#  API PUBLIQUE
# ════════════════════════════════════════════════════════════════════

func is_busy() -> bool:
	return _busy


func is_manual_slot(slot: int) -> bool:
	return slot >= FIRST_MANUAL_SLOT and slot <= LAST_MANUAL_SLOT


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(save_path(slot)) or FileAccess.file_exists(backup_path(slot))


func has_any_save() -> bool:
	for slot in SLOT_COUNT:
		if has_save(slot):
			return true
	return false


## Slot le plus récent, ou -1 si aucune sauvegarde.
func most_recent_slot() -> int:
	var best := -1
	var best_time := -1.0
	for slot in SLOT_COUNT:
		var info := get_slot_info(slot)
		if info.is_empty():
			continue
		var t := float(info.get("timestamp", 0.0))
		if t > best_time:
			best_time = t
			best = slot
	return best


## Résumé d'un slot pour l'UI. Dictionnaire vide si le slot est libre.
func get_slot_info(slot: int) -> Dictionary:
	var data := read_slot(slot)
	if data.is_empty():
		return {}
	var meta: Dictionary = data.get("meta", {})
	meta["timestamp"] = data.get("timestamp", 0.0)
	return meta


func delete_slot(slot: int) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for p in [save_path(slot), backup_path(slot), _tmp_path(slot)]:
		if dir.file_exists(p):
			dir.remove(p)


# ════════════════════════════════════════════════════════════════════
#  ÉCRITURE
# ════════════════════════════════════════════════════════════════════

func save_to_slot(slot: int, gm) -> bool:
	if _busy:
		push_warning("SaveManager : sauvegarde déjà en cours, appel ignoré.")
		return false
	if gm == null:
		push_error("SaveManager : GameManager introuvable, sauvegarde annulée.")
		return false

	_busy = true
	GameState.saveRunning = true
	save_started.emit(slot)

	var ok := _write_slot(slot, capture_state(gm))

	_busy = false
	GameState.saveRunning = false
	save_finished.emit(slot, ok)
	if ok:
		print("💾 Sauvegarde slot %d OK" % slot)
	else:
		push_error("SaveManager : échec d'écriture du slot %d" % slot)
	return ok


func _write_slot(slot: int, data: Dictionary) -> bool:
	var json := JSON.stringify(data, "\t")
	var tmp := _tmp_path(slot)

	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager : impossible d'ouvrir %s (%d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(json)
	f.close()

	# Relecture de contrôle : on ne remplace la sauvegarde valide que si le
	# fichier fraîchement écrit est lisible et bien formé.
	var check := FileAccess.open(tmp, FileAccess.READ)
	if check == null:
		return false
	var reread := check.get_as_text()
	check.close()
	if JSON.parse_string(reread) == null:
		push_error("SaveManager : le fichier temporaire du slot %d est illisible, sauvegarde abandonnée." % slot)
		return false

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager : user:// inaccessible.")
		return false

	var main := save_path(slot)
	var bak := backup_path(slot)
	if dir.file_exists(main):
		if dir.file_exists(bak):
			dir.remove(bak)
		dir.rename(main, bak)
	return dir.rename(tmp, main) == OK


# ════════════════════════════════════════════════════════════════════
#  LECTURE
# ════════════════════════════════════════════════════════════════════

## Lit un slot. Retombe sur le .bak si le fichier principal est absent,
## illisible ou d'une version inconnue. Dictionnaire vide si rien d'exploitable.
func read_slot(slot: int) -> Dictionary:
	var data := _read_file(save_path(slot))
	if data.is_empty():
		data = _read_file(backup_path(slot))
		if not data.is_empty():
			push_warning("SaveManager : slot %d restauré depuis sa copie de secours." % slot)
	return data


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("SaveManager : %s illisible." % path)
		return {}
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager : %s n'est pas un JSON valide." % path)
		return {}
	var data: Dictionary = parsed
	var version := _as_int(data.get("version", -1))
	if version <= 0 or version > SAVE_VERSION:
		push_warning("SaveManager : version de sauvegarde %d non gérée (%s)." % [version, path])
		return {}
	if not data.has("characters") or not data.has("rooms"):
		push_warning("SaveManager : %s incomplet." % path)
		return {}
	return data


# ════════════════════════════════════════════════════════════════════
#  ÉTAT D'ORIGINE
# ════════════════════════════════════════════════════════════════════

## Appelé une seule fois par GameManager._ready(), après reset des salles et
## initialisation des affinités.
func capture_pristine(gm) -> void:
	if gm == null:
		return
	_pristine = capture_state(gm)
	_pristine["scene_kind"] = ""
	_pristine["current_room_id"] = ""
	_pristine["last_room_id"] = ""


## Remet toutes les Resources dans leur état d'origine. À appeler avant de
## démarrer une nouvelle partie comme avant d'appliquer une sauvegarde.
func restore_pristine(gm) -> void:
	if _pristine.is_empty() or gm == null:
		return
	apply_state(_pristine, gm)


# ════════════════════════════════════════════════════════════════════
#  CAPTURE
# ════════════════════════════════════════════════════════════════════

func capture_state(gm) -> Dictionary:
	var characters := []
	for cd in gm.characters:
		if cd != null:
			characters.append(_capture_character(cd))

	var rooms := {}
	if gm.donjon != null:
		for room in gm.donjon.rooms:
			if room != null and room.room_id != "":
				rooms[room.room_id] = _capture_room(room)

	var inventory := []
	for eq in gm.inventory:
		if eq != null:
			inventory.append(_capture_equipment(eq))

	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"meta": _build_meta(gm),
		"scene_kind": gm.current_scene_kind,
		"phase": int(GameState.current_phase),
		"team_corrupted": gm.teamCorrupted,
		"current_room_id": _room_id(gm.current_room_Ressource),
		"last_room_id": _room_id(gm.last_room_Ressource),
		"room_we_are_in_id": _room_id(gm.TheRoom_we_are_in),
		"last_room_we_were_in_id": _room_id(gm.LastRoom_we_were_in),
		"characters": characters,
		"rooms": rooms,
		"inventory": inventory,
	}


## Résumé lisible affiché dans l'écran de sauvegarde.
func _build_meta(gm) -> Dictionary:
	var party := []
	for cd in gm.characters:
		if cd == null:
			continue
		party.append({
			"name": cd.Charaname,
			"stamina": cd.current_stamina,
			"max_stamina": cd.max_stamina,
		})

	var dt := Time.get_datetime_dict_from_system()
	return {
		"room_id": _room_id(gm.current_room_Ressource),
		"scene_kind": gm.current_scene_kind,
		"date": "%02d/%02d/%04d %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute],
		"party": party,
	}


func _capture_character(cd: CharacterData) -> Dictionary:
	var equipped := []
	for eq in cd.equipped_items:
		if eq != null:
			equipped.append(_capture_equipment(eq))

	# Cooldowns des skills d'exploration et flags des skills de camp : ces
	# Resources sont partagées (non dupliquées par personnage), leur état
	# survit aux changements de scène et doit donc être sauvegardé.
	var explo_cooldowns := []
	for s in cd.exploration_skill_resources:
		explo_cooldowns.append(s.current_cooldown if s != null else 0)

	var camp_used := []
	for s in cd.camp_skill_resources:
		camp_used.append(s.used if s != null else false)

	return {
		"path": cd.resource_path,
		"charaname": cd.Charaname,
		"chara_position": cd.Chara_position,
		"current_stamina": cd.current_stamina,
		"current_stress": cd.current_stress,
		"current_horniness": cd.current_horniness,
		"corruption": cd.corruption,
		"corrupted": cd.corrupted,
		"inquisition": cd.inquisition,
		"peek": cd.peek,
		"affinity": cd.affinity.duplicate(),
		"equipped": equipped,
		"explo_cooldowns": explo_cooldowns,
		"camp_skills_used": camp_used,
	}


func _capture_room(room: RoomResource) -> Dictionary:
	var d := {
		"explored": room.explored,
		"ennemikilled": room.ennemikilled,
		"CampDone": room.CampDone,
		"locked": room.locked,
		"exploration_history_played": room.exploration_history_played,
		"door_history_played": room.door_history_played,
		"before_combat_history_played": room.before_combat_history_played,
		"post_combat_history_played": room.post_combat_history_played,
		"interactable_used": room.interactable_used,
		"interactable_opened": room.interactable_opened,
	}
	# L'encounter peut être remplacé à l'exécution (BossIntroSequence) et son
	# butin est modifié à la victoire — les deux doivent être restitués.
	if room.encounter is CombatEncounter:
		var enc: CombatEncounter = room.encounter
		d["encounter_path"] = enc.resource_path
		var loots := []
		for eq in enc.loots:
			if eq != null:
				loots.append(_capture_equipment(eq))
		d["encounter_loots"] = loots
	return d


## Un Equipment issu d'un .tres est référencé par son chemin. Ceux créés à
## l'exécution (cristaux de victoire, cf. CombatManager._show_victory) n'ont
## pas de resource_path : leurs champs sont sérialisés tels quels.
func _capture_equipment(eq: Equipment) -> Dictionary:
	if eq.resource_path != "":
		return {"path": eq.resource_path}
	return {
		"inline": true,
		"name": eq.name,
		"description": eq.description,
		"icon": eq.icon.resource_path if eq.icon != null else "",
		"number": eq.number,
		"isCursed": eq.isCursed,
		"Max_stamina_bonus": eq.Max_stamina_bonus,
		"Max_lust_bonus": eq.Max_lust_bonus,
		"Max_Guilt_bonus": eq.Max_Guilt_bonus,
		"attack_bonus": eq.attack_bonus,
		"defense_bonus": eq.defense_bonus,
		"willpower_bonus": eq.willpower_bonus,
		"evasion_bonus": eq.evasion_bonus,
		"initiative_bonus": eq.initiative_bonus,
		"peekbonus": eq.peekbonus,
		"global_cooldown_reduction": eq.global_cooldown_reduction,
	}


# ════════════════════════════════════════════════════════════════════
#  APPLICATION
# ════════════════════════════════════════════════════════════════════

## Réécrit l'état des Resources depuis un dictionnaire de sauvegarde.
## Ne charge AUCUNE scène — c'est GameManager qui s'en charge ensuite.
func apply_state(data: Dictionary, gm) -> bool:
	if data.is_empty() or gm == null:
		return false

	# ── Salles ──────────────────────────────────────────────────────
	var rooms: Dictionary = data.get("rooms", {})
	if gm.donjon != null:
		for room in gm.donjon.rooms:
			if room == null:
				continue
			room.reset_runtime_state()
			if rooms.has(room.room_id):
				_apply_room(room, rooms[room.room_id])

	# ── Personnages ─────────────────────────────────────────────────
	var saved_characters: Array = data.get("characters", [])
	for i in gm.characters.size():
		var cd: CharacterData = gm.characters[i]
		if cd == null:
			continue
		_reset_transient(cd)
		var entry := _find_character_entry(saved_characters, cd, i)
		if entry.is_empty():
			push_warning("SaveManager : aucun état sauvegardé pour %s." % cd.Charaname)
			continue
		_apply_character(cd, entry)

	# ── Inventaire ──────────────────────────────────────────────────
	var inventory: Array[Equipment] = []
	for entry in data.get("inventory", []):
		var eq := _restore_equipment(entry)
		if eq != null:
			inventory.append(eq)
	gm.inventory = inventory

	# ── GameManager ─────────────────────────────────────────────────
	gm.teamCorrupted = _as_bool(data.get("team_corrupted", false))
	gm.current_room_Ressource   = gm.get_room_by_id(str(data.get("current_room_id", "")))
	gm.last_room_Ressource      = gm.get_room_by_id(str(data.get("last_room_id", "")))
	gm.TheRoom_we_are_in        = gm.get_room_by_id(str(data.get("room_we_are_in_id", "")))
	gm.LastRoom_we_were_in      = gm.get_room_by_id(str(data.get("last_room_we_were_in_id", "")))
	gm.current_scene_kind       = str(data.get("scene_kind", ""))
	GameState.current_phase     = _as_int(data.get("phase", GameStat.GamePhase.EXPLORATION))
	GameState.Pause             = false

	gm.emit_signal("inventory_changed", null)
	return true


## Les personnages sont retrouvés par chemin de ressource, avec repli sur le
## nom puis sur la position dans le tableau.
func _find_character_entry(entries: Array, cd: CharacterData, index: int) -> Dictionary:
	for e in entries:
		if typeof(e) == TYPE_DICTIONARY and cd.resource_path != "" and e.get("path", "") == cd.resource_path:
			return e
	for e in entries:
		if typeof(e) == TYPE_DICTIONARY and e.get("charaname", "") == cd.Charaname:
			return e
	if index < entries.size() and typeof(entries[index]) == TYPE_DICTIONARY:
		return entries[index]
	return {}


func _apply_character(cd: CharacterData, d: Dictionary) -> void:
	cd.Chara_position   = _as_int(d.get("chara_position", cd.Chara_position))
	cd.corruption       = _as_int(d.get("corruption", 0))
	cd.corrupted        = _as_bool(d.get("corrupted", false))
	cd.inquisition      = _as_bool(d.get("inquisition", false))
	cd.peek             = _as_int(d.get("peek", 0))

	var affinity: Dictionary[String, int] = {}
	for k in d.get("affinity", {}):
		affinity[str(k)] = _as_int(d["affinity"][k])
	cd.affinity = affinity

	var equipped: Array[Equipment] = []
	for entry in d.get("equipped", []):
		var eq := _restore_equipment(entry)
		if eq != null:
			equipped.append(eq)
	cd.equipped_items = equipped

	# Les max dépendent de l'équipement : on les recalcule avant de borner les
	# jauges, sinon un item retiré laisserait une jauge au-dessus de son max.
	cd.max_stamina   = cd.base_max_stamina
	cd.max_stress    = cd.base_max_stress
	cd.max_horniness = cd.base_max_horniness
	for eq in equipped:
		cd.max_stamina   += eq.Max_stamina_bonus
		cd.max_stress    += eq.Max_Guilt_bonus
		cd.max_horniness += eq.Max_lust_bonus

	cd.current_stamina   = clampi(_as_int(d.get("current_stamina", cd.max_stamina)), 0, cd.max_stamina)
	cd.current_stress    = clampi(_as_int(d.get("current_stress", 0)), 0, cd.max_stress)
	cd.current_horniness = clampi(_as_int(d.get("current_horniness", 0)), 0, cd.max_horniness)

	var explo_cd: Array = d.get("explo_cooldowns", [])
	for i in cd.exploration_skill_resources.size():
		var s := cd.exploration_skill_resources[i]
		if s != null:
			s.current_cooldown = _as_int(explo_cd[i]) if i < explo_cd.size() else 0

	var camp_used: Array = d.get("camp_skills_used", [])
	for i in cd.camp_skill_resources.size():
		var s := cd.camp_skill_resources[i]
		if s != null:
			s.used = _as_bool(camp_used[i]) if i < camp_used.size() else false


## Remet à zéro ce qui n'a de sens que pendant un combat. Le chargement
## rejouant le combat depuis son début, rien de tout cela ne doit survivre.
func _reset_transient(cd: CharacterData) -> void:
	cd.stun = false
	cd.grab = false
	cd.immobilized = false
	cd.immobilized_turns = 0
	cd.acte_twice = false
	cd.buffs.clear()
	cd.current_bark = null
	for s in cd.skill_resources:
		if s is Skill:
			s.current_cooldown = 0


func _apply_room(room: RoomResource, d: Dictionary) -> void:
	room.explored                     = _as_bool(d.get("explored", false))
	room.ennemikilled                 = _as_bool(d.get("ennemikilled", false))
	room.CampDone                     = _as_bool(d.get("CampDone", false))
	room.locked                       = _as_bool(d.get("locked", room.locked))
	room.exploration_history_played   = _as_bool(d.get("exploration_history_played", false))
	room.door_history_played          = _as_bool(d.get("door_history_played", false))
	room.before_combat_history_played = _as_bool(d.get("before_combat_history_played", false))
	room.post_combat_history_played   = _as_bool(d.get("post_combat_history_played", false))
	room.interactable_used            = _as_bool(d.get("interactable_used", false))
	room.interactable_opened          = _as_bool(d.get("interactable_opened", false))

	var enc_path := str(d.get("encounter_path", ""))
	if enc_path != "" and ResourceLoader.exists(enc_path):
		var enc = load(enc_path)
		if enc is CombatEncounter:
			room.encounter = enc

	if room.encounter is CombatEncounter and d.has("encounter_loots"):
		var loots: Array[Equipment] = []
		for entry in d["encounter_loots"]:
			var eq := _restore_equipment(entry)
			if eq != null:
				loots.append(eq)
		room.encounter.loots = loots


func _restore_equipment(entry) -> Equipment:
	if typeof(entry) != TYPE_DICTIONARY:
		return null

	if not entry.get("inline", false):
		var path := str(entry.get("path", ""))
		if path == "" or not ResourceLoader.exists(path):
			push_warning("SaveManager : équipement introuvable (%s), ignoré." % path)
			return null
		# load() renvoie l'instance partagée du cache : l'identité est préservée,
		# ce dont dépendent gm.inventory.find() et has() dans InventoryUI.
		var res = load(path)
		return res if res is Equipment else null

	var eq := Equipment.new()
	eq.name                     = str(entry.get("name", ""))
	eq.description              = str(entry.get("description", ""))
	eq.number                   = _as_int(entry.get("number", 1))
	eq.isCursed                 = _as_bool(entry.get("isCursed", false))
	eq.Max_stamina_bonus        = _as_int(entry.get("Max_stamina_bonus", 0))
	eq.Max_lust_bonus           = _as_int(entry.get("Max_lust_bonus", 0))
	eq.Max_Guilt_bonus          = _as_int(entry.get("Max_Guilt_bonus", 0))
	eq.attack_bonus             = _as_int(entry.get("attack_bonus", 0))
	eq.defense_bonus            = _as_int(entry.get("defense_bonus", 0))
	eq.willpower_bonus          = _as_int(entry.get("willpower_bonus", 0))
	eq.evasion_bonus            = _as_int(entry.get("evasion_bonus", 0))
	eq.initiative_bonus         = _as_int(entry.get("initiative_bonus", 0))
	eq.peekbonus                = _as_int(entry.get("peekbonus", 0))
	eq.global_cooldown_reduction = _as_int(entry.get("global_cooldown_reduction", 0))
	eq.icon = Utils.load_texture(str(entry.get("icon", "")))
	return eq


# ════════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════════

func _room_id(room: RoomResource) -> String:
	return room.room_id if room != null else ""


## JSON ne connaît que les flottants : toute valeur numérique relue doit être
## reconvertie explicitement.
func _as_int(v) -> int:
	match typeof(v):
		TYPE_INT: return v
		TYPE_FLOAT: return int(round(v))
		TYPE_BOOL: return 1 if v else 0
		TYPE_STRING: return int(v)
	return 0


func _as_bool(v) -> bool:
	match typeof(v):
		TYPE_BOOL: return v
		TYPE_INT, TYPE_FLOAT: return v != 0
		TYPE_STRING: return v == "true"
	return false
