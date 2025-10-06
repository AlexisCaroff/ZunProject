extends Node
class_name  tente
@export var HunterImages: Array[Texture2D]
@export var PriestImages: Array[Texture2D]
@export var WarriorImages: Array[Texture2D]
@export var MysticImages: Array[Texture2D]
@export var switch_time =0.5
@onready var thetexture:Sprite2D =$"../animMasturbate"
@onready var backgroundCadre =$"../BackgroundinsideTente"
var images:Array[Texture2D]
var current_state: bool = true
var timer

@export var bounce_enabled: bool = false
@export var bounce_height: float = 1.5
@export var bounce_duration: float = 0.5

var tween: Tween = null

var somoneInside : CharaCamp
var Tentescale
func _ready() -> void:
	Tentescale=self.scale.y
func startMasturbation(user:CharaCamp): 
	somoneInside=user
	bounce_enabled=true
	match user.Charaname:
		"Priest":  images = PriestImages
		"Mystic":  images = MysticImages
		"Hunter":  images = HunterImages
		"Warrior": images = WarriorImages
	user.gomasturbate()
	thetexture.texture = images[0]
func _process(_delta):
	if bounce_enabled and tween == null:
		start_bounce()
	elif not bounce_enabled and tween != null:
		tween.kill()
		tween = null
		#self.scale.y = 1.0   # reset (si tu veux le remettre à sa position d'origine)

func start_bounce():
	tween = create_tween()
	tween.set_loops()  # boucle infinie
	tween.tween_property(self, "scale:y", bounce_height, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", Tentescale, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_timer_timeout():
	current_state = !current_state
	thetexture.texture = images[0] if current_state else images[1]
	

func _on_inside_tente_button_button_down() -> void:
	timer.stop
	bounce_enabled=false
	somoneInside.current_horny= max(0, somoneInside.current_horny - 20)
	var CampPosition = somoneInside.campposition
	somoneInside=null
	thetexture.texture=images[2]
	await get_tree().create_timer(1.0).timeout
	CampPosition.visible=true
	$"../BackgroundinsideTente".visible =false
	$"../animMasturbate".visible=false
	


func _on_tente_button_button_down() -> void:
	if somoneInside!= null :
		timer = Timer.new()
		timer.wait_time = switch_time
		timer.autostart = true
		timer.one_shot = false
		add_child(timer)
		timer.timeout.connect(_on_timer_timeout)
		$"../BackgroundinsideTente".visible =true
		$"../animMasturbate".visible=true
