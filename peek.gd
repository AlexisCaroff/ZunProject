extends Node2D
@export var ennemies: CombatEncounter

@onready var slots = [
$PortraitSlot1,
$PortraitSlot2,
$PortraitSlot3,
$PortraitSlot4
]
var door : Door

func set_encounter(encounter: CombatEncounter) -> void:
	preview_encounter(encounter)


func preview_encounter(encounter: CombatEncounter) -> void:
	for i in range(slots.size()):
		if i < encounter.enemy_scenes.size():
			var enemy: Character = encounter.enemy_scenes[i].instantiate()
			
			if enemy.portrait_texture:
				# Créer un conteneur Node2D pour le Sprite et le Tween
				var container = Node2D.new()
				slots[i].add_child(container)

				# Créer un Sprite2D pour l'ennemi
				var sprite = Sprite2D.new()
				sprite.texture = enemy.portrait_texture
				sprite.modulate.a = 0  # Commencer avec une alpha à 0 (transparent)
				container.add_child(sprite)  # Ajouter le Sprite à son parent (container)

				# Créer un Tween en utilisant create_tween()
				var fade_in_tween = container.create_tween()  # Création correcte du Tween en Godot 4.5

				# Durée aléatoire entre 0.5 et 1 seconde pour l'animation
				var fade_duration = randf_range(1.0, 1.5)

				# Animer la transparence du Sprite de 0 à 1 sur la durée choisie
				fade_in_tween.tween_property(sprite, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(fade_duration) 

				# Attendre la fin de l'animation avant de passer à l'itération suivante
				await fade_in_tween.finished
	door.check_detection()
