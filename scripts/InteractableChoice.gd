# InteractableChoice.gd
extends Resource
class_name InteractableChoice

enum EffectType { NONE, ITEM, BUFF, TAG }

@export var text: String
@export var effect_type: EffectType = EffectType.NONE

# Données selon le type
@export var item: Resource        # Item.tres
@export var buff: Buff       # Buff.tres
@export var tag: String           # ex: "cursed"
