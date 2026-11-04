extends Sprite2D
@onready var button =$HideTuto
@onready var ButtonShowTuto=$"../ShowTuto"
var gm : GameManager
func _ready() -> void:
	button.connect("button_down",hideTuto)
	if ButtonShowTuto != null:
		ButtonShowTuto.connect("button_down",showTuto)
	gm = get_tree().root.get_node("GameManager") as GameManager
	if gm.current_room_Ressource.ennemikilled==true:
		self.visible= false
	call_deferred("_lift_above_hud")
func hideTuto():
	self.visible= false
	GameState.Pause=false
func showTuto():
	self.visible= true

func _process(_delta):
	if self.visible:
		GameState.Pause=true


## Le HUD du GameManager (bouton journal…) vit dans un CanvasLayer (couche
## 11) dessiné par-dessus toute la scène. L'image de tutoriel passe dans sa
## propre couche, juste au-dessus de celle-là (même numéro, rangée après),
## et sous le fondu de SceneTransition (couche 12). La couche est libérée
## avec la scène d'origine.
func _lift_above_hud() -> void:
	var gm_node := get_tree().root.get_node_or_null("GameManager")
	var origin := get_parent()
	if gm_node == null or origin == null:
		return
	var save_layer := gm_node.get_node_or_null("SaveLayer") as CanvasLayer
	var layer := CanvasLayer.new()
	layer.name = "TutoLayer"
	layer.layer = save_layer.layer if save_layer != null else 11
	gm_node.add_child(layer)
	if save_layer != null:
		gm_node.move_child(layer, save_layer.get_index() + 1)
	# Position et échelle à l'écran conservées (caméra et parents compris).
	var screen_xform := get_global_transform_with_canvas()
	reparent(layer, false)
	transform = screen_xform
	origin.tree_exiting.connect(layer.queue_free)
