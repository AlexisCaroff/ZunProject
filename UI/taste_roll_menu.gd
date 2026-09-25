extends Control
class_name TasteRollMenu

# ════════════════════════════════════════════════════════════════════
#  TIRAGE DES ATTIRANCES — écran de début de partie
# ════════════════════════════════════════════════════════════════════
#  S'ouvre après le menu principal, avant la première salle. Chaque héros
#  voit son attirance tirée au sort (CharacterData.roll_taste), affichée
#  par deux glyphes : carré = attiré par le masculin, triangle = attiré
#  par le féminin. Blanc = actif, gris = inactif.
#
#  Le GENRE des héros (CharacterData.presentation) ne se tire PAS : il se
#  règle dans l'inspecteur, parce que les scènes d'amour sont dessinées
#  avec des corps précis.
#
#  Les cases sont construites par code à partir de gm.characters : la
#  taille de l'équipe peut changer sans retoucher la scène. La position
#  de la grille est exportée pour se régler à la souris dans l'éditeur.
#
#  Le GameManager attend le signal `finished` avant de charger le donjon.
# ════════════════════════════════════════════════════════════════════

signal finished

const SYM_MASC := preload("res://UI/symbols/SYM_attracted_masculine.png")
const SYM_FEM  := preload("res://UI/symbols/SYM_attracted_feminine.png")
const DIAMOND_FRAME := preload("res://UI/UI boxes/UI_affinity_portait_frame.png")
const DIAMOND_MASK  := preload("res://UI/diamond_mask.gdshader")
const GLOW_TEX      := preload("res://UI/symbols/FX_title_glow.png")

## Couleur d'un glyphe actif / inactif.
const SYM_ON  := Color(1, 1, 1, 1)
const SYM_OFF := Color(0.28, 0.28, 0.28, 1)

## Résolution du portrait recadré. Le losange fait 160 px à l'écran ; les
## sources font 2048², inutile de les garder telles quelles en mémoire.
const PORTRAIT_TEXTURE_PX := 256

@export_group("Mise en page")
## Coin haut-gauche de la grille, en coordonnées locales de la boîte.
@export var slot_origin: Vector2 = Vector2(105, 332)
## Écart entre deux cases (colonne, ligne).
@export var slot_spacing: Vector2 = Vector2(432, 186)
@export var slot_columns: int = 2
## Taille du losange de portrait.
@export var portrait_size: float = 160.0
## Serrage du cadrage sur la tête : 1 = toute la largeur du personnage,
## 0.7 = plus près du visage.
@export_range(0.3, 1.5, 0.05) var portrait_zoom: float = 0.95
## Cadrage vertical : 0 = haut du personnage, 0.5 = milieu du buste.
@export_range(0.0, 1.0, 0.05) var portrait_head_bias: float = 0.05
## Position des deux glyphes dans la case, relative à son coin haut-gauche.
@export var symbol_offset: Vector2 = Vector2(212, 50)
@export var symbol_size: float = 60.0
@export var symbol_gap: float = 74.0

@export_group("Tirage")
## Probabilité d'être attiré par les deux.
@export_range(0.0, 1.0, 0.05) var bi_chance: float = 0.25
## Durée du défilement des glyphes avant de se figer.
@export var roll_spin_time: float = 0.9
## Décalage entre deux personnages, pour que le tirage se lise un par un.
@export var stagger: float = 0.14
## Cadence du clignotement pendant le tirage.
@export var flicker_step: float = 0.06

@export_group("Fin du tirage")
## Taille du bouton « Let's go » pendant le tirage (il reste cliquable).
@export var go_rolling_scale: float = 0.85
## Taille du bouton une fois le tirage terminé.
@export var go_ready_scale: float = 1.15
## Taille du halo sous chaque portrait, relative au losange.
@export var glow_size: float = 1.9
## Opacité du halo au repos, une fois l'éclat initial retombé.
@export_range(0.0, 1.0, 0.05) var glow_rest_alpha: float = 0.55
## Durée d'une respiration du halo au repos.
@export var glow_pulse_time: float = 1.6

@onready var box: TextureRect = $CanvasLayer/Box
@onready var slots_root: Control = $CanvasLayer/Box/Slots
@onready var roll_button: Button = $CanvasLayer/RollButton
@onready var bi_button: Button = $CanvasLayer/BiButton
@onready var go_button: Button = $CanvasLayer/GoButton

## Les CharacterData à tirer. Renseigné par le GameManager avant l'ajout
## à l'arbre ; à défaut on va les chercher nous-mêmes.
var characters: Array[CharacterData] = []

## Une entrée par case : { data, root, fem, masc, portrait }
var _slots: Array[Dictionary] = []
var _rolling: bool = false
## Vrai dès que le joueur a validé : les tirages en cours s'arrêtent net.
var _closing: bool = false
var _go_tween: Tween = null


