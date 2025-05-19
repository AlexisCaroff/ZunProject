extends Node2D
class_name Spawner

var characters: Array = []  # <<--- Ici on stocke tous les persos

func _ready():
	var hero1 = preload("res://characters/croise.tscn").instantiate()
	add_child(hero1)
	hero1.position = Vector2(100, 860)
	characters.append(hero1)
	print("Croisé spawned")
	
	var hero2 = preload("res://characters/priest.tscn").instantiate()
	add_child(hero2)
	hero2.position = Vector2(400, 860)
	characters.append(hero2)
	print("priest spawned")
	
	
	var enemy1 = preload("res://characters/cultiste.tscn").instantiate()
	enemy1.character_name = "Cultiste"
	enemy1.is_ally = false
	enemy1.initiative = 4
	add_child(enemy1)
	enemy1.position = Vector2(1000, 860)
	characters.append(enemy1)  # <<--- On ajoute aussi
	print("Cultist spawned")

	$combatManager.StartBattle(characters)  # <<--- On donne la liste au combatManager
func screen_shake(intensity: float = 5.0, duration: float = 0.3) -> void:
	var original_position = position
	var tween = create_tween()

	var steps = int(duration / 0.05)
	for i in steps:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(self, "position", original_position + offset, 0.025)
		tween.tween_property(self, "position", original_position, 0.025)
