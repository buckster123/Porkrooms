@tool
extends Node3D

# The Porkrooms Level Generator
# Builds interconnected backrooms-style chambers procedurally

@export var seed: int = 0 : set = _set_seed
@export var room_count: int = 12
@export var regenerate: bool = false : set = _set_regenerate

# Materials (created at runtime)
var wall_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D
var ceiling_mat: StandardMaterial3D
var trim_mat: StandardMaterial3D
var light_fixture_mat: StandardMaterial3D
var light_bulb_mat: StandardMaterial3D
var dark_void_mat: StandardMaterial3D

# Room tracking
var _rooms: Array[Dictionary] = []
var _rng: RandomNumberGenerator

func _set_seed(val: int) -> void:
	seed = val
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed

func _set_regenerate(val: bool) -> void:
	if val:
		_build_level()
		regenerate = false

func _ready():
	if seed == 0:
		seed = hash(str(Time.get_unix_time_from_system()))
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_build_level()

func _build_level():
	# Clear existing
	for child in get_children():
		child.queue_free()
	_rooms.clear()
	
	_create_materials()
	
	# Generate room graph
	var room_graph = _generate_room_graph()
	
	# Place rooms
	for room_data in room_graph:
		_place_room(room_data)
	
	# Connect hallways between rooms
	for i in range(room_graph.size() - 1):
		_connect_rooms(room_graph[i], room_graph[i + 1])
	
	# Add hiding spots
	_add_hiding_spots()
	
	# Add clutter
	_add_clutter()
	
	print("Level generated: " + str(_rooms.size()) + " rooms")

func _create_materials():
	wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.82, 0.78, 0.55)
	wall_mat.roughness = 0.92
	wall_mat.metallic = 0.0
	
	floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.32, 0.28, 0.20)
	floor_mat.roughness = 0.75
	
	ceiling_mat = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.88, 0.88, 0.82)
	ceiling_mat.roughness = 0.95
	
	trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.95, 0.95, 0.92)
	trim_mat.roughness = 0.4
	
	light_fixture_mat = StandardMaterial3D.new()
	light_fixture_mat.albedo_color = Color(0.9, 0.88, 0.82)
	light_fixture_mat.roughness = 0.3
	
	light_bulb_mat = StandardMaterial3D.new()
	light_bulb_mat.albedo_color = Color(0.95, 0.98, 0.88)
	light_bulb_mat.emission_enabled = true
	light_bulb_mat.emission = Color(0.88, 0.95, 0.78)
	light_bulb_mat.emission_energy = 2.5
	
	dark_void_mat = StandardMaterial3D.new()
	dark_void_mat.albedo_color = Color(0.01, 0.01, 0.01)
	dark_void_mat.roughness = 1.0

func _generate_room_graph() -> Array:
	var graph = []
	
	# Start room (always a chamber)
	graph.append({
		"type": "chamber",
		"width": _rng.randf_range(6.0, 10.0),
		"depth": _rng.randf_range(8.0, 14.0),
		"height": 2.8,
		"pos": Vector3.ZERO,
		"doorways": [],
		"features": ["start"]
	})
	
	for i in range(room_count - 1):
		var prev = graph[-1]
		var room_type = _pick_room_type(i)
		var width = _rng.randf_range(4.0, 10.0)
		var depth = _rng.randf_range(4.0, 14.0)
		var height = _rng.randf_range(2.4, 3.2)
		
		# Pick connection direction
		var dirs = ["north", "south", "east", "west"]
		var dir = dirs[_rng.randi() % dirs.size()]
		
		# Calculate position based on direction
		var offset = Vector3.ZERO
		match dir:
			"north":
				offset = Vector3(0, 0, -(prev["depth"]/2 + depth/2 + _rng.randf_range(2.0, 6.0)))
			"south":
				offset = Vector3(0, 0, (prev["depth"]/2 + depth/2 + _rng.randf_range(2.0, 6.0)))
			"east":
				offset = Vector3((prev["width"]/2 + width/2 + _rng.randf_range(2.0, 6.0)), 0, 0)
			"west":
				offset = Vector3(-(prev["width"]/2 + width/2 + _rng.randf_range(2.0, 6.0)), 0, 0)
		
		var pos = prev["pos"] + offset
		
		# Random features
		var features = []
		if _rng.randf() < 0.3:
			features.append("floor_hole")
		if _rng.randf() < 0.2:
			features.append("stairs")
		if _rng.randf() < 0.4:
			features.append("hiding_spots")
		
		graph.append({
			"type": room_type,
			"width": width,
			"depth": depth,
			"height": height,
			"pos": pos,
			"doorways": [dir],
			"features": features,
			"light_broken": _rng.randf() < 0.25
		})
	
	return graph

