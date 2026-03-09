extends Sprite2D
@onready var  combatM:CombatManager =  $"../../CombatManager"
func _input(event):
	if event is InputEventMouseButton and event.pressed and self.visible:

		self.visible=false 
		combatM.pause=false
		
