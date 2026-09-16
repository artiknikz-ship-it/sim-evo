extends Node2D

var tick_count: int = 0 ################

const GRID_SIZE := 50
const CELL_SIZE := 20

# ============ ПАРАМЕТРЫ МИРА ============
const CREATURE_INITIAL_COUNT: int = 10    # Начальное количество существ

# ============ ДАННЫЕ ============
var grass_data: Dictionary = {}            # {Vector2i: Grass}
var creature_data: Dictionary = {}         # {Vector2i: Creature}
var meat_data: Dictionary = {}  # {Vector2i: Meat}

var total_born: int = 0
var total_died: int = 0

func _ready():
	queue_redraw()
	_initialize_grass()
	_initialize_creatures()

func _initialize_grass():
	var grass_count = 0
	while grass_count < Global.grass_settings["grass_initial_count"]:
		var random_pos = Vector2i(randi() % GRID_SIZE, randi() % GRID_SIZE)
		if not grass_data.has(random_pos) and not creature_data.has(random_pos):
			grass_data[random_pos] = Grass.new()
			grass_count += 1

func _initialize_creatures():
	var creature_count = 0
	while creature_count < CREATURE_INITIAL_COUNT:
		var random_pos = Vector2i(randi() % GRID_SIZE, randi() % GRID_SIZE)
		if not grass_data.has(random_pos) and not creature_data.has(random_pos):
			var creature = Creature.new()
			creature.grid_position = random_pos
			creature_data[random_pos] = creature
			

			creature_count += 1

func _update_grass():
	var grass_to_remove = []
	var grass_to_add = {}
	
	for pos in grass_data:
		var grass = grass_data[pos]
		
		# Обновляем траву
		grass.update()
		
		# Проверка на перенаселение
		var neighbors = _count_grass_neighbors(pos)
		if neighbors > grass.max_neighbors:
			grass_to_remove.append(pos)
			continue
		
		# Размножение
		if grass.can_reproduce() and randf() < grass.fertility:
			var empty_neighbors = _get_empty_neighbors(pos)
			if empty_neighbors.size() > 0:
				var new_pos = empty_neighbors[randi() % empty_neighbors.size()]
				var offspring = grass.reproduce()
				grass_to_add[new_pos] = offspring
		
		# Смерть
		if grass.is_dead():
			grass_to_remove.append(pos)
	
	# Применяем изменения
	for pos in grass_to_remove:
		grass_data.erase(pos)
	
	for pos in grass_to_add:
		grass_data[pos] = grass_to_add[pos]
	
	queue_redraw()

func _update_creatures():
	var creatures_to_remove = []
	var creatures_to_add = {}
	
	# Используем копию ключей для безопасной итерации
	for pos in creature_data.keys().duplicate():
		if not creature_data.has(pos):
			continue
		
		var creature = creature_data[pos]
		
		# Обновляем существо
		creature.update()
		
		# Проверка смерти
		if creature.is_dead:
			creatures_to_remove.append(pos)
			total_died += 1
			meat_data[pos] = Meat.new(creature.energy, creature.toxin_resistance)
			continue
		
		# ГОРИЗОНТАЛЬНЫЙ ПЕРЕНОС ГЕНОВ (добавь эту строку)
		_try_gene_exchange(pos, creature)
		
		# ПИТАНИЕ
		_try_eat(pos, creature)
		
		# ДВИЖЕНИЕ
		if creature.energy > 0:
			_try_move_creature(pos, creature)
			
		# Размножение
		if creature.can_reproduce():
			var fertility = creature.get_fertility()
			if randf() < fertility:
				var empty_neighbors = _get_empty_neighbors(pos)
				if empty_neighbors.size() > 0:
					var new_pos = empty_neighbors[randi() % empty_neighbors.size()]
					var offspring = creature.reproduce()
					offspring.grid_position = new_pos
					creatures_to_add[new_pos] = offspring
					total_born += 1
	
	# Применяем изменения
	for pos in creatures_to_remove:
		creature_data.erase(pos)
	
	for pos in creatures_to_add:
		creature_data[pos] = creatures_to_add[pos]
	
	queue_redraw()