func _pick_room_type(index: int) -> String:
	var roll = _rng.randf()
	if roll < 0.5:
		return "chamber"
	elif roll < 0.75:
		return "hallway"
	elif roll < 0.9:
		return "storage"
	else:
		return "pit_room"

func _place_room(room_data: Dictionary):
	var room_root = Node3D.new()
	room_root.name = "Room_" + str(_rooms.size())
	room_root.position = room_data["pos"]
	add_child(room_root)
	if Engine.is_editor_hint():
		room_root.owner = get_tree().edited_scene_root
	
	var w = room_data["width"]
	var d = room_data["depth"]
	var h = room_data["height"]
	
	# Floor
	_add_box("Floor", room_root, Vector3.ZERO, Vector3(w, 0.1, d), floor_mat, true)
	
	# Ceiling
	_add_box("Ceiling", room_root, Vector3(0, h, 0), Vector3(w, 0.1, d), ceiling_mat)
	
	# Walls
	_add_box("Wall_N", room_root, Vector3(0, h/2, -d/2 - 0.05), Vector3(w, h, 0.1), wall_mat)
	_add_box("Wall_S", room_root, Vector3(0, h/2, d/2 + 0.05), Vector3(w, h, 0.1), wall_mat)
	_add_box("Wall_E", room_root, Vector3(w/2 + 0.05, h/2, 0), Vector3(0.1, h, d), wall_mat)
	_add_box("Wall_W", room_root, Vector3(-w/2 - 0.05, h/2, 0), Vector3(0.1, h, d), wall_mat)
	
	# Baseboard trim
	var trim_h = 0.08
	_add_box("Trim_N", room_root, Vector3(0, trim_h/2, -d/2 - 0.02), Vector3(w + 0.2, trim_h, 0.04), trim_mat)
	_add_box("Trim_S", room_root, Vector3(0, trim_h/2, d/2 + 0.02), Vector3(w + 0.2, trim_h, 0.04), trim_mat)
	_add_box("Trim_E", room_root, Vector3(w/2 + 0.02, trim_h/2, 0), Vector3(0.04, trim_h, d + 0.2), trim_mat)
	_add_box("Trim_W", room_root, Vector3(-w/2 - 0.02, trim_h/2, 0), Vector3(0.04, trim_h, d + 0.2), trim_mat)
	
	# Plafond lights — generous coverage with mood variation
	var room_area = w * d
	var light_count = max(2, int(room_area / 12) + 1)
	for i in range(light_count):
		var lx = _rng.randf_range(-w * 0.4, w * 0.4)
		var lz = _rng.randf_range(-d * 0.4, d * 0.4)
		var broken = room_data.get("light_broken", false) and _rng.randf() < 0.2
		var mood = _rng.randf()  # 0=dim corner, 1=bright center
		_add_plafond_light(room_root, "Light_" + str(i), Vector3(lx, h - 0.04, lz), broken, mood)
	
	# Corner fill lights (dim ambient)
	var corners = [
		Vector3(-w*0.45, h*0.8, -d*0.45),
		Vector3(w*0.45, h*0.8, -d*0.45),
		Vector3(-w*0.45, h*0.8, d*0.45),
		Vector3(w*0.45, h*0.8, d*0.45),
	]
	for i in range(4):
		if _rng.randf() < 0.6:
			_add_corner_light(room_root, "Corner_" + str(i), corners[i])
	
	# Floor hole
	if room_data["features"].has("floor_hole"):
		var hx = _rng.randf_range(-w * 0.3, w * 0.3)
		var hz = _rng.randf_range(-d * 0.3, d * 0.3)
		var hw = _rng.randf_range(1.0, 2.0)
		var hd = _rng.randf_range(1.0, 2.0)
		_add_box("Hole", room_root, Vector3(hx, -0.05, hz), Vector3(hw, 0.1, hd), dark_void_mat)
	
	# Stairs
	if room_data["features"].has("stairs"):
		_add_stairs(room_root, w, d, h)
	
	# Hiding spots
	if room_data["features"].has("hiding_spots"):
		for j in range(_rng.randi_range(1, 3)):
			var sx = _rng.randf_range(-w * 0.4, w * 0.4)
			var sz = _rng.randf_range(-d * 0.4, d * 0.4)
			_add_hiding_spot(room_root, "Hide_" + str(j), Vector3(sx, 0, sz))
	
	_rooms.append({
		"node": room_root,
		"data": room_data
	})

