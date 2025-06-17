extends Camera2D

var shake_strength := 0.0
var shake_duration := 0.0
var shake_time := 0.0
var frequency := 25.0
var noise := FastNoiseLite.new()

var original_offset := Vector2.ZERO

func _ready():
	
	var screen_size = get_viewport_rect().size
	var base_size = Vector2(1920, 1080)  # résolution de base
	var zoom_factor = screen_size / base_size
	self.zoom = Vector2( zoom_factor.x,  zoom_factor.y)
	original_offset = offset
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 5.0

func shake(strength: float = 5.0, duration: float = 0.3):
	shake_strength = strength
	shake_duration = duration
	shake_time = 0.0

func _process(delta: float) -> void:
	if shake_time < shake_duration:
		shake_time += delta
		var progress := shake_time / shake_duration
		var decay := pow(1.0 - progress, 2) # Évite un arrêt trop brutal

		var time = Time.get_ticks_msec() / 1000.0 * frequency
		var x_offset = noise.get_noise_2d(time, 0.0)
		var y_offset = noise.get_noise_2d(0.0, time + 100.0) # évite la symétrie

		offset = original_offset + Vector2(x_offset, y_offset) * shake_strength * decay
	else:
		offset = original_offset
