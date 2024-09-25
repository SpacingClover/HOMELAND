class_name MapView extends Node3D

static var MAP_SPACING_SCALE : float = 3
static var current : MapView

@onready var camera_root : Node3D = $camera_root
@onready var camera : Camera3D = $camera_root/Camera3D
@onready var map_root : Node3D = $map_root
@onready var markerinfo : PanelContainer = $markerinfo
@onready var markerinfotitle : Label = $markerinfo/VBoxContainer/Label
@onready var markerinfohr : HSeparator = $markerinfo/VBoxContainer/hr
@onready var markerinfobody : Label = $markerinfo/VBoxContainer/Label2
@onready var header : Label = $header

var viewport : GameView
var cameratween : Tween
var targeted_node : CityMarker3D

func _init()->void:
	Global.mapview = self
	MapView.current = self

func _ready()->void:
	markerinfo.hide()

func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		var marker : CityMarker3D = get_cursor_object()
		if not marker: markerinfo.hide(); return
		display_city_info(marker.city)
	elif event.is_action_pressed(&"scroll_up"):
		camera.position /= 1.1
	elif event.is_action_pressed(&"scroll_down"):
		camera.position *= 1.1

func orbit(vel:Vector2,lockvert:bool=false)->void:
	camera_root.global_rotation_degrees.y += vel.x
	if not lockvert:
		camera_root.rotation_degrees.x = clamp(camera_root.rotation_degrees.x+vel.y,-70,-20)

func move_camera_to(target:Node3D,animated:bool=true)->void:
	if not target or not is_instance_valid(target): return
	if cameratween: if cameratween.is_running(): await cameratween.finished
	
	var targetpos : Vector3 = target.global_position; targetpos.y -= 0.05
	
	cameratween = create_tween().set_parallel(true)
	cameratween.tween_property(camera_root,"global_position",targetpos,0.75)
	var mesh : MeshInstance3D
	
	if targeted_node and animated: if is_instance_valid(targeted_node):
		mesh = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.layers = 4
		targeted_node.add_child(mesh)
		mesh.look_at(target.global_position)
		mesh.scale /= 5.25
		mesh.scale.y = 0.01
		mesh.scale.z *= 1.5
		mesh.global_position.y -= 0.05
		
		var mat : StandardMaterial3D = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color.YELLOW
		mesh.material_override = mat
		
		cameratween.tween_property(mesh,"global_position",targetpos,0.75)
	
	if targeted_node:
		targeted_node.sprite.frame = targeted_node.FRAMES.MED_ORANGE_DOT
	else:
		target.sprite.frame = target.FRAMES.MED_ORANGE_DOT_WITH_YELLOW_CIRCLE
	targeted_node = target
	await cameratween.finished
	target.sprite.frame = target.FRAMES.MED_ORANGE_DOT_WITH_YELLOW_CIRCLE
	
	if mesh and is_instance_valid(mesh):
		mesh.queue_free()

func display_map(game:GameData)->void:
	reset_map()
	for city : City in game.cities:
		place_city_marker(city)

func place_city_marker(city:City)->void:
	var marker : CityMarker3D = preload("res://scenes/scn/marker.scn").instantiate()
	marker.city = city
	map_root.add_child(marker)

func reset_map()->void:
	for child : Node3D in map_root.get_children():
		map_root.remove_child(child)
		child.queue_free()

func get_cursor_object()->CityMarker3D:
	var mousepos : Vector2 = get_viewport().get_mouse_position()
	var from : Vector3 = camera.project_ray_origin(mousepos)
	var to : Vector3 = from + camera.project_ray_normal(mousepos)*10
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,16)
	var result : Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.keys().is_empty():
		return null
	else:
		return result["collider"]

func display_city_info(city:City)->void:
	markerinfotitle.text = &" "+city.name+&" "
	markerinfo.show()
	markerinfohr.hide()
	markerinfobody.hide()
	
	if city == Global.current_region:
		markerinfohr.show()
		markerinfobody.show()
		markerinfobody.text = "you are here"
	
	markerinfo.position = camera.unproject_position(city.mapvisual.global_position) + Vector2(100,-50)
