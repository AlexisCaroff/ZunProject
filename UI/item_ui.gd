extends Control
class_name ItemUi
@onready var imageContainer = $boxUI/imageObj
@onready var label=$boxUI/Labelname
@export var image = null

func _ready() -> void:
	if image != null:
		imageContainer.texture = image

# Méthode pour définir l'image et le texte de l'objet
func setObject(theimage: Texture, text: String):
	imageContainer = $boxUI/imageObj
	label=$boxUI/Labelname
	image = theimage
	imageContainer.texture = image
	label.text = text
