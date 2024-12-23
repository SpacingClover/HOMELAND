class_name CityView extends Node3D
static var current : CityView

static var visual_shader : StandardMaterial3D = preload("res://visuals/materials/3d_view_visual.tres")
static var offsetcube : ArrayMesh = preload("res://geometry/offsetcube.obj")
static var offsetcoll : ConvexPolygonShape3D = preload("res://geometry/offsetcube.shape")
static var bordermesh : ArrayMesh = preload("res://geometry/border.obj")

const ROOM_MOVE_RANGE : int = 5

enum{
	AXIS_X,
	AXIS_Y,
	AXIS_Z
}

@onready var root : Node3D = $root3d
@onready var camera_root : Node3D = $camera_root
@onready var camera : Camera3D = $camera_root/Camera3D
@onready var raycast : RayCast3D = $camera_root/Camera3D/raycast
@onready var bounds_raycast : RayCast3D = $bounds_raycast
@onready var playermarker : MeshInstance3D = $playermarker
@onready var overlay_camera : Camera3D = $camera_root/Camera3D/SubViewportContainer/SubViewport/Camera3D
@onready var axismarker : Node3D = $camera_root/Camera3D/SubViewportContainer/SubViewport/Camera3D/axis_marker

var viewport : GameView
var tween : Tween
var selected_room : RoomInstance3D
var hightlighted_room : RoomInstance3D
var room_last_selected : RoomInstance3D
var visual : Node3D
var room_movement_border : StaticBody3D
var highlighted_face : RoomInstance3D.RoomInstanceFace

var rooms_3D : Array[RoomInstance3D]

var selected_room_original_pos : Vector3
var selected_room_previous_pos : Vector3
var loaded_room_marker_offset : Vector3
var loaded_room_marker_PREVIOUS_offset : Vector3

var room_movement_axis : int = 0:
	set(val): room_movement_axis = val; axismarker.set_axis(val)

var dragging_room : bool = false
var motion_in_progress : bool = false
var change_axis_locked : bool = false
var selecting_faces_directly : bool = false

func _init()->void:
	Global.world3D = self
	CityView.current = self

func _ready()->void:
	orbit(Vector2.ZERO)
	axismarker._ready()

func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		mouse_motion()
	elif event.is_action_pressed(&"click"):
		Lclick()
	elif event.is_action_pressed(&"rclick"):
		Rclick()
	#elif Input.is_action_just_pressed(&"space"):
		#switch_axis()
	elif event.is_action_pressed(&"scroll_up"):
		change_zoom_amount(-1)
	elif event.is_action_pressed(&"scroll_down"):
		change_zoom_amount(1)
		

func change_zoom_amount(by:float)->void:
	by /= 10
	camera.size += by
	mouse_motion()

func orbit(vel:Vector2,lockvert:bool=false)->void:
	camera_root.global_rotation_degrees.y += vel.x
	if not lockvert:
		camera_root.rotation_degrees.x = clamp(camera_root.rotation_degrees.x+vel.y,-70,70)
	overlay_camera.global_rotation = camera.global_rotation
	axismarker.global_rotation = Vector3.ZERO

func mouse_motion()->void:
	var room : PhysicsBody3D = get_clicked()
	if Global.is_level_editor_mode_enabled and room is RoomInstance3D.RoomInstanceFace:
		if highlighted_face:
			if not is_instance_valid(highlighted_face):
				highlighted_face = null
			elif room != highlighted_face:
				highlighted_face.disable_highlight()
		highlighted_face = room
		highlighted_face.highlight()
	elif room is RoomInstance3D:
		if hightlighted_room and room != hightlighted_room and not hightlighted_room.is_selected:
			hightlighted_room.disable_highlight()
		if room.data_reference is Feature:
			return
		if room:
			room.highlight()
			
		hightlighted_room = room
		
	elif room is StaticBody3D and selected_room: #dragging room over axis visual
		slide_room_along_axis(get_click_pos(),AXIS_X)
		slide_room_along_axis(get_click_pos(),AXIS_Z)
		
	elif room == null and not selected_room and hightlighted_room: #unhighlight
		if not is_instance_valid(hightlighted_room):
			hightlighted_room = null
		else:
			hightlighted_room.disable_highlight()

