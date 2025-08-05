extends Sprite2D
@onready var  explomanage = $"../ExplorationManager"
var big_size = Vector2(0.7, 0.7)
var startsize = Vector2(0.6,0.6)
var current_tween: Tween = null
@export var amount:int = 30

func _on_button_button_down() -> void:
	
	var target :CharaExplo = explomanage.characters[randi() % explomanage.characters.size()]
	target.current_stamina = min(target.max_stamina, target.current_stamina + amount)
	target.update_display()
	GameState.update_hero_stat(target.Charaname, "stamina", target.current_stamina)


func _on_button_mouse_entered() -> void:
	self .scale = startsize 	
	


	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self , "scale", big_size, 0.2)
	

func _on_button_mouse_exited() -> void:
	self .scale = big_size	
	
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "scale", startsize, 0.2)
