extends RefCounted
class_name PortraitColumn

# ════════════════════════════════════════════════════════════════════
#  COLONNE DE PORTRAITS — sélection du personnage (porte, exploration)
# ════════════════════════════════════════════════════════════════════
#  La scène fournit des cadres (charaPortraitFrame1..4, un par position de
#  la formation). On pose dans chacun le portrait d'exploration du héros qui
#  occupe cette position, et un bouton : cliquer = sélectionner. Le héros
#  sélectionné est pleinement éclairé, les autres un peu éteints.
#
#  Construit par code : les scènes n'ont que les cadres à placer.

const DIM := Color(0.6, 0.6, 0.6, 1)

## Retrait du portrait dans son cadre (mêmes proportions que le cadre du
## portrait sélectionné : 17/185 et 19/176, portrait 146×146).
const INSET := Vector2(17.0 / 185.0, 19.0 / 176.0)
const SIZE := Vector2(146.0 / 185.0, 146.0 / 176.0)


## Crée portraits et boutons dans les cadres. `on_click` reçoit l'index du
## cadre (0 = position 1 de la formation). Renvoie les entrées à passer à
## refresh().
static func build(frames: Array, on_click: Callable) -> Array:
	var entries: Array = []
	for i in frames.size():
		var frame := frames[i] as Control
		if frame == null:
			entries.append({})
			continue
		var parent := frame.get_parent()
		var shown := frame.size * frame.scale
		var rect := Rect2(frame.position + shown * INSET, shown * SIZE)

		var portrait := TextureRect.new()
		portrait.name = "%sPortrait" % frame.name
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.z_index = frame.z_index + 1
		_place(portrait, rect)

		var button := Button.new()
		button.name = "%sButton" % frame.name
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.z_index = frame.z_index + 2
		_place(button, rect)
		button.pressed.connect(on_click.bind(i))
		# Léger grossissement au survol.
		button.mouse_entered.connect(func(): _hover(portrait, true))
		button.mouse_exited.connect(func(): _hover(portrait, false))

		# Ajout différé : souvent appelé depuis un _ready().
		parent.add_child.call_deferred(portrait)
		parent.add_child.call_deferred(button)
		entries.append({"portrait": portrait, "button": button})
	return entries


## `by_slot[i]` = CharacterData en position i (ou null). Le sélectionné est
## éclairé, les autres éteints.
static func refresh(entries: Array, by_slot: Array, selected: CharacterData) -> void:
	for i in entries.size():
		var e: Dictionary = entries[i]
		if e.is_empty():
			continue
		var portrait := e["portrait"] as TextureRect
		var button := e["button"] as Button
		var chara: CharacterData = by_slot[i] if i < by_slot.size() else null
		if not is_instance_valid(portrait):
			continue
		portrait.texture = chara.explorationPortrait if chara != null else null
		portrait.modulate = Color.WHITE if chara != null and chara == selected else DIM
		if is_instance_valid(button):
			button.disabled = chara == null
			button.tooltip_text = chara.Name if chara != null else ""


static func _place(c: Control, rect: Rect2) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = rect.position
	c.size = rect.size
	c.pivot_offset = rect.size * 0.5


static func _hover(portrait: TextureRect, on: bool) -> void:
	if not is_instance_valid(portrait):
		return
	portrait.create_tween().tween_property(portrait, "scale",
			Vector2.ONE * (1.1 if on else 1.0), 0.12)
