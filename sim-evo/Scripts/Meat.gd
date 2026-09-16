class_name Meat
extends RefCounted

var energy: float = 50.0           # Энергия мяса
var age: int = 0                   # Возраст трупа
var decomposition_time: int = 15   # Время разложения (тиков)
var toxin_level: float = 0.0       # Токсичность (от существа)

func _init(initial_energy: float = 50.0, initial_toxin: float = 0.0):
	energy = initial_energy
	toxin_level = initial_toxin
	decomposition_time = randi_range(15, 20)

func update():
	age += 1

func is_decomposed() -> bool:
	return age >= decomposition_time