func _ready() -> void:
	if characters.is_empty():
		var gm := get_tree().root.get_node_or_null("GameManager") as GameManager
		if gm != null:
			characters = gm.characters

	roll_button.pressed.connect(roll_all)
	bi_button.pressed.connect(_on_make_them_bi)
	go_button.pressed.connect(_on_go)

	_build_slots()
	_set_go_ready(false, true)
	# Le menu s'ouvre en tirant tout seul : le joueur voit le hasard à
	# l'œuvre, il n'a pas à le déclencher.
	roll_all()


# ════════════════════════════════════════════════════════════════════
#  CONSTRUCTION DES CASES
# ════════════════════════════════════════════════════════════════════

func _build_slots() -> void:
	for child in slots_root.get_children():
		child.queue_free()
	_slots.clear()

	for i in characters.size():
		var data: CharacterData = characters[i]
		if data == null:
			continue
		var col: int = i % max(1, slot_columns)
		var row: int = i / max(1, slot_columns)
		var slot := _make_slot(data)
		slot["root"].position = slot_origin + Vector2(
			col * slot_spacing.x, row * slot_spacing.y)
		slots_root.add_child(slot["root"])
		_slots.append(slot)
		# État de départ : les deux glyphes éteints, le tirage les allume.
		_paint(slot, false, false)


func _make_slot(data: CharacterData) -> Dictionary:
	var root := Control.new()
	root.name = "Slot_" + data.Charaname
	root.custom_minimum_size = Vector2(slot_spacing.x, slot_spacing.y)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ── Halo sous le portrait, allumé à la fin du tirage ────────────
	# Premier enfant = dessiné derrière le cadre et le portrait.
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = GLOW_TEX
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = glow_mat
	glow.modulate.a = 0.0
	root.add_child(glow)
	var glow_px := portrait_size * glow_size
	_place(glow, Vector2.ONE * (portrait_size - glow_px) * 0.5, Vector2(glow_px, glow_px))

	# Le portrait d'exploration est déjà un losange avec son propre cadre :
	# on l'affiche tel quel. Sinon on retombe sur l'ancien montage (cadre +
	# buste recadré et découpé par le shader).
	var portrait: TextureRect
	if data.explorationPortrait != null:
		portrait = TextureRect.new()
		portrait.name = "Portrait"
		portrait.texture = data.explorationPortrait
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(portrait)
		_place(portrait, Vector2.ZERO, Vector2(portrait_size, portrait_size))
	else:
		portrait = _make_cropped_portrait(root, data)

	# ── Bouton de re-tirage individuel ──────────────────────────────
	var btn := Button.new()
	btn.name = "Reroll"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.tooltip_text = "%s — clic pour retirer au sort" % data.Name
	root.add_child(btn)
	_place(btn, Vector2.ZERO, Vector2(portrait_size, portrait_size))

	# ── Les deux glyphes ────────────────────────────────────────────
	var masc := _make_symbol(SYM_MASC, symbol_offset)
	var fem := _make_symbol(SYM_FEM, symbol_offset + Vector2(symbol_gap, 0))
	root.add_child(masc)
	root.add_child(fem)
	_place(masc, masc.get_meta("place_pos"), Vector2(symbol_size, symbol_size))
	_place(fem, fem.get_meta("place_pos"), Vector2(symbol_size, symbol_size))

	var slot := {
		"data": data,
		"root": root,
		"fem": fem,
		"masc": masc,
		"portrait": portrait,
		"glow": glow,
		"done": false,
	}
	btn.pressed.connect(func(): _reroll_one(slot))
	return slot


## Ancien montage, pour un personnage sans portrait d'exploration : cadre
## losange + buste recadré sur la tête et découpé par le shader.
func _make_cropped_portrait(root: Control, data: CharacterData) -> TextureRect:
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = DIAMOND_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	_place(frame, Vector2.ZERO, Vector2(portrait_size, portrait_size))

	# ── Portrait, découpé en losange par le shader ──────────────────
	# Le cadre a un intérieur opaque : le portrait passe PAR-DESSUS,
	# rentré de quelques pixels pour laisser voir la bordure dorée.
	# STRETCH_SCALE (et pas COVERED) : la texture remplit exactement le
	# rectangle, donc les UV du shader collent au losange. C'est le carré
	# découpé dans la source par _square_crop() qui évite la déformation.
	var inset := portrait_size * 0.09
	var side := portrait_size - inset * 2.0
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = _square_crop(_portrait_of(data))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = DIAMOND_MASK
	portrait.material = mat
	root.add_child(portrait)
	_place(portrait, Vector2(inset, inset), Vector2(side, side))
	return portrait


