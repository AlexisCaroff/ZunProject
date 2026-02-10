extends Node2D
@onready var actionpoints: Array[TextureRect]= [
	$HBoxContainer2/DotAction1,
	$HBoxContainer2/DotAction2,
	$HBoxContainer2/DotAction3,
	$HBoxContainer2/DotAction4,
	$HBoxContainer2/DotAction5
]

@onready var HPProgressBar= $HPProgressBar
@onready var LustProgressBar=$LustProgressBar
@onready var HornyBar=$HornyJauge/HornyJaugePleine
@onready var TheHornyBar=$HornyJauge

func getHpbar():
	HPProgressBar= $HPProgressBar
	return  HPProgressBar
func getLustbar():
	LustProgressBar=$LustProgressBar
	return LustProgressBar
func getactionpoints():
	actionpoints= [
	$HBoxContainer2/DotAction1,
	$HBoxContainer2/DotAction2,
	$HBoxContainer2/DotAction3,
	$HBoxContainer2/DotAction4,
	$HBoxContainer2/DotAction5
	]
	return actionpoints
func get_HornyBar():
	HornyBar=$HornyJauge/HornyJaugePleine
	return HornyBar
