extends Sprite2D
class_name ExploPortrait
var occupant : CharaExplo
@onready var button= $Button
@onready var explorationManager = $"../../ExplorationManager"

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color(0.74,0.6,0.48)

# échelle configurables
@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
const SELECTOR_TEX = preload("res://UI/selectorCombatChara.png")
var selectorChara : Sprite2D

func _ready():

	# couleur de départ
	self_modulate = normal_color
	scale = normal_scale
	button.button_down.connect(clicOnPorttrait)
	button.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
	
func set_occupant(Chara:CharaExplo):
	occupant=Chara
	self.texture= Chara.characterData.explorationPortrait
	occupant.exploPortrait = self
	
func clicOnPorttrait():
	explorationManager.selectCharacter(occupant)
	explorationManager.portrait_selector.position=self.position



func _on_mouse_entered():
	
		var tween = create_tween()
		tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func _on_mouse_exited():
	
		var tween = create_tween()
		tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	
