extends Camera2D

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var min_zoom: float = 0.3
var max_zoom: float = 3.0

func _ready():
	position = Vector2(500, 500)
	zoom = Vector2(0.8, 0.8)
	make_current()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(0.9)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				drag_start_position = get_global_mouse_position()
			else:
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_delta = get_global_mouse_position() - drag_start_position
		position -= mouse_delta
		# Округляем позицию для устранения дрожания
		position = position.round()
		drag_start_position = get_global_mouse_position()

func _zoom_camera(factor: float):
	var new_zoom = zoom.x * factor
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	# Округляем позицию при зуме
	position = position.round()
