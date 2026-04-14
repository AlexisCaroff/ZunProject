extends Button
class_name ButtonJournal

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color(0.74,0.6,0.48)
@onready var buttonQuit = $ButtonQuit

@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var centered : bool = true

var _hide_timer: SceneTreeTimer = null

func _ready():
	if centered:
		pivot_offset = size / 2
	self_modulate = normal_color
	scale = normal_scale
	if disabled:
		modulate.a = 0.0

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	# ButtonQuit prévient ce script quand la souris entre/sort
	buttonQuit.connect("mouse_entered", Callable(self, "_on_child_mouse_entered"))
	buttonQuit.connect("mouse_exited", Callable(self, "_on_child_mouse_exited"))

func _on_mouse_entered():
	if disabled:
		return
	_cancel_hide()
	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttonQuit, "position", Vector2(0, 113), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if disabled:
		return
	_schedule_hide()

func _on_child_mouse_entered():
	_cancel_hide()

func _on_child_mouse_exited():
	_schedule_hide()

func _schedule_hide():
	_hide_timer = get_tree().create_timer(0.15)
	_hide_timer.timeout.connect(_do_hide)

func _cancel_hide():
	_hide_timer = null

func _do_hide():
	if _hide_timer == null:
		return
	_hide_timer = null
	var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttonQuit, "position", Vector2(-160, 113), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
