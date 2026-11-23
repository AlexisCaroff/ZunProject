extends Resource
class_name DialogueStyleSet

## Quelle couleur de bulle pour quel personnage.
## Fichier : res://UI dialog/dialogue_styles.tres (à éditer dans l'Inspecteur).
## La clé est le nom tel qu'écrit dans les fichiers de dialogue, avant le
## « : » (ex. "Broodmother"). Un nom absent utilise `default_style`.

@export var default_style: DialogueBubbleStyle
@export var speaker_styles: Dictionary[String, DialogueBubbleStyle] = {}


func style_for(speaker: String) -> DialogueBubbleStyle:
	var key := speaker.strip_edges()
	if speaker_styles.has(key):
		return speaker_styles[key]
	# Tolère la ponctuation des alias (« Inquisitor. »).
	var trimmed := key.rstrip(".!?")
	if speaker_styles.has(trimmed):
		return speaker_styles[trimmed]
	return default_style if default_style != null else DialogueBubbleStyle.new()