func _update_meat():
	var meat_to_remove = []
	var grass_to_add = {}
	
	for pos in meat_data:
		var meat = meat_data[pos]
		meat.update()
		
		# Разложение
		if meat.is_decomposed():
			meat_to_remove.append(pos)
			# Создаём траву из трупа
			var new_grass = Grass.new()
			if meat.toxin_level > 0.5:
				new_grass.toxicity = 0.5 + meat.toxin_level * 0.5
			grass_to_add[pos] = new_grass
	
	# Применяем изменения
	for pos in meat_to_remove:
		meat_data.erase(pos)
	
	for pos in grass_to_add:
		grass_data[pos] = grass_to_add[pos]

func _try_move_creature(old_pos: Vector2i, creature: Creature):
	for step in range(creature.speed):
		var empty_neighbors = _get_empty_neighbors(old_pos)
		if empty_neighbors.size() == 0:
			break
		
		# Перемешиваем соседей для случайного движения
		empty_neighbors.shuffle()
		
		var new_pos: Vector2i
		
		# Если голодное - ищем траву в радиусе зрения
		if creature.energy < creature.energy_storage * 0.5:
			new_pos = _find_nearest_grass_pos(old_pos, empty_neighbors, creature)
		else:
			empty_neighbors.shuffle()
			new_pos = empty_neighbors[0]
		
		# Перемещаем
		creature_data.erase(old_pos)
		creature.grid_position = new_pos
		creature_data[new_pos] = creature
		
		# Тратим энергию
		creature.energy -= Creature.MOVEMENT_ENERGY_COST / creature.stamina
		
		old_pos = new_pos

func _try_eat(pos: Vector2i, creature: Creature):
	# Проверяем мясо на текущей клетке
	if meat_data.has(pos):
		_eat_meat(pos, creature)
		return
	
	# Проверяем траву на текущей клетке
	if grass_data.has(pos):
		_eat_grass(pos, creature)
		return
	
	# Проверяем соседние клетки
	var neighbors = _get_neighbors(pos)
	for neighbor_pos in neighbors:
		if meat_data.has(neighbor_pos):
			_eat_meat(neighbor_pos, creature)
			return
		if grass_data.has(neighbor_pos):
			_eat_grass(neighbor_pos, creature)
			return
	
	# Охота на живых существ (для хищников)
	if creature.can_hunt and creature.aggression > 0.3:
		for neighbor_pos in neighbors:
			if creature_data.has(neighbor_pos):
				var target = creature_data[neighbor_pos]
				# Проверяем каннибализм
				if target.diet_type == creature.diet_type and creature.cannibalism < 0.5:
					continue  # Не атакуем свой вид без каннибализма
				
				_try_hunt(creature, target)

func _eat_meat(pos: Vector2i, creature: Creature):
	var meat = meat_data[pos]
	
	# Хищники и всеядные едят мясо
	if creature.diet_type == 1 or creature.diet_type == 2:
		var energy_gain = meat.energy * creature.digestion_efficiency
		
		# Проверка на токсичность мяса
		if meat.toxin_level > 0:
			var poison_damage = meat.toxin_level * 5.0 * (1.0 - creature.toxin_resistance)
			creature.energy -= poison_damage
		
		creature.energy = min(creature.energy + energy_gain, creature.energy_storage)
		meat_data.erase(pos)

func _try_hunt(creature: Creature, target: Creature):
	# Шанс успешной охоты зависит от агрессии и защиты цели
	var hunt_chance = creature.aggression * (1.0 - target.defense * 0.5)
	
	if randf() < hunt_chance:
		# Успешная охота
		var energy_gain = target.energy * creature.digestion_efficiency
		creature.energy = min(creature.energy + energy_gain, creature.energy_storage)
		
		# Цель умирает
		target.energy = 0
		target.is_dead = true
		
		print("Охота успешна! Хищник получил ", str(energy_gain).pad_decimals(1), " энергии")
	else:
		# Неудачная охота - тратим энергию
		creature.energy -= 5.0

func _eat_grass(pos: Vector2i, creature: Creature):
	var grass = grass_data[pos]
	
	# Травоядные и всеядные могут есть траву
	if creature.diet_type == 0 or creature.diet_type == 2:
		var energy_gain = grass.energy * creature.digestion_efficiency
		
		# Проверка на ядовитость
		if grass.toxicity > 0:
			var poison_damage = grass.toxicity * 10.0 * (1.0 - creature.toxin_resistance)
			creature.energy -= poison_damage
		
		creature.energy = min(creature.energy + energy_gain, creature.energy_storage)
		
		# Удаляем съеденную траву
		grass_data.erase(pos)

