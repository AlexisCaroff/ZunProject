extends Resource
class_name Equipment
@export var icon: Texture2D
@export var name: String
@export var description: String
@export var isCursed: bool= false
@export var number :int =1
# --- Modificateurs de stats ---
@export var Max_stamina_bonus: int =0
@export var Max_lust_bonus: int =0
@export var Max_Guilt_bonus: int =0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var willpower_bonus: int = 0

@export var evasion_bonus: int = 0
@export var initiative_bonus: int = 0
@export var peekbonus: int = 0

# --- Cooldown ---
# Réduit le cooldown de TOUS les skills (en tours)
@export var global_cooldown_reduction: int = 0

# Réduction ciblée (par nom de skill ou tag)
@export var skill_specific_cooldown: Dictionary[String, int] = {}
# --- Effets spéciaux ---
# Appelé quand ce personnage utilise une compétence
func on_skill_use(_user: Character, _skill: Skill, _target: Character):
	pass

# Appelé quand ce personnage reçoit une attaque
func on_receive_attack(_user: Character, _attacker: Character, _damage: int):
	pass
func after_skill_use(user: Character, skill: Skill, _target: Character):
	pass
