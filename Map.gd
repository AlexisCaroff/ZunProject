extends Node2D
class_name Map
@export var positions: Array[Node2D] = [] 
@onready var curentposition : Node2D =$DonjonMap1/Room1
@onready var oldposition :Node2D
@onready var TeamPositisonIndicator = $Position
@export var move_time: float = 1.0   
var tween: Tween
@onready var camera= $Camera2D

func _ready() -> void:
	if oldposition != null:
		TeamPositisonIndicator.position=oldposition.position
	
	for child in $DonjonMap1.get_children():
		positions.append(child)
	# Exemple : aller à la première position si elle existe



func move_to_position(target_node: Node2D) -> void:
	curentposition = target_node
	if tween and tween.is_running():
		tween.kill()  # stoppe le tween en cours si nécessaire

	tween = create_tween()
	tween.tween_property( TeamPositisonIndicator, "position", curentposition.position, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	oldposition = curentposition 
func focus_on_room(room: Node2D, viewport ):
	var vp_size: Vector2 = viewport.size
	var target_pos = room.position
	var tween = create_tween()
	tween.tween_property( camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	print("try to move")
	