func Lclick()->void:
	Global.titlescreen.editorgui.rightclickpopup.hide()
	var body : PhysicsBody3D = get_clicked()
	
	if Global.is_level_editor_mode_enabled and selecting_faces_directly:
		if body is RoomInstance3D.RoomInstanceFace:
			body.set_face_type(Global.titlescreen.editorgui.setfacetype.selected,true)
	
	elif selected_room:
		place_room()
		
	elif (body and body is RoomInstance3D) and not (body.data_reference is Feature and not Global.is_level_editor_mode_enabled):
		select_room(body)

func Rclick()->void:
	if selected_room:
		drop_selected_visual()
	elif Global.is_level_editor_mode_enabled:
		Global.titlescreen.editorgui.open_rightclick_popup(get_clicked())

func display_rooms()->void:
	rooms_3D.clear()
	for room_ref : Room in Global.current_region.rooms:
		display_room(room_ref)
	Global.current_region.check_for_adjacient_doors()

func display_room(room_ref:Room)->void:
	var room_3D : RoomInstance3D = RoomInstance3D.new(room_ref)
	root.add_child(room_3D)
	rooms_3D.append(room_3D)

func set_marker_position(object:Object)->void:
	##this must be altered so that each marked object is registered with a marker,
	##and object is looked up and the position is updated
	if not Global.player:
		return
	if object == Global.player:
		var pos : Vector3 = object.global_position
		playermarker.position = Vector3(pos.z,Global.current_room.roomvisual.global_position.y,-pos.x)/11.75
		if room_movement_axis != AXIS_Y:
			playermarker.position += loaded_room_marker_offset/5.85
		else:
			playermarker.position += loaded_room_marker_offset/6.39
		#camera_root.global_position = playermarker.position

func recenter_camera()->void:
	var cameratween : Tween = create_tween()
	cameratween.tween_property(camera_root,"position",Global.current_room.get_room_center()*root.scale,1)
	#cameratween.tween_property(camera_root,"position",Global.current_room.roomvisual.get_center(),1)

func select_room(room:RoomInstance3D)->void:
	selected_room = room
	selected_room.select()
	selected_room.super_highlight()
	create_visual(selected_room)
	selected_room_original_pos = selected_room.position
	selected_room_previous_pos = selected_room.position
	room_last_selected = selected_room
	raycast.collision_mask = 4
	create_room_movement_border()
	if Global.is_level_editor_mode_enabled: Global.titlescreen.editorgui.new_room_selected()

func switch_axis()->void:
	breakpoint
	if change_axis_locked: return
	
	room_movement_axis += 1
	
	if room_movement_axis > AXIS_Z:
		room_movement_axis = AXIS_X
	if room_movement_axis == AXIS_Y:
		room_movement_axis += 1
	
	if selected_room:
		if Global.current_region:
			Global.current_region.check_for_adjacient_doors()
	
	create_visual(selected_room)
	
	change_axis_locked = true
	await get_tree().create_timer(0.1).timeout
	change_axis_locked = false

func drop_selected_visual()->void:
	if selected_room:
		selected_room.drop()
		return_room_to_original_pos()
	selection_over()
	if Global.current_region:
		Global.current_region.check_for_adjacient_doors()

func return_room_to_original_pos()->void:
	var disp : Vector3 = -(selected_room.position-selected_room_original_pos)
	selected_room.data_reference.add_to_position(disp)
	selected_room.position = selected_room_original_pos
	if selected_room.data_reference == Global.current_room:
		loaded_room_marker_offset = loaded_room_marker_PREVIOUS_offset
		set_marker_position(Global.player)
	#var tween : Tween = create_tween()
	#tween.tween_property(selected_room,"position",selected_room_original_pos,0.05)

func look_for_box_at_coord(coord:Vector3i)->MeshInstance3D:
	for room : RoomInstance3D in rooms_3D:
		for i : MeshInstance3D in room.get_children():
			var box : Box = i.get_meta(&"boxdata")
			if box.coords == coord:
				return i
	return

