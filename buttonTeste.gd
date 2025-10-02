extends Button

@export_file("*.tscn") var target_scene : String

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	else:
		push_warning("Aucun chemin de scène défini pour " + str(self))
