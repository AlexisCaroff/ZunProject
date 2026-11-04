extends Resource
class_name CharacterData
@export var headPosition: Vector2= Vector2(1.0,-310.0)
@export var torso_Position  : Vector2  = Vector2(0.0,0.0)
@export var portrait_texture: Texture2D
@export var explorationPortrait:Texture2D
@export var dead_portrait_texture: Texture2D
@export var Hit_texture: Texture2D
@export var initiative_icon: Texture2D
@export var Dialogue_texture: Texture2D
@export var textureCamp: Texture2D
## Sprite affiché pendant que le personnage est posté devant la porte en
## mode peek. Null = on garde le sprite courant.
@export var peek_texture: Texture2D
## Poses à lust max (cf. LustBreak) : nu (exib), masturbation (degenerate).
## Null = sprite normal.
@export var naked_texture: Texture2D
@export var masturbate_texture: Texture2D

@export var Name : String = "name"
@export var Charaname: String = "Classe"
@export var IsDemon: bool = false
@export var size : String= "average"

# ════════════════════════════════════════════════════════════════════
#  GENRE & ATTIRANCE
# ════════════════════════════════════════════════════════════════════
#  `presentation` est FIXE : elle se règle à la main dans l'inspecteur et
#  ne se tire jamais au sort, parce que les scènes d'amour sont dessinées
#  avec des corps précis.
#
#  `attracted_to_*` est TIRÉ au début de chaque partie par le menu
#  TasteRollMenu (res://UI/taste_roll_menu.tscn). Au moins l'un des deux
#  est vrai : personne n'est attiré par rien.
#
#  Deux personnages peuvent coucher ensemble si l'attirance est
#  RÉCIPROQUE — voir is_compatible_with().
# ════════════════════════════════════════════════════════════════════

enum Presentation { FEMININE, MASCULINE, ANDROGYNOUS }

## Comment ce personnage est perçu par les autres. À régler par personnage
## dans l'inspecteur ; ANDROGYNOUS séduit les deux camps.
@export var presentation: Presentation = Presentation.FEMININE

@export_group("Attirance (tirée en début de partie)")
@export var attracted_to_feminine: bool = true
@export var attracted_to_masculine: bool = false
@export_group("")

# ---- Affinity
@export var affinity: Dictionary[String, int] = {}
# --- Stats de combat
@export var base_max_stamina: int = 100
@export var base_max_stress: int = 100
@export var base_max_horniness: int = 100

@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_willpower: int = 5
@export var base_initiative: int = 1
@export var base_evasion: int = 5
@export var base_precision: int = 100
var precision: int = 100        # recalculé chaque update_stats

@export var attack: int = 10
@export var defense: int = 5
@export var willpower: int = 5
@export var evasion: int = 5
@export var initiative: int = 1
@export var peek :int =0
@export var equipped_items: Array[Equipment] = []



#etat
@export var stun : bool = false
@export var grab : bool  = false
@export var Chara_position:int = 0 


# --- Jauges
@export var max_stamina: int = 100
@export var max_stress: int = 100
@export var max_horniness: int = 100

@export var current_stamina: int = 100
@export var current_stress: int = 0
@export var current_horniness: int = 0

@export var isOneshot : bool= false

@export var skill_resources: Array[Resource] = []

@export var exploration_skill_resources: Array[ExplorationSkill] = []
# --- Tags (type, classe, etc.)
@export var tags: Array[String] = []
@export var assist: String = ""
#combat

# --- Contrôle
@export var is_player_controlled: bool = true
@export var ai_brain: AiBrain
@export var can_be_moved : bool = true

@export var min_durationIddle: float = 0.6
@export var max_durationIddle: float = 1.0
@export var min_scale: float = 0.95
@export var max_scale: float = 1.0
@export var corruption: int = 0

var acte_twice : bool =false
@export var camp_skill_resources: Array[CampSkill] = []
@export var bark_scene: PackedScene = preload("res://UI/bark.tscn")
@export var taunts := [
	"Is that all you've got?",
	"Try harder!",
	"Pathetic!",
	"You're wide open!",
	"You fight like a wet noodle!",
	"Oops! Did that hurt?",
	
]
@export var reaction := [
	"",
	"",
	""
]
@export var affinityReaction := [
	"",
	"",
	""
]
var buffs: Array[Buff] = []
## Bonus valables plusieurs combats (Buff.fights_left) : rejoués au début de
## chaque combat, décomptés à sa fin (CombatManager._consume_fight_buffs).
var fight_buffs: Array[Buff] = []

