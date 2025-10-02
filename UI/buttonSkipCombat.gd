extends Button
@onready var cm =$"../CombatManager"

func _on_button_down() -> void:
	cm._show_victory()
