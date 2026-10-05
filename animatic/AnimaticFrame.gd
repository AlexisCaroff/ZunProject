class_name AnimaticFrame
extends Resource

@export var texture: Texture2D

@export var audio: AudioStream
@export_file("*.txt") var subtitle_file: String = ""
@export var skip_on_click: bool = true


func load_subtitle() -> String:
	if subtitle_file.is_empty():
		return ""
	if not FileAccess.file_exists(subtitle_file):
		push_warning("AnimaticFrame: fichier subtitle introuvable : %s" % subtitle_file)
		return ""
	var file := FileAccess.open(subtitle_file, FileAccess.READ)
	if file == null:
		push_warning("AnimaticFrame: impossible d'ouvrir %s" % subtitle_file)
		return ""
	return file.get_as_text()
