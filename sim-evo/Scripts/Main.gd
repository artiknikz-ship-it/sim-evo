extends Node2D

var is_paused: bool = false
var simulation_speed: float = 1.0
var tick_timer: float = 0.0
var tick_interval: float = 1.0

# Статистика
var total_born: int = 0
var total_died: int = 0
var simulation_ticks: int = 0
var simulation_time: float = 0.0

@onready var pause_button: Button = $UILayer/ControlPanel/VBoxContainer/HBoxContainer/PauseButton
@onready var step_button: Button = $UILayer/ControlPanel/VBoxContainer/HBoxContainer/StepButton
@onready var restart_button: Button = $UILayer/ControlPanel/VBoxContainer/HBoxContainer/RestartButton
@onready var speed_slider: HSlider = $UILayer/ControlPanel/VBoxContainer/HBoxContainer2/SpeedSlider
@onready var speed_value_label: Label = $UILayer/ControlPanel/VBoxContainer/HBoxContainer2/SpeedValueLabel
@onready var ticks_label: Label = $UILayer/ControlPanel/VBoxContainer/HBoxContainer3/TicksLabel
@onready var time_label: Label = $UILayer/ControlPanel/VBoxContainer/HBoxContainer3/TimeLabel

@onready var population_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/PopulationLabel
@onready var total_born_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/TotalBornLabel
@onready var total_died_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/TotalDiedLabel
@onready var grass_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/GrassLabel
@onready var meat_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/MeatLabel
@onready var avg_energy_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/AvgEnergyLabel
@onready var avg_age_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/AvgAgeLabel
@onready var avg_speed_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/AvgSpeedLabel
@onready var population_graph: PopulationGraph = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/PopulationGraph
@onready var simulation_editor: SimulationEditor = $UILayer/SimulationEditor
@onready var herbivores_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/HerbivoresLabel
@onready var omnivores_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/OmnivoresLabel
@onready var carnivores_label: Label = $UILayer/StatsPanel/ScrollContainer/VBoxContainer/CarnivoresLabel

@onready var world: Node2D = $World

func _ready():
	pause_button.pressed.connect(_on_pause_pressed)
	step_button.pressed.connect(_on_step_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	speed_slider.value_changed.connect(_on_speed_changed)
	simulation_editor.apply_settings.connect(_on_apply_settings)
	
	_update_ui()

func _process(delta):
	if not is_paused:
		tick_timer += delta * simulation_speed
		simulation_time += delta
		
		while tick_timer >= tick_interval:
			_process_tick()
			tick_timer -= tick_interval
		
		_update_time_label()

func _process_tick():
	simulation_ticks += 1
	# Запоминаем популяцию до обновления
	var old_population = world.creature_data.size()
	
	world._update_grass()
	world._update_creatures()
	world._update_meat()
	
	# Подсчёт родившихся и умерших
	var new_population = world.creature_data.size()
	if new_population > old_population:
		total_born += new_population - old_population
	elif new_population < old_population:
		total_died += old_population - new_population
	
	_update_ui()
	
	var herbivores = 0
	var carnivores = 0
	var omnivores = 0
	
	for pos in world.creature_data:
		var creature = world.creature_data[pos]
		match creature.diet_type:
			0: herbivores += 1
			1: carnivores += 1
			2: omnivores += 1
	
	population_graph.add_data_point(herbivores, carnivores, omnivores)

func _on_pause_pressed():
	is_paused = !is_paused
	pause_button.text = "Продолжить" if is_paused else "Пауза"

func _on_step_pressed():
	if is_paused:
		_process_tick()

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_speed_changed(value: float):
	simulation_speed = value
	speed_value_label.text = str(int(value)) + "x"

func _update_ui():
	# Базовая статистика
	population_label.text = "Популяция: " + str(world.creature_data.size())
	total_born_label.text = "Всего родилось: " + str(world.total_born)
	total_died_label.text = "Всего умерло: " + str(world.total_died)
	grass_label.text = "Трава: " + str(world.grass_data.size())
	meat_label.text = "Мясо: " + str(world.meat_data.size())
	
	# Средние показатели
	if world.creature_data.size() > 0:
		var total_energy = 0.0
		var total_age = 0
		var total_speed = 0
		
		for pos in world.creature_data:
			var creature = world.creature_data[pos]
			total_energy += creature.energy
			total_age += creature.age
			total_speed += creature.speed
		
		var count = world.creature_data.size()
		avg_energy_label.text = "Ср. энергия: " + str(int(total_energy / count))
		avg_age_label.text = "Ср. возраст: " + str(int(total_age / count))
		avg_speed_label.text = "Ср. скорость: " + str(float(total_speed) / count).pad_decimals(2)
	else:
		avg_energy_label.text = "Ср. энергия: 0"
		avg_age_label.text = "Ср. возраст: 0"
		avg_speed_label.text = "Ср. скорость: 0"
	
	# Подсчёт по типам диеты
	var herbivores = 0
	var carnivores = 0
	var omnivores = 0
	
	for pos in world.creature_data:
		var creature = world.creature_data[pos]
		match creature.diet_type:
			0: herbivores += 1
			1: carnivores += 1
			2: omnivores += 1
	
	herbivores_label.text = "Травоядные: " + str(herbivores)
	omnivores_label.text = "Всеядные: " + str(omnivores)
	carnivores_label.text = "Хищники: " + str(carnivores)

func _update_time_label():
	ticks_label.text = "Тиков: " + str(simulation_ticks)
	var minutes = int(simulation_time / 60)
	var seconds = int(simulation_time) % 60
	time_label.text = "Время: %02d:%02d" % [minutes, seconds]

func _on_apply_settings(settings: Dictionary):
	print("Перезапуск симуляции с настройками: ", settings)
	# Перезапускаем сцену с новыми параметрами
	Global.creature_settings = settings.creature
	Global.grass_settings = settings.grass
	get_tree().reload_current_scene()