func _connect_rooms(room_a: Dictionary, room_b: Dictionary):
	# Create hallway between two rooms
	var pos_a = room_a["pos"]
	var pos_b = room_b["pos"]
	var diff = pos_b - pos_a
	
	# Simple hallway
	var hall_width = 1.5
	var hall_height = 2.4
	var hall_length = diff.length()
	
	if hall_length < 3.0:
		return  # Too close
	
	var hall_root = Node3D.new()
	hall_root.name = "Hallway_" + str(_rooms.size())
	hall_root.position = pos_a + diff * 0.5
	add_child(hall_root)
	if Engine.is_editor_hint():
		hall_root.owner = get_tree().edited_scene_root
	
	# Safe rotation without look_at (avoids "not in tree" issue)
	var forward = (pos_b - hall_root.position).normalized()
	if forward.length() > 0.001:
		var angle = atan2(forward.x, forward.z)
		hall_root.rotation.y = angle
	
	# Floor
	_add_box("Floor", hall_root, Vector3.ZERO, Vector3(hall_width, 0.1, hall_length), floor_mat, true)
	# Ceiling
	_add_box("Ceiling", hall_root, Vector3(0, hall_height, 0), Vector3(hall_width, 0.1, hall_length), ceiling_mat)
	# Walls
	_add_box("Wall_L", hall_root, Vector3(-hall_width/2 - 0.05, hall_height/2, 0), Vector3(0.1, hall_height, hall_length), wall_mat)
	_add_box("Wall_R", hall_root, Vector3(hall_width/2 + 0.05, hall_height/2, 0), Vector3(0.1, hall_height, hall_length), wall_mat)
	
	# Lights every 4m (brighter for hallways)
	var light_count = max(2, int(hall_length / 3))
	for i in range(light_count):
		var lz = -hall_length/2 + (i + 0.5) * (hall_length / light_count)
		_add_plafond_light(hall_root, "Light_" + str(i), Vector3(0, hall_height - 0.04, lz), false, 0.7)
	
	_rooms.append({
		"node": hall_root,
		"data": {"type": "hallway", "pos": hall_root.position}
	})

func _add_box(name: String, parent: Node3D, pos: Vector3, size: Vector3, mat: Material, is_floor: bool = false):
	var mi = MeshInstance3D.new()
	mi.name = name
	mi.mesh = BoxMesh.new()
	mi.mesh.size = size
	mi.material_override = mat
	mi.position = pos
	if is_floor:
		mi.set_meta("surface", "Concrete")
	parent.add_child(mi)
	if Engine.is_editor_hint():
		mi.owner = get_tree().edited_scene_root

func _add_plafond_light(parent: Node3D, name: String, pos: Vector3, broken: bool, mood: float = 0.5):
	var fixture_root = Node3D.new()
	fixture_root.name = name
	fixture_root.position = pos
	parent.add_child(fixture_root)
	if Engine.is_editor_hint():
		fixture_root.owner = get_tree().edited_scene_root
	
	var radius = 0.25
	var height = 0.06
	
	# Fixture housing (cylinder)
	var housing = MeshInstance3D.new()
	housing.name = name + "_Housing"
	housing.mesh = CylinderMesh.new()
	housing.mesh.top_radius = radius
	housing.mesh.bottom_radius = radius * 1.1
	housing.mesh.height = height
	housing.material_override = light_fixture_mat
	fixture_root.add_child(housing)
	if Engine.is_editor_hint():
		housing.owner = get_tree().edited_scene_root
	
	# Bulb face
	var bulb = MeshInstance3D.new()
	bulb.name = name + "_Bulb"
	bulb.mesh = CylinderMesh.new()
	bulb.mesh.top_radius = radius * 0.85
	bulb.mesh.bottom_radius = radius * 0.85
	bulb.mesh.height = height * 0.1
	bulb.position = Vector3(0, -height * 0.3, 0)
	bulb.material_override = light_bulb_mat
	fixture_root.add_child(bulb)
	if Engine.is_editor_hint():
		bulb.owner = get_tree().edited_scene_root
	
	# Light with mood variation
	var light = SpotLight3D.new()
	light.name = name + "_Spot"
	light.position = Vector3(0, -height * 0.5, 0)
	light.light_color = Color(0.9, 0.95, 0.82)
	
	# Mood-based energy: bright center, dim corners
	var base_energy = lerp(2.5, 7.0, mood)
	if broken:
		base_energy *= 0.25
	light.light_energy = base_energy
	
	light.spot_range = 12.0 + mood * 5.0
	light.spot_angle = 75.0 + mood * 10.0
	light.spot_angle_attenuation = 2.0
	light.shadow_enabled = true
	fixture_root.add_child(light)
	if Engine.is_editor_hint():
		light.owner = get_tree().edited_scene_root
	
	# If broken, add flicker script
	if broken:
		light.set_script(load("res://scripts/flicker_light.gd"))

