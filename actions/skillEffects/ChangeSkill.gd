extends SkillEffect
class_name ChangeSkill
 
## Skills "normales" du nouveau set (PAS la skill ChangeMask alternée — voir
## paired_change_skill_path).
@export var updated_skills: Array[Resource]
 
@export_file("*.tres") var paired_change_skill_path: String = ""
 
@export var portrait_texture: Texture2D
@export var Hit_texture: Texture2D
@export var dead_texture: Texture2D
 
 
func apply(user: Character, _target: PositionSlot) -> void:
	var skills_to_apply: Array[Resource] = updated_skills.duplicate()
 
	# Insère la skill ChangeMask alternée (chargée paresseusement)
	if paired_change_skill_path != "":
		var paired: Resource = load(paired_change_skill_path)
		if paired != null:
			skills_to_apply.push_front(paired)
		else:
			push_warning("ChangeSkill : impossible de charger paired_change_skill_path = %s" % paired_change_skill_path)
 
	user._updateSkills(skills_to_apply)
	user.characterData.portrait_texture      = portrait_texture
	user.characterData.dead_portrait_texture = dead_texture
	user.characterData.Hit_texture           = Hit_texture
 
