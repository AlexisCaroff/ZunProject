extends Resource
class_name LootTable

# ════════════════════════════════════════════════════════════════════
#  TABLE DE BUTIN ALÉATOIRE
# ════════════════════════════════════════════════════════════════════
#  Une seule table globale, référencée par le GameManager, sert à la fois
#  aux récompenses de fin de combat et aux coffres. Chaque source peut
#  moduler le résultat avec son propre nombre de tirages / sa propre
#  chance (voir roll()).
#
#  Usage :
#      var butin := gm.loot_table.roll()             # règles de la table
#      var butin := gm.loot_table.roll(2, 1.0)       # 2 tirages garantis
# ════════════════════════════════════════════════════════════════════

@export var entries: Array[LootEntry] = []

## Probabilité qu'un tirage donne quelque chose (0 = jamais, 1 = toujours).
@export_range(0.0, 1.0, 0.05) var drop_chance: float = 0.5

## Nombre de tirages tentés par défaut.
@export var rolls: int = 1

## Interdit de tirer deux fois la même ligne dans un même butin.
@export var unique_per_roll: bool = false


## Tire le butin. `roll_count` et `chance` à -1 reprennent les valeurs de
## la table. Le tableau retourné contient des COPIES prêtes à partir en
## inventaire : les .tres d'origine ne sont jamais mutés.
func roll(roll_count: int = -1, chance: float = -1.0, depth: int = 0) -> Array[Equipment]:
	var result: Array[Equipment] = []
	if entries.is_empty():
		return result

	var n: int = rolls if roll_count < 0 else roll_count
	var p: float = drop_chance if chance < 0.0 else chance
	var used: Array[LootEntry] = []

	for i in n:
		if randf() > p:
			continue
		var entry := _pick_entry(used, depth)
		if entry == null:
			continue
		if unique_per_roll:
			used.append(entry)
		var made := _instantiate(entry)
		if made != null:
			result.append(made)

	return result


func _pick_entry(excluded: Array[LootEntry], depth: int) -> LootEntry:
	var pool: Array[LootEntry] = []
	var total: float = 0.0
	for e in entries:
		if e == null or e.item == null:
			continue
		if e.weight <= 0.0:
			continue
		if e.min_depth > depth:
			continue
		if excluded.has(e):
			continue
		pool.append(e)
		total += e.weight

	if pool.is_empty() or total <= 0.0:
		return null

	var pick: float = randf() * total
	for e in pool:
		pick -= e.weight
		if pick <= 0.0:
			return e
	return pool[pool.size() - 1]


## Une potion devient une pile indépendante ; les autres équipements
## restent référencés par leur .tres (identité attendue par InventoryUI).
func _instantiate(entry: LootEntry) -> Equipment:
	var count := entry.roll_count()
	if entry.item is Potion:
		return Potion.make(entry.item as Potion, count)
	return entry.item
