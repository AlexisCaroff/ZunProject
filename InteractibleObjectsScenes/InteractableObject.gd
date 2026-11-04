# InteractableObject.gd
extends Node2D
class_name InteractableObject

@export var data: InteractableObjectResource

## Référence vers la salle qui contient ce coffre, assignée par
## ExplorationManager.load_interactable() au moment du spawn.
## Sert à persister l'état "fouillé/ouvert" entre les visites.
var room: RoomResource = null

@onready var button: Button = $Button
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var etiquette = $etiquette
@export  var big_size = Vector2(0.8, 0.8)
@export  var startsize = Vector2(0.6, 0.6)
var current_tween: Tween = null
@export var item_ui_scene: PackedScene = preload("res://UI/item_ui.tscn")
@export var openedSprite: Texture2D
@onready var SpriteOlder: Sprite2D = $Sprite2D


## Contour au survol : même shader que la sélection des personnages.
const OUTLINE_SHADER := preload("res://characters/character_outline.gdshader")
## Épaisseur du contour À L'ÉCRAN (px), quelle que soit l'échelle du sprite.
@export var outline_screen_width: float = 2.0
@export var outline_color: Color = Color(0.93, 0.78, 0.45, 1.0)


func _ready():
	_setup_outline()
	button.connect("button_down", start_interaction)
	button.connect("mouse_entered", _on_button_mouse_entered)
	button.connect("mouse_exited", _on_button_mouse_exited)

	# Restauration de l'état si le joueur a déjà interagi avec ce coffre.
	if room and room.interactable_used:
		_apply_used_state(room.interactable_opened)


func start_interaction():
	if button.disabled or _interacting:
		return
	if dialogue_manager == null:
		push_error("DialogueManager introuvable")
		return
	_interacting = true
	_set_outline(false)
	# Le personnage actif s'approche de l'objet avant que le dialogue s'ouvre.
	await _approach()

	# Sécurité : éviter double connexion
	if not dialogue_manager.choice_made.is_connected(_on_choice_made):
		dialogue_manager.choice_made.connect(_on_choice_made)

	dialogue_manager.is_Choice = true
	dialogue_manager.text_choice1 = data.choice_1.text
	dialogue_manager.text_choice2 = data.choice_2.text
	dialogue_manager.external_choice_receiver = self

	dialogue_manager.load_dialogue(data.dialogue_file)
	# Dialogue déjà entendu (on était reparti sans rien prendre) : on va droit
	# aux choix. Sans répliques, start_dialogue() affiche les choix seuls.
	if room != null and room.interactable_dialogue_seen:
		dialogue_manager.dialogue_lines.clear()
	elif room != null:
		room.interactable_dialogue_seen = true
	dialogue_manager.start_dialogue()


func _on_choice_made(choice_index: int):
	match choice_index:
		0:
			resolve_choice(data.choice_1)
		1:
			resolve_choice(data.choice_2)


func resolve_choice(choice: InteractableChoice):
	var gm: GameManager = get_tree().root.get_node("GameManager")
	var characters := gm.characters

	# « Leave » (aucun effet) : on n'a rien pris, l'objet reste cliquable et
	# n'est pas marqué comme utilisé.
	if choice.effect_type == InteractableChoice.EffectType.NONE:
		await _return_to_place()
		return

	# Coffre piégé : le slime attaque le personnage actif et s'enfuit, puis on
	# récupère quand même le contenu. Un seul déclenchement par coffre.
	if room != null and gm.chest_is_trapped(room):
		room.chest_trap_state = 2
		await _spring_trap(gm)

	match choice.effect_type:
		InteractableChoice.EffectType.NONE:
			pass

		InteractableChoice.EffectType.ITEM:
			await _give_item(gm, choice.item)

		InteractableChoice.EffectType.RANDOM_LOOT:
			# Butin garanti d'abord, puis le tirage dans la table globale.
			var found: Array[Equipment] = []
			for fixed in choice.guaranteed_items:
				if fixed != null:
					found.append(fixed)
			found.append_array(gm.roll_loot(choice.loot_rolls, choice.loot_chance))

			if found.is_empty():
				await _show_empty_chest()
			for loot in found:
				await _give_item(gm, loot)

		InteractableChoice.EffectType.BUFF:
			for chara in characters:
				chara.add_buff(choice.buff)

		InteractableChoice.EffectType.TAG:
			for chara in characters:
				if not chara.tags.has(choice.tag):
					chara.tags.append(choice.tag)

	# Applique l'état "utilisé" visuellement
	_apply_used_state(choice.opening)

	# Persiste l'état sur la salle pour les visites futures.
	if room:
		room.interactable_used = true
		if choice.opening:
			room.interactable_opened = true

	await _return_to_place()


