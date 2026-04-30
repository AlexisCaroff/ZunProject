extends Control
class_name AnonDialogue

signal dialogue_finished

@export var fade_duration: float = 0.3

@onready var text_label: RichTextLabel = $RichTextLabel
@onready var bg: ColorRect             = $Background
@onready var click_hint: Label         = $ClickHint
@onready var arrow =$Arrow
@onready var skip_button: Button =$SkipButton

var _lines: Array[String] = []
var _index: int = 0
var _started: bool = false
var _ending: bool = false
var arrowscale

func _ready() -> void:
	visible = false
	arrowscale=arrow.scale
	if skip_button:
		skip_button.connect("button_down",_on_skip_pressed)
		skip_button.visible = false

		
func _is_mouse_over_skip() -> bool:
	var mouse := get_global_mouse_position()
	var rect := skip_button.get_global_rect()
	return rect.has_point(mouse)
func over_skip():
	
	var tween = create_tween()
	tween.tween_property(arrow, "scale", arrowscale*1.1, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func out_over_skip():
	var tween = create_tween()
	tween.tween_property(arrow, "scale",arrowscale , 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
		
		
func load_dialogue(file_path: String) -> void:
	_lines.clear()
	_index = 0
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("AnonDialogue : impossible de lire " + file_path)
		return
	while not file.eof_reached():
		var raw := file.get_line().strip_edges()
		if raw == "":
			continue
		# Retire le préfixe "Speaker : " si présent (ex: "Narrator : ...")
		var colon := raw.find(":")
		if colon != -1:
			raw = raw.substr(colon + 1).strip_edges()
		_lines.append(raw)
	file.close()


func start_dialogue() -> void:
	if _lines.is_empty():
		emit_signal("dialogue_finished")
		return
	_index = 0
	_started = true
	visible = true
	if skip_button:
		skip_button.visible = true
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, fade_duration)
	await t.finished
	_show_line()


func _show_line() -> void:
	if _index >= _lines.size():
		_end()
		return
	text_label.text = _lines[_index]


func _end() -> void:
	_started = false
	_ending = true
	if skip_button:
		skip_button.visible = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, fade_duration)
	await t.finished
	visible = false
	_ending = false
	emit_signal("dialogue_finished")


func _on_skip_pressed() -> void:
	if not _started or _ending:
		return
	print ("skip")
	_index = _lines.size()
	_show_line()


func _input(event: InputEvent) -> void:
	if not _started:
		return
	if not event.is_pressed():
		return
	if _ending:
		return

	var advance := false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# ✅ Vérifie si la souris survole le bouton via le signal déjà connecté
		# au lieu de get_global_rect() qui peut être décalé par Arrow
		if skip_button and skip_button.visible and _is_mouse_over_skip():
			return
		advance = true
	elif event is InputEventKey and event.keycode == KEY_SPACE:
		advance = true
	elif event is InputEventKey and event.keycode == KEY_X:
		_index = _lines.size()
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		_index += 1
		_show_line()