func update_raycast()->void:
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()#relative to subviewport
	
	mouse_pos -= viewport.size/2 #move (0,0) to center in viewport
	mouse_pos /= ((viewport.size/Vector2(viewport.size.x/viewport.size.y,1)) / camera.size) #scale to fit
	
	raycast.position = Vector3(mouse_pos.x,-mouse_pos.y,0)
	
	raycast.clear_exceptions()
	if Global.current_room and Global.in_game:
		raycast.add_exception(Global.current_room.roomvisual)
	
	raycast.force_raycast_update()

func get_clicked()->PhysicsBody3D:
	update_raycast()
	return raycast.get_collider()

func get_click_pos()->Vector3:
	update_raycast()
	return raycast.get_collision_point()

func place_room()->void:
	selected_room.place()
	if selected_room.data_reference == Global.current_room:
		loaded_room_marker_PREVIOUS_offset = loaded_room_marker_offset
	selection_over()
	Global.current_region.check_for_adjacient_doors()
	if not Global.is_level_editor_mode_enabled: recenter_camera()

func get_room_bounds_on_axis(room:RoomInstance3D,axis:int)->RoomVisualBoundsInformation:
	var data : RoomVisualBoundsInformation = RoomVisualBoundsInformation.new(axis)
	var dir : Vector3 = Vector3.ZERO
	var max : Vector3
	var min : Vector3
	var minset : bool = false
	var maxset : bool = false
	match axis:
		AXIS_X: dir.x = 100
		AXIS_Y: dir.y = 100
		AXIS_Z: dir.z = 100
	
	bounds_raycast.add_exception(room)
	
	bounds_raycast.target_position = dir
	for i : int in range(2):
		for child : Node3D in room.get_children():
			if not (child is CollisionShape3D):#all works
				continue
			
			bounds_raycast.global_position = child.global_position #works
			bounds_raycast.force_raycast_update()
			
			if not bounds_raycast.is_colliding(): #should work
				continue
			
			var collision_as_distance : Vector3 = bounds_raycast.get_collision_point() - bounds_raycast.global_position
			
			var axis_pos : float
			match axis:
				AXIS_X: axis_pos = collision_as_distance.x
				AXIS_Y: axis_pos = collision_as_distance.y
				AXIS_Z: axis_pos = collision_as_distance.z
			
			var current_max : float
			match axis:
				AXIS_X: current_max = max.x
				AXIS_Y: current_max = max.y
				AXIS_Z: current_max = max.z
			
			var current_min : float
			match axis:
				AXIS_X: current_min = min.x
				AXIS_Y: current_min = min.y
				AXIS_Z: current_min = min.z
			
			if i == 0: #check positive
				if not maxset: #first positive collision, set
					max = collision_as_distance
					data.max_position = bounds_raycast.get_collision_point()
					data.max_projected_from = bounds_raycast.global_position
					maxset = true
				elif current_max > axis_pos: #later, set if closer
					max = collision_as_distance
					data.max_position = bounds_raycast.get_collision_point()
					data.max_projected_from = bounds_raycast.global_position
			if i == 1: #check negative
				if not minset: #first negative collision, set
					min = collision_as_distance
					data.min_position = bounds_raycast.get_collision_point()
					data.min_projected_from = bounds_raycast.global_position
					minset = true
				elif current_min < axis_pos: #later, set if closer
					min = collision_as_distance
					data.min_position = bounds_raycast.get_collision_point()
					data.min_projected_from = bounds_raycast.global_position
			
		bounds_raycast.target_position *= -1 #flips the bounds_raycast to check the other side
	
	bounds_raycast.remove_exception(room)
	return data

