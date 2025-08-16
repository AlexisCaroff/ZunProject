extends TextureRect

func activate(tex,duration:float):

	if tex != null:
		
	# Affecter la texture et rendre visible
		texture = tex
		visible = true
		
		# Attendre "duration" secondes
		await get_tree().create_timer(duration).timeout
		
		# Cacher après le délai
		visible = false
