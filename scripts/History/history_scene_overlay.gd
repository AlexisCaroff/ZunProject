extends Control
class_name HistorySceneOverlay

@export var history_scene: HistoryScene

@onready var background: Sprite2D = $CanvasLayer/Background
@onready var dialogue_manager: DialogueManager =$CanvasLayer/DialogueManager
@onready var close_button: Button = $CanvasLayer/CloseButton
signal history_finished


func _ready():
	close_button.pressed.connect(close)

	if history_scene:
		setup_from_resource(history_scene)


func setup_from_resource(data: HistoryScene):
	# Background
	
	background.texture = data.illustration
	if data.fill_width and data.illustration != null:
		_fill_width(data.illustration)
	if data.show_scene_behind:
		background.visible = false
		var black := get_node_or_null("CanvasLayer/ColorRect") as CanvasItem
		if black != null:
			black.visible = false
	if dialogue_manager==null:
		dialogue_manager = $DialogueManager
	# Dialogue
	#dialogue_manager.participants = data.participants
	dialogue_manager.is_Choice = data.is_choice
	if data.choice_1_text:
		dialogue_manager.text_choice1 = data.choice_1_text
	if data.choice_2_text:
		dialogue_manager.text_choice2 = data.choice_2_text

	dialogue_manager.load_dialogue(data.dialogue_file)

	
	dialogue_manager.start_dialogue()

	dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)
	
	dialogue_manager.dialogue_finished.connect(_on_no_choice)
	dialogue_manager.dialogue_choice_requested.connect(_on_choice_requested)
	dialogue_manager.choice_made.connect(_on_choice_made)

	dialogue_manager.start_dialogue()

## Largeur de l'écran, proportions gardées, bord haut à 0. Le ColorRect noir
## de la scène, derrière, remplit la bande vide sous l'image.
func _fill_width(tex: Texture2D) -> void:
	var view_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	var k: float = view_w / float(tex.get_width())
	background.centered = true
	background.scale = Vector2(k, k)
	background.position = Vector2(view_w * 0.5, tex.get_height() * k * 0.5)


func _on_dialogue_finished():
	if not dialogue_manager.is_Choice:
		close()
func _on_choice_requested():
	# L’overlay reste ouvert
	pass
	
func _on_choice_made(choice_index: int):
# ajouter fonction ici
	print("Choix sélectionné :", choice_index)

	close()
func _on_no_choice():
	close()
func close():
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	await gm.sceneTransition.fade_out(0.5)
	await get_tree().create_timer(0.2).timeout
	gm.sceneTransition.fade_in(0.5)
	emit_signal("history_finished")
	queue_free()
