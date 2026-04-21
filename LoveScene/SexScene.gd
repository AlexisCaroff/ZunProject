extends Node2D
class_name SexScene

@onready var sprite = $HunterxWarrior
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var anon_dialogue = $AnonDialogue
@onready var background = $background
var base_scale: Vector2

## Dialogue avec noms et portraits (DialogueManager standard)
@export var dialogue_path: String      = "res://dialogue/love/HunterWarrior.txt"
## Dialogue sans noms (AnonDialogue) — joué après le premier
@export var anon_dialogue_path: String = "res://dialogue/love/HunterWarrior_anon.txt"


func _ready() -> void:
	base_scale = scale
	scale = scale * 0.8
	modulate.a = 0.0
	sprite.visible=false
	for child in get_children():
		if child is Button:
			var empty := StyleBoxEmpty.new()
			child.add_theme_stylebox_override("focus", empty)
			child.add_theme_stylebox_override("focus_visible", empty)

	# Phase 1 terminée → lancer phase 2
	dialogue_manager.dialogue_finished.connect(_on_phase1_finished)
	# Phase 2 terminée → fermer la scène
	anon_dialogue.dialogue_finished.connect(_on_dialogue_finished)

	# Animation d'intro
	var tween := create_tween()
	tween.parallel().tween_property(self, "scale", base_scale, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)

	await tween.finished

	# Lance la phase 1
	dialogue_manager.load_dialogue(dialogue_path)
	dialogue_manager.start_dialogue()


func _on_phase1_finished() -> void:
	# Enchaîne immédiatement sur la phase 2
	anon_dialogue.load_dialogue(anon_dialogue_path)
	background.visible =false
	anon_dialogue.start_dialogue()
	sprite.visible=true

func _on_dialogue_finished() -> void:
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	var tente_node = _find_tente_parent()
	anon_dialogue.visible=false
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
