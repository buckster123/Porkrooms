extends Resource
class_name RoomData

enum RoomType { CHAMBER, HALLWAY, STAIRCASE, PIT_ROOM, STORAGE }

@export var room_type: RoomType = RoomType.CHAMBER
@export var width: float = 8.0
@export var depth: float = 12.0
@export var height: float = 2.8

# Doorways: Dictionary of direction -> [offset, width, height]
# Directions: "north", "south", "east", "west"
@export var doorways: Dictionary = {}

# Features
@export var has_floor_hole: bool = false
@export var hole_position: Vector2 = Vector2.ZERO
@export var hole_size: Vector2 = Vector2(1.5, 1.5)

@export var has_stairs: bool = false
@export var stair_direction: String = "east"  # which wall the stairs descend from
@export var stair_width: float = 1.2

@export var hiding_spots: int = 0  # number of random hiding spots
@export var clutter_level: int = 2  # 0=empty, 1=sparse, 2=moderate, 3=cluttered

@export var light_count: int = -1  # -1 = auto based on room size
@export var light_color: Color = Color(1.0, 0.85, 0.4)
@export var light_broken: bool = false  # some lights flicker/die

@export var wall_stain_chance: float = 0.3
@export var floor_wetness: float = 0.0  # 0-1, affects footstep sounds
