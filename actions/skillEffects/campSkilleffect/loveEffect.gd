extends CampEffect
class_name CampLoveEffect

@export var name : String
@export var love_images := {
	"Priest+Mystic": "res://LoveScene/PriestxMystic.jpg",
	"Mystic+Hunter": "res://LoveScene/MysticxHunter.jpg",
	"Priest+Warrior": "res://LoveScene/PriestxWarrior.jpg",
	"Hunter+Warrior": "res://LoveScene/HunterxWarrior.jpg",
	"Mystic+Warrior":"res://LoveScene/WarriorxMystic.jpg", 
	"Priest+Hunter":"res://LoveScene/PriestxHunter.jpg"
}
var camp
var love_image: Sprite2D
var user

func apply(theuser: CharaCamp, target: CharaCamp):
	user=theuser
	camp = user.camp
	if not camp:
		return

	var key1 = "%s+%s" % [user.Charaname, target.Charaname]
	var key2 = "%s+%s" % [target.Charaname, user.Charaname] # inverse (couple symétrique)

	var file_path := ""
	if love_images.has(key1):
		file_path = love_images[key1]
	elif love_images.has(key2):
		file_path = love_images[key2]

	if file_path == "":
		print("⚠️ Aucun visuel pour ", user.Charaname, " et ", target.Charaname)
		return

	var texture := load(file_path)
	if not texture:
		push_error("Impossible de charger l'image : " + file_path)
		return

	# comme avant → afficher dans un TextureRect
	love_image= camp.loveimage
	love_image.texture= texture
	love_image.visible=true

	



	
		
