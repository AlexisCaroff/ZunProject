extends Node
class_name  tente
@export var HunterImages: Array[Texture2D]
@export var PriestImages: Array[Texture2D]
@export var WarriorImages: Array[Texture2D]
@export var MysticImages: Array[Texture2D]
@export var switch_time =0.5
@onready var thetexture:Sprite2D =$"../animMasturbate"
@onready var backgroundCadre =$"../BackgroundinsideTente"
@onready var tenteback = $"../TenteBack"
var images:Array[Texture2D]
var current_state: bool = true
var timer

@export var bounce_enabled: bool = false
@export var bounce_height: float = 1.5
@export var bounce_duration: float = 0.5
var back_tween :Tween = null
var tween: Tween = null

var somoneInside : CharaCamp
var twoInside : Array[CharaCamp]
var Tentescale
@onready var love_sprite: Sprite2D = $"../LoveImage"

@export var love_images := {
	"Priest+Mystic": preload("res://LoveScene/LoveSceneimage/PriestMystic.png"),
	"Mystic+Hunter": preload("res://LoveScene/LoveSceneimage/MysticHunter.png"),
	"Priest+Warrior": preload("res://LoveScene/LoveSceneimage/PriestWarriorAnim.png"), # animée
	"Hunter+Warrior": preload("res://LoveScene/LoveSceneimage/HunterWarrior.png"),
	"Mystic+Warrior": preload("res://LoveScene/LoveSceneimage/WarriorMystic.png"),
	"Priest+Hunter": preload("res://LoveScene/LoveSceneimage/PriestHunter.png")
}
@export var love_scenes := {
	"Priest+Mystic": "res://LoveScene/PriestxMystic.tscn",
	"Mystic+Hunter": "res://LoveScene/MysticxHunter.tscn",
	"Priest+Warrior": "res://LoveScene/PriestxWarrior.tscn",
	"Hunter+Warrior": "res://LoveScene/HunterxWarrior.tscn",
	"Mystic+Warrior": "res://LoveScene/WarriorxMystic.tscn",
	"Priest+Hunter": "res://LoveScene/PriestxHunter.tscn"
}
var current_love_scene: Node = null
var scene_path := ""
var camp : Campement
@onready var button : Button = $TenteButton
@onready var ButtonStopMasturb=$"../animMasturbate/InsideTenteButton"
func _ready() -> void:
	Tentescale=self.scale.y
	button.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	ButtonStopMasturb.connect("button_down",_on_inside_tente_button_button_down)
	
func startMasturbation(user:CharaCamp): 
	somoneInside=user
	ButtonStopMasturb.visible=true
	bounce_enabled=true
	match user.Charaname:
		"Priest":  images = PriestImages
		"Mystic":  images = MysticImages
		"Hunter":  images = HunterImages
		"Warrior": images = WarriorImages
	user.gomasturbate()
	thetexture.texture = images[0]
	
func startlove(user:CharaCamp, target: CharaCamp):
	camp = user.camp
	bounce_enabled=true
	var key1 = "%s+%s" % [user.Charaname, target.Charaname]
	var key2 = "%s+%s" % [target.Charaname, user.Charaname]
	var littlebuff := load("res://characters/kink/bigAttackBuff.tres")
	
	user.campposition.visible=false
	target.campposition.visible=false
	twoInside.append(user)
	twoInside.append(target)
	
	show_love_image(user, target)
	
	
	for chara in twoInside:
		chara.add_buff(littlebuff)
	if love_scenes.has(key1):
		scene_path = love_scenes[key1]
	elif love_scenes.has(key2):
		scene_path = love_scenes[key2]

	if scene_path == "":
		print("⚠️ Aucun visuel pour ", user.Charaname, " et ", target.Charaname)
		return
	print(scene_path, user.Charaname, " et ", target.Charaname)




func _process(_delta):
	if bounce_enabled and tween == null:
		start_bounce()
	elif not bounce_enabled and tween != null:
		tween.kill()
		tween = null
		back_tween.kill()
		back_tween=null
		#self.scale.y = 1.0   # reset (si tu veux le remettre à sa position d'origine)

