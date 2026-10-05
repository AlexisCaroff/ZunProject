extends Node2D
class_name SexScene

@onready var sprite = $HunterxWarrior
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var anon_dialogue = $AnonDialogue

var base_scale: Vector2

## Dialogue avec noms et portraits (DialogueManager standard)
@export var dialogue_path: String      = "res://dialogue/love/HunterWarrior.txt"
## Dialogue sans noms (AnonDialogue) — joué après le premier
@export var anon_dialogue_path: String = "res://dialogue/love/HunterWarrior_anon.txt"
@onready var skipButton : Button =$AnonDialogue/SkipButton

func _ready() -> void:
	
	
	
	for child in get_children():
		if child is Button:
			var empty := StyleBoxEmpty.new()
			child.add_theme_stylebox_override("focus", empty)
			child.add_theme_stylebox_override("focus_visible", empty)

	
	skipButton.connect("button_down", _on_skip_pressed)
	anon_dialogue.dialogue_finished.connect(_on_dialogue_finished)
	_on_phase1_finished()

func _on_phase1_finished() -> void:
	# Enchaîne immédiatement sur la phase 2
	anon_dialogue.load_dialogue(anon_dialogue_path)

	anon_dialogue.start_dialogue()
	sprite.visible=true

func _on_skip_pressed() -> void:
	# Force la fin du dialogue sans passer par les étapes intermédiaires
	print ("skip pressed")
	anon_dialogue.visible = false
	_on_dialogue_finished()
	
var _finished := false
func _on_dialogue_finished() -> void:
	if _finished:
		return
	_finished = true
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	var tente_node = _find_tente_parent()
	anon_dialogue.visible = false
	await gm.sceneTransition.fade_out(0.5)
	self.visible = false
	if tente_node:
		tente_node.loved_one_go_out()
	await gm.sceneTransition.fade_in(0.5)
	self.queue_free()

func _find_tente_parent() -> Node:
	var node = get_parent()
	while node != null:
		if node is tente:
			return node
		for child in node.get_children():
			if child is tente:
				return child
		node = node.get_parent()
	return null