# ════════════════════════════════════════════════════════════════════
#  APPROCHE 
# ════════════════════════════════════════════════════════════════════


@export var approach_time: float = 0.45

@export var approach_gap: float = -100.0

var _interacting := false
var _walker: CharaExplo = null
var _walker_rest_texture: Texture2D = null


func _explo_manager() -> Node:
	return get_tree().current_scene.find_child("ExplorationManager", true, false)



func _lock_party(on: bool) -> void:
	var mgr := _explo_manager()
	if mgr == null or mgr.get("_swapping") == null:
		return
	mgr.set("_swapping", on)
	if mgr.has_method("_refresh_move_button"):
		mgr._refresh_move_button()



func _approach_point(hero: CharaExplo) -> Vector2:
	var obj := SpriteOlder.global_position if SpriteOlder != null else global_position
	var side := -1.0 if hero.global_position.x < obj.x else 1.0


	var obj_edge := obj.x
	if SpriteOlder != null and SpriteOlder.texture != null:
		var tex := SpriteOlder.texture
		var u := _used_rect(tex)
		var sx := absf(SpriteOlder.global_scale.x)
		var left := obj.x + (u.position.x - tex.get_width() * 0.5) * sx
		var right := obj.x + (u.end.x - tex.get_width() * 0.5) * sx
		obj_edge = left if side < 0.0 else right


	var half := 0.0
	var shift := 0.0
	if hero.sprite is Control:
		var r := (hero.sprite as Control).get_global_rect()
		var tex: Texture2D = hero.characterData.peek_texture
		if tex == null:
			tex = hero.sprite.texture
		if tex != null and tex.get_width() > 0:
			var px := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
			var u := _used_rect(tex)
			half = u.size.x * px * 0.5
			shift = r.get_center().x - hero.global_position.x \
					+ (u.get_center().x - tex.get_width() * 0.5) * px

	var x := obj_edge + side * (half + approach_gap) - shift
	# On ne recule jamais : déjà au contact, le personnage reste où il est.
	if side * (x - hero.global_position.x) > 0.0:
		x = hero.global_position.x
	return Vector2(x, hero.global_position.y)


## Zone réellement dessinée d'une texture (mise en cache).
static var _used_cache := {}
static func _used_rect(tex: Texture2D) -> Rect2:
	if _used_cache.has(tex):
		return _used_cache[tex]
	var r := Rect2(Vector2.ZERO, tex.get_size())
	var img := tex.get_image()
	if img != null and img.is_compressed():
		if img.decompress() != OK:
			img = null
	if img != null:
		var u := img.get_used_rect()
		if u.size.x > 0 and u.size.y > 0:
			r = Rect2(u)
	_used_cache[tex] = r
	return r


func _approach() -> void:
	var hero := _active_explo_character()
	if hero == null:
		return
	_lock_party(true)
	_walker = hero
	_walker_rest_texture = hero.sprite.texture
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(hero, "global_position", _approach_point(hero), approach_time)
	await t.finished
	# Arrivé devant l'objet : pose de peek.
	if is_instance_valid(hero) and hero.characterData.peek_texture != null:
		hero.sprite.texture = hero.characterData.peek_texture


## Fin de l'interaction : sprite normal, puis retour à sa place.
func _return_to_place() -> void:
	var hero := _walker
	_walker = null
	if hero != null and is_instance_valid(hero):
		if _walker_rest_texture != null:
			hero.sprite.texture = _walker_rest_texture
		var home: Vector2 = hero.CharaPosition.global_position if hero.CharaPosition != null \
				else hero.global_position
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(hero, "global_position", home, approach_time)
		await t.finished
	_walker_rest_texture = null
	_lock_party(false)
	_interacting = false


# ════════════════════════════════════════════════════════════════════
#  COFFRE PIÉGÉ : attaque de tentacule du Spitter, puis petit dialogue
# ════════════════════════════════════════════════════════════════════

