class_name SimulationEditor
extends PanelContainer

signal apply_settings(settings: Dictionary)

# Ссылки на SpinBox'ы
var creature_spinboxes: Dictionary = {}
var grass_spinboxes: Dictionary = {}

func _ready():
	_collect_spinboxes()
	_load_current_settings()

func _collect_spinboxes():
	var vbox = $ScrollContainer/VBoxContainer
	
	# Существа
	creature_spinboxes = {
		"vision_cells_count": vbox.get_node("HBoxContainer/vision_cells_count"),
		"metabolism": vbox.get_node("HBoxContainer2/metabolism"),
		"digestion_efficiency": vbox.get_node("HBoxContainer3/digestion_efficiency"),
		"reproduction_threshold": vbox.get_node("HBoxContainer4/reproduction_threshold"),
		"mutation_rate": vbox.get_node("HBoxContainer5/mutation_rate"),
		"offspring_energy": vbox.get_node("HBoxContainer6/offspring_energy"),
		"maturity_age": vbox.get_node("HBoxContainer7/maturity_age"),
		"max_age": vbox.get_node("HBoxContainer8/max_age"),
		"fertility_peak": vbox.get_node("HBoxContainer9/fertility_peak"),
		"aggression": vbox.get_node("HBoxContainer10/aggression"),
		"defense": vbox.get_node("HBoxContainer11/defense"),
		"sociality": vbox.get_node("HBoxContainer12/sociality"),
		"energy_storage": vbox.get_node("HBoxContainer13/energy_storage"),
		"longevity": vbox.get_node("HBoxContainer14/longevity"),
		"toxin_resistance": vbox.get_node("HBoxContainer15/toxin_resistance"),
		"hibernation": vbox.get_node("HBoxContainer16/hibernation"),
		"memory_size": vbox.get_node("HBoxContainer17/memory_size"),
		"learning_rate": vbox.get_node("HBoxContainer18/learning_rate")
	}
	
	# Трава
	grass_spinboxes = {
		"grass_initial_count": vbox.get_node("HBoxContainer19/grass_initial_count"),
		"grass_max_energy": vbox.get_node("HBoxContainer20/grass_max_energy"),
		"grass_growth_rate": vbox.get_node("HBoxContainer21/grass_growth_rate"),
		"grass_reproduction_threshold": vbox.get_node("HBoxContainer22/grass_reproduction_threshold"),
		"grass_reproduction_cost": vbox.get_node("HBoxContainer23/grass_reproduction_cost"),
		"grass_fertility": vbox.get_node("HBoxContainer24/grass_fertility"),
		"grass_mutation_chance": vbox.get_node("HBoxContainer25/grass_mutation_chance")
	}

func _load_current_settings():
	for key in creature_spinboxes:
		if Global.creature_settings.has(key):
			creature_spinboxes[key].value = Global.creature_settings[key]
	
	for key in grass_spinboxes:
		if Global.grass_settings.has(key):
			grass_spinboxes[key].value = Global.grass_settings[key]

func _on_apply_pressed():
	var settings = {
		"creature": {},
		"grass": {}
	}
	
	for key in creature_spinboxes:
		settings.creature[key] = creature_spinboxes[key].value
	
	for key in grass_spinboxes:
		settings.grass[key] = grass_spinboxes[key].value
	
	print("Применяем настройки: ", settings)
	emit_signal("apply_settings", settings)
