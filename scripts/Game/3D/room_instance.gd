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
var tag : Label3D

var is_selected : bool = false
var are_rooms_selectable : bool = false

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
		boxdata.doorvisuals.clear()
		
		var col : CollisionShape3D = CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		col.position = boxdata.coords
		add_child(col)
		
		for dir : Vector3i in City.DIRECTIONS:
			if boxdata.get_door(dir) != Box.NONE:
				add_child(RoomInstanceFace.new(data_reference,boxdata,dir,Global.is_level_editor_mode_enabled,Global.world3D.selecting_faces_directly))	
	
	embedded_tutorial_setup()

func highlight()->void:
	if is_selected:
		return
	for child : Node3D in get_children():
		if child is RoomInstanceFace:
			child.highlight()

func super_highlight()->void:
	is_selected = true
	for child : Node3D in get_children():
		if child is RoomInstanceFace:
			child.super_hightlight()

func disable_highlight()->void:
	is_selected = false
	for child : Node3D in get_children():
		if child is RoomInstanceFace:
			child.disable_highlight()

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

func show_tag()->void:
	tag.show()

func toggle_collision()->void:
	collision_layer = 0 if collision_layer == 1 else 1

func set_faces_selectable(to:bool)->void:
	for child : Node3D in get_children():
		if child is RoomInstanceFace:
			child.set_colliding(to)
		elif child is CollisionShape3D:
			child.disabled = to
	are_rooms_selectable = to

