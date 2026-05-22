extends CharacterBody3D

@export var wander_radius: float = 5.0
@export var wander_speed: float = 1.5
@export var chase_speed: float = 4.0
@export var detection_range: float = 10.0

var _target_pos: Vector3
var _state: String = "idle"
var _timer: float = 0.0

func _ready():
	# Stand-in appearance: dark silhouette
	var mesh = MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	mesh.mesh.radius = 0.4
	mesh.mesh.height = 1.4
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.02, 0.01)
	mat.roughness = 0.9
	mat.metallic = 0.0
	mesh.material_override = mat
	add_child(mesh)
	
	# Snout
	var snout = MeshInstance3D.new()
	snout.mesh = BoxMesh.new()
	snout.mesh.size = Vector3(0.15, 0.12, 0.2)
	snout.position = Vector3(0, 0.2, 0.35)
	snout.material_override = mat
	add_child(snout)
	
	_random_target()

func _physics_process(delta):
	_timer += delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < detection_range:
			_state = "chase"
		else:
			_state = "wander"
	
	if _state == "chase" and player:
		var dir = (player.global_position - global_position).normalized()
		velocity = Vector3(dir.x, 0, dir.z) * chase_speed
	elif _state == "wander":
		if global_position.distance_to(_target_pos) < 0.5 or _timer > 5.0:
			_random_target()
			_timer = 0.0
		var dir = (_target_pos - global_position).normalized()
		velocity = Vector3(dir.x, 0, dir.z) * wander_speed
	
	move_and_slide()

func _random_target():
	_target_pos = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
