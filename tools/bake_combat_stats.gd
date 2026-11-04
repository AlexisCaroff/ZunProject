extends Node

# Écrit dans une scène de combat la mise en page des stats que ui_combat.gd
# ferait sinon en jeu (icônes, jauges, ligne « Buff: »).
#   Godot --headless --path . res://tools/bake_combat_stats.tscn  (scène vide portant ce script)

func _ready() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		paths = PackedStringArray(["res://lvl/CombatInterface.tscn"])
	for path in paths:
		var ps := load(path) as PackedScene
		var root := ps.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		var layer := root.get_node("CanvasLayer")
		if layer.get_node_or_null("StatStaminaIcon") != null:
			print(path, " : déjà mise en page")
			root.free()
			continue
		var before := layer.get_children()
		root.build_stat_layout(layer)
		for c in layer.get_children():
			if not c in before:
				c.owner = root
		var out := PackedScene.new()
		var err := out.pack(root)
		if err == OK:
			err = ResourceSaver.save(out, path)
		print(path, " : ", error_string(err))
		root.free()
	get_tree().quit()
