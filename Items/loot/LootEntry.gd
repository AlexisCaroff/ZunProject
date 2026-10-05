extends Resource
class_name LootEntry

# ════════════════════════════════════════════════════════════════════
#  UNE LIGNE DE TABLE DE BUTIN
# ════════════════════════════════════════════════════════════════════

## L'objet tiré. N'importe quel Equipment fonctionne, mais une Potion
## sera automatiquement dupliquée et empilée.
@export var item: Equipment

## Poids relatif du tirage. Une ligne de poids 3 sort trois fois plus
## souvent qu'une ligne de poids 1. 0 = jamais.
@export var weight: float = 1.0

## Quantité tirée (bornes incluses).
@export var min_count: int = 1
@export var max_count: int = 1

## Ne peut tomber qu'à partir de ce round du donjon / cette profondeur.
## Laisser à 0 si tu ne t'en sers pas.
@export var min_depth: int = 0


func roll_count() -> int:
	var lo: int = max(1, min_count)
	var hi: int = max(lo, max_count)
	return randi_range(lo, hi)
