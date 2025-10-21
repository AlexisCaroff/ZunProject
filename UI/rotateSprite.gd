extends Sprite2D
@export var vitesse = 2.0
@export var scale_amplitude: float = 0.3  
@export var scale_speed: float = 2.0         #
@export var base_scale: Vector2 = Vector2.ONE  
var time: float = 0.0



func _process(delta: float) -> void:
	
	rotation += vitesse * delta   
	time += delta
	var scale_factor = 1.0 + sin(time * scale_speed) * scale_amplitude
	scale = base_scale * scale_factor