func _is_grass_visible(creature: Creature, grass_pos: Vector2i) -> bool:
	var dx = grass_pos.x - creature.grid_position.x
	var dy = grass_pos.y - creature.grid_position.y
	
	# Проверяем, что трава на соседней клетке
	if abs(dx) > 1 or abs(dy) > 1:
		return false
	
	# Определяем направление (0-7)
	var direction = _get_direction(dx, dy)
	
	# Проверяем, видит ли существо это направление
	return direction in creature.vision_cells

func _get_direction(dx: int, dy: int) -> int:
	# 0=верх, 1=верх-право, 2=право, 3=низ-право, 4=низ, 5=низ-лево, 6=лево, 7=верх-лево
	if dx == 0 and dy == -1: return 0
	if dx == 1 and dy == -1: return 1
	if dx == 1 and dy == 0: return 2
	if dx == 1 and dy == 1: return 3
	if dx == 0 and dy == 1: return 4
	if dx == -1 and dy == 1: return 5
	if dx == -1 and dy == 0: return 6
	if dx == -1 and dy == -1: return 7
	return -1  # Не соседняя клетка

func _find_nearest_grass_pos(current_pos: Vector2i, possible_moves: Array, creature: Creature) -> Vector2i:
	var visible_grass = []
	
	# Ищем только видимую траву
	for grass_pos in grass_data:
		if _is_grass_visible(creature, grass_pos):
			visible_grass.append(grass_pos)
	
	if visible_grass.size() == 0:
		# Нет видимой травы - случайное движение
		possible_moves.shuffle()
		return possible_moves[0]
	
	# Ищем ближайшую видимую траву
	var best_pos = possible_moves[0]
	var best_distance = 999999.0
	
	for move_pos in possible_moves:
		for grass_pos in visible_grass:
			var dist = move_pos.distance_to(grass_pos)
			if dist < best_distance:
				best_distance = dist
				best_pos = move_pos
	
	return best_pos

func _count_grass_neighbors(grid_pos: Vector2i) -> int:
	var count = 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(
				(grid_pos.x + dx + GRID_SIZE) % GRID_SIZE,
				(grid_pos.y + dy + GRID_SIZE) % GRID_SIZE
			)
			if grass_data.has(check_pos):
				count += 1
	return count

func _get_empty_neighbors(grid_pos: Vector2i) -> Array:
	var empty = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(
				(grid_pos.x + dx + GRID_SIZE) % GRID_SIZE,
				(grid_pos.y + dy + GRID_SIZE) % GRID_SIZE
			)
			if not grass_data.has(check_pos) and not creature_data.has(check_pos):
				empty.append(check_pos)
	return empty

func _get_neighbors(grid_pos: Vector2i) -> Array:
	var neighbors = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(
				(grid_pos.x + dx + GRID_SIZE) % GRID_SIZE,
				(grid_pos.y + dy + GRID_SIZE) % GRID_SIZE
			)
			neighbors.append(check_pos)
	return neighbors