## Compétence dont on rejoue l'animation (image, VFX lanceur et impact).
const TRAP_SKILL := preload("res://actions/ennemiCombatSkills/tentacleAttack.tres")
## Dialogue joué après l'attaque. {A} = personnage actif, {B} = un autre
## membre de l'équipe.
const TRAP_DIALOGUE := "res://dialogue/chest_trap_slime.txt"
## Assombrissement de la salle pendant l'attaque (comme en combat).
@export var trap_veil_alpha: float = 0.6


func _spring_trap(gm: GameManager) -> void:
	button.disabled = true
	_set_outline(false)
	var target := _active_explo_character()
	if target != null:
		await _play_trap_attack(target)
	await _play_trap_dialogue(gm, target)


## Personnage sélectionné en exploration (le « personnage actif »).
func _active_explo_character() -> CharaExplo:
	var mgr := get_tree().current_scene.find_child("ExplorationManager", true, false)
	if mgr != null:
		var c = mgr.get("selected_character")
		if c is CharaExplo and is_instance_valid(c):
			return c
	return null


## Rejoue l'attaque « Tentacles Attack » du Spitter sur `target` : le slime
## jaillit du coffre jusqu'au contact, impact sur le héros, puis il repart.
func _play_trap_attack(target: CharaExplo) -> void:
	var skill: Skill = TRAP_SKILL
	var host := get_parent()

	# Voile sombre sur toute la vue (bloque aussi les clics).
	var veil := ColorRect.new()
	veil.top_level = true
	veil.color = Color(0, 0, 0, 0)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	veil.position = inv * Vector2.ZERO
	veil.size = get_viewport().get_visible_rect().size * inv.get_scale()
	veil.z_as_relative = false
	veil.z_index = 40
	host.add_child(veil)

	# Le héros passe devant le voile.
	var old_z := target.z_index
	var old_rel := target.z_as_relative
	target.z_as_relative = false
	target.z_index = 41

	# Le slime : même repère que le héros (échelle du personnage, sprite
	# décalé comme le sien), pour garder les proportions du combat.
	# Visuel du héros : TextureRect en exploration (Sprite2D en combat). On
	# part de son rectangle à l'écran pour l'échelle « pixel » du dessin.
	var hero_vis = target.sprite
	var hero_rect: Rect2 = hero_vis.get_global_rect() if hero_vis is Control 			else Rect2(hero_vis.global_position, Vector2.ZERO)
	var hero_tex: Texture2D = hero_vis.texture
	var px := 1.0
	if hero_tex != null and hero_rect.size.x > 0.0:
		px = minf(hero_rect.size.x / hero_tex.get_width(), hero_rect.size.y / hero_tex.get_height())
	var hero_center := hero_rect.get_center()
	var k := target.global_scale
	var slime := Node2D.new()
	slime.top_level = true
	slime.z_as_relative = false
	slime.z_index = 42
	var body := Sprite2D.new()
	body.texture = skill.ImageSkill
	body.scale = Vector2(px, px) / k
	body.position = (hero_center - target.global_position) / k
	slime.add_child(body)

	var start := SpriteOlder.global_position if SpriteOlder != null else global_position
	# Côté d'où vient le slime. Les dessins regardent vers la droite : en
	# combat les ennemis (à droite) sont retournés (flip_h), on fait pareil.
	var side := 1.0 if start.x >= target.global_position.x else -1.0
	body.flip_h = side > 0.0
	var reach: float = body.texture.get_width() * px * 0.55
	var dest := target.global_position + Vector2(side * reach, 0)
	# Le personnage est venu jusqu'au coffre : le contact est souvent plus près
	# que le coffre lui-même. Le slime ne doit alors pas reculer, il jaillit
	# sur place (en se dressant un peu) et frappe à bout portant.
	# Le dessin est alors centré sur le coffre : son tentacule part du coffre
	# vers le personnage qui s'y est penché.
	if side * (dest.x - start.x) > 0.0:
		dest.x = start.x - body.position.x * k.x
	slime.global_position = start
	slime.scale = k * 0.3
	slime.modulate.a = 0.0
	host.add_child(slime)
	if skill.caster_effect_scene != null:
		var fx := skill.caster_effect_scene.instantiate()
		slime.add_child(fx)
		fx.scale.x = -1.0 if side > 0.0 else 1.0
		fx.position = Vector2 (140,-60) 

	# Jaillissement jusqu'au contact.
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(veil, "color:a", trap_veil_alpha, 0.15)
	t.tween_property(slime, "modulate:a", 1.0, 0.12)
	t.tween_property(slime, "global_position", dest, 0.25)
	t.tween_property(slime, "scale", k, 0.25)
	await t.finished
	var Hitoffset = Vector2(140,0)
	# Impact : pose « touché », VFX d'impact, petit recul.
	var old_tex: Texture2D = hero_vis.texture
	if target.characterData.Hit_texture != null:
		hero_vis.texture = target.characterData.Hit_texture
	if skill.target_effect_scene != null:
		var hit := skill.target_effect_scene.instantiate()
		target.add_child(hit)
		hit.scale.x = -1.0 if side > 0.0 else 1.0
		hit.global_position = target.global_position + target.characterData.torso_Position * target.scale + Hitoffset
	_apply_trap_damage(target)
	# Surpris le nez dans le coffre : recul net, puis il se reprend.
	var rest := target.position
	var shake := create_tween()
	shake.tween_property(target, "position", rest + Vector2(-side * 45.0, -12.0), 0.08)
	shake.tween_property(target, "position", rest, 0.2)
	await get_tree().create_timer(skill.duration + 0.5).timeout

	# Le slime replonge dans le coffre et file.
	var back := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	back.tween_property(slime, "global_position", start, 0.25)
	back.tween_property(slime, "scale", k * 0.3, 0.25)
	back.tween_property(slime, "modulate:a", 0.0, 0.25)
	back.tween_property(veil, "color:a", 0.0, 0.3)
	await back.finished
	if is_instance_valid(target):
		hero_vis.texture = old_tex
		target.z_index = old_z
		target.z_as_relative = old_rel
	slime.queue_free()
	veil.queue_free()


