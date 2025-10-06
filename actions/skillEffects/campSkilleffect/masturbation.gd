extends CampEffect
class_name MasturbationEffect

var tente

func apply(user: CharaCamp, target: CharaCamp):
	var camp = user.camp
	tente=camp.TheTente
	tente.startMasturbation(target)
	camp.After_camp_skill(camp.skillused)
