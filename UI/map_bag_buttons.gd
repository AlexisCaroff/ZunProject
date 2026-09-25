extends RefCounted
class_name MapBagButtons

# ════════════════════════════════════════════════════════════════════
#  BOUTONS CARTE / SAC CÔTE À CÔTE
# ════════════════════════════════════════════════════════════════════
#  Les scènes (exploration, porte, combat) n'ont qu'un bouton de bascule
#  carte ↔ sac. On le dédouble par code : l'original devient le bouton
#  « Carte », sa copie posée juste à sa gauche le bouton « Sac ». Chaque
#  bouton affiche toujours la même icône ; celui de la vue active est
#  allumé, l'autre grisé.
#
#  Usage :
#      var pair := MapBagButtons.split(toggle, map_tex, bag_tex, 88.0)
#      pair.map.pressed.connect(func(): _show_inventory(false))
#      pair.bag.pressed.connect(func(): _show_inventory(true))
#      MapBagButtons.set_active(pair, showing_inventory)
# ════════════════════════════════════════════════════════════════════

const ACTIVE := Color(1, 1, 1, 1)
const INACTIVE := Color(0.55, 0.55, 0.55, 1)

## Noms des icônes présentes selon les scènes. La première trouvée porte
## l'icône du bouton ; les autres sont masquées.
const ICON_NAMES := ["IconBag", "IconMap", "IconMapToggle"]
## Cadre posé sous l'icône quand le bouton n'en a pas déjà un.
const BOX_TEX := preload("res://UI/UI boxes/UI_combat_itembox.png")


## Dédouble `toggle`. `spacing` = distance entre les deux boutons, dans le
## repère du parent du bouton. Renvoie { map: Button, bag: Button }.
static func split(toggle: Button, map_tex: Texture2D, bag_tex: Texture2D,
		spacing: float) -> Dictionary:
	# Textures laissées à null : on reprend celles que la scène porte déjà.
	if map_tex == null:
		map_tex = _texture_of(toggle, ["IconMapToggle", "IconMap"])
	if bag_tex == null:
		bag_tex = _texture_of(toggle, ["IconBag"])
	# Sans DUPLICATE_SIGNALS : les connexions du bouton d'origine (bascule)
	# ne doivent pas être recopiées sur le bouton sac.
	var bag := toggle.duplicate(Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_GROUPS) as Button
	bag.name = "ButtonBag"
	bag.offset_left -= spacing
	bag.offset_right -= spacing
	# Ajout différé : split() est souvent appelé depuis un _ready(), quand le
	# parent est encore occupé à ajouter ses enfants — un add_child direct
	# échoue alors en silence et le bouton sac n'apparaît jamais.
	var parent := toggle.get_parent()
	parent.add_child.call_deferred(bag)
	parent.move_child.call_deferred(bag, toggle.get_index())

	_set_icon(toggle, map_tex)
	_set_icon(bag, bag_tex)
	add_hover(toggle)
	add_hover(bag)
	toggle.tooltip_text = "Map"
	bag.tooltip_text = "Party bag"
	return {"map": toggle, "bag": bag}


## Allume le bouton de la vue affichée, grise l'autre.
static func set_active(pair: Dictionary, showing_inventory: bool) -> void:
	var map_btn := pair.get("map") as CanvasItem
	var bag_btn := pair.get("bag") as CanvasItem
	if is_instance_valid(map_btn):
		map_btn.modulate = INACTIVE if showing_inventory else ACTIVE
	if is_instance_valid(bag_btn):
		bag_btn.modulate = ACTIVE if showing_inventory else INACTIVE


## Place les boutons au-dessus de tout ce qui occupe le coin (panneau du
## sac compris), quelle que soit leur profondeur dans l'arbre.
static func raise(pair: Dictionary, z: int) -> void:
	for key in ["map", "bag"]:
		var b := pair.get(key) as CanvasItem
		if is_instance_valid(b):
			b.z_as_relative = false
			b.z_index = z


## Donne un cadre au bouton s'il n'en porte pas déjà un (même cadre que les
## cases d'objet). `size_px` = côté du cadre, dans le repère du bouton.
static func ensure_box(button: Button, size_px: float = 81.0) -> void:
	for n in button.find_children("*", "Sprite2D", true, false):
		if (n as Sprite2D).texture == BOX_TEX:
			return
	var box := Sprite2D.new()
	box.name = "Box"
	box.texture = BOX_TEX
	box.show_behind_parent = true
	# Offsets et non `size` : le bouton sac n'est pas encore dans l'arbre.
	box.position = Vector2(button.offset_right - button.offset_left,
			button.offset_bottom - button.offset_top) * 0.5
	box.scale = Vector2.ONE * (size_px / float(BOX_TEX.get_width()))
	button.add_child(box)
	button.move_child(box, 0)


## Léger grossissement au survol, comme les boutons du combat. Un bouton
## qui porte déjà lvl/button.gd (combat) a le sien : on n'y touche pas.
static func add_hover(button: Button, factor: float = 1.15) -> void:
	if "hover_scale" in button:
		return
	var rest := button.scale
	button.pivot_offset = Vector2(button.offset_right - button.offset_left,
			button.offset_bottom - button.offset_top) * 0.5
	button.mouse_entered.connect(func():
		button.create_tween().tween_property(button, "scale", rest * factor, 0.15) 				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT))
	button.mouse_exited.connect(func():
		button.create_tween().tween_property(button, "scale", rest, 0.15) 				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT))


static func _texture_of(button: Button, names: Array) -> Texture2D:
	for n in names:
		var s := button.get_node_or_null(n) as Sprite2D
		if s != null and s.texture != null:
			return s.texture
	return null


static func _set_icon(button: Button, tex: Texture2D) -> void:
	var main: Sprite2D = null
	for n in ICON_NAMES:
		var s := button.get_node_or_null(n) as Sprite2D
		if s == null:
			continue
		if main == null:
			main = s
			s.visible = true
		else:
			s.visible = false
	if main != null and tex != null:
		main.texture = tex
