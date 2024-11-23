class_name RoomInterior3D extends Node3D

static var rotations : Array[Vector3] = [Vector3(90,180,0),Vector3(90,0,0),Vector3(90,270,0),Vector3(90,90,0),Vector3(0,90,0),Vector3(180,90,0)]
static var brickwall  : Rect2i = Rect2i(48,16,16,16)
static var brickfloor : Rect2i = Rect2i(32,16,16,16)

static var tilemesh : PlaneMesh = PlaneMesh.new()
static var tilecol  : BoxShape3D = BoxShape3D.new()
static var doormesh : PackedScene = preload("res://scenes/tscn/doortile.tscn")
static var rubble   : PackedScene = preload("res://scenes/scn/rubble.scn")

static func _static_init()->void:
	tilecol.size = Vector3(1,0.001,1)

var roomdata : Room

var doors : Array[Door3D]
var objects : Array[RoomItemInstance]

var leftmost  : float
var rightmost : float
var closest   : float

var is_room_one_wide : bool = false #along x axis

func _init(room:Room)->void:
	roomdata = room
	is_room_one_wide = roomdata.scale.z == 1
	Global.player.center_camera_in_room = is_room_one_wide

func _ready()->void:
	leftmost = -INF
	rightmost = INF
	closest = -INF
	
	position = roomdata.coords
	
	for box : Box in roomdata.boxes:
		create_box(box)
	
	if Global.player:
		Global.player.camera_left_limit = leftmost
		Global.player.camera_right_limit = rightmost
		Global.player.camera_near_limit = closest
	
	for item : RoomItem in roomdata.items:
		var obj : RoomItemInstance = item.create_instance()
		objects.append(obj); add_child(obj)
	
	embedded_tutorial_setup()

func create_box(box:Box)->void:
	var faces : Array[int] = box.doors
	for i : int in range(6):
		if City.DIRECTIONS[i] == City.UP: continue
		match faces[i]:
			Box.NONE: pass
			_: create_face(box,City.DIRECTIONS[i],rotations[i],faces[i])
	
	if is_room_one_wide:
		Global.player.centered_room_pos = get_child(0).global_position.x
	
	if box.state == Box.RUBBLE:
		var rubbleinst : Node3D = rubble.instantiate()
		rubbleinst.position = box.coords - roomdata.coords
		rubbleinst.rotation_degrees.y = randi_range(0,3)*90
		add_child(rubbleinst)

func create_face(box:Box,dir:Vector3i,angle:Vector3,type:int)->void:
	var body : StaticBody3D = StaticBody3D.new()
	
	var mesh : MeshInstance3D = MeshInstance3D.new()
	
	var mat : StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = get_texture_region(type,dir)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.uv1_scale = Vector3(2,2,2)
	
	if type > Box.HOLE: ##door
		var door : Node3D = doormesh.instantiate()
		
		var door_mat : StandardMaterial3D = StandardMaterial3D.new()
		door_mat.albedo_texture = preload("res://visuals/spritesheets/world_textures/door.png")
		door_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
		door_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		door_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		door.get_child(1).get_child(0).get_child(0).material_override = door_mat
		door.get_child(0).material_override = door_mat
		door.scale /= 4
		door.rotation_degrees = Vector3(-90,90,0)
		door.position = Vector3(0,0.5,0)
		
		door.lock_id = box.get_lock(dir)
		
		match type:
			Box.DOOR:
				door.manual_init(box,dir,Door3D.CLOSED)
			Box.OPEN:
				door.manual_init(box,dir,Door3D.OPENIN)
			Box.OPEN_OUT:
				door.manual_init(box,dir,Door3D.OPENOUT)
				if dir.x != 0:
					door.scale.z = -door.scale.z
				elif dir.z != 0:
					door.scale.z = -door.scale.z
			Box.CITY_EXIT_DOOR:
				door.manual_init(box,dir,Door3D.CLOSED,true)
				#door_mat.albedo_color = Color.GREEN
		
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mat.uv1_offset.y = 0.06
		mat.uv2_scale.x = -1
		
		mesh = door.get_child(2)
		doors.append(door)
		body.add_child(door)
	
	elif type == Box.HOLE:
		var hole : StaticBody3D = load("res://scenes/scn/wallhole.scn").instantiate()
		hole.scale /= 4
		hole.rotation_degrees = Vector3(180,270,90)
		hole.position = Vector3(0,0.5,0)
		mesh = hole.get_child(0)
		body.add_child(hole)
	
	elif type == Box.WALL:
		mesh.mesh = tilemesh
		mesh.scale /= 2
		mesh.position = Vector3(0,0.5,0)
		mesh.rotation_degrees.x += 180
	
	if type != Box.HOLE: ## the hole mesh should probably be fixed
		mesh.material_override = mat
	mesh.layers = 2
	
	var col : CollisionShape3D = CollisionShape3D.new()
	col.shape = tilecol
	col.position = Vector3(0,0.5,0)
	col.rotation_degrees.x += 180
	
	if type == Box.WALL:
		body.add_child(mesh)
	body.add_child(col)
	body.position = box.coords - roomdata.coords
	body.rotation_degrees = angle
	body.collision_layer = 106
	body.collision_mask = 0
	
	add_child(body)
	
	var tilepos : Vector3 = mesh.global_position
	if leftmost < tilepos.x  : leftmost = tilepos.x
	if rightmost > tilepos.x : rightmost = tilepos.x
	if closest < tilepos.z   : closest = tilepos.z

func get_texture_region(type:int,direction:Vector3i,door:bool=false)->CompressedTexture2D: #going to need another arg for what theme the room is and other stuff yk
	if type == Box.WALL:
		if direction.y != 0:
			return preload("res://visuals/spritesheets/world_textures/brickfloor.png")
		else:
			pass
	
	return preload("res://visuals/spritesheets/world_textures/brickwall.png")

func get_door_at(box:Box,direction:Vector3i)->Door3D:
	for door : Door3D in doors:
		if door.box == box and door.direction == direction:
			return door
	return null

func embedded_tutorial_setup()->void:
	if PopUps.tutorial_enabled and PopUps.next_tutorial_popup == PopUps.TUTORIAL.PAN_VIEW:
		PopUps.call_tutorial(PopUps.TUTORIAL.PAN_VIEW)

func save_room_objects()->void:
	roomdata.items.clear()
	for obj : RoomItemInstance in objects:
		if not obj or not is_instance_valid(obj): continue
		roomdata.items.append(obj.get_data())
