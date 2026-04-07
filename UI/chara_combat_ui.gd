extends Node2D
class_name CharaUi

@onready var actionpoints: Array[TextureRect] = [
	$HBoxContainer2/DotAction1,
	$HBoxContainer2/DotAction2,
	$HBoxContainer2/DotAction3,
	$HBoxContainer2/DotAction4,
	$HBoxContainer2/DotAction5
]

@onready var HPProgressBar          = $HPProgressBar
@onready var LustProgressBar        = $LustProgressBar
@onready var LustProgressBarSeparator = $HBoxContainer3
@onready var HornyBar               = $HornyJauge/HornyJaugePleine
@onready var TheHornyBar            = $HornyJauge
## HBoxContainer dédié aux icônes de buff — à créer dans chara_combat_ui.tscn, nommé "BuffBar"
@onready var buff_bar: HBoxContainer = $BuffBar

func getHpbar():
	HPProgressBar = $HPProgressBar
	return HPProgressBar

func getLustbar():
	LustProgressBar = $LustProgressBar
	return LustProgressBar

func getactionpoints():
	actionpoints = [
		$HBoxContainer2/DotAction1,
		$HBoxContainer2/DotAction2,
		$HBoxContainer2/DotAction3,
		$HBoxContainer2/DotAction4,
		$HBoxContainer2/DotAction5
	]
	return actionpoints

func get_HornyBar():
	HornyBar = $HornyJauge/HornyJaugePleine
	return HornyBar

func get_buff_bar() -> HBoxContainer:
	return buff_bar
