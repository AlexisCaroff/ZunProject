extends Control
class_name AnimaticPlayer

@export var animatic: Animatic

@onready var img_a: TextureRect = $CanvasLayer/Images/ImageA
@onready var img_b: TextureRect = $CanvasLayer/Images/ImageB
@onready var audio_player: AudioStreamPlayer2D = $CanvasLayer/AudioStreamPlayer2D
@onready var subtitle_label: RichTextLabel = $CanvasLayer/SubtitleLabel
@onready var click_area: Button = $CanvasLayer/ClickArea

signal finished

var _current_index: int = 0
var _front: TextureRect
var _back: TextureRect
var _waiting_for_click: bool = false
var _audio_done: bool = false
var _is_transitioning: bool = false

func _ready() -> void:
	_front = img_a
	_back = img_b

	_front.modulate.a = 1.0
	_back.modulate.a = 0.0
	GameState.Pause=true
	click_area.pressed.connect(_on_click)
	audio_player.finished.connect(_on_audio_finished)
	_show_frame(_current_index)

# ---------- Lecture d'une frame ----------

func _show_frame(index: int) -> void:
	if index >= animatic.frames.size():
		_end_animatic()
		return

	var frame: AnimaticFrame = animatic.frames[index]

	_front.texture = frame.texture
	subtitle_label.text = frame.load_subtitle() 

	_audio_done = false
	_waiting_for_click = false

	# Lance l'audio si présent
	if frame.audio:
		audio_player.stream = frame.audio
		audio_player.play()
	else:
		# Pas d'audio : on considère l'audio comme terminé immédiatement
		_on_audio_finished()

# ---------- Avance à la frame suivante ----------

func _advance() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_waiting_for_click = false

	var next_index := _current_index + 1

	# Dernière frame : hold puis fin
	if next_index >= animatic.frames.size():
		await get_tree().create_timer(animatic.final_hold_time).timeout
		_end_animatic()
		return

	# Prépare la frame suivante derrière
	_back.texture = animatic.frames[next_index].texture
	_back.modulate.a = 0.0

	await _cross_fade()
	_swap_images()

	_current_index = next_index
	_is_transitioning = false
	_show_frame(_current_index)

# ---------- Fondu enchaîné ----------
# L'image courante (_front) reste visible.
# La suivante (_back) apparaît progressivement par dessus via fade in.

func _cross_fade() -> void:
	# S'assure que _back est au dessus de _front
	_back.z_index = _front.z_index + 1
	_back.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_back, "modulate:a", 1.0, animatic.fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

func _swap_images() -> void:
	var tmp := _front
	_front = _back
	_back = tmp

# ---------- Callbacks ----------

func _on_audio_finished() -> void:
	_audio_done = true
	subtitle_label.text = ""

	if animatic.auto_advance:
		_advance()
	else:
		# Mode manuel : on attend un clic
		_waiting_for_click = true

func _on_click() -> void:
	if _is_transitioning:
		return

	var frame: AnimaticFrame = animatic.frames[_current_index]

	if not frame.skip_on_click:
		return

	# Coupe l'audio si on saute
	if audio_player.playing:
		audio_player.stop()
		subtitle_label.text = ""

	_advance()

# ---------- Fin ----------

func _end_animatic() -> void:
	GameState.Pause=false
	emit_signal("finished")
	queue_free()
