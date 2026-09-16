class_name Creature
extends RefCounted

# ============ ГЕНОМ СУЩЕСТВА ============
# Сенсорные гены
var vision_cells: Array = []                     # Список видимых направлений (0-7, где 0=верх, 1=верх-право, и т.д.)
var vision_type: int = 2                         # Тип видимых объектов (0=трава, 1=мясо, 2=оба, 3=движущиеся)
var vision_priority: int = 0                     # Приоритет внимания (0=еда, 1=угроза, 2=сородичи)

# Гены движения
var speed: int = 1                               # Скорость (1-3 клетки за ход)
var movement_pattern: int = 0                    # Паттерн движения (0=случайный, 1=направленный, 2=зигзаг)
var stamina: float = 1.0                         # Выносливость (затраты энергии на движение)

# Гены питания
var diet_type: int = 0                           # Тип диеты (0=травоядный, 1=плотоядный, 2=всеядный)
var metabolism: float = 0.5                      # Метаболизм (скорость потери энергии)
var digestion_efficiency: float = 0.5            # Эффективность пищеварения (0.3-0.9)

var can_eat_meat: bool = true                  # Может есть мясо (трупы)
var can_hunt: bool = false                     # Может охотиться на живых
var cannibalism: float = 0.0                   # Каннибализм (0-1, шанс атаковать свой вид)

# Гены размножения
var reproduction_threshold: float = 100.0        # Порог энергии для размножения
var mutation_rate: float = 0.05                  # Индивидуальный шанс мутаций
var offspring_energy: float = 50.0               # Энергия передаваемая потомку
var reproduction_cooldown: int = 3               # Перезарядка размножения
var maturity_age: int = 5                        # Возраст зрелости
var max_age: int = 50                            # Максимальный возраст
var fertility_peak: int = 15                     # Пик плодовитости

# Гены взаимодействия
var aggression: float = 0.0                      # Агрессивность (0-1)
var defense: float = 0.0                         # Защита (0-1)
var sociality: float = 0.3                       # Социальность (0-1)

# Гены адаптации
var energy_storage: float = 150.0                # Максимальный запас энергии
var longevity: float = 1.0                       # Продолжительность жизни (множитель)

# Дополнительные гены
var camouflage: float = 0.0                      # Камуфляж (0-1)
var toxin_resistance: float = 0.0                # Устойчивость к ядам (0-1)
var hibernation: float = 0.0                     # Спячка (0-1)
var communication_range: int = 1                 # Радиус коммуникации
var memory_size: int = 1                         # Размер памяти (0-5)
var learning_rate: float = 0.1                   # Обучаемость (0-1)

# ============ СОСТОЯНИЕ ============
var energy: float = 100.0                        # Текущая энергия
var age: int = 0                                 # Текущий возраст
var grid_position: Vector2i = Vector2i.ZERO      # Позиция в сетке
var is_dead: bool = false                        # Флаг смерти
var memory: Array = []                           # Память о местах

# ============ КОНСТАНТЫ ============
const BASE_METABOLISM_COST: float = 1.0          # Базовая потеря энергии за тик
const MOVEMENT_ENERGY_COST: float = 1.0          # Энергия за движение
const MIN_ENERGY: float = 0.0                    # Минимальная энергия

func _init(initial_energy: float = -1, initial_age: int = -1):
	# Применяем настройки из Global
	metabolism = Global.creature_settings["metabolism"]
	digestion_efficiency = Global.creature_settings["digestion_efficiency"]
	reproduction_threshold = Global.creature_settings["reproduction_threshold"]
	mutation_rate = Global.creature_settings["mutation_rate"]
	offspring_energy = Global.creature_settings["offspring_energy"]
	maturity_age = Global.creature_settings["maturity_age"]
	max_age = Global.creature_settings["max_age"]
	fertility_peak = Global.creature_settings["fertility_peak"]
	aggression = Global.creature_settings["aggression"]
	defense = Global.creature_settings["defense"]
	sociality = Global.creature_settings["sociality"]
	energy_storage = Global.creature_settings["energy_storage"]
	longevity = Global.creature_settings["longevity"]
	toxin_resistance = Global.creature_settings["toxin_resistance"]
	hibernation = Global.creature_settings["hibernation"]
	memory_size = Global.creature_settings["memory_size"]
	learning_rate = Global.creature_settings["learning_rate"]
	
	can_eat_meat = diet_type == 1 or diet_type == 2  # Хищники и всеядные едят мясо
	can_hunt = diet_type == 1                        # Только хищники охотятся
	cannibalism = 0.0                                # Изначально нет каннибализма
	
	# Зрение
	vision_cells = _generate_vision_cells(Global.creature_settings["vision_cells_count"])
	
	if initial_energy >= 0:
		energy = initial_energy
	else:
		energy = randf_range(80, 120)
	
	if initial_age >= 0:
		age = initial_age
	else:
		age = randi_range(0, maturity_age)
	
	# Инициализация зрения: 3 случайные клетки из 8
	vision_cells = _generate_vision_cells(3)


