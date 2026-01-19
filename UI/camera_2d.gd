extends Camera2D
class_name Camera
var shake_strength := 0.0
var shake_duration := 0.0
var shake_time := 0.0
var frequency := 25.0
var noise := FastNoiseLite.new()

var original_offset := Vector2.ZERO
var baseZoom : Vector2
var base_position : Vector2
@export var screen := Rect2(Vector2.ZERO, Vector2(1920, 1080))
func _ready():
	base_position  = self.position
	screen =get_viewport_rect()
	var screen_size = get_viewport_rect().size
	var base_size = Vector2(1920, 1080)  # résolution de base
	var zoom_factor = screen_size / base_size
	self.zoom = Vector2( zoom_factor.x,  zoom_factor.y)
	baseZoom = self.zoom
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
func zoom_to_position(	target_pos: Vector2,target_zoom: float, duration := 0.5):
	#update_camera_limits(Vector2(target_zoom, target_zoom))
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(self,"position",target_pos,	duration)

	tween.parallel().tween_property(self,"zoom",Vector2(target_zoom, target_zoom),duration)
	await tween.finished
	

func reset(time:float = 0.0):
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	print ("reset camera")
	tween.parallel().tween_property(self,"position",base_position,	time)
	tween.parallel().tween_property(self,"zoom",baseZoom,time)
	
func _get_view_size(zoom : Vector2 = self.zoom) -> Vector2:
	var viewport_size := get_viewport_rect().size
	return viewport_size / zoom
	
	
func update_camera_limits(zoom : Vector2 = self.zoom):
	var half_view := _get_view_size(zoom) * 0.5
	print (str(half_view))
	self.limit_left   = screen.position.x + half_view.x
	self.limit_top    = screen.position.y + half_view.y
	self.limit_right  = screen.position.x + screen.size.x - half_view.x
	self.limit_bottom = screen.position.y + screen.size.y - half_view.y
	print (str(limit_left) +" "+ str(limit_top) )
	print (str(limit_right) +" "+ str(limit_bottom) )
