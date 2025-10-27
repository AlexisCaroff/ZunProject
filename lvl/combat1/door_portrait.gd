extends Sprite2D
var occupant : CharaExplo
@onready var button= $Button
@onready var Doormanager = $"../../Door"
@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)

func _ready():
	
	button.button_down.connect(clicOnPorttrait)
	button.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():

		var tween = create_tween()
		tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
func _on_mouse_exited():

		var tween = create_tween()
		tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		

func set_occupant(Chara:CharaExplo):
	occupant=Chara
	self.texture= Chara.explorationPortrait
	
func clicOnPorttrait():
	Doormanager.selectCharacter(occupant)
	Doormanager.portrait_selector.position=self.position

	
