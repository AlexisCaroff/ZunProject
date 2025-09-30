extends Sprite2D
@onready var camp =$".."
func _ready():
	# S'assurer que le Node capte les événements de souris
	pass

# Fonction qui est appelée lors d'un événement de clic partout dans le jeu
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Action à effectuer lors d'un clic gauche, par exemple, masquer un Sprite2D
			print("Clic détecté sur toute la scène !")
			# Exemple d'action : masquage d'un élément spécifique
			if self.visible:
				self.visible = false  # Masquer l'image love
				camp.After_camp_skill(camp.skillused)
