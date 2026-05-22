@tool
extends Node3D

@export var room_width: float = 8.0
@export var room_depth: float = 12.0
@export var room_height: float = 2.8
@export var regenerate: bool = false : set = _set_regenerate

var wall_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D
var ceiling_mat: StandardMaterial3D

func _set_regenerate(val: bool) -> void:
	if val:
		_build_room()
		regenerate = false

func _ready():
	_build_room()

func _build_room():
	# Clear existing children
	for child in get_children():
		if child.name.begins_with("Room_"):
			child.queue_free()
	
	await get_tree().process_frame
	
	# Create materials
	wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.82, 0.78, 0.55)
	wall_mat.roughness = 0.9
	wall_mat.metallic = 0.0
	
	floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.30, 0.22)
	floor_mat.roughness = 0.7
	
	ceiling_mat = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.88, 0.88, 0.82)
	ceiling_mat.roughness = 0.95
	
	# Floor
	_add_box("Room_Floor", Vector3(room_width, 0.1, room_depth), Vector3(0, -0.05, 0), floor_mat)
	
	# Ceiling
	_add_box("Room_Ceiling", Vector3(room_width, 0.1, room_depth), Vector3(0, room_height + 0.05, 0), ceiling_mat)
	
	# Walls
	_add_box("Room_Wall_N", Vector3(room_width, room_height, 0.1), Vector3(0, room_height/2, -room_depth/2 - 0.05), wall_mat)
	_add_box("Room_Wall_S", Vector3(room_width, room_height, 0.1), Vector3(0, room_height/2, room_depth/2 + 0.05), wall_mat)
	_add_box("Room_Wall_E", Vector3(0.1, room_height, room_depth), Vector3(room_width/2 + 0.05, room_height/2, 0), wall_mat)
	_add_box("Room_Wall_W", Vector3(0.1, room_height, room_depth), Vector3(-room_width/2 - 0.05, room_height/2, 0), wall_mat)
	
	# Doorway gap in North wall (remove by not placing a section)
	# Actually let's add a doorway frame
	_add_box("Room_DoorFrame_L", Vector3(0.4, room_height, 0.15), Vector3(-0.8, room_height/2, -room_depth/2 - 0.05), wall_mat)
	_add_box("Room_DoorFrame_R", Vector3(0.4, room_height, 0.15), Vector3(0.8, room_height/2, -room_depth/2 - 0.05), wall_mat)
	_add_box("Room_DoorFrame_T", Vector3(2.0, 0.4, 0.15), Vector3(0, room_height - 0.2, -room_depth/2 - 0.05), wall_mat)
	
	# Fluorescent lights
	_add_light("Room_Light_1", Vector3(-2, room_height - 0.2, -3))
	_add_light("Room_Light_2", Vector3(2, room_height - 0.2, -3))
	_add_light("Room_Light_3", Vector3(-2, room_height - 0.2, 3))
	_add_light("Room_Light_4", Vector3(2, room_height - 0.2, 3))

func _add_box(name: String, size: Vector3, pos: Vector3, mat: Material):
	var mi = MeshInstance3D.new()
	mi.name = name
	mi.mesh = BoxMesh.new()
	mi.mesh.size = size
	mi.material_override = mat
	mi.position = pos
	# Add surface metadata for footstep detection
	if name == "Room_Floor":
		mi.set_meta("surface", "Concrete")
	add_child(mi)
	mi.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

func _add_light(name: String, pos: Vector3):
	var light = OmniLight3D.new()
	light.name = name
	light.position = pos
	light.light_color = Color(0.95, 0.98, 0.85)
	light.light_energy = 1.0
	light.omni_range = 8.0
	light.shadow_enabled = true
	add_child(light)
	light.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	
	# Add flicker script
	light.set_script(load("res://scripts/flicker_light.gd"))
