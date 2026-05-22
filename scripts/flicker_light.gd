extends Light3D

@export var min_energy: float = 0.3
@export var max_energy: float = 1.5
@export var flicker_speed: float = 8.0
@export var chaos: float = 0.5

var _time: float = 0.0
var _random_offset: float = 0.0

func _ready():
	_random_offset = randf() * 100.0
	light_color = Color(0.95, 0.98, 0.85)

func _process(delta):
	_time += delta * flicker_speed
	# Combine sine waves with randomness for fluorescent buzz
	var base = sin(_time + _random_offset)
	var noise = sin(_time * 2.7 + _random_offset * 1.3) * 0.3
	var spike = randf() < (0.02 * chaos) if chaos > 0 else false
	
	var val = (base + noise) * 0.5 + 0.5
	if spike:
		val = randf_range(0.0, 2.0)
	
	light_energy = lerp(min_energy, max_energy, clamp(val, 0.0, 1.0))
