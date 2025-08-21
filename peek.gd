extends Node2D
@export var ennemies: CombatEncounter

@onready var slots = [
$PortraitSlot1,
$PortraitSlot2,
$PortraitSlot3,
$PortraitSlot4
]

func set_encounter(encounter: CombatEncounter) -> void:
	preview_encounter(encounter)

func preview_encounter(encounter: CombatEncounter) -> void:
	for i in range(slots.size()):
		if i < encounter.enemy_scenes.size():
			var enemy: Character = encounter.enemy_scenes[i].instantiate()
			
			if enemy.portrait_texture:
				var sprite = Sprite2D.new()
				sprite.texture = enemy.portrait_texture
				slots[i].add_child(sprite)
				print("show ennemy"+ enemy.Charaname)
				enemy.queue_free()
