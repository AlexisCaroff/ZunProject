extends Sprite2D
class_name MapDoor
@export var connectedRooms : Array[String]
@export var locked: bool = false
@export var destroyed: bool = false
@onready var button: Button = $Button

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

# échelle configurables
@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(2.0, 2.0)
var gm : GameManager

func _ready():
	gm = get_tree().root.get_node("GameManager") as GameManager
	scale = normal_scale
	if button.disabled:
		modulate.a = 0.0
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("focus_visible", empty)
	# connecter les signaux de souris
	button.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	button.connect("button_down", Callable(self, "_on_button_down"))
func _on_mouse_entered():
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION:
		if not button.disabled:
			var tween = create_tween()
			tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func _on_mouse_exited():
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION:
		if not button.disabled:
			var tween = create_tween()
			tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			if get_child(0) != null:
				var obj = get_child(0)
				tween.tween_property(obj, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_down():
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION:
		for room in connectedRooms:
			var theroom = gm.get_room_by_id(room)
			if not theroom.explored:
				gm.enter_room( theroom)
		
