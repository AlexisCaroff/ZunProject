extends Button
@onready var pose1        = $"../pose1"
@onready var doorbutton   = $"../Door"
@onready var peekScene    = $"../SubViewportContainer"
@onready var sub_viewport = $"../SubViewportContainer/SubViewport"


func _on_button_down() -> void:
	self.visible            = false
	doorbutton.position     = pose1.position
	peekScene.visible       = false
	doorbutton.peeking      = false
	# Le personnage regagne sa place dans la formation.
	doorbutton.on_peek_exit()

	# Met en pause toute la scène du SubViewport
	sub_viewport.process_mode = Node.PROCESS_MODE_DISABLED