func create_visual(room:RoomInstance3D)->void:
	if not room:
		return
	if visual:
		visual.queue_free()
	visual = Node3D.new()
	root.add_child(visual)
		
	for axis : int in [AXIS_X,AXIS_Z]:
		
		var vpart : StaticBody3D = StaticBody3D.new()
		visual.add_child(vpart)
		var vmesh : MeshInstance3D = MeshInstance3D.new()
		vmesh.mesh = offsetcube
		vmesh.material_override = visual_shader
		vpart.collision_layer = 4
		vpart.add_child(vmesh)
		
		room.collision_layer = 0
		var bounds_info : RoomVisualBoundsInformation = get_room_bounds_on_axis(room,axis)
		
		var min_inf : bool = abs(bounds_info.min_position.length()) == 100
		var max_inf : bool = abs(bounds_info.max_position.length()) == 100
		var min_touching : bool = bounds_info.bounds().min == 0
		var max_touching : bool = bounds_info.bounds().max == 0
		
		vpart.global_position = room.get_center()
		vpart.scale *= Vector3(room.data_reference.scale)/2
		
		if min_inf and max_inf: ##both ends go into infinity
			vmesh.mesh = BoxMesh.new()
			vpart.scale *= 2
			match axis:
				AXIS_X: vpart.scale.x *= 100
				AXIS_Y: vpart.scale.y *= 100
				AXIS_Z: vpart.scale.z *= 100
		elif min_inf: ##negative end goes into infinity
			match axis:
				AXIS_X:
					vpart.look_at(vpart.global_position + Vector3.BACK)
					vpart.global_position.x = bounds_info.max_position.x
				AXIS_Y:
					vpart.look_at(vpart.global_position + Vector3.LEFT,Vector3.FORWARD)
					vpart.global_position.y = bounds_info.max_position.y
				AXIS_Z:
					vpart.look_at(vpart.global_position + Vector3.LEFT)
					vpart.global_position.z = bounds_info.max_position.z
					vpart.scale = Vector3(vpart.scale.z,vpart.scale.y,vpart.scale.x)
			vpart.scale.x *= 100
		elif max_inf: ##positive end goes into infinity
			match axis:
				AXIS_X:
					vpart.look_at(vpart.global_position + Vector3.FORWARD)
					vpart.global_position.x = bounds_info.min_position.x
				AXIS_Y:
					vpart.look_at(vpart.global_position + Vector3.RIGHT,Vector3.FORWARD)
					vpart.global_position.y = bounds_info.min_position.y
				AXIS_Z:
					vpart.look_at(vpart.global_position + Vector3.RIGHT)
					vpart.global_position.z = bounds_info.min_position.z
					vpart.scale = Vector3(vpart.scale.z,vpart.scale.y,vpart.scale.x)
			vpart.scale.x *= 100
		else: ##both ends collide
			vmesh.mesh = BoxMesh.new()
			vpart.scale *= 2
			if not (min_touching and max_touching):
				var center : Vector3 = room.get_center()
				var col_midpoint : Vector3 = bounds_info.col_midpoint()
				print(bounds_info.length() * 5.9)
				match axis:
					AXIS_X: vpart.global_position = Vector3(col_midpoint.x,center.y,center.z); vpart.scale.x = bounds_info.length() * 5.9
					AXIS_Y: vpart.global_position = Vector3(center.x,col_midpoint.y,center.z); vpart.scale.y = bounds_info.length() * 5.9
					AXIS_Z: vpart.global_position = Vector3(center.x,center.y,col_midpoint.z); vpart.scale.z = bounds_info.length() * 5.9
			else:
				vpart.queue_free(); vpart = null; return
					
		vpart.position = round(vpart.position*2)/2

