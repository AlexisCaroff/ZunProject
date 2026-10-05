extends Resource
class_name ExplorationSkill

# --- Identité
@export var name: String = "Confession"
@export var descriptionName: String = "Confession"
@export var description: String = "Convertit du Lust en Guilt sur un allié."
@export var icon: Texture2D
@export var animTexture : Texture
# --- Ciblage
enum TargetType { SELF, ALLY, ANY }
@export var target_type: TargetType = TargetType.ANY

# --- Effet : conversion lust → guilt
## Combien de Lust le lanceur perd
@export var lust_cost: int = 20
## Combien de Guilt la cible gagne
@export var guilt_gain: int = 15
## Si vrai : applique aussi le guilt au lanceur (utile en SELF)
@export var apply_guilt_to_caster_too: bool = false

# --- VFX (optionnels, comme les skills de combat)
## VFX joué sur le LANCEUR
@export var caster_effect_scene: PackedScene
## VFX joué sur la CIBLE
@export var target_effect_scene: PackedScene

# --- Cooldown (optionnel)
@export var cooldown: int = 0
var current_cooldown: int = 0


func can_use(caster_data: CharacterData) -> bool:
	if caster_data == null:
		return false
	if current_cooldown > 0:
		return false
	
	return true


## Applique l'effet du skill. NE gère PAS les animations (c'est fait dans ExplorationManager).
func apply_effect(caster: Node, target: Node) -> void:
	var caster_data: CharacterData = caster.characterData
	var target_data: CharacterData = target.characterData

	print ("Whip !")

	target_data.current_horniness = max (target_data.current_horniness-lust_cost,0)

	# La cible gagne du Guilt (au max sa marge restante)
	var actual_guilt_gain: int = min(guilt_gain, target_data.max_stress - target_data.current_stress)
	target_data.current_stress += actual_guilt_gain

	if apply_guilt_to_caster_too and caster != target:
		var caster_guilt_gain: int = min(guilt_gain, caster_data.max_stress - caster_data.current_stress)
		caster_data.current_stress += caster_guilt_gain

	current_cooldown = cooldown
