extends CharacterBody3D

# Dual-mode player controller: Desktop (WASD + mouse) and VR (thumbstick + head tracking)

@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.5
@export var mouse_sensitivity: float = 0.003
@export var vr_turn_speed: float = 45.0  # degrees per second

@onready var origin: XROrigin3D = $XROrigin3D
@onready var camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XROrigin3D/RightHand

var _is_vr: bool = false
var _frozen: bool = false
var _camera_yaw: float = 0.0
var _camera_pitch: float = 0.0
var _xr_check_frames: int = 0

func _ready():
	# Check if XR is active (may take a few frames on Quest)
	_update_xr_status()
	XRServer.interface_added.connect(_on_xr_interface_added)
	# Spawn at level generator's spawn point (above first room floor)
	call_deferred("_position_at_spawn")

func _on_xr_interface_added(interface_name: String):
	if interface_name == "OpenXR":
		call_deferred("_update_xr_status")

func _position_at_spawn():
	var generator = get_node_or_null("../LevelGenerator")
	if generator and generator.has_method("get_spawn_point"):
		global_position = generator.get_spawn_point()

func _update_xr_status():
	if XRServer.primary_interface:
		_is_vr = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		print("VR mode active")
	else:
		_is_vr = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("Desktop mode active")
		# Position camera at eye height for desktop
		origin.position.y = 1.0

func _physics_process(delta):
	# Retry XR detection for first few frames (Quest init timing)
	if _xr_check_frames < 10 and not _is_vr:
		_xr_check_frames += 1
		_update_xr_status()
	
	if _frozen:
		return
	
	if _is_vr:
		_process_vr_movement(delta)
	else:
		_process_desktop_movement(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	move_and_slide()

func _process_desktop_movement(delta):
	var speed = walk_speed
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	# Use XROrigin3D basis for movement direction (tracks camera yaw)
	var direction = (origin.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Mouse look rotates the CharacterBody3D (parent), not the camera
	# The camera inside XROrigin3D follows head tracking in VR, but in desktop
	# we rotate the whole player body
	origin.rotation.y = _camera_yaw
	camera.rotation.x = _camera_pitch

func _process_vr_movement(delta):
	var speed = walk_speed
	if left_hand and left_hand.is_button_pressed("ax_button"):
		speed = sprint_speed
	
	# Left thumbstick movement
	var input = Vector2.ZERO
	if left_hand:
		var primary = left_hand.get_input("primary")
		if primary != null:
			input = Vector2(primary.x, -primary.y)
	
	# Orient movement to head direction
	var head_basis = origin.global_transform.basis
	var direction = head_basis * Vector3(input.x, 0, input.y)
	
	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Snap turn on right thumbstick
	if right_hand:
		var right_primary = right_hand.get_input("primary")
		if right_primary != null:
			var turn_input = right_primary.x
			if abs(turn_input) > 0.5:
				var turn_dir = sign(turn_input)
				origin.rotation.y -= turn_dir * vr_turn_speed * delta

func _input(event):
	if not _is_vr:
		# Desktop mouse look
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_camera_yaw -= event.relative.x * mouse_sensitivity
			_camera_pitch -= event.relative.y * mouse_sensitivity
			_camera_pitch = clamp(_camera_pitch, -deg_to_rad(85), deg_to_rad(85))
		
		# Toggle flashlight
		if event.is_action_pressed("ToggleLight"):
			_toggle_flashlight()
		
		# Interact
		if event.is_action_pressed("Interact"):
			_interact()
	else:
		# VR button inputs
		if event.is_action_pressed("ToggleLight"):
			_toggle_flashlight()
		
		if event.is_action_pressed("Interact"):
			_interact()

func _toggle_flashlight():
	var flashlights = get_tree().get_nodes_in_group("flashlight")
	for fl in flashlights:
		if fl.has_method("toggle"):
			fl.toggle()

func _interact():
	# Raycast from camera/center for interactions
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = camera.global_position
	query.to = camera.global_position - camera.global_transform.basis.z * 3.0
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result and result.collider is InteractionBase:
		result.collider.interact(self)

func set_frozen(frozen: bool):
	_frozen = frozen

func display_interaction_info(text: String):
	# TODO: update UI label
	pass
