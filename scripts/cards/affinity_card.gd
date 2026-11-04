extends Resource
class_name AffinityCard


#  CARTE D'AFFINITÉ

#  Un événement de camp que le personnage SÉLECTIONNÉ déclenche, contre des
#  points de camp. Les cartes se gagnent en combat (GameManager.roll_card),
#  se consultent partout (HUD, à côté de la carte et du sac) mais ne se
#  jouent qu'au campement (Campement.play_card).
#  chacun est appliqué à chaque cible, avec le joueur de la carte en `user`.

## Qui la carte vise.
##  SELF        : le joueur de la carte lui-même
##  OTHER_ALLY  : un autre membre de l'équipe (à déposer sur lui)
##  ANY_ALLY    : n'importe quel membre, joueur compris
##  ALL         : toute l'équipe (déposer la carte sur n'importe qui)
enum Target { SELF, OTHER_ALLY, ANY_ALLY, ALL }

## Mot-clé de user_name : tout le monde peut jouer la carte.
const ANYONE := "All"

@export var title: String = "Card"
@export_multiline var description: String = ""
## Coût en points de camp.
@export var cost: int = 1
## Charaname du seul personnage qui peut la jouer, ou "All".
@export var user_name: String = ANYONE
@export var target: Target = Target.ALL
## Petite icône d'effet, dessinée sur la carte.
@export var icon: Texture2D
## Illustration (facultative) : remplace le portrait du joueur sur la carte.
@export var illustration: Texture2D
@export var effects: Array[CampEffect] = []


func is_for_anyone() -> bool:
	return user_name == "" or user_name == ANYONE


func can_be_played_by(cd: CharacterData) -> bool:
	return cd != null and (is_for_anyone() or cd.Charaname == user_name)


func target_label() -> String:
	match target:
		Target.SELF:
			return "Self"
		Target.OTHER_ALLY:
			return "One ally"
		Target.ANY_ALLY:
			return "One character"
	return "Whole team"
