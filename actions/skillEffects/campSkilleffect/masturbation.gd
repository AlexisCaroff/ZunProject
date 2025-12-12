extends CampEffect
class_name MasturbationEffect

var thetente

func apply(user: CharaCamp, target: CharaCamp):
	var camp = user.camp
	thetente=camp.TheTente
	thetente.startMasturbation(target)
	camp.After_camp_skill(camp.skillused)