## Dégâts de stamina du slime piégé. Hors combat le héros n'est jamais mis
## K.O. : la stamina ne descend pas sous 1.
@export var trap_stamina_damage: int = 20
const TRAP_DAMAGE_VFX := preload("res://actions/damageEffect/HitVFX.tscn")

func _apply_trap_damage(target: CharaExplo) -> void:
	var data := target.characterData
	if data == null:
		return
	var before := data.current_stamina
	data.current_stamina = max(1, data.current_stamina - trap_stamina_damage)
	var lost := before - data.current_stamina
	print("🪤 Piège : %s perd %d stamina" % [data.Charaname, lost])
	var fx := TRAP_DAMAGE_VFX.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.z_as_relative = false
	fx.z_index = 43
	fx.global_position = target.global_position + Vector2(50, -140)
	if fx.has_method("setup"):
		fx.setup(lost, Color(1, 0.4, 0.3))
	# Jauge seule : update_display() remettrait le portrait par-dessus la
	# pose « touché » / « peek » en cours.
	if target.hp_Jauge != null:
		target.hp_Jauge.value = data.current_stamina
	# Panneau de stats du HUD (le personnage actif y est affiché).
	var mgr := get_tree().current_scene.find_child("ExplorationManager", true, false)
	if mgr != null and mgr.has_method("_refresh_stats_display"):
		mgr._refresh_stats_display(data)


## « Le slime s'est déjà enfui » : TRAP_DIALOGUE avec les noms de l'équipe.
func _play_trap_dialogue(gm: GameManager, target: CharaExplo) -> void:
	if dialogue_manager == null or not FileAccess.file_exists(TRAP_DIALOGUE):
		return
	var a := target.characterData.Charaname if target != null else ""
	var others: Array[String] = []
	for c in gm.characters:
		if c != null and c.Charaname != a:
			others.append(c.Charaname)
	if a == "":
		a = others.pop_front() if not others.is_empty() else "Narrator"
	var b: String = others.pick_random() if not others.is_empty() else a
	var text := FileAccess.get_file_as_string(TRAP_DIALOGUE).replace("{A}", a).replace("{B}", b)
	# DialogueManager lit un fichier : on écrit la version personnalisée.
	var path := "user://chest_trap_dialogue.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(text)
	f.close()

	var was_choice := dialogue_manager.is_Choice
	dialogue_manager.is_Choice = false
	dialogue_manager.load_dialogue(path)
	if not dialogue_manager.dialogue_lines.is_empty():
		dialogue_manager.start_dialogue()
		await dialogue_manager.dialogue_finished
	# Sans choix, le DialogueManager reste « en cours » à la fin : le clic
	# suivant relançait la fin du dialogue et, is_Choice rétabli, rouvrait
	# les choix du coffre (objet obtenu deux fois).
	dialogue_manager.dialogue_started = false
	dialogue_manager.hideChoix()
	dialogue_manager.is_Choice = was_choice


