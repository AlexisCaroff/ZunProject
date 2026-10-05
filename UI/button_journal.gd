extends Button
class_name ButtonJournal

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color(0.74,0.6,0.48)

## Conteneur des boutons qui glissent depuis le journal (Save, Quit).
@onready var slide_panel: Control = $VBoxContainer

@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var centered : bool = true

## Position repliée (hors écran, à gauche) et dépliée du panneau.
@export var hidden_position: Vector2 = Vector2(-160, 113)
@export var shown_position: Vector2 = Vector2(0, 113)

var gm: GameManager
var _hide_timer: SceneTreeTimer = null

func _ready():
	gm = get_tree().root.get_node_or_null("GameManager") as GameManager
	if centered:
		pivot_offset = size / 2
	self_modulate = normal_color
	scale = normal_scale
	if disabled:
		modulate.a = 0.0

	slide_panel.position = hidden_position

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	# Chaque bouton du panneau garde celui-ci ouvert tant qu'il est survolé,
	# sinon le panneau se replierait dès que la souris quitte le journal.
	for child in slide_panel.get_children():
		if child is Control:
			child.mouse_entered.connect(_on_child_mouse_entered)
			child.mouse_exited.connect(_on_child_mouse_exited)


func _process(_delta: float) -> void:
	# Le journal vit sur SaveLayer (au-dessus de toutes les UI de jeu) : il doit
	# donc se masquer explicitement sur le menu principal, qui a son propre Quit.
	var should_show: bool = gm != null and gm.game_started
	if visible == should_show:
		return
	visible = should_show
	if not should_show:
		_cancel_hide()
		scale = normal_scale
		slide_panel.position = hidden_position


func _on_mouse_entered():
	if disabled:
		return
	_cancel_hide()
	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(slide_panel, "position", shown_position, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if disabled:
		return
	_schedule_hide()

func _on_child_mouse_entered():
	_cancel_hide()

func _on_child_mouse_exited():
	_schedule_hide()

func _schedule_hide():
	_hide_timer = get_tree().create_timer(0.15)
	_hide_timer.timeout.connect(_do_hide)

func _cancel_hide():
	_hide_timer = null

func _do_hide():
	if _hide_timer == null:
		return
	_hide_timer = null
	var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(slide_panel, "position", hidden_position, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
