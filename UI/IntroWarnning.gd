extends TextureRect
## Carton d'avertissement du lancement. Un clic ouvre le menu principal ;
## l'introduction du narrateur se joue après « Start » (cf.
## GameManager._play_intro_cinematic).
@onready var cine = get_node_or_null("../Cinematic")
@onready var gm: GameManager = $"../.."

func _ready() -> void:
	# Le défilement attend « Start » : masqué d'ici là, sinon son image
	# resterait affichée par-dessus le menu.
	if cine != null:
		cine.visible = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and self.visible:
		self.visible = false
		gm.spawn_start_menu()
