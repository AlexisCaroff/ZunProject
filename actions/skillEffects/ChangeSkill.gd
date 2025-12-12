extends SkillEffect
class_name ChangeSkill

@export var updated_skills: Array[Resource]
@export var portrait_texture: Texture2D
@export var Hit_texture: Texture2D
@export var dead_texture: Texture2D


func apply(user: Character, _target: PositionSlot) -> void:
	user._updateSkills(updated_skills)
	user.characterData.portrait_texture=portrait_texture
	user.characterData.dead_portrait_texture= dead_texture
	user.characterData.Hit_texture= Hit_texture