func slide_room_along_axis(mouse_coords:Vector3,axis:int=room_movement_axis)->void:
	var bounds_info : RoomVisualBoundsInformation = get_room_bounds_on_axis(selected_room,axis)
	
	var pos : Vector3 = mouse_coords
	pos -= selected_room_previous_pos * root.scale
	match axis:
		AXIS_X: if abs(pos.x - (selected_room_previous_pos.x*root.scale.x)) < 0.05: return
		AXIS_Y: if abs(pos.y - (selected_room_previous_pos.y*root.scale.y)) < 0.05: return
		AXIS_Z: if abs(pos.z - (selected_room_previous_pos.z*root.scale.z)) < 0.05: return
	pos /= root.scale
	pos -= selected_room.get_center_local()
	pos = round(pos)
	
	var disp : Vector3 = pos
	var move_by : int
	var direction_positive : bool #if the direction is positive / towards max
	match axis:
		AXIS_X:
			if disp.x > 0: direction_positive = true
			elif disp.x < 0: direction_positive = false
			move_by = disp.x
			disp.y = 0; disp.z = 0
		AXIS_Y:
			if disp.y > 0: direction_positive = true
			elif disp.y < 0: direction_positive = false
			move_by = disp.y
			disp.x = 0; disp.z = 0
		AXIS_Z:
			if disp.z > 0: direction_positive = true
			elif disp.z < 0: direction_positive = false
			move_by = disp.z
			disp.x = 0; disp.y = 0
	
	pos -= (Vector3(selected_room.data_reference.scale)*2) * int(direction_positive) #moves room so that the center is about the cursor
	
	if move_by == 0: selected_room.position = selected_room_previous_pos; return
	
	if direction_positive:
		var max : int = bounds_info.bounds().max
		if max == 0: selected_room.position = selected_room_previous_pos; return
		elif move_by > max:
			match axis:
				AXIS_X: disp = Vector3(max,0,0)
				AXIS_Y: disp = Vector3(0,max,0)
				AXIS_Z: disp = Vector3(0,0,max)
	else:
		var min : int = bounds_info.bounds().min
		if min == 0: selected_room.position = selected_room_previous_pos; return
		elif abs(move_by) > min:
			match axis:
				AXIS_X: disp = Vector3(-min,0,0)
				AXIS_Y: disp = Vector3(0,-min,0)
				AXIS_Z: disp = Vector3(0,0,-min)
	
	##check if room is within bounds
	if not Global.is_level_editor_mode_enabled:
		var difference : Vector3i = abs((selected_room.data_reference.coords+Vector3i(disp))-selected_room.data_reference.original_coords)
		if direction_positive: difference += selected_room.data_reference.scale - Vector3i(1,1,1)
		match axis:
			AXIS_X when difference.x >= ROOM_MOVE_RANGE: return
			AXIS_Y when difference.y >= ROOM_MOVE_RANGE: return
			AXIS_Z when difference.z >= ROOM_MOVE_RANGE: return
	
	selected_room.position = selected_room_previous_pos + disp
	selected_room.data_reference.add_to_position(disp)
	selected_room_previous_pos = selected_room.position
	
	update_doors_in_moved_room(selected_room.data_reference)
	Global.current_region.check_for_adjacient_doors()
	
	create_visual(selected_room)
	
	if Global.current_room == selected_room.data_reference and Global.shooterscene:
		Global.player.shake_camera()
		loaded_room_marker_offset += disp
		set_marker_position(Global.player)

func create_room_movement_border()->void:
	if room_movement_border: room_movement_border.queue_free()
	room_movement_border = StaticBody3D.new()
	
	var mesh : MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = bordermesh
	mesh.layers = 1
	mesh.position = selected_room.data_reference.original_coords
	mesh.scale *= float(ROOM_MOVE_RANGE) - 0.5
	mesh.scale.y = 0.5
	var mat : StandardMaterial3D = StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.75,0.2,0)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh.material_override = mat
	room_movement_border.add_child(mesh)
	mesh.create_convex_collision()
	var col : StaticBody3D = mesh.get_child(0)
	col.collision_layer = 4
	col.scale.y = 0.01
	
	#room_movement_border.collision_layer = 4
	
	if Global.is_level_editor_mode_enabled and not Global.in_game:
		mesh.hide()
		col.scale.x *= 100000
		col.scale.z *= 100000
	root.add_child(room_movement_border)

