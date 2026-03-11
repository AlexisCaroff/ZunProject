extends Node
class_name GameStat

enum GamePhase { EXPLORATION, COMBAT, CAMP,PEEK, DOOR }
var current_phase: GamePhase = GamePhase.EXPLORATION
var saveRunning :bool = false