func start_bounce():
	tween = create_tween()
	tween.set_loops()  # boucle infinie
	tween.tween_property(self, "scale:y", bounce_height, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", Tentescale, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	back_tween = create_tween()
	back_tween.set_loops()
	back_tween.tween_property(tenteback, "scale:y", bounce_height, bounce_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	back_tween.tween_property(tenteback, "scale:y", Tentescale, bounce_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_timer_timeout():
	current_state = !current_state
	thetexture.texture = images[0] if current_state else images[1]
	

func _on_inside_tente_button_button_down() -> void:
	print ("stop masturb")
	ButtonStopMasturb.visible=false
	timer.stop
	bounce_enabled=false
	somoneInside.current_horny= max(0, somoneInside.current_horny - 20)
	
	var CampPosition = somoneInside.campposition
	
	thetexture.texture=images[2]
	await get_tree().create_timer(1.0).timeout
	CampPosition.visible=true
	somoneInside.animate_heal(4,somoneInside,Color.HOT_PINK)
	$"../BackgroundinsideTente".visible =false
	$"../animMasturbate".visible=false
	somoneInside=null


func _on_tente_button_button_down() -> void:
	print ( "clic on tente")
	if somoneInside!= null :
		timer = Timer.new()
		timer.wait_time = switch_time
		timer.autostart = true
		timer.one_shot = false
		add_child(timer)
		timer.timeout.connect(_on_timer_timeout)
		$"../BackgroundinsideTente".visible =true
		$"../animMasturbate".visible=true
	if not twoInside.is_empty():
		print ( "clic on tente with peoples inside")
		var love_scene_packed: PackedScene = load(scene_path)
		bounce_enabled=false
		var littlebuff := load("res://characters/kink/bigAttackBuff.tres")
				
		if not love_scene_packed:
			push_error("❌ Impossible de charger la scène : " + scene_path)
			return

				# Supprime l’ancienne scène si elle existe
		if current_love_scene and is_instance_valid(current_love_scene):
			current_love_scene.queue_free()
			print ( "clic on tente with peoples inside")
				# Instancie la nouvelle scène et l’ajoute au camp
		current_love_scene = love_scene_packed.instantiate()
		current_love_scene.z_index= 12
		camp.add_child(current_love_scene)
		for chara in twoInside:
			chara.campposition.visible=true
			#chara.add_buff(littlebuff)
		twoInside.clear()
		love_sprite.visible = false
		
func loved_one_go_out():
	for child in love_sprite.get_children():
		child.queue_free()
	love_sprite.visible = false
	for chara in twoInside:
		chara.campposition.visible = true
	await get_tree().process_frame
	twoInside.clear()
	bounce_enabled = false
	
func show_love_image(user: CharaCamp, target: CharaCamp):
	var key1 = "%s+%s" % [user.Charaname, target.Charaname]
	var key2 = "%s+%s" % [target.Charaname, user.Charaname]
	var texture: Texture2D = null

	if love_images.has(key1):
		texture = love_images[key1]
	elif love_images.has(key2):
		texture = love_images[key2]

	if texture == null:
		print("⚠️ Pas d'image pour cette combinaison :", key1)
		return

	# Supprime toute ancienne animation dans le love_sprite
	for child in love_sprite.get_children():
		child.queue_free()

	# Cas spécial : Priest+Warrior → animation 7x5
	if key1 == "Priest+Warrior" or key2 == "Priest+Warrior":
		love_sprite.visible = true
		love_sprite.texture = null  # on n’affiche pas la texture statique

		var anim := SpriteFrames.new()
		
		anim.set_animation_loop("default", true)
		anim.set_animation_speed("default", 60.0)  # ✅ 60 FPS

		var sprite_sheet = texture
		var frame_width = sprite_sheet.get_width() / 7
		var frame_height = sprite_sheet.get_height() / 5

		for y in range(5):
			for x in range(7):
				var region = Rect2(x * frame_width, y * frame_height, frame_width, frame_height)
				var frame_tex = AtlasTexture.new()
				frame_tex.atlas = sprite_sheet
				frame_tex.region = region
				anim.add_frame("default", frame_tex)

		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.name = "LoveAnimation"
		animated_sprite.frames = anim
		animated_sprite.scale=Vector2(2.0,2.0)
		animated_sprite.position.y = -10
		animated_sprite.play("default")
		

		# 💡 Ajout en enfant direct du LoveImage
		love_sprite.add_child(animated_sprite)

	else:
		# Cas normal : image fixe
		love_sprite.texture = texture
		love_sprite.visible = true

func _on_mouse_entered():
	# Rend le sprite plus visible (ou plus transparent selon ton besoin)
	self.modulate.a = 0.5  # 50% d’opacité

func _on_mouse_exited():
	self.modulate.a = 1.0  
	
