extends Node2D

@export var fade_duration: float = 0.4
@export var scale_duration: float = 0.4
@export var child_delay: float = 0.1
@export var target_scale: Vector2 = Vector2(1.3, 1.3)
@export var cam_zoom_target: Vector2 = Vector2(1.5, 1.5)
@export var cam_zoom_duration: float = 0.6

@onready var fade=$"../ColorRect2"
var _current_index: int = -1
var _cam: Camera2D

func _ready() -> void:
	_cam = get_viewport().get_camera_2d()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_show_next_child()

func _show_next_child() -> void:
	var children := get_children()
	if children.is_empty():
		return

	_current_index += 1

	if _current_index >= children.size():
		return

	var next := children[_current_index]
	next.modulate.a = 0.0
	next.visible = true

	var t := create_tween()
	t.tween_property(next, "modulate:a", 1.0, fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var sub_children := next.get_children()
	for i in sub_children.size():
		var sub := sub_children[i]
		sub.modulate.a = 0.0
		sub.visible = true
		var st := create_tween()
		st.tween_interval( child_delay + child_delay * i)
		st.tween_property(sub, "modulate:a", 1.0, fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Dernier enfant : scale + zoom caméra
	if _current_index == children.size() - 1:
		t.tween_property(next, "scale", target_scale, scale_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(next, "scale", target_scale*0.9, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _cam:
			t.parallel().tween_property(_cam, "zoom", cam_zoom_target, cam_zoom_duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.parallel().tween_property(_cam, "position", next.global_position, cam_zoom_duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.parallel().tween_property(fade,"modulate:a",1.0, 1.5)
