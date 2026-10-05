@tool
extends EditorScript

# ════════════════════════════════════════════════════════════════════
#  VÉRIFICATEUR DE SKILLS  —  à lancer depuis l'éditeur
# ════════════════════════════════════════════════════════════════════
#
#  Ouvrir ce fichier dans l'éditeur de script, puis Fichier ▸ Exécuter
#  (Ctrl+Maj+X). Le rapport s'affiche dans la console « Sortie ».
#
#  À quoi ça sert
#  ──────────────
#  Le bug récurrent « les effets d'un skill se vident tout seuls » ne se
#  voit qu'au moment où le skill est utilisé en jeu, souvent des heures
#  après la vraie cause. Ce script relit TOUS les .tres de skill sur le
#  disque, sans passer par le cache de l'éditeur, et dit lesquels sont
#  cassés. Trois verdicts possibles :
#
#   • VIDE            → le .tres n'a plus d'effet du tout. Il faut les
#                       réassigner dans l'inspecteur (et sauvegarder).
#   • SANS SCRIPT     → l'effet est là mais son script ne s'est pas
#                       attaché. C'est le cas qui provoque en jeu
#                       « Nonexistent function 'apply' in base 'Resource' ».
#   • OK              → rien à signaler.
#
#  Interpréter le résultat
#  ───────────────────────
#  Si ce script dit OK partout mais que le jeu se plaint quand même,
#  alors le disque est sain et c'est le dossier .godot/ qui est périmé :
#  fermer Godot, supprimer .godot/, rouvrir le projet (réimport complet).
#
#  Si au contraire il signale un fichier, c'est bien ce .tres-là qu'il
#  faut réparer — pas la peine de chercher ailleurs.

## Dossiers passés au peigne fin.
const DOSSIERS := [
	"res://actions/HerosCombatSkills",
	"res://actions/ennemiCombatSkills",
	"res://actions/CampSkill",
	"res://actions/ExplorationSkills",
]


func _run() -> void:
	var fichiers: Array[String] = []
	for d in DOSSIERS:
		_collecte(d, fichiers)
	fichiers.sort()

	var casses: Array[String] = []
	var vides: Array[String] = []
	var vus := 0

	print("\n═══════════════════════════════════════════════════════════")
	print("  VÉRIFICATION DES SKILLS — ", fichiers.size(), " fichier(s) trouvé(s)")
	print("═══════════════════════════════════════════════════════════")

	for chemin in fichiers:
		# CACHE_MODE_IGNORE : on relit vraiment le disque, sans réutiliser
		# ce que l'éditeur garde en mémoire. C'est tout l'intérêt.
		var res := ResourceLoader.load(chemin, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null:
			casses.append(chemin)
			print("  ✗ ILLISIBLE     ", chemin)
			continue

		var listes := {}
		if "effects" in res:
			listes["effects"] = res.effects
		if "second_effects" in res:
			listes["second_effects"] = res.second_effects
		if listes.is_empty():
			continue  # pas un Skill (CharacterData, LootTable…)

		vus += 1
		var nom: String = str(res.name) if "name" in res else chemin.get_file()
		var soucis: Array[String] = []

		# « effects » vide n'est pas forcément anormal : « move » ou un
		# skill purement narratif n'en a légitimement aucun. C'est
		# pourtant AUSSI le symptôme du bug, donc on le signale à part,
		# en avertissement, sans le compter comme cassé.
		var principale: Array = listes["effects"] if listes.has("effects") else []
		var vide := principale.is_empty()

		for cle in listes:
			var i := 0
			for e in listes[cle]:
				if e == null:
					soucis.append("%s[%d] null" % [cle, i])
				elif e.get_script() == null:
					soucis.append("%s[%d] SANS SCRIPT" % [cle, i])
				elif not e.has_method("apply"):
					soucis.append("%s[%d] pas de apply()" % [cle, i])
				i += 1

		if not soucis.is_empty():
			casses.append(chemin)
			print("  ✗ ", nom.rpad(22), chemin)
			for s in soucis:
				print("        → ", s)
		elif vide:
			vides.append(chemin)
			print("  ⚠ ", nom.rpad(22), chemin, "   (aucun effet)")
		else:
			print("  ✓ ", nom.rpad(22), chemin)

	print("───────────────────────────────────────────────────────────")
	print("  ", vus, " skill(s) examiné(s) — ", casses.size(), " cassé(s), ",
			vides.size(), " sans effet.")

	if not casses.is_empty():
		print("  CASSÉS (effet présent mais sans script) :")
		for c in casses:
			print("    ", c)
		print("  → Réassigner les effets dans l'inspecteur, sauvegarder.")
		print("    Si ça ne tient pas, recréer le .tres SOUS UN AUTRE NOM")
		print("    et repointer le CharacterData dessus.")

	if not vides.is_empty():
		print("  SANS EFFET — normal pour « move » et les skills purement")
		print("  narratifs, anormal pour une attaque :")
		for v in vides:
			print("    ", v)

	if casses.is_empty():
		print("  Aucun effet orphelin : les fichiers sur le disque sont sains.")
		print("  Si le jeu se plaint quand même, c'est le cache : fermer")
		print("  Godot, supprimer le dossier .godot/, rouvrir le projet.")
	print("═══════════════════════════════════════════════════════════\n")


func _collecte(dossier: String, sortie: Array[String]) -> void:
	var d := DirAccess.open(dossier)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with("."):
				_collecte(dossier.path_join(n), sortie)
		elif n.get_extension().to_lower() == "tres":
			sortie.append(dossier.path_join(n))
		n = d.get_next()
	d.list_dir_end()
