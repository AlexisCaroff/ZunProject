extends Sprite2D
var chara: Character
@export var attackPos: Vector2
@export var MidPos: Vector2
@export var outsidePos: Vector2
@export var esquivPos: Vector2
@export var attack_scale := Vector2(1.2, 1.2) # Taille pendant l’attaque
@export var normal_scale := Vector2(1.0, 1.0)

var tween: Tween

func attack_anim(character: Character):
	chara = character
	self.texture = chara.portrait_texture
	self.position = outsidePos 
	self.scale=Vector2(2.0,2.0)
	# Création du tween principal
	tween = create_tween()
	
	# Étape 1 : entrée jusqu’à la position intermédiaire
	tween.tween_property(self, "position", MidPos, 0.2)
	
	# Étape 2 : attaque
	tween.tween_callback(Callable(self, "_on_attack"))

func _on_attack():
	# Changement de texture (attaque)
	if chara.combat_manager.pending_skill.ImageSkill != null:
		self.texture = chara.combat_manager.pending_skill.ImageSkill

	# Mouvement vers la position d’attaque
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", attackPos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", attack_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Petite pause pour marquer l'impact
	tween.tween_interval(0.5)

	# Retour à la normale
	tween.tween_callback(Callable(self, "_on_return"))
	
func _on_return():
	self.texture = chara.portrait_texture
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", outsidePos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
