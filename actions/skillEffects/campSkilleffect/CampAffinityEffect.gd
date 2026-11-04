extends CampEffect
class_name AffinityCampEffect

# Affinité entre le joueur de la carte et la cible, dans les deux sens.
# Les multiplicateurs de foi modulent le gain selon la cible : un sermon
# touche les zélotes, laisse les barbares de marbre.

@export var amount: int = 10
@export var zealot_mult: float = 1.0
@export var neutral_mult: float = 1.0
@export var barbarian_mult: float = 1.0


func gain_for(target: CharacterData) -> int:
	var m := neutral_mult
	match target.faith:
		CharacterData.Faith.ZEALOT:
			m = zealot_mult
		CharacterData.Faith.BARBARIAN:
			m = barbarian_mult
	return int(round(amount * m))


func apply(user: CharaCamp, target: CharaCamp):
	if user == null or target == null or user == target:
		return
	var u := user.characterData
	var t := target.characterData
	var gain := gain_for(t)
	if gain == 0:
		target.say("...")
		return
	u.affinity[t.Charaname] = clampi(int(u.affinity.get(t.Charaname, 0)) + gain, 0, 100)
	t.affinity[u.Charaname] = clampi(int(t.affinity.get(u.Charaname, 0)) + gain, 0, 100)
	target.animate_heal(gain, user, Color.HOT_PINK)
