extends Node
class_name  tente
@export var masturbe_images := {
	"Priestess": [
		preload("res://camp imgs/camp_char_solo_P1.png"),
		preload("res://camp imgs/camp_char_solo_P2.png"),
		preload("res://camp imgs/camp_char_solo_P3.png")
	],
	"Mystic": [
		preload("res://camp imgs/camp_char_solo_M1.png"),
		preload("res://camp imgs/camp_char_solo_M2.png"),
		preload("res://camp imgs/camp_char_solo_M3.png")
	],
	"Hunter": [
		preload("res://camp imgs/camp_char_solo_H1.png"),
		preload("res://camp imgs/camp_char_solo_H2.png"),
		preload("res://camp imgs/camp_char_solo_H3.png")
	],
	"Warrior": [
		preload("res://camp imgs/camp_char_solo_W1.png"),
		preload("res://camp imgs/camp_char_solo_W2.png"),
		preload("res://camp imgs/camp_char_solo_W3.png")
	]}
@export var switch_time =0.5
@onready var thetexture:Sprite2D =$"../animMasturbate"
@onready var backgroundCadre =$"../BackgroundinsideTente"
@onready var tenteback = $"../TenteBack"
var images:Array[Texture2D]
var current_state: bool = true
var timer:Timer

@export var bounce_enabled: bool = false
@export var bounce_height: Vector2 = Vector2(1.0,1.0)
@export var bounce_duration: float 
var back_tween :Tween = null
var tween: Tween = null

var somoneInside : CharaCamp
var twoInside : Array[CharaCamp]
var Tentescale : Vector2 
@onready var love_sprite: Sprite2D = $"../LoveImage"

@export var love_images := {
	"Priestess+Mystic": [
		preload("res://camp imgs/camp_char_duo_MP1.png"),
		preload("res://camp imgs/camp_char_duo_MP2.png")
	],
	"Mystic+Hunter": [
		preload("res://camp imgs/camp_char_duo_MH1.png"),
		preload("res://camp imgs/camp_char_duo_MH2.png")
	],
	"Hunter+Warrior": [
		preload("res://camp imgs/camp_char_duo_WH1.png"),
		preload("res://camp imgs/camp_char_duo_WH2.png")
	],
	"Mystic+Warrior": [
		preload("res://camp imgs/camp_char_duo_WM1.png"),
		preload("res://camp imgs/camp_char_duo_WM2.png")
	],
	"Priestess+Hunter": [
		preload("res://camp imgs/camp_char_duo_PH1.png"),
		preload("res://camp imgs/camp_char_duo_PH2.png")
	],


	"Priestess+Warrior": preload("res://LoveScene/LoveSceneimage/PriestWarriorAnim.png")
}
@export var love_scenes := {
	"Priestess+Mystic": "res://LoveScene/PriestxMystic.tscn",
	"Mystic+Hunter": "res://LoveScene/MysticxHunter.tscn",
	"Priestess+Warrior": "res://LoveScene/PriestxWarrior.tscn",
	"Hunter+Warrior": "res://LoveScene/HunterxWarrior.tscn",
	"Mystic+Warrior": "res://LoveScene/WarriorxMystic.tscn",
	"Priestess+Hunter": "res://LoveScene/PriestxHunter.tscn"
}
var current_love_scene: Node = null
var scene_path := ""
var camp : Campement
@onready var button : Button = $TenteButton
@onready var ButtonStopMasturb=$"../animMasturbate/InsideTenteButton"
@onready var cam:Camera =$"../Camera2D"
var anim : SpriteFrames
var is_anim_zoom_playing :bool = false
var cliclove:bool = false
var gm: GameManager
func _ready() -> void:
	Tentescale=self.scale
	button.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
	gm = get_tree().root.get_node("GameManager") as GameManager