## Délai avant que la carte d'objet ne parte seule vers le sac.
@export var item_auto_leave: float = 2.0


## Affiche la carte d'objet AU-DESSUS de l'objet interactif, sur un halo ;
## elle part vers le sac au clic ou après item_auto_leave secondes, puis
## l'objet est rangé dans le sac d'équipe.
func _give_item(gm: GameManager, item) -> void:
	if item == null:
		return
	var item_ui = item_ui_scene.instantiate()
	var label: String = item.name
	# Une pile de potions annonce sa quantité sur la carte.
	if item is Potion and item.number > 1:
		label = "%s x%d" % [item.name, item.number]
	item_ui.setObject(item.icon, label)
	item_ui.despawn = true
	item_ui.auto_despawn_delay = item_auto_leave
	get_tree().current_scene.add_child(item_ui)
	_place_card_above(item_ui)
	item_ui.fly_target = _bag_icon_center()
	item_ui.show_glow()
	await item_ui.despawned

	gm.add_to_inventory(item)


## Centre de l'icône du sac dans le HUD (bouton « Sac » créé par
## MapBagButtons, sinon l'ancien bouton de bascule). INF si introuvable.
func _bag_icon_center() -> Vector2:
	var root := get_tree().current_scene
	for n in ["ButtonBag", "ToggleMapInventory"]:
		var b := root.find_child(n, true, false) as Control
		if b != null and b.is_visible_in_tree():
			return b.get_global_rect().get_center()
	return Vector2.INF


## Carte centrée au-dessus du sprite de l'objet.
func _place_card_above(item_ui: Control) -> void:
	var box := item_ui.get_node_or_null("boxUI") as Control
	var card := box.size if box != null else Vector2(141, 141)
	var top := global_position
	if SpriteOlder != null and SpriteOlder.texture != null:
		var h := SpriteOlder.texture.get_height() * SpriteOlder.global_scale.y
		top = SpriteOlder.global_position - Vector2(0, h * 0.5)
	item_ui.global_position = top - Vector2(card.x * 0.5, card.y + 30.0)


## Coffre vide : on le signale quand même, sinon l'ouverture n'a aucun retour.
func _show_empty_chest() -> void:
	var item_ui = item_ui_scene.instantiate()
	item_ui.setObject(null, "Empty...")
	item_ui.despawn = true
	item_ui.auto_despawn_delay = item_auto_leave
	get_tree().current_scene.add_child(item_ui)
	_place_card_above(item_ui)
	await item_ui.despawned


## Applique le visuel "utilisé" : bouton désactivé, étiquette cachée,
## sprite assombri, et éventuellement texture "ouverte".
func _apply_used_state(opened: bool) -> void:
	if opened and openedSprite:
		SpriteOlder.texture = openedSprite
	button.disabled = true
	_set_outline(false)
	if etiquette:
		etiquette.visible = false
	SpriteOlder.modulate = Color(0.6, 0.6, 0.6, 1.0)


func _setup_outline() -> void:
	setup_outline(SpriteOlder, outline_screen_width, outline_color)


func _set_outline(on: bool) -> void:
	set_outline(SpriteOlder, on)


## Contour au survol, partagé avec le bouton du campement en exploration.
static func setup_outline(sprite: Sprite2D, screen_width: float = 2.0,
		color: Color = Color(0.93, 0.78, 0.45, 1.0)) -> void:
	if sprite == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	mat.set_shader_parameter("enabled", false)
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_direction", Vector2.ZERO)
	# Le shader compte en pixels de texture : on compense l'échelle du sprite
	# (souvent 0.25) pour garder un contour visible.
	var k: float = max(0.01, abs(sprite.global_scale.x))
	mat.set_shader_parameter("outline_width", clampf(screen_width / k, 1.0, 200.0))
	sprite.material = mat


static func set_outline(sprite: Sprite2D, on: bool) -> void:
	if sprite != null and sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("enabled", on)


func _on_button_mouse_entered() -> void:
	if button.disabled:
		return
	_set_outline(true)
	etiquette.scale = startsize
	etiquette.visible = true
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(etiquette, "scale", big_size, 0.2)


func _on_button_mouse_exited() -> void:
	_set_outline(false)
	if button.disabled:
		return
	etiquette.scale = big_size

	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(etiquette, "scale", startsize, 0.2)
	await current_tween.finished
	etiquette.visible = false