func _generate_vision_cells(count: int) -> Array:
	var cells = []
	var all_directions = [0, 1, 2, 3, 4, 5, 6, 7]
	all_directions.shuffle()
	
	for i in range(min(count, 8)):
		cells.append(all_directions[i])
	
	return cells
# ============ МЕТОДЫ ============
func update():
	age += 1

	if reproduction_cooldown > 0:
		reproduction_cooldown -= 1
	
	# Потеря энергии от метаболизма
	var energy_loss = BASE_METABOLISM_COST * metabolism * (1.0 / longevity)
	
	# Спячка уменьшает метаболизм при низкой энергии
	if hibernation > 0 and energy < energy_storage * 0.3:
		energy_loss *= (1.0 - hibernation * 0.7)
	
	energy -= energy_loss
	
	# Проверка смерти от голода
	if energy <= MIN_ENERGY:
		is_dead = true
		return
	
	# Проверка смерти от старости
	if age >= int(max_age * longevity):
		is_dead = true

func can_reproduce() -> bool:
	# Проверка возможности размножения
	return (energy >= reproduction_threshold and 
			age >= maturity_age and 
			reproduction_cooldown <= 0 and 
			not is_dead)

func reproduce() -> Creature:
	# Создание потомка с мутациями
	energy -= offspring_energy
	reproduction_cooldown = 5  # Базовый кулдаун
	
	var offspring = Creature.new(offspring_energy, 0)
	_copy_genes_to(offspring)
	
	# Мутации с индивидуальным шансом
	_mutate_offspring(offspring)
	
	return offspring

func _copy_genes_to(offspring: Creature):
	# Копирование всех генов
	offspring.vision_cells = vision_cells.duplicate()
	offspring.vision_type = vision_type
	offspring.vision_priority = vision_priority
	offspring.speed = speed
	offspring.movement_pattern = movement_pattern
	offspring.stamina = stamina
	offspring.diet_type = diet_type
	offspring.metabolism = metabolism
	offspring.digestion_efficiency = digestion_efficiency
	offspring.reproduction_threshold = reproduction_threshold
	offspring.mutation_rate = mutation_rate
	offspring.offspring_energy = offspring_energy
	offspring.maturity_age = maturity_age
	offspring.max_age = max_age
	offspring.fertility_peak = fertility_peak
	offspring.aggression = aggression
	offspring.defense = defense
	offspring.sociality = sociality
	offspring.energy_storage = energy_storage
	offspring.longevity = longevity
	offspring.camouflage = camouflage
	offspring.toxin_resistance = toxin_resistance
	offspring.hibernation = hibernation
	offspring.communication_range = communication_range
	offspring.memory_size = memory_size
	offspring.learning_rate = learning_rate
	
	offspring.can_eat_meat = can_eat_meat
	offspring.can_hunt = can_hunt
	offspring.cannibalism = cannibalism

