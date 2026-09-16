class_name PopulationGraph
extends Control

var population_history: Array = []  # [{herbivores, carnivores, omnivores}]

func _ready():
	queue_redraw()

func add_data_point(herbivores: int, carnivores: int, omnivores: int):
	population_history.append({
		"herbivores": herbivores,
		"carnivores": carnivores,
		"omnivores": omnivores
	})
	if population_history.size() > 100:
		population_history.pop_front()
	queue_redraw()

func _draw():
	if population_history.size() < 2:
		return
	
	var width = size.x
	var height = size.y
	
	# Находим максимальное значение для масштабирования
	var max_pop = 1
	for data in population_history:
		var total = data.herbivores + data.carnivores + data.omnivores
		if total > max_pop:
			max_pop = total
	
	# Добавляем запас сверху (10% от максимума)
	max_pop = int(max_pop * 1.1) + 1
	
	# Рисуем фон
	draw_rect(Rect2(0, 0, width, height), Color(0.1, 0.1, 0.1, 1.0))
	
	# Рисуем горизонтальные линии сетки
	var grid_color = Color(0.3, 0.3, 0.3, 0.5)
	var grid_lines = 5
	for i in range(grid_lines + 1):
		var y = height - (i * height / grid_lines)
		draw_line(Vector2(0, y), Vector2(width, y), grid_color, 1.0)
	
	var step_x = width / (population_history.size() - 1)
	
	# Рисуем линии для каждого типа
	_draw_line_for_type("herbivores", Color(0.0, 0.8, 0.0), step_x, height, max_pop)
	_draw_line_for_type("carnivores", Color(1.0, 0.0, 0.0), step_x, height, max_pop)
	_draw_line_for_type("omnivores", Color(1.0, 0.6, 0.0), step_x, height, max_pop)
	
	# Подписи значений
	var font_size = 10
	var max_label = str(max_pop)
	var min_label = "0"
	draw_string(ThemeDB.fallback_font, Vector2(5, height - 5), min_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(5, 15), max_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 0.7))

func _draw_line_for_type(type: String, color: Color, step_x: float, height: float, max_pop: float):
	var points = []
	for i in range(population_history.size()):
		var x = i * step_x
		var value = population_history[i][type]
		var y = height - (value / max_pop) * (height - 20)  # Отступ 20px для подписей
		points.append(Vector2(x, y))
	
	# Рисуем линию
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, 2.0)
