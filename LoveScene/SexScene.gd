extends Node2D

@onready var sprite = $HunterxWarrior  # ← à adapter par scène
@onready var dialogue_manager: DialogueManager = $DialogueManager

var base_scale: Vector2

# ⬇️ À configurer dans chaque scène via @export ou directement ici
@export var dialogue_path: String = "res://dialogue/love/HunterWarrior.txt"


func _ready() -> void:
	base_scale = sprite.scale
	sprite.scale = sprite.scale * 0.8
	modulate.a = 0.0

	# Supprime le focus visible sur tous les boutons enfants
	for child in get_children():
		if child is Button:
			var empty := StyleBoxEmpty.new()
			child.add_theme_stylebox_override("focus", empty)
			child.add_theme_stylebox_override("focus_visible", empty)

	# Connecte la fin du dialogue → fermeture de la scène
	dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)

	# 1️⃣ Animation d'intro : apparition + zoom
	var tween := create_tween()
	tween.parallel().tween_property(sprite, "scale", base_scale, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)

	# 2️⃣ Après l'intro : charge et lance le dialogue
	await tween.finished
	dialogue_manager.load_dialogue(dialogue_path)
	dialogue_manager.start_dialogue()


func _on_dialogue_finished():
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager

	# Récupère la tente parente pour appeler loved_one_go_out()
	# La love scene est enfant du Campement, lui-même parent des tentes
	var tente_node = _find_tente_parent()

	await gm.sceneTransition.fade_out(0.5)
	self.visible = false

	if tente_node:
		tente_node.loved_one_go_out()

	await gm.sceneTransition.fade_in(0.5)
	self.queue_free()


func _find_tente_parent() -> Node:
	# Remonte l'arbre pour trouver un node de classe "tente"
	var node = get_parent()
	while node != null:
		if node is tente:
			return node
		# Cherche aussi parmi les enfants directs du parent (la tente est sibling)
		for child in node.get_children():
			if child is tente:
				return child
		node = node.get_parent()
	return null