func _mutate_offspring(offspring: Creature):
	# Мутации генов с индивидуальным шансом
	# Каждая мутация - плавное изменение от значения родителя
	
	# Сенсорные гены
	if randf() < mutation_rate:
		var old_count = vision_cells.size()
		var new_count = clamp(old_count + randi_range(-1, 1), 1, 8)
		offspring.vision_cells = offspring._generate_vision_cells(new_count)
		if offspring.vision_cells.size() != old_count:
			print("Мутация зрения: ", old_count, " -> ", offspring.vision_cells.size())
	
	if randf() < mutation_rate:
		var old_value = speed
		offspring.speed = clamp(speed + randi_range(-1, 1), 1, 3)
		if offspring.speed != old_value:
			print("Мутация скорости: ", old_value, " -> ", offspring.speed)
	
	if randf() < mutation_rate:
		var old_value = metabolism
		offspring.metabolism = clamp(metabolism + randf_range(-0.1, 0.1), 0.2, 1.0)
		if abs(offspring.metabolism - old_value) > 0.05:
			print("Мутация метаболизма: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = digestion_efficiency
		offspring.digestion_efficiency = clamp(digestion_efficiency + randf_range(-0.1, 0.1), 0.3, 0.9)
		if abs(offspring.digestion_efficiency - old_value) > 0.05:
			print("Мутация пищеварения: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = aggression
		offspring.aggression = clamp(aggression + randf_range(-0.1, 0.1), 0.0, 1.0)
		if abs(offspring.aggression - old_value) > 0.05:
			print("Мутация агрессии: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = defense
		offspring.defense = clamp(defense + randf_range(-0.1, 0.1), 0.0, 1.0)
		if abs(offspring.defense - old_value) > 0.05:
			print("Мутация защиты: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = sociality
		offspring.sociality = clamp(sociality + randf_range(-0.1, 0.1), 0.0, 1.0)
		if abs(offspring.sociality - old_value) > 0.05:
			print("Мутация социальности: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = camouflage
		offspring.camouflage = clamp(camouflage + randf_range(-0.1, 0.1), 0.0, 1.0)
		if abs(offspring.camouflage - old_value) > 0.05:
			print("Мутация камуфляжа: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = toxin_resistance
		offspring.toxin_resistance = clamp(toxin_resistance + randf_range(-0.2, 0.2), 0.0, 1.0)
		if abs(offspring.toxin_resistance - old_value) > 0.1:
			print("Мутация иммунитета: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = hibernation
		offspring.hibernation = clamp(hibernation + randf_range(-0.1, 0.1), 0.0, 1.0)
		if abs(offspring.hibernation - old_value) > 0.05:
			print("Мутация спячки: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = memory_size
		offspring.memory_size = clamp(memory_size + randi_range(-1, 1), 0, 5)
		if offspring.memory_size != old_value:
			print("Мутация памяти: ", old_value, " -> ", offspring.memory_size)
	
	if randf() < mutation_rate:
		var old_value = learning_rate
		offspring.learning_rate = clamp(learning_rate + randf_range(-0.05, 0.05), 0.0, 0.5)
		if abs(offspring.learning_rate - old_value) > 0.03:
			print("Мутация обучаемости: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < mutation_rate:
		var old_value = energy_storage
		offspring.energy_storage = clamp(energy_storage + randf_range(-20, 20), 100.0, 200.0)
		if abs(offspring.energy_storage - old_value) > 10:
			print("Мутация запаса энергии: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	# Редкие мутации диеты (1% шанс)
	if randf() < 0.01:
		var old_value = diet_type
		offspring.diet_type = randi_range(0, 2)
		if offspring.diet_type != old_value:
			print("МУТАЦИЯ ДИЕТЫ: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	# Очень редкие мутации (0.1% шанс)
	if randf() < 0.001:
		var old_value = stamina
		offspring.stamina = clamp(stamina + randf_range(-0.2, 0.2), 0.5, 2.0)
		if abs(offspring.stamina - old_value) > 0.1:
			print("Редкая мутация выносливости: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	if randf() < 0.001:
		var old_value = longevity
		offspring.longevity = clamp(longevity + randf_range(-0.1, 0.1), 0.5, 1.5)
		if abs(offspring.longevity - old_value) > 0.05:
			print("Редкая мутация долголетия: ", str(old_value).pad_decimals(2), " -> ", str(offspring.toxin_resistance).pad_decimals(2))
	
	# Мутация каннибализма (редкая, 2% шанс)
	if randf() < 0.02:
		var old_value = cannibalism
		offspring.cannibalism = clamp(cannibalism + randf_range(-0.2, 0.2), 0.0, 1.0)
		if abs(offspring.cannibalism - old_value) > 0.1:
			print("Мутация каннибализма: ", str(old_value).pad_decimals(2), " -> ", str(offspring.cannibalism).pad_decimals(2))

func get_fertility() -> float:
	# Плодовитость зависит от возраста
	if age < maturity_age:
		return 0.0
	
	var age_factor: float
	if age <= fertility_peak:
		# Растёт до пика
		age_factor = float(age - maturity_age) / float(fertility_peak - maturity_age)
	else:
		# Снижается после пика
		var max_life = max_age * longevity
		age_factor = 1.0 - float(age - fertility_peak) / float(max_life - fertility_peak)
	
	return clamp(age_factor, 0.1, 1.0)
