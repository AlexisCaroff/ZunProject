@tool
extends EditorScript

const CHARACTER_SCENES := [
	"res://characters/CharacterEnemyAdict.tscn",
	"res://characters/CharacterEnemyMommyBoss.tscn",
	"res://characters/CharacterEnemyNymphe.tscn",
	"res://characters/CharacterTestEnemySpitter1.tscn",
	"res://characters/CharaEnnemyTemptress.tscn",
	"res://characters/CharaHunter.tscn",
	"res://characters/CharaMystic.tscn",
	"res://characters/CharaPriest.tscn",
	"res://characters/CharaWarrior.tscn",
]

const OUT_DIR := "res://characters/data/"


func _run():
	print("▶️ Conversion Characters → CharacterData")
	_make_out_dir()

	for s in CHARACTER_SCENES:
		_process_scene(s)

	print("✔️ Conversion terminée.")


func _make_out_dir():
	var d = DirAccess.open("res://")
	if d:
		d.make_dir_recursive(OUT_DIR)


func _process_scene(scene_path: String):
	print("\n=== Traitement :", scene_path, "===")

	var packed := load(scene_path)
	if not packed:
		push_error("❌ Impossible de charger la scène")
		return

	var inst = packed.instantiate()

	# Recherche du Character
	var char = _find_character_node(inst)
	if not char:
		push_error("❌ Aucun Character trouvé")
		return

	var basename := scene_path.get_file().get_basename()
	var out_path := OUT_DIR + basename + ".tres"

	# Nouvelle ressource propre
	var data := CharacterData.new()

	# Remplissage
	var copied = _copy_matching_properties(char, data)
	print("   Champs copiés :", copied)

	# Nom par défaut si vide
	if data.Charaname == "" or data.Charaname == "name":
		data.Charaname = basename

	# Sauvegarde CharacterData
	var err := ResourceSaver.save(data, out_path)
	if err != OK:
		push_error("❌ Échec sauvegarde CharacterData")
	else:
		print("💾 Data sauvegardée :", out_path)

	# Attache le chemin dans la scène (meta)
	char.set_meta("character_data_path", out_path)

	# Sauvegarde scène
	var new_packed := PackedScene.new()
	new_packed.pack(inst)
	ResourceSaver.save(new_packed, scene_path)
	print("💾 Scène sauvegardée :", scene_path)


func _find_character_node(n):
	if n is Character:
		return n
	for c in n.get_children():
		var f = _find_character_node(c)
		if f:
			return f
	return null


func _copy_matching_properties(src: Node, dst: Resource):
	var copied := []

	# récupère les propriétés exportées de CharacterData
	for prop in dst.get_property_list():
		var name = prop.name

		# uniquement les propriétés exportées/storées
		if (prop.usage & PROPERTY_USAGE_EDITOR) == 0:
			continue

		if not src.has_method("get"):
			continue
		if not src.get_property_list().any(func(p): return p.name == name):
			continue

		var value = src.get(name)

		# ⚠️ ignore les Resources complexes
		if value is Resource and (not value is Texture2D) and (not value is PackedScene):
			continue

		# valeur simple OK
		dst.set(name, value)
		copied.append(name)

	return copied
