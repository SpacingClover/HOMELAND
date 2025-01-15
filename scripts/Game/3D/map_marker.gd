class_name CityMarker3D extends StaticBody3D

enum FRAMES{
	MED_ORANGE_DOT,
	MED_ORANGE_DOT_WITH_YELLOW_CIRCLE,
	ORANGE_CIRCLE_WITH_MED_YELLOW_DOT,
	ORANGE_CIRCLE_AND_MED_ORANGE_DOT,
	ORANGE_CIRCLE,
	ORANGE_CIRCLE_WTIH_SMALL_ORANGE_DOT,
	ORANGE_CIRCLE_WITH_SMALL_YELLOW_DOT,
	ORANGE_CIRCLE_WITH_ORANGE_X,
	ORANGE_CIRCLE_WITH_YELLOW_X,
	ORANGE_CIRCLE_WITH_ORANGE_ARROWS,
	FILLED_ORANGE_CIRCLE
}

static var texture : Texture2D = preload("res://visuals/spritesheets/icons/map_markers.png")
static var sphere : SphereShape3D = SphereShape3D.new()

@onready var sprite : Sprite3D = $sprite
@onready var collider : CollisionShape3D = $col
var city : City:
	set(x): city = x; city_idx = Global.current_game.cities.find(x)
var city_idx : int

var roads : Dictionary

func _ready()->void:
	tree_exiting.connect(set.bind("sprite",null))
	sprite.frame = FRAMES.MED_ORANGE_DOT
	global_position = Vector3(city.coords.x,0,city.coords.y) * MapView.MAP_SPACING_SCALE
	
	if Global.current_region == city:
		mark_current()
	
	city.mapvisual = self
	
	await get_tree().create_timer(0.1).timeout
	add_roads()

func mark_current()->void:
	MapView.current.move_camera_to(self)

func mark_normal()->void:
	sprite.frame = FRAMES.MED_ORANGE_DOT

func add_roads()->void:
	var connections : Array[ConnectionResponse] = Global.current_game.city_connections_register.get_city_connections(city)
	for connection : ConnectionResponse in connections:
		add_road(connection.city)

func add_road(to:City)->void:
	var line : MeshInstance3D = MeshInstance3D.new()
	add_child(line)
	line.mesh = load("res://geometry/offsetcube.obj")
	line.global_position = global_position
	line.look_at(to.mapvisual.global_position)
	line.rotation_degrees.y += 90
	line.scale /= 10
	line.scale.y = 0.01
	line.scale.x *= global_position.distance_to(to.mapvisual.global_position) * 2
	line.global_position.y -= 0.1
	line.layers = 4
	var mat : StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1,0.4,0)
	line.material_override = mat
	roads[to] = line