func _draw():
	# Рисуем фон мира
	draw_rect(Rect2(0, 0, GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE), Color(0.15, 0.15, 0.15, 1.0))
	
	# Рисуем траву
	for pos in grass_data:
		var grass = grass_data[pos]
		var energy_factor = grass.energy / grass.max_energy
		var color = Color(0.2, 0.6, 0.2).lerp(Color(0.6, 0.2, 0.6), grass.toxicity)
		color = color.lightened(energy_factor * 0.5)
		
		var center = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2, pos.y * CELL_SIZE + CELL_SIZE / 2)
		var radius = CELL_SIZE / 3 * (0.5 + energy_factor * 0.5)
		draw_circle(center, radius, color)
	
	# Рисуем существ
	for pos in creature_data:
		var creature = creature_data[pos]
		var energy_factor = creature.energy / creature.energy_storage
		
		# Цвет зависит от диеты
		var color: Color
		match creature.diet_type:
			0: color = Color(0.3, 0.5, 1.0)  # Синий - травоядный
			1: color = Color(1.0, 0.3, 0.3)  # Красный - плотоядный
			2: color = Color(1.0, 0.8, 0.3)  # Жёлтый - всеядный
		
		# Яркость от энергии
		color = color.lightened(energy_factor * 0.3)
		
		var center = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2, pos.y * CELL_SIZE + CELL_SIZE / 2)
		var radius = CELL_SIZE / 2.5  # Больше, чем у травы
		
		# Основной круг
		draw_circle(center, radius, color)
		
		# Обводка (тёмная)
		draw_arc(center, radius, 0, TAU, 32, Color(0, 0, 0, 0.8), 2.0)
		
		# Индикатор энергии (маленькая точка в центре)
		var energy_color = Color(0, 1, 0) if energy_factor > 0.5 else Color(1, 1, 0) if energy_factor > 0.25 else Color(1, 0, 0)
		draw_circle(center, 3.0, energy_color)
		
		# Индикатор каннибализма (розовая точка в правом верхнем углу)
		if creature.cannibalism > 0.5:
			var cannibal_indicator = center + Vector2(radius * 0.7, -radius * 0.7)
			draw_circle(cannibal_indicator, 3.0, Color(1.0, 0.0, 0.5))
	
	# Рисуем мясо
	for pos in meat_data:
		var meat = meat_data[pos]
		var center = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2, pos.y * CELL_SIZE + CELL_SIZE / 2)
		
		# Серый круг
		draw_circle(center, CELL_SIZE / 3, Color(0.5, 0.5, 0.5))
		# Красная точка в центре
		draw_circle(center, 2.0, Color(1.0, 0.0, 0.0))
	
	# Рисуем сетку поверх
	var grid_color := Color(0.5, 0.5, 0.5, 0.3)
	for i in range(GRID_SIZE + 1):
		draw_line(Vector2(i * CELL_SIZE, 0), Vector2(i * CELL_SIZE, GRID_SIZE * CELL_SIZE), grid_color, 1.0)
		draw_line(Vector2(0, i * CELL_SIZE), Vector2(GRID_SIZE * CELL_SIZE, i * CELL_SIZE), grid_color, 1.0)

func _try_gene_exchange(pos: Vector2i, creature: Creature):
	# Проверяем соседние клетки на наличие других существ
	var neighbors = _get_neighbors(pos)
	
	for neighbor_pos in neighbors:
		if creature_data.has(neighbor_pos):
			var other_creature = creature_data[neighbor_pos]
			
			# Проверяем генетическую совместимость (70-85%)
			var similarity = _calculate_genetic_similarity(creature, other_creature)
			
			if similarity >= 0.7 and similarity <= 0.85:
				# Шанс 2-3% на обмен геном
				if randf() < 0.025:
					_exchange_random_gene(creature, other_creature)

func _calculate_genetic_similarity(creature1: Creature, creature2: Creature) -> float:
	var differences = 0
	var total_genes = 20
	
	# Зрение теперь это массив клеток
	if creature1.vision_cells.size() != creature2.vision_cells.size():
		differences += 1
	# Можно также сравнивать сами клетки
	else:
		var vision_different = false
		for cell in creature1.vision_cells:
			if cell not in creature2.vision_cells:
				vision_different = true
				break
		if vision_different:
			differences += 1
	
	# Остальные гены без изменений
	if creature1.vision_type != creature2.vision_type: differences += 1
	if creature1.vision_priority != creature2.vision_priority: differences += 1
	if creature1.speed != creature2.speed: differences += 1
	if creature1.movement_pattern != creature2.movement_pattern: differences += 1
	if abs(creature1.stamina - creature2.stamina) > 0.2: differences += 1
	if creature1.diet_type != creature2.diet_type: differences += 1
	if abs(creature1.metabolism - creature2.metabolism) > 0.2: differences += 1
	if abs(creature1.digestion_efficiency - creature2.digestion_efficiency) > 0.2: differences += 1
	if abs(creature1.reproduction_threshold - creature2.reproduction_threshold) > 20: differences += 1
	if abs(creature1.mutation_rate - creature2.mutation_rate) > 0.02: differences += 1
	if abs(creature1.offspring_energy - creature2.offspring_energy) > 20: differences += 1
	if creature1.maturity_age != creature2.maturity_age: differences += 1
	if creature1.max_age != creature2.max_age: differences += 1
	if creature1.fertility_peak != creature2.fertility_peak: differences += 1
	if abs(creature1.aggression - creature2.aggression) > 0.3: differences += 1
	if abs(creature1.defense - creature2.defense) > 0.3: differences += 1
	if abs(creature1.sociality - creature2.sociality) > 0.3: differences += 1
	if abs(creature1.energy_storage - creature2.energy_storage) > 30: differences += 1
	if abs(creature1.toxin_resistance - creature2.toxin_resistance) > 0.3: differences += 1
	
	return 1.0 - float(differences) / float(total_genes)

