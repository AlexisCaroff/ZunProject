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
## Porte atteignable depuis la carte : elle donne sur au moins une salle
## déjà découverte. Les portes encore dans le noir ne mènent nulle part,
## sinon un clic dessus permettait de sauter des salles.
func is_reachable() -> bool:
	if gm == null:
		return false
	for room in connectedRooms:
		var r = gm.get_room_by_id(room)
		if r != null and r.explored:
			return true
	return false


func _on_mouse_entered():
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION or GameState.current_phase == GameStat.GamePhase.DOOR:
		if not button.disabled and is_reachable():
			var tween = create_tween()
			tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func _on_mouse_exited():
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION or GameState.current_phase == GameStat.GamePhase.DOOR:
		if not button.disabled:
			var tween = create_tween()
			tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			if get_child(0) != null:
				var obj = get_child(0)
				tween.tween_property(obj, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_down():
	if not is_reachable():
		return
	if GameState.current_phase == GameStat.GamePhase.EXPLORATION or GameState.current_phase == GameStat.GamePhase.DOOR:
		for room in connectedRooms:
			var theroom = gm.get_room_by_id(room)
			if theroom != null and not theroom.explored:
				gm.enter_room( theroom)
		