func update_doors_in_moved_room(room:Room)->void:
	
	if Global.current_room == room and Global.shooterscene and Global.in_game: #if the affected room is currently loaded in 2.5D scene
		for door : Door3D in Global.shooterscene.room3d.doors:
			if door.is_open:
				door.close()
			#door.handle_lock_icon()
				
	for box : Box in room.boxes: #all cases, set door data for unloaded doors and unloaded adjactient doors, and close loaded adjacient doors
		for direction : Vector3i in City.DIRECTIONS:
			
			if box.has_doorway(direction,true): #good
				box.set_door(direction,Box.DOOR)
				
				var adjacient_box : Box = Global.current_region.get_box_at(box.coords+direction)
				if adjacient_box:
					if adjacient_box.has_doorway(-direction,true):
						adjacient_box.set_door(-direction,Box.DOOR)
						
						var adjacient_room : Room = Global.current_region.get_room_at(box.coords+direction)
						if Global.current_room == adjacient_room:
							var door : Door3D = Global.shooterscene.room3d.get_door_at(adjacient_box,-direction)
							if door:
								if door.is_open:
									door.close()
								#door.handle_lock_icon()

func reset_3d_view()->void:
	selection_over()
	if Global.current_region:
		Global.current_region.clear_visuals()
	for child : Node3D in root.get_children():
		child.queue_free()

func selection_over()->void:
	if visual:
		visual.queue_free()
	if room_movement_border:
		room_movement_border.queue_free()
	if selected_room:
		selected_room.collision_layer = 1
		selected_room.disable_highlight()
	visual = null
	dragging_room = false
	room_movement_border = null
	selected_room = null
	hightlighted_room = null
	raycast.collision_mask = 1

class Limit extends RefCounted:
	func _init(min_:float,max_:float)->void:
		min = min_
		max = max_
	var min : float
	var max : float
	func length()->float:
		return abs(max - min) - 1
	func mean()->float:
		return (max+min)/2
	func _to_string()->String:
		return "("+str(min)+","+str(max)+")"
	func multiply(by:float)->Limit:
		return Limit.new(min*by,max*by)
	func divide(by:float)->Limit:
		return Limit.new(min/by,max/by)
	func add(by:float)->Limit:
		return Limit.new(min+by,max+by)
	func sub(by:float)->Limit:
		return Limit.new(min-by,max-by)
	func floor()->Limit:
		return Limit.new(floor(min),floor(max))
	func ceil()->Limit:
		return Limit.new(ceil(min),ceil(max))
	func round()->Limit:
		return Limit.new(round(min),round(max))

class RoomVisualBoundsInformation extends RefCounted:
	func _init(on_axis:int)->void:
		axis = on_axis
		match axis:
			AXIS_X: min_position = Vector3(-100,0,0); max_position = Vector3(100,0,0)
			AXIS_Y: min_position = Vector3(0,-100,0); max_position = Vector3(0,100,0)
			AXIS_Z: min_position = Vector3(0,0,-100); max_position = Vector3(0,0,100)
	var min_position : Vector3
	var max_position : Vector3
	var min_projected_from : Vector3
	var max_projected_from : Vector3
	var axis : int
	func bounds()->Limit:
		return Limit.new((min_position - min_projected_from).length(),(max_position - max_projected_from).length()).divide(0.172).floor()
	func length()->float:
		return min_position.distance_to(max_position)
	func col_midpoint()->Vector3:
		return (min_position+max_position)/2
	func get_axis()->int:
		return axis

func create_room(of_type:int)->void:
	var room : Room
	match of_type:
		0: room = Room.new(Vector3i(1,1,1),Vector3i.ZERO,true)
		1: room = CityExit.new(Vector3i(1,1,1),Vector3i.ZERO,true)
		2: room = Feature.new(Vector3i(1,1,1),Vector3i.ZERO,true)
	Global.current_region.rooms.append(room)
	Global.current_region.validate_city()
	display_room(room)
	select_room(room.roomvisual)

func delete_room()->void:
	if not is_instance_valid(room_last_selected):
		room_last_selected = null
		return
	if room_last_selected:
		if selected_room:
			drop_selected_visual()
		Global.current_region.rooms.remove_at(room_last_selected.data_reference.index)
		room_last_selected.queue_free()
		Global.titlescreen.editorgui.deleteroom.disabled = true
	if hightlighted_room:
		if is_instance_valid(hightlighted_room):
			hightlighted_room.disable_highlight()
		hightlighted_room = null
	Global.titlescreen.editorgui.display_spawn_info()
