class_name RoomInstance3D extends StaticBody3D

static var boxmaterial : StandardMaterial3D = preload("res://visuals/materials/3d_view.tres")
#static var boxoverlaymaterial : StandardMaterial3D = null
static var boxglow : StandardMaterial3D = preload("res://visuals/materials/glow.tres")
static var yellowglow : Color = Color("a2d800")
static var pinkglow : Color = Color("e70061")
static var doormaterial : StandardMaterial3D = preload("res://visuals/materials/3dDoor.tres")
static var staticfeaturematerial : StandardMaterial3D
static var cityexitdoorroommaterial : StandardMaterial3D = preload("res://visuals/materials/city_exit_door.tres")
static var featureroommaterial : StandardMaterial3D = preload("res://visuals/materials/3D_feature.tres")
static var rubbleboxmaterial : StandardMaterial3D = preload("res://visuals/materials/rubbleicom.tres")
static var lock_icon : CompressedTexture2D = preload("res://visuals/spritesheets/icons/lock_icon.png")
static var road_visual : MeshInstance3D = preload("res://scenes/scn/road_icon.scn").instantiate()

static func _static_init()->void:
	doormaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

var data_reference : Room

var is_selected : bool = false

signal room_instance_selected
signal room_instance_placed
signal room_instance_dropped

func _init(room_resource:Room)->void:
	data_reference = room_resource
	data_reference.roomvisual = self
	input_ray_pickable = true
	collision_layer = 1
	collision_mask = 1
	for boxdata : Box in data_reference.boxes:
		var mesh : MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.set_meta(&"boxdata",boxdata)
		if boxdata.state != Box.RUBBLE:
			mesh.material_override = boxmaterial.duplicate()
		else:
			mesh.material_override = rubbleboxmaterial.duplicate()
		mesh.position = boxdata.coords
		boxdata.set_boxvisual_reference(mesh)
		if room_resource is Feature:
			if room_resource is CityExit: mesh.material_override = cityexitdoorroommaterial
			else: mesh.material_override = featureroommaterial
		add_child(mesh)
		
		var col : CollisionShape3D = CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		col.position = boxdata.coords
		add_child(col)
		
		for dir : Vector3i in City.DIRECTIONS:
			if boxdata.has_doorway(dir):
				var doormesh : MeshInstance3D = MeshInstance3D.new()
				doormesh.mesh = BoxMesh.new()
				doormesh.scale.z = 0.1
				doormesh.position = dir/1.9
				if dir.y != 0:
					doormesh.rotation_degrees.x = 90
				elif dir.x != 0:
					doormesh.rotation_degrees.y = 90
				doormesh.scale /= 1.5
				doormesh.material_override = doormaterial.duplicate(true)
				
				mesh.add_child(doormesh)
				boxdata.add_door_reference(doormesh,dir)
				
				DEV_OUTPUT.current.doormeshlist.append(doormesh)
				
				if boxdata.has_locked_door(dir):
					var lock_sprite : Sprite3D = Sprite3D.new()
					lock_sprite.texture = lock_icon
					lock_sprite.no_depth_test = true
					lock_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
					lock_sprite.position.y = 1
					lock_sprite.scale *= 3
					lock_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					lock_sprite.modulate = KeyInstance.get_key_color(boxdata.get_lock(dir))
					
					doormesh.add_child(lock_sprite)
			
			if boxdata.get_door(dir) == Box.CITY_EXIT_DOOR:
				var road_icon : MeshInstance3D = road_visual.duplicate()
				match dir:
					City.TOP: road_icon.rotation_degrees.y = 180
					City.BOTTOM: road_icon.rotation_degrees.y = 0
					City.LEFT: road_icon.rotation_degrees.y = 90
					City.RIGHT: road_icon.rotation_degrees.y = 270
				road_icon.scale *= 1.3
				mesh.add_child(road_icon)
				
	embedded_tutorial_setup()

func highlight()->void:
	if is_selected:
		return
	for child : Node3D in get_children():
		if child is MeshInstance3D and child.has_meta(&"boxdata"):
			
			child.material_override.emission_enabled = true
			child.material_override.emission = yellowglow
			child.material_override.emission_energy_multiplier = 0.75

func super_highlight()->void:
	is_selected = true
	for child : Node3D in get_children():
		if child is MeshInstance3D and child.has_meta(&"boxdata"):
			child.material_override.emission_enabled = true
			child.material_override.emission = pinkglow
			child.material_override.emission_energy_multiplier = 1

func disable_highlight()->void:
	is_selected = false
	for child : Node3D in get_children():
		if child is MeshInstance3D and child.has_meta(&"boxdata"):
			child.material_override.emission_enabled = false

func get_min_x()->int:
	var min : int = get_child(0).position.x
	for child : Node3D in get_children():
		if child.position.x < min:
			min = child.position.x
	return min + position.x

func get_max_x()->int:
	var max : int = get_child(0).position.x
	for child : Node3D in get_children():
		if child.position.x > max:
			max = child.position.x
	return max + position.x

func get_min_y()->int:
	var min : int = get_child(0).position.y
	for child : Node3D in get_children():
		if child.position.y < min:
			min = child.position.y
	return min + position.y

func get_max_y()->int:
	var max : int = get_child(0).position.y
	for child : Node3D in get_children():
		if child.position.y > max:
			max = child.position.y
	return max + position.y

func get_min_z()->int:
	var min : int = get_child(0).position.z
	for child : Node3D in get_children():
		if child.position.z < min:
			min = child.position.z
	return min + position.z

func get_max_z()->int:
	var max : int = get_child(0).position.z
	for child : Node3D in get_children():
		if child.position.z > max:
			max = child.position.z
	return max + position.z

func get_center()->Vector3:
	var pos : Vector3
	for child : Node3D in get_children():
		pos += child.global_position
	pos /= get_child_count()
	return pos

func get_center_local()->Vector3:
	var pos : Vector3
	for child : Node3D in get_children():
		pos += child.position
	pos /= get_child_count()
	return pos

func select()->void:
	is_selected = true
	room_instance_selected.emit()

func place()->void:
	is_selected = false
	room_instance_placed.emit()

func drop()->void:
	is_selected = false
	room_instance_dropped.emit()

func embedded_tutorial_setup()->void:
	if PopUps.tutorial_enabled and PopUps.next_tutorial_popup <= PopUps.TUTORIAL.MOVE_ROOM:
		room_instance_placed.connect(PopUps.call_tutorial.bind(PopUps.TUTORIAL.DROP_ROOM),CONNECT_ONE_SHOT)