class RoomInstanceFace extends StaticBody3D:
	static var boxshape : BoxShape3D = BoxShape3D.new()
	static var planemesh : PlaneMesh = PlaneMesh.new()
	static func _static_init()->void:
		planemesh.size /= 2
		boxshape.size.y = 0.1
		pass #shape the boxmesh and planemesh
	var room : Room
	var box : Box
	var dir : Vector3i
	var mesh : MeshInstance3D
	var col : CollisionShape3D
	func _init(room_:Room,box_:Box,dir_:Vector3i,has_collision:bool=false,enabled:bool=false)->void:
		room = room_
		box = box_
		dir = dir_
		position = box.coords
		if box.get_door(dir) == Box.NONE:
			queue_free()
			return
		if has_collision:
			col = CollisionShape3D.new(); col.shape = boxshape
			col.disabled = not enabled
			col.position.y = 0.5
			add_child(col)
		match dir:
			City.LEFT:rotation_degrees = Vector3(-90,0,0)
			City.RIGHT:rotation_degrees = Vector3(90,0,0)
			City.TOP:rotation_degrees = Vector3(-90,90,0)
			City.BOTTOM:rotation_degrees = Vector3(-90,-90,0)
			City.DOWN:rotation_degrees = Vector3(0,0,180)
		mesh = MeshInstance3D.new(); mesh.mesh = planemesh
		mesh.position.y = 0.5
		
		if box.state == Box.RUBBLE:
			set_face_type(4)
		elif room is CityExit:
			set_mesh_material(RoomInstance3D.cityexitdoorroommaterial)
			if box.get_door(dir) == Box.CITY_EXIT_DOOR:
				set_face_type(3)
		elif room is Feature:
			set_mesh_material(RoomInstance3D.featureroommaterial.duplicate(true))
		else: ##normal face
			set_mesh_material(RoomInstance3D.boxmaterial.duplicate(true))
		if box.has_doorway(dir):
			set_face_type(2)
		add_child(mesh)
		
	func highlight()->void:
		mesh.material_override.emission_enabled = true
		mesh.material_override.emission = RoomInstance3D.yellowglow
		mesh.material_override.emission_energy_multiplier = 0.75
	func super_hightlight()->void:
		mesh.material_override.emission_enabled = true
		mesh.material_override.emission = RoomInstance3D.pinkglow
		mesh.material_override.emission_energy_multiplier = 1
	func disable_highlight()->void:
		mesh.material_override.emission_enabled = false
	func set_mesh_material(material:StandardMaterial3D)->void:
		mesh.material_override = material
	func set_colliding(to:bool)->void:
		if to: col.disabled = not get_parent().visible
		else: col.disabled = true
	func set_face_type(to:int,setdata:bool=false)->void:
		match to:
			0:## normal wall
				clear_children()
				if setdata: box.set_door(dir,Box.WALL); box.set_lock(dir,Box.NO_LOCK)
			1:## hole in the wall
				clear_children()
				var doormesh : MeshInstance3D = MeshInstance3D.new()
				doormesh.mesh = CylinderMesh.new()
				doormesh.scale = Vector3(0.8,0.05,0.8)
				doormesh.position.y = 0.5
				doormesh.material_override = RoomInstance3D.doormaterial.duplicate(true)
				add_child(doormesh)
				box.add_door_reference(doormesh,dir)
				if setdata: box.set_door(dir,Box.HOLE); box.set_lock(dir,Box.NO_LOCK)
			2:## door
				clear_children()
				add_door()
				if setdata: box.set_door(dir,Box.DOOR); box.set_lock(dir,Box.NO_LOCK)
			3 when room is CityExit:## city exit door
				clear_children()
				var road_icon : MeshInstance3D = RoomInstance3D.road_visual.duplicate()
				road_icon.scale *= 1.3
				match dir:
					City.LEFT: road_icon.rotation_degrees = Vector3(0,90,90)
					City.RIGHT: road_icon.rotation_degrees = Vector3(0,-90,90)
					City.TOP: road_icon.rotation_degrees = Vector3(0,90,90)
					City.BOTTOM: road_icon.rotation_degrees = Vector3(0,90,90)
					City.UP: road_icon.rotation_degrees = Vector3(0,0,90)
					City.DOWN: road_icon.rotation_degrees = Vector3(0,180,90)
				add_child(road_icon)
				add_door()
				if setdata: box.set_door(dir,Box.CITY_EXIT_DOOR); box.set_lock(dir,Box.NO_LOCK)
			4:## box rubble
				clear_children()
				if not is_inside_tree(): await tree_entered ## doesnt have parent on init
				for sibling : Node3D in get_parent().get_children():
					if sibling is RoomInstanceFace:
						if sibling.box == box:
							sibling.clear_children()
							sibling.set_mesh_material(RoomInstance3D.rubbleboxmaterial.duplicate(true))
							box.state = Box.HOLE
							box.set_door(sibling.dir,Box.HOLE)
				set_mesh_material(RoomInstance3D.rubbleboxmaterial.duplicate(true))
				if setdata: box.set_door(dir,Box.HOLE); box.set_lock(dir,Box.NO_LOCK)
		Global.current_region.check_for_adjacient_doors()
	func clear_children()->void:
		for child : Node3D in get_children():
			if child != col and child != mesh:
				if child is MeshInstance3D and box.get_door_reference(dir):
					box.remove_door_reference(child)
				else:
					child.queue_free()
	func add_door()->void:
		var doormesh : MeshInstance3D = MeshInstance3D.new()
		doormesh.mesh = BoxMesh.new()
		doormesh.scale = Vector3(0.7,0.1,0.7)
		doormesh.position.y = 0.5
		doormesh.material_override = RoomInstance3D.doormaterial.duplicate(true)
		add_child(doormesh)
		box.add_door_reference(doormesh,dir)
		
		if box.has_locked_door(dir):
			var lock_sprite : Sprite3D = Sprite3D.new()
			lock_sprite.texture = RoomInstance3D.lock_icon
			lock_sprite.no_depth_test = true
			lock_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lock_sprite.position = Vector3(0,0,1)
			lock_sprite.scale *= 3
			lock_sprite.scale.y *= 8
			lock_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			lock_sprite.modulate = KeyInstance.get_key_color(box.get_lock(dir))
			
			doormesh.add_child(lock_sprite)
