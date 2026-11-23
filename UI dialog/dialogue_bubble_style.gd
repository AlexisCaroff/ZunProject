extends Resource
class_name DialogueBubbleStyle

## Couleurs d'une bulle de dialogue (UI/dialogue_ui.tscn, DialogueUI.gd).
## Les images (queue de bulle, onglet du nom, décos des coins) sont
## recolorées par shader : les valeurs par défaut ci-dessous sont leurs
## couleurs d'origine (beige).

@export_group("Bulle")
@export var fill: Color = Color("d7c9ba")
@export var border: Color = Color("846850")
@export var text_color: Color = Color("3a2a22")
@export var deco: Color = Color("baaa99")

@export_group("Onglet du nom")
@export var name_fill: Color = Color("a58e76")
@export var name_border: Color = Color("927b63")
@export var name_text: Color = Color("f6ecdf")
