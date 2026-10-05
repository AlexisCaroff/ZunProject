extends Button
class_name ButtonSave
# Bouton de sauvegarde manuelle, rangé dans le panneau coulissant de
# ButtonJournal (game_manager.tscn) aux côtés de Quit. Le panneau vit sur un
# CanvasLayer haut placé pour rester cliquable par-dessus les UI de combat et
# d'exploration ; c'est ButtonJournal qui gère son affichage d'ensemble.

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color(0.83, 0.17, 0.5, 1)
@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.15, 1.15)

var gm: GameManager


func _ready() -> void:
	gm = get_tree().root.get_node_or_null("GameManager") as GameManager
	self_modulate = normal_color
	scale = normal_scale
	# Dans un VBoxContainer la taille n'est pas connue à _ready : on recentre le
	# pivot à chaque redimensionnement, sinon le survol grossit depuis le coin.
	resized.connect(_recenter_pivot)
	_recenter_pivot()

	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("focus_visible", empty)

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _recenter_pivot() -> void:
	pivot_offset = size / 2


func _on_pressed() -> void:
	if gm:
		gm.open_save_menu()


func _on_mouse_entered() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", hover_color, 0.15)


func _on_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", normal_color, 0.2)
