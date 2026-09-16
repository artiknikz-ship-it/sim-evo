class_name Grass
extends RefCounted

# ============ ГЕНОМ ТРАВЫ ============
var energy: float = 1.0                        # Текущая энергия
var toxicity: float = 0.0                      # Ядовитость (0-1, 0 = не ядовитая)
var growth_rate: float = 1.0                   # Скорость восстановления энергии за тик
var max_neighbors: int = 3                     # Максимум соседей для выживания (3-7)
var reproduction_cooldown: int = 7             # Кулдаун между размножениями (тиков)
var fertility: float = 0.1                     # Шанс успешного размножения (0-1)
var age: int = 0                               # Возраст травы
var max_age: int = 15                          # Максимальный возраст (тиков)

# ============ ПЕРЕМЕННЫЕ ВМЕСТО КОНСТАНТ ============
var max_energy: float = 15.0                   # Максимальный запас энергии
var reproduction_threshold: float = 10.0       # Порог энергии для размножения
var reproduction_cost: float = 5.0             # Затраты энергии на размножение
var mutation_rate: float = 0.04                # Шанс мутации гена (4%)

func _init(initial_energy: float = -1):
	max_energy = Global.grass_settings["grass_max_energy"]
	growth_rate = Global.grass_settings["grass_growth_rate"]
	reproduction_threshold = Global.grass_settings["grass_reproduction_threshold"]
	reproduction_cost = Global.grass_settings["grass_reproduction_cost"]
	fertility = Global.grass_settings["grass_fertility"]
	mutation_rate = Global.grass_settings["grass_mutation_chance"]
	
	if initial_energy >= 0:
		energy = initial_energy
	else:
		energy = randf_range(5, 15)
	
	toxicity = 0.0
	max_neighbors = randi_range(3, 7)
	reproduction_cooldown = randi_range(3, 10)
	age = 0
	max_age = randi_range(10, 50)

# ============ МЕТОДЫ ============
func update():
	age += 1
	
	if reproduction_cooldown > 0:
		reproduction_cooldown -= 1
	
	energy = min(energy + growth_rate, max_energy)
	
	if age >= max_age:
		energy = 0

func is_dead() -> bool:
	return energy <= 0 or age >= max_age

func can_reproduce() -> bool:
	return energy >= reproduction_threshold and reproduction_cooldown <= 0

func reproduce() -> Grass:
	energy -= reproduction_cost
	reproduction_cooldown = randi_range(3, 10)
	
	var offspring = Grass.new(reproduction_cost)
	offspring.toxicity = toxicity
	offspring.growth_rate = growth_rate
	offspring.max_neighbors = max_neighbors
	offspring.fertility = fertility
	offspring.max_age = max_age
	
	# Мутации
	if randf() < mutation_rate:
		offspring.toxicity = clamp(randf_range(0.0, 1.0), 0, 1)
	if randf() < mutation_rate:
		offspring.growth_rate = randf_range(0.5, 2.0)
	if randf() < mutation_rate:
		offspring.max_neighbors = randi_range(3, 7)
	if randf() < mutation_rate:
		offspring.fertility = clamp(randf_range(0.3, 0.9), 0.3, 0.9)
	if randf() < mutation_rate:
		offspring.reproduction_cooldown = randi_range(3, 10)
	if randf() < mutation_rate:
		offspring.max_age = randi_range(60, 140)
	
	return offspring
