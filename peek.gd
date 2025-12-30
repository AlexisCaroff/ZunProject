extends Node2D
@export var ennemies: CombatEncounter
@onready var danger_bar:ProgressBar =$ProgressBar
@onready var slots = [
$PortraitSlot1,
$PortraitSlot2,
$PortraitSlot3,
$PortraitSlot4
]
var container
@export var square_size: Vector2 = Vector2(16,16)
@export var square_color: Color = Color(0.8, 0.6, 0.2)
var door : Door
@export_file("*.tscn") var enemy_scene_path: String = "res://scripts/detectable_enemy.tscn"

var enemy_scene: PackedScene
var enemies: Array[DetectableEnemy] = []
@export var enemy_count := 3
@export var detection_width := 40.0

@onready var crosshair: Crosshair = $Crosshair
const seeEffectScene:= preload("res://actions/damageEffect/seeVFX.tscn")

var game_over := false


func set_encounter(encounter: CombatEncounter) -> void:
	preview_encounter(encounter)


func _ready():
	if enemy_scene_path == "":
		push_error("❌ enemy_scene_path est vide")
		return

	enemy_scene = load(enemy_scene_path)
	if enemy_scene == null:
		push_error("❌ Impossible de charger la scène : " + enemy_scene_path)
		
func spawn_enemy(pos: Vector2) -> Node2D:
	if enemy_scene == null:
		push_error("enemy_scene non chargée")
		return null

	var enemy := enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = pos
	enemies.append(enemy)

	return enemy
	

func spawn_enemies(ennemiesData: Array[CharacterData]):
	enemies.clear()

	var min_distance := 150  # distance minimale entre deux ennemis

	for i in ennemiesData.size():
		var pos := Vector2(randf_range(500, 1500), randf_range(600, 700))
		
		# Vérifier si cette position est trop proche d'un ennemi déjà placé
		var tries := 0
		while true:
			var too_close := false
			for e in enemies:
				if pos.distance_to(e.position) < min_distance:
					too_close = true
					break
			if not too_close:
				break  # position correcte
			pos = Vector2(randf_range(500, 1500), randf_range(600, 700))
			tries += 1
			if tries > 20:  # éviter boucle infinie
				break

		# Instancier l'ennemi
		var enemy := spawn_enemy(pos)
		enemy.sprite.texture = ennemiesData[i].portrait_texture
		enemy.enemy_revealed.connect(_on_enemy_revealed)
		enemy.enemy_failed.connect(_on_enemy_failed)

		# Ajuster offset si nécessaire
		enemy.sprite.offset = Vector2.ZERO

		# Ajouter à la liste
		enemies.append(enemy)
		

func _process(delta):
	update_danger_bar()
	if game_over:
		return

	for enemy in enemies:
		if enemy.revealed or enemy.dead:
			continue
	
		var dx = abs(enemy.global_position.x - crosshair.global_position.x)

		if dx <= detection_width:
			enemy.reveal(delta)
func update_danger_bar():
	if enemies.is_empty():
		danger_bar.value = 0
		return

	var total := 0.0
	var active_count := 0

	for enemy in enemies:
		if enemy.dead or enemy.revealed:
			continue
		total += enemy.get_danger_value()
		active_count += 1

	if active_count == 0:
		danger_bar.value = 0
	else:
		danger_bar.value = total / active_count
func _on_enemy_revealed(_enemy):
	seeParticule(_enemy)
	if enemies.all(func(e): return e.revealed):
		win_game()
func _on_enemy_failed(_enemy):
	lose_game()
func win_game():
	game_over = true
	door.win_ambush()
func lose_game():
	game_over = true
	door.get_ambushed()
	print("💀 DÉFAITE — un ennemi est devenu dangereux")
	

func preview_encounter(encounter: CombatEncounter) -> void:
	
	
	
	if encounter == null:
		return
	var ennemiesData : Array[CharacterData]
	# Crée un carré pour chaque élément du tableau
	for i in encounter.enemy_scenes.size():

			
		var enemy: CharacterData = encounter.enemy_scenes[i].instantiate().characterData
		ennemiesData.append(enemy)			
	spawn_enemies(ennemiesData)
			
				

				# Durée aléatoire entre 0.5 et 1 seconde pour l'animation
				

				# Animer la transparence du Sprite de 0 à 1 sur la durée choisie
				

				
				
	#door.check_detection()
func seeParticule(_enemy):
	var effect_instance = seeEffectScene.instantiate()
	_enemy.add_child(effect_instance)
	effect_instance.global_position = _enemy.global_position 
	if effect_instance.has_method("setup"):
		effect_instance.setup(1)
func move_randomly_in_area(node: Node2D): 
	var random_x = randf_range(-550, 550)
	var random_y = randf_range(-300, -100)
	node.position += Vector2(random_x, random_y)
