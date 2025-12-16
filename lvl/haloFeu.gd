extends TextureRect
@export var min_alpha := 0.4
@export var max_alpha := 0.8
@export var speed := 1.5

var noise := FastNoiseLite.new()
var time := 0.0
var scale_base := Vector2.ONE
var scale_amp := 0.05

func _ready():
	
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.8

func _process(delta):
	time += delta * speed
	var n := noise.get_noise_1d(time) # -1 → 1
	var t := (n + 1.0) * 0.5          # 0 → 1
	modulate.a = lerp(min_alpha, max_alpha, t)
	scale = scale_base * (1.0 + t * scale_amp)
