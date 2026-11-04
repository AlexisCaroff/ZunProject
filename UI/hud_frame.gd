extends RefCounted
class_name HudFrame

# ════════════════════════════════════════════════════════════════════
#  CADRE DU COIN BAS-DROIT DU HUD (carte, sac, cartes d'affinité)
# ════════════════════════════════════════════════════════════════════
#  Les trois vues occupent le même rectangle et partagent un seul cadre,
#  toujours affiché, quelle que soit la vue :
#      dessous : UI_inventory_box_char qui déborde un peu + carré noir
#      dessus  : contour de la carte (UI/contourMap.png)
#  Rangs (z absolus) :
#      fond 5 < carte 6 < sac 7 < cartes 8 = contour 8 < boutons 9
#  (le contour est ajouté après le panneau des cartes : à z égal, il
#  passe devant.)

const BOX := preload("res://UI/UI inventory/UI_inventory_box_char.png")
const CONTOUR := preload("res://UI/contourMap.png")

const Z_BACK := 5
const Z_MAP := 6
const Z_BAG := 7
const Z_PANEL := 8
const Z_BUTTONS := 9

## Débord de la boîte autour du rectangle (gauche, haut, droite, bas).
const OVERHANG := Rect2(10, 12, 10, 8)
## La boîte est dessinée 3× plus grande puis réduite : ses bords (en pixels
## de texture) gardent ainsi une épaisseur proche de l'ancien fond du sac.
const BOX_SCALE := 3.0


## `map_view` : SubViewportContainer de la mini-carte, recalé sur `rect`.
## `old_contour` : ancien cadre de la scène, rendu transparent (ses enfants,
## les boutons du combat par exemple, restent visibles).
## `bag` : panneau du sac, dont le fond propre est retiré.
static func install(parent: Node, rect: Rect2, map_view: Control = null,
		old_contour: CanvasItem = null, bag: Control = null, buttons: Array = []) -> void:
	if old_contour != null:
		old_contour.self_modulate = Color(1, 1, 1, 0)
	if map_view != null:
		fit_map(map_view, rect)
	if bag != null:
		var bg := bag.get_node_or_null("Bg") as CanvasItem
		if bg != null:
			bg.visible = false
		bag.z_as_relative = false
		bag.z_index = Z_BAG
	raise_buttons(buttons)
	# Ajouts différés : install() est appelé depuis des _ready().
	parent.add_child.call_deferred(_make_back(rect))
	parent.add_child.call_deferred(_make_contour(rect))


static func raise_buttons(buttons: Array) -> void:
	for b in buttons:
		if b is CanvasItem and is_instance_valid(b):
			(b as CanvasItem).z_as_relative = false
			(b as CanvasItem).z_index = Z_BUTTONS


## Mini-carte à la taille du rectangle. La carte garde son centre : elle est
## décalée de la moitié de l'écart de taille du SubViewport.
static func fit_map(map_view: Control, rect: Rect2) -> void:
	map_view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map_view.offset_left = rect.position.x
	map_view.offset_top = rect.position.y
	map_view.offset_right = rect.end.x
	map_view.offset_bottom = rect.end.y
	map_view.z_as_relative = false
	map_view.z_index = Z_MAP
	for vp in map_view.get_children():
		if not vp is SubViewport:
			continue
		var old_size := Vector2((vp as SubViewport).size)
		(vp as SubViewport).size = Vector2i(rect.size)
		var shift := (rect.size - old_size) * 0.5
		for n in vp.get_children():
			if n is Node2D:
				(n as Node2D).position += shift


static func _make_back(rect: Rect2) -> Control:
	var back := Control.new()
	back.name = "HudFrameBack"
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back.position = rect.position
	back.size = rect.size
	back.z_as_relative = false
	back.z_index = Z_BACK

	var box := NinePatchRect.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.texture = BOX
	box.patch_margin_left = 16
	box.patch_margin_right = 16
	box.patch_margin_top = 66
	box.patch_margin_bottom = 52
	box.position = -OVERHANG.position
	box.size = (rect.size + OVERHANG.position + OVERHANG.size) * BOX_SCALE
	box.scale = Vector2.ONE / BOX_SCALE
	back.add_child(box)

	var black := ColorRect.new()
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.color = Color.BLACK
	black.size = rect.size
	back.add_child(black)
	return back


static func _make_contour(rect: Rect2) -> NinePatchRect:
	var frame := NinePatchRect.new()
	frame.name = "HudFrameContour"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = CONTOUR
	frame.patch_margin_left = 24
	frame.patch_margin_top = 24
	frame.patch_margin_right = 24
	frame.patch_margin_bottom = 24
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = rect.position
	frame.size = rect.size
	frame.z_as_relative = false
	frame.z_index = Z_PANEL
	return frame


## Rectangle d'un panneau posé par offsets (le sac des scènes).
static func rect_of(c: Control) -> Rect2:
	return Rect2(c.offset_left, c.offset_top,
			c.offset_right - c.offset_left, c.offset_bottom - c.offset_top)
