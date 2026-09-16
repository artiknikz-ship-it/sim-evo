# Global.gd
extends Node

# Настройки существ
var creature_settings: Dictionary = {
	"vision_cells_count": 3,
	"metabolism": 0.5,
	"digestion_efficiency": 0.5,
	"reproduction_threshold": 100.0,
	"mutation_rate": 0.05,
	"offspring_energy": 50.0,
	"maturity_age": 5,
	"max_age": 50,
	"fertility_peak": 15,
	"aggression": 0.0,
	"defense": 0.0,
	"sociality": 0.3,
	"energy_storage": 150.0,
	"longevity": 1.0,
	"toxin_resistance": 0.0,
	"hibernation": 0.0,
	"memory_size": 1,
	"learning_rate": 0.1,
	
	"can_eat_meat": true,
	"can_hunt": false,
	"cannibalism": 0.0
}

# Настройки травы
var grass_settings: Dictionary = {
	"grass_initial_count": 100,
	"grass_max_energy": 20.0,
	"grass_growth_rate": 1.0,
	"grass_reproduction_threshold": 5.0,
	"grass_reproduction_cost": 5.0,
	"grass_fertility": 0.5,
	"grass_mutation_chance": 0.04
}
