extends CharacterBody3D
class_name EnemyAI

enum State { IDLE, ROAM, CHASE, ATTACK, JUMPSCARE, STUNNED }
var state: State = State.IDLE

@export var roam_speed: float = 1.5
@export var chase_speed: float = 5.0
@export var detection_range: float = 12.0
@export var attack_range: float = 1.8
@export var wander_radius: float = 8.0
@export var idle_duration: float = 2.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var growl_audio: AudioStreamPlayer3D = $GrowlAudio if has_node("GrowlAudio") else null

var player: Node3D
var _target_pos: Vector3
var _timer: float = 0.0
var _jumpscare_active: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	# Build stand-in mesh if no child mesh
	if get_child_count() == 0:
		_build_stand_in_mesh()
	_transition(State.IDLE)

func _physics_process(delta):
	match state:
		State.IDLE: _idle_state(delta)
		State.ROAM: _roam_state(delta)
		State.CHASE: _chase_state(delta)
		State.ATTACK: _attack_state(delta)
		State.JUMPSCARE: _jumpscare_state(delta)
		State.STUNNED: _stunned_state(delta)

func _idle_state(delta):
	velocity = Vector3.ZERO
	_timer += delta
	if _timer >= idle_duration:
		_timer = 0
		if _can_see_player():
			_transition(State.CHASE)
		else:
			_transition(State.ROAM)

func _roam_state(delta):
	if _can_see_player():
		_transition(State.CHASE)
		return
	
	if global_position.distance_to(_target_pos) < 0.5 or _timer > 5.0:
		_random_target()
		_timer = 0
	
	_velocity_toward(_target_pos, roam_speed)
	move_and_slide()
	_timer += delta

func _chase_state(delta):
	if not _can_see_player():
		_transition(State.ROAM)
		return
	
	var dist = global_position.distance_to(player.global_position)
	if dist < attack_range:
		_transition(State.ATTACK)
		return
	
		_velocity_toward(player.global_position, chase_speed)
		move_and_slide()
		
		# Face player (only when in tree)
		if is_inside_tree():
			var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
			look_at(look_target, Vector3.UP)

func _attack_state(delta):
	velocity = Vector3.ZERO
	
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	
	if is_inside_tree() and player:
		var dist = global_position.distance_to(player.global_position)
		if dist > attack_range * 1.5:
			_transition(State.CHASE)
		elif dist < attack_range * 0.5:
			_transition(State.JUMPSCARE)

func _jumpscare_state(delta):
	if _jumpscare_active:
		return
	_jumpscare_active = true
	
	# Freeze player
	if player and player.has_method("set_frozen"):
		player.set_frozen(true)
	
	# Face player directly
	if is_inside_tree() and player:
		look_at(player.global_position, Vector3.UP)
	
	# Play jumpscare animation
	if anim_player and anim_player.has_animation("jumpscare"):
		anim_player.play("jumpscare")
		await anim_player.animation_finished
	
	# Reset level after delay
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _stunned_state(delta):
	velocity = Vector3.ZERO
	_timer += delta
	if _timer > 3.0:
		_timer = 0
		_transition(State.IDLE)

func _transition(new_state: State):
	state = new_state
	match new_state:
		State.IDLE:
			velocity = Vector3.ZERO
			_timer = 0
		State.ROAM:
			_random_target()
			_timer = 0
		State.CHASE:
			if growl_audio and not growl_audio.playing:
				growl_audio.play()
		State.JUMPSCARE:
			_jumpscare_active = false

func _can_see_player() -> bool:
	if not player:
		return false
	return global_position.distance_to(player.global_position) < detection_range

func _random_target():
	_target_pos = global_position + Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)

func _velocity_toward(target: Vector3, speed: float):
	var dir = (target - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _build_stand_in_mesh():
	# Dark silhouette body
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.mesh.radius = 0.4
	body.mesh.height = 1.4
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.02, 0.01)
	mat.roughness = 0.9
	body.material_override = mat
	add_child(body)
	
	# Snout
	var snout = MeshInstance3D.new()
	snout.mesh = BoxMesh.new()
	snout.mesh.size = Vector3(0.15, 0.12, 0.2)
	snout.position = Vector3(0, 0.2, 0.35)
	snout.material_override = mat
	add_child(snout)
	
	# Glowing red eyes
	var left_eye = OmniLight3D.new()
	left_eye.position = Vector3(-0.12, 0.35, 0.32)
	left_eye.light_color = Color(1.0, 0.0, 0.0)
	left_eye.light_energy = 2.0
	left_eye.omni_range = 2.0
	add_child(left_eye)
	
	var right_eye = OmniLight3D.new()
	right_eye.position = Vector3(0.12, 0.35, 0.32)
	right_eye.light_color = Color(1.0, 0.0, 0.0)
	right_eye.light_energy = 2.0
	right_eye.omni_range = 2.0
	add_child(right_eye)
	
	# Audio placeholder
	var audio = AudioStreamPlayer3D.new()
	audio.name = "GrowlAudio"
	add_child(audio)

func stun(duration: float = 3.0):
	_transition(State.STUNNED)
	_timer = 0
