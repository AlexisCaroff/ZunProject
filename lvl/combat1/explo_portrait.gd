extends Sprite2D
var occupant : CharaExplo
@onready var button= $Button
@onready var explorationManager = $"../../ExplorationManager"
func _ready():
	
	button.button_down.connect(clicOnPorttrait)
func set_occupant(Chara:CharaExplo):
	occupant=Chara
	self.texture= Chara.explorationPortrait
	
func clicOnPorttrait():
	explorationManager.selectCharacter(occupant)
	explorationManager.portrait_selector.position=self.position
	
	
