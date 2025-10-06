extends SkillEffect
class_name AddCooldownEffect
var Chartarget:Character
func apply(user: Character, target: PositionSlot) -> void:
	var random_index = randi_range(0, 3)
	var targetskill = target.occupant.skills[random_index]
	targetskill.current_cooldown+=2
	target.occupant.DebuffAnim("drained ")
