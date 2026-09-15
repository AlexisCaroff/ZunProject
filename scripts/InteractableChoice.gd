# InteractableChoice.gd
extends Resource
class_name InteractableChoice

# RANDOM_LOOT est ajouté EN FIN d'énum : les valeurs déjà stockées dans les
# .tres existants (0..3) restent valides. Les décaler casserait tous les
# coffres déjà réglés.
enum EffectType { NONE, ITEM, BUFF, TAG, RANDOM_LOOT }

@export var text: String
@export var effect_type: EffectType = EffectType.NONE

# Données selon le type
@export var item: Resource        # Item.tres
@export var buff: Buff       # Buff.tres
@export var tag: String           # ex: "cursed"
@export var opening : bool = false

@export_group("RANDOM_LOOT")
## Nombre de tirages dans la table de butin globale du GameManager.
## -1 = la valeur réglée sur la table elle-même.
@export var loot_rolls: int = 1
## Chance qu'un tirage donne quelque chose. -1 = valeur de la table.
@export_range(-1.0, 1.0, 0.05) var loot_chance: float = 1.0
## Butin garanti en plus du tirage aléatoire (peut rester vide).
@export var guaranteed_items: Array[Equipment] = []
