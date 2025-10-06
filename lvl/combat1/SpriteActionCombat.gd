extends Sprite2D

@export var attackPos: Vector2
@export var MidPos: Vector2
@export var outsidePos: Vector2
@export var esquivPos: Vector2


func attackAnim(character: Character ):
	self.texture= character.portrait_texture
	var tween := create_tween() as Tween
	self.position= outsidePos 
	tween.tween_property(self, "position", MidPos , 0.2)
	
	if character.combat_manager.pending_skill.ImageSkill != null:
		self.texture=character.combat_manager.pending_skill.ImageSkill
	tween.tween_property(self, "position", attackPos, 0.2).set_delay(0.2)
	tween.tween_property(self, "position", MidPos , 0.05)
	#self.texture= character.portrait_texture
	tween.tween_property(self, "position", outsidePos , 0.2)
	await tween.finished
