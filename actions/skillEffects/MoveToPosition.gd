class_name MoveToPositionEffect
extends SkillEffect

enum Mode { GRAB, PUSH }

@export var mode: Mode = Mode.GRAB
@export var speed : float = 0.5
## Pairing arrière → avant (utilisé par GRAB)
## et avant → arrière (utilisé par PUSH, sens inverse)
## ex: {3: 1, 4: 2} signifie : slot index 3 se tire vers slot index 1
##                              slot index 4 se tire vers slot index 2
@export var slot_pairing: Dictionary = {3: 1, 4: 2}


func apply(user: Character, target: PositionSlot) -> void:
	print (user.characterData.Charaname+" cast mooooooooove Tooooo Position !")
	var cm    := user.combat_manager
	var slots : Array[PositionSlot] = cm.get_positions(target.occupant.characterData.is_player_controlled)

	if not target.occupant.characterData.can_be_moved:
		return

	var target_idx : int = _find_slot_index(slots, target)
	if target_idx == -1:
		push_warning("MoveToPositionEffect : slot cible introuvable dans la liste.")
		return

	match mode:
		Mode.GRAB:
			_do_grab(cm, slots, target, target_idx)
		Mode.PUSH:
			_do_push(cm, slots, target, target_idx)


# ─────────────────────────────────────────────
#  GRAB — tire un ennemi de l'arrière vers l'avant
# ─────────────────────────────────────────────

func _do_grab(cm: CombatManager, slots: Array[PositionSlot], back_slot: PositionSlot, back_idx: int) -> void:
	if not slot_pairing.has(back_idx):
		push_warning("GRAB : la cible n'est pas en position arrière connue (index %d)." % back_idx)
		return

	var front_idx  : int          = slot_pairing[back_idx]
	var front_slot : PositionSlot = _get_slot_by_index(slots, front_idx)
	if front_slot == null:
		push_warning("GRAB : slot avant index %d introuvable." % front_idx)
		return

	var grabbed : Character = back_slot.occupant
	var blocker : Character = front_slot.occupant if front_slot.is_occupied() else null

	if blocker != null and not blocker.characterData.can_be_moved:
		push_warning("GRAB : le personnage en avant ne peut pas être déplacé.")
		return

	# 1. D'abord : tire la cible vers l'avant
	back_slot.remove_character()
	await cm.move_character_to_async(grabbed, front_slot, speed)

	# 2. Ensuite : si la position était occupée, déplace le bloqueur vers l'arrière
	if blocker != null:
		await cm.move_character_to_async(blocker, back_slot, speed)


# ─────────────────────────────────────────────
#  PUSH — pousse un ennemi de l'avant vers l'arrière
# ─────────────────────────────────────────────

func _do_push(cm: CombatManager, slots: Array[PositionSlot], front_slot: PositionSlot, front_idx: int) -> void:
	var back_idx : int = -1
	for k in slot_pairing.keys():
		if slot_pairing[k] == front_idx:
			back_idx = k
			break

	if back_idx == -1:
		push_warning("PUSH : la cible n'est pas en position avant connue (index %d)." % front_idx)
		return

	var back_slot : PositionSlot = _get_slot_by_index(slots, back_idx)
	if back_slot == null:
		push_warning("PUSH : slot arrière index %d introuvable." % back_idx)
		return

	var pushed  : Character = front_slot.occupant
	var blocker : Character = back_slot.occupant if back_slot.is_occupied() else null

	if blocker != null and not blocker.characterData.can_be_moved:
		push_warning("PUSH : le personnage en arrière ne peut pas être déplacé.")
		return

	# 1. D'abord : pousse la cible vers l'arrière
	front_slot.remove_character()
	await cm.move_character_to_async(pushed, back_slot, speed)

	# 2. Ensuite : si la position était occupée, déplace le bloqueur vers l'avant
	if blocker != null:
		await cm.move_character_to_async(blocker, front_slot, speed)


# ─────────────────────────────────────────────
#  Helper
# ─────────────────────────────────────────────

func _find_slot_index(slots: Array[PositionSlot], slot: PositionSlot) -> int:
	for s in slots:
		if s == slot:
			return s.position_data.index
	return -1


func _get_slot_by_index(slots: Array[PositionSlot], idx: int) -> PositionSlot:
	for s in slots:
		if s.position_data.index == idx:
			return s
	return null
