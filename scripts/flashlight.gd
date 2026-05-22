extends SpotLight3D

@export var max_battery: float = 100.0
@export var drain_rate: float = 3.0
@export var flicker_threshold: float = 25.0
@export var recharge_amount: float = 50.0

var battery: float = 100.0
var is_on: bool = true

func _ready():
	light_color = Color(0.92, 0.97, 0.88)
	light_energy = 3.5
	spot_range = 18.0
	spot_angle = 40.0
	shadow_enabled = true

func _process(delta):
	if is_on:
		battery -= drain_rate * delta
		battery = max(battery, 0)
		
		if battery <= 0:
			is_on = false
			visible = false
			light_energy = 0
		elif battery < flicker_threshold:
			# Flicker intensity based on battery level
			var flicker = randf()
			var threshold = battery / flicker_threshold
			if flicker > threshold:
				light_energy = randf_range(0.5, 2.5)
			else:
				light_energy = 2.0
		else:
			light_energy = 2.0

func toggle():
	if battery > 0:
		is_on = not is_on
		visible = is_on
		if is_on:
			light_energy = 2.0
	else:
		# Dead battery sound cue could go here
		pass

func recharge(amount: float = -1.0):
	if amount < 0:
		amount = recharge_amount
	battery = min(battery + amount, max_battery)
	if not is_on and battery > 0:
		is_on = true
		visible = true
