extends Node2D
class_name DetectableEnemy

@export var reveal_speed := 0.6        # vitesse de révélation (viseur dessus)
@export var danger_speed := 0.1        # vitesse de montée de l'alpha
@export var reveal_threshold := 0.9    # r > 0.8 = visible
@export var move_speed := 5.0         # vitesse du mouvement
@export var move_radius := 100.0       # rayon autour de la position initiale
@export var move_change_interval := 1.5 # temps entre changements de direction (s)


@onready var sprite: Sprite2D = $Sprite2D

var revealed := false
var dead := false

# Pour le mouvement aléatoire
var origin_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var move_timer := 0.0

func _ready():
	sprite.modulate = Color(0, 0, 0, 0)
	origin_pos = position
	_set_new_target()
func get_danger_value() -> float:
	return sprite.modulate.a
func _process(delta):
	if revealed or dead:
		return

	# L'ennemi devient dangereux avec le temps
	sprite.modulate.a += danger_speed * delta
	sprite.modulate.a = clamp(sprite.modulate.a, 0.0, 1.0)

	# Légère variation d'échelle
	var scalaugm = randf_range(0.0, 0.05) * delta
	sprite.scale.x += scalaugm
	sprite.scale.y += scalaugm

	if sprite.modulate.a >= 1.0:
		dead = true
		emit_signal("enemy_failed", self)

	# --- Mouvement aléatoire ---
	move_timer += delta
	if move_timer >= move_change_interval:
		move_timer = 0
		_set_new_target()

	# Déplacement vers target_pos
	position = position.move_toward(target_pos, move_speed * delta)

func _set_new_target():
	# Choisit une position aléatoire dans le rayon autour de origin_pos
	var angle = randf() *TAU * 360
	print(sin(angle))
	var radius = randf() * move_radius
	target_pos = origin_pos + Vector2(cos(angle), angle) * radius

func reveal(delta):
	if revealed or dead:
		return

	var c := sprite.modulate
	c.r += reveal_speed * delta
	c.g += reveal_speed * delta
	c.b += reveal_speed * delta

	sprite.modulate = c

	if sprite.modulate.r >= reveal_threshold:
		revealed = true
		sprite.modulate = Color(1,1,1,1)
		emit_signal("enemy_revealed", self)

signal enemy_revealed(enemy)
signal enemy_failed(enemy)