func startMasturbation(user:CharaCamp): 
	
	user.gomasturbate()
	for child in love_sprite.get_children():
		child.queue_free()
	somoneInside=user
	
	bounce_enabled=true
	var data = null
	if masturbe_images.has(user.characterData.Charaname):
		data = masturbe_images[user.characterData.Charaname]
	love_sprite.visible = true
	love_sprite.texture = null
	if data == null:
		print ("data is null")
	if data is Array:
		var frames: Array = [data[0],data[1]]

		anim = SpriteFrames.new()
		anim.set_animation_loop("default", true)
		anim.set_animation_speed("default", 4.0) 

		for tex in frames:
			anim.add_frame("default", tex)

		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.frames = anim
		animated_sprite.scale = Vector2(0.6, 0.6)
		animated_sprite.position.y = -250
		animated_sprite.play("default")

		love_sprite.add_child(animated_sprite)
		
	

	
func startlove(user:CharaCamp, target: CharaCamp):
	camp = user.camp
	bounce_enabled=true
	var key1 = "%s+%s" % [user.characterData.Charaname, target.characterData.Charaname]
	var key2 = "%s+%s" % [target.characterData.Charaname, user.characterData.Charaname]
	var littlebuff := load("res://characters/kink/bigAttackBuff.tres")
	
	user.campposition.visible=false
	target.campposition.visible=false
	twoInside.append(user)
	twoInside.append(target)
	cliclove =false
	show_love_image(user, target)
	
	
	for chara in twoInside:
		chara.add_buff(littlebuff)
	if love_scenes.has(key1):
		scene_path = love_scenes[key1]
	elif love_scenes.has(key2):
		scene_path = love_scenes[key2]

	if scene_path == "":
		print("⚠️ Aucun visuel pour ", user.Charaname, " et ", target.characterData.Charaname)
		return
	print(scene_path, user.characterData.Charaname, " et ", target.characterData.Charaname)




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
	tween.tween_property(self, "scale", bounce_height, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Tentescale, bounce_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	
	back_tween = create_tween()
	back_tween.set_loops()
	back_tween.tween_property(tenteback, "scale", bounce_height, bounce_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	back_tween.tween_property(tenteback, "scale", Tentescale, bounce_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)




func _on_tente_button_button_down() -> void:
	
	print ( "clic on tente")
	var cam_pos = self.position
	cam_pos.x +=250
	cam_pos.y -=100
	
	if somoneInside!= null :
		bounce_enabled=false
		somoneInside.characterData.current_horniness= max(0, somoneInside.characterData.current_horniness - 20)
		var data = masturbe_images[somoneInside.characterData.Charaname]
		is_anim_zoom_playing =true
		var campPosition = somoneInside.campposition
		var frames: Array = [data[2]]
		for child in love_sprite.get_children():
			child.queue_free()
		anim = SpriteFrames.new()
		anim.set_animation_loop("default", true)
		anim.set_animation_speed("default", 4.0) 

		for tex in frames:
			anim.add_frame("default", tex)
		
		
		cam.zoom_to_position(cam_pos, cam.baseZoom.x*1.5 ,0.6)
		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.frames = anim
		animated_sprite.scale = Vector2(0.6, 0.6)
		animated_sprite.position.y = -250
		animated_sprite.play("default")

		love_sprite.add_child(animated_sprite)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(love_sprite,"modulate:r",2,0.2)
		tween.tween_property(love_sprite,"modulate:r",1,0.2)
		tween.tween_property(love_sprite,"modulate:r",2,0.2)
		tween.tween_property(love_sprite,"modulate:r",1,0.2)
		await tween.finished
		campPosition.visible=true
		somoneInside.animate_heal(20,somoneInside,Color.HOT_PINK)
		
		love_sprite.visible = false
		somoneInside=null
		is_anim_zoom_playing =false
		cam.reset()
	
	if not twoInside.is_empty() && cliclove == false:
		cliclove = true
		print ( "clic on tente with peoples inside")
		is_anim_zoom_playing =true
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(self,"modulate:a",0.1,2.0)
		tween.parallel().tween_property(anim, "speed_scale", 100, 0.50)
		if anim.get_animation_speed("default")==2.0:
			anim.set_animation_speed("default", 4.0) 
		else : anim.set_animation_speed("default", 60.0) 
		await cam.zoom_to_position(cam_pos, cam.baseZoom.x*1.5 ,2.0)
		
		
		var love_scene_packed: PackedScene = load(scene_path)
		await gm.sceneTransition.fade_out(1.5)
		
		
		var littlebuff := load("res://characters/kink/bigAttackBuff.tres")
		twoInside[0].characterData.affinity[twoInside[1].characterData.Charaname] += 20
		twoInside[1].characterData.affinity[twoInside[0].characterData.Charaname] += 20
		print (twoInside[0].characterData.Charaname+" and "+ twoInside[1].characterData.Charaname +" love "+str(twoInside[1].characterData.affinity[twoInside[0].characterData.Charaname]))
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
		cam.reset()
		
		await gm.sceneTransition.fade_in(0.5)
		is_anim_zoom_playing =false
		self.modulate.a = 1.0  
		
func masturbin_go_out():
	if somoneInside !=null:
		somoneInside.campposition.visible=true
		somoneInside.characterData.current_horniness= max(0, somoneInside.characterData.current_horniness - 20)
		somoneInside.animate_heal(20,somoneInside,Color.HOT_PINK)
		somoneInside = null
		love_sprite.visible = false
		bounce_enabled=false
		
func loved_one_go_out():
	for child in love_sprite.get_children():
		child.queue_free()
	love_sprite.visible = false
	for chara in twoInside:
		
		chara.campposition.visible = true
	for char in twoInside:
		char.characterData.current_horniness= max(0, char.characterData.current_horniness - 20)
	twoInside[0].characterData.affinity[twoInside[1].characterData.Charaname] += 100
	twoInside[1].characterData.affinity[twoInside[0].characterData.Charaname] += 100
	print (twoInside[0].characterData.Charaname+" and "+ twoInside[1].characterData.Charaname +" love "+str(twoInside[1].characterData.affinity[twoInside[0].characterData.Charaname]))
	print("yaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	await get_tree().process_frame
	twoInside.clear()
	bounce_enabled = false
	
	
func show_love_image(user: CharaCamp, target: CharaCamp):
	var key1 = "%s+%s" % [user.characterData.Charaname, target.characterData.Charaname]
	var key2 = "%s+%s" % [target.characterData.Charaname, user.characterData.Charaname]

	var data = null
	if love_images.has(key1):
		data = love_images[key1]
	elif love_images.has(key2):
		data = love_images[key2]

	if data == null:
		print("⚠️ Pas d'image pour cette combinaison :", key1)
		return

	# Nettoyage
	for child in love_sprite.get_children():
		child.queue_free()

	love_sprite.visible = true
	love_sprite.texture = null

	# 🔥 CAS SPÉCIAL : Priestess + Warrior (spritesheet 7x5)
	if data is Texture2D:
		var sprite_sheet: Texture2D = data

		anim = SpriteFrames.new()
		anim.set_animation_loop("default", true)
		anim.set_animation_speed("default", 50.0)
	
		var frame_width = sprite_sheet.get_width() / 7
		var frame_height = sprite_sheet.get_height() / 5

		for y in range(5):
			for x in range(7):
				var region = Rect2(x * frame_width, y * frame_height, frame_width, frame_height)
				var frame_tex := AtlasTexture.new()
				frame_tex.atlas = sprite_sheet
				frame_tex.region = region
				anim.add_frame("default", frame_tex)

		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.frames = anim
		animated_sprite.scale = Vector2(2.0, 2.0)
		animated_sprite.position.y = -10
		animated_sprite.play("default")

		love_sprite.add_child(animated_sprite)
		return

	# ❤️ CAS NORMAL : animation 2 images
	if data is Array:
		var frames: Array = data

		anim = SpriteFrames.new()
		anim.set_animation_loop("default", true)
		anim.set_animation_speed("default", 2.0) 

		for tex in frames:
			anim.add_frame("default", tex)

		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.frames = anim
		animated_sprite.scale = Vector2(0.6, 0.6)
		animated_sprite.position.y = -250
		animated_sprite.play("default")

		love_sprite.add_child(animated_sprite)

func _on_mouse_entered():
	if !is_anim_zoom_playing:
		self.modulate.a = 0.2  # 50% d’opacité

func _on_mouse_exited():
	if !is_anim_zoom_playing:
		self.modulate.a = 1.0  
	