func _exchange_random_gene(creature1: Creature, creature2: Creature):
	# Выбираем случайный ген для обмена
	var gene_index = randi_range(0, 19)
	var gene_name = ""
	
	match gene_index:
		0: 
			var temp = creature1.vision_cells
			creature1.vision_cells = creature2.vision_cells
			creature2.vision_cells = temp
			gene_name = "vision_cells"
		1:
			var temp = creature1.vision_type
			creature1.vision_type = creature2.vision_type
			creature2.vision_type = temp
			gene_name = "vision_type"
		2:
			var temp = creature1.vision_priority
			creature1.vision_priority = creature2.vision_priority
			creature2.vision_priority = temp
			gene_name = "vision_priority"
		3:
			var temp = creature1.speed
			creature1.speed = creature2.speed
			creature2.speed = temp
			gene_name = "speed"
		4:
			var temp = creature1.movement_pattern
			creature1.movement_pattern = creature2.movement_pattern
			creature2.movement_pattern = temp
			gene_name = "movement_pattern"
		5:
			var temp = creature1.stamina
			creature1.stamina = creature2.stamina
			creature2.stamina = temp
			gene_name = "stamina"
		6:
			var temp = creature1.diet_type
			creature1.diet_type = creature2.diet_type
			creature2.diet_type = temp
			gene_name = "diet_type"
		7:
			var temp = creature1.metabolism
			creature1.metabolism = creature2.metabolism
			creature2.metabolism = temp
			gene_name = "metabolism"
		8:
			var temp = creature1.digestion_efficiency
			creature1.digestion_efficiency = creature2.digestion_efficiency
			creature2.digestion_efficiency = temp
			gene_name = "digestion_efficiency"
		9:
			var temp = creature1.reproduction_threshold
			creature1.reproduction_threshold = creature2.reproduction_threshold
			creature2.reproduction_threshold = temp
			gene_name = "reproduction_threshold"
		10:
			var temp = creature1.mutation_rate
			creature1.mutation_rate = creature2.mutation_rate
			creature2.mutation_rate = temp
			gene_name = "mutation_rate"
		11:
			var temp = creature1.offspring_energy
			creature1.offspring_energy = creature2.offspring_energy
			creature2.offspring_energy = temp
			gene_name = "offspring_energy"
		12:
			var temp = creature1.maturity_age
			creature1.maturity_age = creature2.maturity_age
			creature2.maturity_age = temp
			gene_name = "maturity_age"
		13:
			var temp = creature1.max_age
			creature1.max_age = creature2.max_age
			creature2.max_age = temp
			gene_name = "max_age"
		14:
			var temp = creature1.fertility_peak
			creature1.fertility_peak = creature2.fertility_peak
			creature2.fertility_peak = temp
			gene_name = "fertility_peak"
		15:
			var temp = creature1.aggression
			creature1.aggression = creature2.aggression
			creature2.aggression = temp
			gene_name = "aggression"
		16:
			var temp = creature1.defense
			creature1.defense = creature2.defense
			creature2.defense = temp
			gene_name = "defense"
		17:
			var temp = creature1.sociality
			creature1.sociality = creature2.sociality
			creature2.sociality = temp
			gene_name = "sociality"
		18:
			var temp = creature1.energy_storage
			creature1.energy_storage = creature2.energy_storage
			creature2.energy_storage = temp
			gene_name = "energy_storage"
		19:
			var temp = creature1.toxin_resistance
			creature1.toxin_resistance = creature2.toxin_resistance
			creature2.toxin_resistance = temp
			gene_name = "toxin_resistance"
	
	# Вывод в консоль при успешном обмене
	print("Генетический обмен: ", gene_name, " между существами на позициях ", creature1.grid_position, " и ", creature2.grid_position)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / CELL_SIZE), floor(world_pos.y / CELL_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE / 2, grid_pos.y * CELL_SIZE + CELL_SIZE / 2)