## Foi du personnage : certaines cartes d'affinité (sermon, confession)
## touchent les zélotes et laissent les barbares indifférents.
enum Faith { NEUTRAL, ZEALOT, BARBARIAN }
@export var faith: Faith = Faith.NEUTRAL
var current_bark: Bark = null
@export var corrupted: bool  = false
@export var inquisition :bool  = false
@export var immobilized: bool  = false
@export var immobilized_turns: int = 0


# ════════════════════════════════════════════════════════════════════
#  ATTIRANCE — API
# ════════════════════════════════════════════════════════════════════

## Ce personnage est-il attiré par `other` ? Sens unique.
func is_attracted_to(other: CharacterData) -> bool:
	if other == null:
		return false
	match other.presentation:
		Presentation.FEMININE:
			return attracted_to_feminine
		Presentation.MASCULINE:
			return attracted_to_masculine
		Presentation.ANDROGYNOUS:
			return attracted_to_feminine or attracted_to_masculine
	return false


## Attirance réciproque : la condition pour une scène d'amour.
func is_compatible_with(other: CharacterData) -> bool:
	if other == null or other == self:
		return false
	return is_attracted_to(other) and other.is_attracted_to(self)


## Applique un tirage. Garantit qu'au moins une des deux attirances est
## vraie — un personnage attiré par rien serait injouable côté romance.
func set_taste(feminine: bool, masculine: bool) -> void:
	if not feminine and not masculine:
		feminine = true
	attracted_to_feminine = feminine
	attracted_to_masculine = masculine


## Tire une attirance au sort. `bi_chance` est la probabilité d'être
## attiré par les deux ; le reste se partage à parts égales.
func roll_taste(bi_chance: float = 0.25) -> void:
	if randf() < bi_chance:
		set_taste(true, true)
	elif randf() < 0.5:
		set_taste(true, false)
	else:
		set_taste(false, true)


# ════════════════════════════════════════════════════════════════════
#  DÉTAIL DES STATS (infobulle) : base + kinks + équipement + buffs
# ════════════════════════════════════════════════════════════════════

## Bonus de stat apportés par les kinks — mêmes règles que le combat
## (Character.update_stats).
const KINK_STAT_BONUS := {
	"sadist": {"attack": 2},
	"maso": {"evasion": -2},
}
const _BUFF_STAT_OF := {"attack": 0, "defense": 1, "willpower": 3, "evasion": 4}
const _STAT_LABEL := {"attack": "Attack", "defense": "Defense", "willpower": "Willpower", "evasion": "Evasion"}


## Décompose une stat ("attack", "defense", "willpower", "evasion") :
## { base, kinks, kink_names, equipment, buffs, total }. Les buffs sont ceux
## posés hors combat (characterData.buffs : potions, camp…) ; en combat, le
## Character passe les siens via `combat_buffs` (Character.buffs).
func stat_breakdown(stat: String, combat_buffs = null) -> Dictionary:
	var base := int(get("base_" + stat))
	var kinks := 0
	var kink_names: Array[String] = []
	for t in tags:
		if KINK_STAT_BONUS.has(t) and KINK_STAT_BONUS[t].has(stat):
			kinks += int(KINK_STAT_BONUS[t][stat])
			kink_names.append(t)
	var equipment := 0
	for eq in equipped_items:
		if eq != null:
			equipment += int(eq.get(stat + "_bonus"))
	var buff_total := 0
	if _BUFF_STAT_OF.has(stat):
		var source: Array = combat_buffs if combat_buffs != null else buffs
		for b in source:
			if b != null and int(b.stat) == int(_BUFF_STAT_OF[stat]):
				buff_total += int(b.amount)
	return {
		"base": base, "kinks": kinks, "kink_names": kink_names,
		"equipment": equipment, "buffs": buff_total,
		"total": base + kinks + equipment + buff_total,
	}


