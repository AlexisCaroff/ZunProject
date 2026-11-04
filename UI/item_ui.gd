extends Control
class_name ItemUi
@onready var imageContainer = $boxUI/imageObj
@onready var label=$boxUI/Labelname
@export var image = null
@onready var boxUi = $boxUI
@export var animation_duration: float = 0.4
@export var despawn: bool = false
## Avec despawn : la carte part seule vers le sac après ce délai (0 = au clic
## seulement). Réglé par les objets interactifs ; l'écran de victoire garde 0.
@export var auto_despawn_delay: float = 0.0
signal animation_finished
## La carte a fini de partir vers le sac (et va être libérée).
signal despawned
var _leaving: bool = false
## Point (global) vers lequel la carte s'envole en partant : l'icône du sac
## dans le HUD. INF = ancien comportement (décalage fixe vers la droite).
var fly_target: Vector2 = Vector2.INF
const GLOW_TEX := preload("res://UI/symbols/FX_title_glow.png")

func _ready() -> void:
	if image != null:
		imageContainer.texture = image
	boxUi.pivot_offset = boxUi.size / 2
	boxUi.scale = Vector2(0, 0)
	
	
	# Tween pour le zoom-in avec rebond
	var tween = create_tween()
	tween.tween_property(boxUi, "scale", Vector2(1, 1), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		emit_signal("animation_finished")
		if despawn and auto_despawn_delay > 0.0:
			get_tree().create_timer(auto_despawn_delay).timeout.connect(on_left_click)
	)
func _input(event):
	if event is InputEventMouseButton && despawn:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_left_click()
			
func on_left_click():
	if _leaving or not is_inside_tree():
		return
	_leaving = true
	var tween = create_tween()
	tween.parallel().tween_property(boxUi, "scale", Vector2(0, 0), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if fly_target != Vector2.INF:
		# Le centre de la carte rejoint l'icône du sac.
		var dest: Vector2 = fly_target - (boxUi.position + boxUi.size * 0.5)
		tween.parallel().tween_property(self, "global_position", dest, animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		tween.parallel().tween_property(self, "position", position+Vector2(700,300), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():emit_signal("animation_finished"))
	await tween.finished
	emit_signal("despawned")
	queue_free()


## Halo additif derrière la carte, qui respire doucement.
func show_glow(size_px: float = 260.0) -> void:
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = GLOW_TEX
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)
	move_child(glow, 0)   # derrière la carte
	var center: Vector2 = boxUi.position + boxUi.size * 0.5
	glow.size = Vector2(size_px, size_px)
	glow.position = center - glow.size * 0.5
	glow.pivot_offset = glow.size * 0.5
	glow.modulate.a = 0.0
	var t := glow.create_tween()
	t.tween_property(glow, "modulate:a", 1.0, 0.3)
	t.tween_callback(func():
		var loop := glow.create_tween().set_loops()
		loop.tween_property(glow, "modulate:a", 0.55, 0.8).set_trans(Tween.TRANS_SINE)
		loop.tween_property(glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE))

func setObject(theimage: Texture, text: String):
	imageContainer = $boxUI/imageObj
	label=$boxUI/Labelname
	image = theimage
	imageContainer.texture = image
	label.text = text
