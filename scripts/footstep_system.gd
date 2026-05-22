extends Node3D

@onready var ray: RayCast3D = $RayCast3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var step_interval_walk: float = 0.5
@export var step_interval_run: float = 0.3
@export var surfaces: Dictionary = {}

var _step_timer: float = 0.0
var _current_interval: float = step_interval_walk

func _physics_process(delta):
	var player = get_parent() as CharacterBody3D
	if not player:
		return
	
	var is_moving = player.velocity.length() > 0.1 and player.is_on_floor()
	
	# Adjust interval based on speed
	var speed = player.velocity.length()
	if speed > 3.0:
		_current_interval = step_interval_run
	else:
		_current_interval = step_interval_walk
	
	if is_moving:
		_step_timer += delta
		if _step_timer >= _current_interval:
			_play_footstep()
			_step_timer = 0.0
	else:
		_step_timer = 0.0

func _play_footstep():
	ray.force_raycast_update()
	if not ray.is_colliding():
		return
	
	var collider = ray.get_collider()
	var surface = "Concrete"
	
	if collider.has_meta("surface"):
		surface = collider.get_meta("surface")
	elif collider.get_parent().has_meta("surface"):
		surface = collider.get_parent().get_meta("surface")
	
	var stream = surfaces.get(surface)
	if stream:
		audio.stream = stream
		audio.pitch_scale = randf_range(0.88, 1.12)
		audio.volume_db = randf_range(-8.0, -4.0)
		audio.play()