func _make_symbol(tex: Texture2D, pos: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = SYM_OFF
	rect.set_meta("place_pos", pos)
	return rect


## Pose un Control en absolu. On écrit les offsets plutôt que position/size :
## `size` est recalculé à l'entrée dans l'arbre, les offsets non — sans ça
## les portraits reprenaient la taille native de leur texture.
func _place(c: Control, pos: Vector2, size_px: Vector2) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.offset_left = pos.x
	c.offset_top = pos.y
	c.offset_right = pos.x + size_px.x
	c.offset_bottom = pos.y + size_px.y
	c.custom_minimum_size = size_px
	c.pivot_offset = size_px * 0.5


## Cadre le portrait sur la tête. Les portraits de dialogue sont des bustes
## posés dans une grande zone transparente : découper bêtement un carré
## donnerait un visage minuscule perdu au milieu du vide. On cherche donc
## la zone réellement dessinée, puis on prend un carré en haut de celle-ci.
func _square_crop(src: Texture2D) -> Texture2D:
	if src == null:
		return null
	var s: Vector2 = src.get_size()
	if s.x <= 0.0 or s.y <= 0.0:
		return src

	# On recopie réellement les pixels au lieu d'utiliser une AtlasTexture :
	# une atlas décale les UV, et le shader de masque losange — qui travaille
	# en UV 0..1 — découperait alors de travers.
	var img := src.get_image()
	if img == null:
		return src
	if img.is_compressed() and img.decompress() != OK:
		return src

	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		used = Rect2i(Vector2i.ZERO, Vector2i(int(s.x), int(s.y)))

	var side: int = int(min(float(used.size.x) * portrait_zoom, float(used.size.y)))
	side = mini(side, mini(int(s.x), int(s.y)))
	if side <= 1:
		return src

	var x: int = used.position.x + int(float(used.size.x - side) * 0.5)
	var y: int = used.position.y + int(float(used.size.y - side) * portrait_head_bias)
	x = clampi(x, 0, int(s.x) - side)
	y = clampi(y, 0, int(s.y) - side)

	var crop := Image.create(side, side, false, img.get_format())
	crop.blit_rect(img, Rect2i(x, y, side, side), Vector2i.ZERO)
	# Les portraits sources font 2048² : on redescend à une taille d'icône,
	# le losange ne fait que 160 px à l'écran.
	crop.resize(PORTRAIT_TEXTURE_PX, PORTRAIT_TEXTURE_PX, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(crop)


## Le portrait de dialogue est le buste cadré serré ; on retombe sur les
## autres textures si un personnage n'en a pas.
func _portrait_of(data: CharacterData) -> Texture2D:
	if data.Dialogue_texture != null:
		return data.Dialogue_texture
	if data.explorationPortrait != null:
		return data.explorationPortrait
	return data.portrait_texture


# ════════════════════════════════════════════════════════════════════
#  TIRAGE
# ════════════════════════════════════════════════════════════════════

func roll_all() -> void:
	if _rolling:
		return
	_rolling = true
	_set_controls_enabled(false)
	_set_go_ready(false)
	_spin_dice()

	for i in _slots.size():
		_set_glow(_slots[i], false)
		_roll_slot(_slots[i], i * stagger)

	var total: float = roll_spin_time + stagger * float(max(0, _slots.size() - 1)) + 0.2
	await get_tree().create_timer(total).timeout
	if not is_inside_tree() or _closing:
		return
	_rolling = false
	_set_controls_enabled(true)
	_set_go_ready(true)
	for slot in _slots:
		_set_glow(slot, true)


func _reroll_one(slot: Dictionary) -> void:
	if _rolling:
		return
	_rolling = true
	_set_controls_enabled(false)
	_set_glow(slot, false)
	await _roll_slot(slot, 0.0)
	if not is_inside_tree() or _closing:
		return
	_rolling = false
	_set_controls_enabled(true)
	_set_glow(slot, true)


## Fait défiler les glyphes au hasard, puis fige le résultat du tirage.
func _roll_slot(slot: Dictionary, delay: float) -> void:
	slot["done"] = false
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	# _closing : le joueur a validé pendant le tirage, _on_go a déjà figé
	# le résultat de cette case.
	if not is_inside_tree() or _closing:
		return

	var elapsed: float = 0.0
	while elapsed < roll_spin_time:
		await get_tree().create_timer(flicker_step).timeout
		if not is_inside_tree() or _closing:
			return
		elapsed += flicker_step
		_paint(slot, randf() < 0.5, randf() < 0.5)

	_finish_slot(slot)
	_pop(slot)


## Tire et affiche le résultat définitif d'une case.
func _finish_slot(slot: Dictionary) -> void:
	var data: CharacterData = slot["data"]
	data.roll_taste(bi_chance)
	_paint(slot, data.attracted_to_feminine, data.attracted_to_masculine)
	slot["done"] = true
	print("🎲 %s → %s" % [data.Charaname, data.taste_label()])


func _paint(slot: Dictionary, feminine: bool, masculine: bool) -> void:
	var fem: TextureRect = slot["fem"]
	var masc: TextureRect = slot["masc"]
	if not is_instance_valid(fem) or not is_instance_valid(masc):
		return
	fem.modulate = SYM_ON if feminine else SYM_OFF
	masc.modulate = SYM_ON if masculine else SYM_OFF


## Petit rebond sur les glyphes au moment où le résultat se fige.
func _pop(slot: Dictionary) -> void:
	for key in ["fem", "masc"]:
		var rect: TextureRect = slot[key]
		if not is_instance_valid(rect):
			continue
		rect.scale = Vector2(1.45, 1.45)
		var tween := create_tween()
		tween.tween_property(rect, "scale", Vector2.ONE, 0.25) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spin_dice() -> void:
	var icon := roll_button.get_node_or_null("Dice")
	if icon == null:
		return
	var tween := create_tween()
	tween.tween_property(icon, "rotation", icon.rotation + TAU * 2.0, roll_spin_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ════════════════════════════════════════════════════════════════════
#  BOUTONS
# ════════════════════════════════════════════════════════════════════

## Raccourci accessibilité : tout le monde attiré par tout le monde, aucune
## paire n'est fermée.
func _on_make_them_bi() -> void:
	if _rolling:
		return
	for slot in _slots:
		var data: CharacterData = slot["data"]
		data.set_taste(true, true)
		_paint(slot, true, true)
		_pop(slot)
		_set_glow(slot, true)


## Cliquable même pendant le tirage : les cases pas encore figées reçoivent
## leur résultat tout de suite, sinon elles le tireraient après coup, une fois
## la partie lancée.
func _on_go() -> void:
	if _closing:
		return
	_closing = true
	for slot in _slots:
		if not slot["done"]:
			_finish_slot(slot)
	_rolling = false
	_set_controls_enabled(false)
	go_button.disabled = true
	emit_signal("finished")


## Le bouton « Let's go » n'est PAS concerné : il reste actif pendant le tirage.
func _set_controls_enabled(on: bool) -> void:
	roll_button.disabled = not on
	bi_button.disabled = not on
	for slot in _slots:
		var btn := (slot["root"] as Control).get_node_or_null("Reroll") as Button
		if btn != null:
			btn.disabled = not on


# ════════════════════════════════════════════════════════════════════
#  FIN DU TIRAGE — bouton et halos
# ════════════════════════════════════════════════════════════════════

## Petit pendant le tirage, il grossit d'un coup quand tout est figé.
## normal_scale / hover_scale sont ceux de lvl/button.gd : le survol repart
## de la nouvelle taille au lieu de la ramener à 1.
func _set_go_ready(is_ready: bool, instant: bool = false) -> void:
	var target := Vector2.ONE * (go_ready_scale if is_ready else go_rolling_scale)
	go_button.set("normal_scale", target)
	go_button.set("hover_scale", target * 1.1)
	if _go_tween:
		_go_tween.kill()
	if instant:
		go_button.scale = target
		return
	_go_tween = create_tween()
	if is_ready:
		_go_tween.tween_property(go_button, "scale", target, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_go_tween.tween_property(go_button, "scale", target, 0.2) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Halo sous le portrait : un éclat quand la case est figée, puis une lente
## respiration. `on = false` l'éteint (nouveau tirage).
func _set_glow(slot: Dictionary, on: bool) -> void:
	var glow: TextureRect = slot.get("glow")
	if not is_instance_valid(glow):
		return
	var old: Tween = slot.get("glow_tween")
	if old:
		old.kill()
	var tween := create_tween()
	slot["glow_tween"] = tween
	if not on:
		tween.tween_property(glow, "modulate:a", 0.0, 0.15)
		return

	glow.scale = Vector2.ONE * 0.5
	glow.modulate.a = 0.0
	# Éclat
	tween.set_parallel(true)
	tween.tween_property(glow, "scale", Vector2.ONE * 1.15, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "modulate:a", 1.0, 0.2)
	tween.set_parallel(false)
	tween.tween_property(glow, "scale", Vector2.ONE, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(glow, "modulate:a", glow_rest_alpha, 0.35)
	# Respiration, sans fin (le tween meurt avec le menu)
	tween.tween_callback(func(): _breathe_glow(slot))


func _breathe_glow(slot: Dictionary) -> void:
	var glow: TextureRect = slot.get("glow")
	if not is_instance_valid(glow):
		return
	var tween := create_tween().set_loops()
	slot["glow_tween"] = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", glow_rest_alpha * 0.55, glow_pulse_time * 0.5)
	tween.tween_property(glow, "modulate:a", glow_rest_alpha, glow_pulse_time * 0.5)
