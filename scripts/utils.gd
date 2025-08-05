# utils.gd
extends Node

func load_texture(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null