## Recalcule les stats finales (base + kinks + buffs + équipement) : la
## seule règle de calcul, partagée par le combat, la porte, l'exploration,
## le camp et le menu personnages. `source_buffs` = buffs de combat du
## Character ; null = buffs posés hors combat (characterData.buffs).
func recompute_stats(source_buffs = null) -> void:
	max_stamina = base_max_stamina
	max_horniness = base_max_horniness
	max_stress = base_max_stress
	attack = base_attack
	defense = base_defense
	initiative = base_initiative
	willpower = base_willpower
	evasion = base_evasion
	precision = base_precision
	immobilized = false   # remis à false — le buff IMMOBILIZE le repose si actif
	for t in tags:
		if KINK_STAT_BONUS.has(t):
			for st in KINK_STAT_BONUS[t]:
				set(st, int(get(st)) + int(KINK_STAT_BONUS[t][st]))
	evasion = max(0, evasion)
	for b in (source_buffs if source_buffs != null else buffs):
		if b != null:
			b.apply_to(self)
	for eq in equipped_items:
		if eq == null:
			continue
		attack += eq.attack_bonus
		defense += eq.defense_bonus
		max_horniness += eq.Max_lust_bonus
		max_stamina += eq.Max_stamina_bonus
		max_stress += eq.Max_Guilt_bonus
		willpower += eq.willpower_bonus
		evasion += eq.evasion_bonus
		initiative += eq.initiative_bonus


## Texte d'infobulle : la valeur finale puis chaque apport.
func stat_tooltip(stat: String, combat_buffs = null) -> String:
	var d := stat_breakdown(stat, combat_buffs)
	var lines: Array[String] = ["%s: %d" % [_STAT_LABEL.get(stat, stat.capitalize()), d.total]]
	lines.append("  Base: %d" % d.base)
	var kink_txt := "  Kinks: %+d" % d.kinks
	if not d.kink_names.is_empty():
		kink_txt += " (%s)" % ", ".join(d.kink_names)
	lines.append(kink_txt)
	lines.append("  Equipment: %+d" % d.equipment)
	lines.append("  Temporary buffs: %+d" % d.buffs)
	return "\n".join(lines)


## Vrai si chaque membre de `team` a au moins un partenaire possible
## (attirance réciproque) dans l'équipe : personne n'est privé de scène au
## camp, et l'équipe ne peut pas tomber sur « tout le monde n'aime que les
## femmes », qui laisserait les hommes sans rien.
static func team_is_valid(team: Array) -> bool:
	for a in team:
		if a == null:
			continue
		var has_partner := false
		for b in team:
			if b != null and a.is_compatible_with(b):
				has_partner = true
				break
		if not has_partner:
			return false
	return true


## Tire les attirances de toute l'équipe en respectant team_is_valid().
## On retire tout le monde jusqu'à `attempts` fois ; si le hasard n'y arrive
## pas (équipe très déséquilibrée), on répare à la main.
static func roll_team(team: Array, bi_chance: float = 0.25, attempts: int = 60) -> void:
	for i in attempts:
		for c in team:
			if c != null:
				c.roll_taste(bi_chance)
		if team_is_valid(team):
			return
	_repair_team(team)


## Retire un seul membre en gardant l'équipe valide. Si aucun tirage ne
## convient, il garde son attirance actuelle.
static func reroll_member(member: CharacterData, team: Array,
		bi_chance: float = 0.25, attempts: int = 40) -> void:
	var old_fem := member.attracted_to_feminine
	var old_masc := member.attracted_to_masculine
	for i in attempts:
		member.roll_taste(bi_chance)
		if team_is_valid(team):
			return
	member.set_taste(old_fem, old_masc)
	if not team_is_valid(team):
		_repair_team(team)


## Dernier recours : chaque personnage isolé est rendu compatible avec un
## autre membre, en ajoutant (sans en retirer) les attirances nécessaires
## des deux côtés.
static func _repair_team(team: Array) -> void:
	for a in team:
		if a == null:
			continue
		var isolated := true
		for b in team:
			if b != null and a.is_compatible_with(b):
				isolated = false
				break
		if not isolated:
			continue
		var partner: CharacterData = null
		for b in team:
			if b != null and b != a:
				partner = b
				break
		if partner == null:
			return
		a._add_attraction_to(partner)
		partner._add_attraction_to(a)


func _add_attraction_to(other: CharacterData) -> void:
	match other.presentation:
		Presentation.FEMININE:
			attracted_to_feminine = true
		Presentation.MASCULINE:
			attracted_to_masculine = true
		_:
			if not attracted_to_feminine and not attracted_to_masculine:
				attracted_to_feminine = true


## Libellé court, pour les tooltips et le journal.
func taste_label() -> String:
	if attracted_to_feminine and attracted_to_masculine:
		return "Bi"
	if attracted_to_feminine:
		return "Feminine attracted"
	if attracted_to_masculine:
		return "Masculine attracted"
	return "—"
