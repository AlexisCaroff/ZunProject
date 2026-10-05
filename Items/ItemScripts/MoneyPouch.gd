extends Equipment
class_name MoneyPouch

# ════════════════════════════════════════════════════════════════════
#  BOURSE — de l'argent présenté comme un objet de butin
# ════════════════════════════════════════════════════════════════════
#  L'argent est un compteur sur le GameManager, pas un objet de sac. Mais
#  l'écran de victoire, lui, ne sait afficher que des Equipment.
#
#  Cette classe sert de passe-plat : la bourse défile comme une carte de
#  butin ("+42"), puis GameManager.add_to_inventory() la reconnaît, verse
#  `number` au compteur et ne lui donne AUCUNE case d'inventaire.
#
#  À ne pas confondre avec les cristaux de combat, qui restent un vrai
#  objet occupant une case.
# ════════════════════════════════════════════════════════════════════

const DEFAULT_ICON := "res://UI/UI boxes/UI_crystal.png"


## Fabrique une bourse prête à partir dans le butin d'une rencontre.
static func make(amount: int, icon_tex: Texture2D = null) -> MoneyPouch:
	var pouch := MoneyPouch.new()
	pouch.number = max(0, amount)
	pouch.name = "%d Gold" % pouch.number
	pouch.description = "De quoi graisser une patte."
	if icon_tex != null:
		pouch.icon = icon_tex
	elif ResourceLoader.exists(DEFAULT_ICON):
		pouch.icon = load(DEFAULT_ICON)
	return pouch