func _add_stairs(parent: Node3D, room_w: float, room_d: float, room_h: float):
	var stair_w = 1.2
	var stair_d = 2.5
	var stair_count = max(6, int(room_h / 0.3))
	var step_h = room_h / stair_count
	
	var sx = room_w/2 - stair_w - 0.5
	var sz = -room_d/2 + 0.5
	
	for i in range(stair_count):
		var step = MeshInstance3D.new()
		step.name = "Stair_" + str(i)
		step.mesh = BoxMesh.new()
		step.mesh.size = Vector3(stair_w, step_h, stair_d / stair_count + 0.02)
		step.position = Vector3(sx, i * step_h, sz + i * (stair_d / stair_count))
		step.material_override = floor_mat
		parent.add_child(step)
		if Engine.is_editor_hint():
			step.owner = get_tree().edited_scene_root

func _add_corner_light(parent: Node3D, name: String, pos: Vector3):
	"""Dim wall-mounted light for corner ambient fill."""
	var light = OmniLight3D.new()
	light.name = name
	light.position = pos
	light.light_color = Color(0.82, 0.9, 0.75)
	light.light_energy = 1.2
	light.omni_range = 6.0
	light.omni_attenuation = 2.0
	light.shadow_enabled = false
	parent.add_child(light)
	if Engine.is_editor_hint():
		light.owner = get_tree().edited_scene_root

func _add_hiding_spot(parent: Node3D, name: String, pos: Vector3):
	var spot = Node3D.new()
	spot.name = name
	spot.position = pos
	parent.add_child(spot)
	if Engine.is_editor_hint():
		spot.owner = get_tree().edited_scene_root
	
	# Simple locker-like box
	var locker = MeshInstance3D.new()
	locker.name = name + "_Locker"
	locker.mesh = BoxMesh.new()
	locker.mesh.size = Vector3(0.8, 2.0, 0.6)
	locker.position = Vector3(0, 1.0, 0)
	locker.material_override = wall_mat
	spot.add_child(locker)
	if Engine.is_editor_hint():
		locker.owner = get_tree().edited_scene_root
	
	# Door (slightly ajar)
	var door = MeshInstance3D.new()
	door.name = name + "_Door"
	door.mesh = BoxMesh.new()
	door.mesh.size = Vector3(0.75, 1.9, 0.04)
	door.position = Vector3(0.35, 1.0, 0.3)
	door.rotation_degrees = Vector3(0, -25, 0)
	door.material_override = trim_mat
	spot.add_child(door)
	if Engine.is_editor_hint():
		door.owner = get_tree().edited_scene_root

func _add_hiding_spots():
	pass  # Handled per-room

func _add_clutter():
	for room_info in _rooms:
		var room_data = room_info["data"]
		var room_node = room_info["node"]
		var w = room_data.get("width", 8.0)
		var d = room_data.get("depth", 12.0)
		
		# Random boxes/barrels
		var clutter_count = _rng.randi_range(0, 4)
		for i in range(clutter_count):
			var cx = _rng.randf_range(-w * 0.4, w * 0.4)
			var cz = _rng.randf_range(-d * 0.4, d * 0.4)
			var clutter = MeshInstance3D.new()
			clutter.name = "Clutter_" + str(i)
			clutter.mesh = BoxMesh.new()
			clutter.mesh.size = Vector3(
				_rng.randf_range(0.3, 0.8),
				_rng.randf_range(0.3, 1.2),
				_rng.randf_range(0.3, 0.8)
			)
			clutter.position = Vector3(cx, clutter.mesh.size.y / 2, cz)
			clutter.material_override = floor_mat
			room_node.add_child(clutter)
			if Engine.is_editor_hint():
				clutter.owner = get_tree().edited_scene_root

func get_spawn_point() -> Vector3:
	if _rooms.size() > 0:
		return _rooms[0]["node"].global_position + Vector3(0, 1.7, 0)
	return Vector3.ZERO
