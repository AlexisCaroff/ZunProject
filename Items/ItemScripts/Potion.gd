extends Equipment
class_name Potion

# ════════════════════════════════════════════════════════════════════
#  POTION — objet consommable du sac d'équipe
# ════════════════════════════════════════════════════════════════════
#  Une Potion EST un Equipment : elle circule donc sans rien changer
#  dans gm.inventory, InventoryUI, DoorInventory, CombatEncounter.loots
#  et la sauvegarde. Ce qui la distingue :
#
#    • elle ne s'équipe pas (bloqué dans InventoryUI.try_equip_on_character)
#    • cliquer dessus ouvre un popup de confirmation puis la consomme
#    • elle s'empile : `number` est la quantité de la pile
#
#  Les effets sont déclaratifs (pas de sous-classe à écrire) :
#    - soins immédiats sur les trois jauges
#    - buffs posés sur la cible ; hors combat ils sont rangés dans
#      characterData.buffs et Character._ready() les rejoue au début du
#      prochain combat — exactement le canal utilisé par les camp skills
#    - grants_extra_turn = le acte_twice du chasseur
# ════════════════════════════════════════════════════════════════════

## Identifiant de pile. Deux potions de même stack_id fusionnent dans la
## même case d'inventaire. Laisser vide : le chemin du .tres est utilisé.
@export var stack_id: String = ""

## Chemin du .tres d'origine, renseigné par make(). Une potion en
## inventaire est toujours une copie (sinon modifier `number` modifierait
## la ressource partagée) — on garde donc d'où elle vient pour la sauvegarde.
@export var origin_path: String = ""

## Taille maximale d'une pile. Au-delà, une nouvelle case est utilisée.
@export var max_stack: int = 9

@export_group("Effets immédiats")
## Rend de la stamina.
@export var heal_stamina: int = 0
## Fait BAISSER la lust (current_horniness).
@export var heal_lust: int = 0
## Fait BAISSER la culpabilité (current_stress).
@export var heal_guilt: int = 0

@export_group("Effets de combat")
## Buffs posés sur la cible. Hors combat ils attendent le prochain combat.
@export var buffs: Array[Buff] = []
## Donne un tour supplémentaire au prochain passage dans la file d'initiative
## (même mécanique que le camp skill du chasseur).
@export var grants_extra_turn: bool = false

@export_group("Usage")
@export var usable_out_of_combat: bool = true
@export var usable_in_combat: bool = true
## En combat, boire la potion consomme le tour du personnage.
@export var ends_turn_in_combat: bool = true
## Texte du popup de confirmation. Vide = texte généré automatiquement.
@export_multiline var confirm_text: String = ""
@export var use_sound: AudioStream


# ── Identité / pile ─────────────────────────────────────────────────

func get_stack_id() -> String:
	if stack_id != "":
		return stack_id
	if origin_path != "":
		return origin_path
	if resource_path != "":
		return resource_path
	return name


## Crée la copie qui ira en inventaire. On ne met JAMAIS le .tres original
## dans gm.inventory : `number` est muté à chaque utilisation, et un .tres
## est une instance partagée par tout le jeu.
static func make(src: Potion, count: int = -1) -> Potion:
	if src == null:
		return null
	# duplicate(false) : copie superficielle. L'icône et le tableau de buffs
	# restent partagés avec le .tres (on ne les mute jamais), seuls les
	# champs simples — dont `number` — sont propres à cette pile.
	var copy: Potion = src.duplicate(false)
	if copy.origin_path == "":
		copy.origin_path = src.resource_path
	if copy.stack_id == "":
		copy.stack_id = src.get_stack_id()
	copy.number = count if count > 0 else max(1, src.number)
	return copy


func can_stack_with(other: Equipment) -> bool:
	return other is Potion and (other as Potion).get_stack_id() == get_stack_id()


# ── Utilisation ─────────────────────────────────────────────────────

func is_usable(in_combat: bool) -> bool:
	return usable_in_combat if in_combat else usable_out_of_combat


## Applique la potion sur une CharacterData nue (menu perso, exploration,
## porte). Les buffs sont déposés dans characterData.buffs : ils seront
## rejoués par Character._ready() au début du prochain combat.
func apply_to_data(cd: CharacterData) -> void:
	if cd == null:
		return

	if heal_stamina > 0:
		cd.current_stamina = min(cd.max_stamina, cd.current_stamina + heal_stamina)
	if heal_lust > 0:
		cd.current_horniness = max(0, cd.current_horniness - heal_lust)
	if heal_guilt > 0:
		cd.current_stress = max(0, cd.current_stress - heal_guilt)

	for b in buffs:
		if b != null:
			cd.buffs.append(b.duplicate())

	if grants_extra_turn:
		cd.acte_twice = true

	print("🧪 %s bue par %s" % [name, cd.Charaname])


## Applique la potion en plein combat : on passe par le Character pour
## avoir les icônes de buff, les VFX de soin et le recalcul des stats.
func apply_to_character(c: Character) -> void:
	if c == null or c.characterData == null:
		return
	var cd: CharacterData = c.characterData

	if heal_stamina > 0:
		cd.current_stamina = min(cd.max_stamina, cd.current_stamina + heal_stamina)
		c.animate_heal(heal_stamina, c)
	if heal_lust > 0:
		cd.current_horniness = max(0, cd.current_horniness - heal_lust)
	if heal_guilt > 0:
		cd.current_stress = max(0, cd.current_stress - heal_guilt)

	for b in buffs:
		if b != null:
			c.add_buff(b)

	if grants_extra_turn:
		cd.acte_twice = true

	c.update_stats()
	c.update_ui()
	print("🧪 %s bue en combat par %s" % [name, cd.Charaname])


# ── Affichage ───────────────────────────────────────────────────────

## Résumé bbcode des effets, réutilisé par le popup et le tooltip.
func effects_bbcode() -> String:
	var lines: Array[String] = []
	if heal_stamina > 0:
		lines.append("[color=FF9966]+%d Stamina[/color]" % heal_stamina)
	if heal_lust > 0:
		lines.append("[color=FF66AA]-%d Lust[/color]" % heal_lust)
	if heal_guilt > 0:
		lines.append("[color=AAAAAA]-%d Guilt[/color]" % heal_guilt)
	if grants_extra_turn:
		lines.append("[color=FFFF66]Un tour supplémentaire[/color]")
	for b in buffs:
		if b == null:
			continue
		if b.amount != 0:
			lines.append("[color=CC99FF]%s %+d (%d tours)[/color]" % [
				Buff.Stat.keys()[b.stat], b.amount, b.duration])
		else:
			lines.append("[color=CC99FF]%s (%d tours)[/color]" % [
				Buff.Stat.keys()[b.stat], b.duration])
	return "\n".join(lines)


func confirm_message(target_name: String) -> String:
	if confirm_text != "":
		return confirm_text
	return "Faire boire %s à %s ?" % [name, target_name]
