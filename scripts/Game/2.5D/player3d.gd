class_name Player3D extends CharacterBody3D

enum SPRITE_SECTIONS{ ##this will be an offset in the spritesheet depending on what the player is holding
	DEFAULT,
	PISTOL,
	SHOTGUN
}
var sprite_section : int = SPRITE_SECTIONS.DEFAULT

const CAMERACENTER : Vector3 = Vector3(0,2.36,5.795)
const BODYIDLEFRAME : int = 4
const BODY_BOBFRAME : int = 5
const LEGSIDLEFRAME : int = 0
const LEGSMINFRAME : int = 1
const LEGSMAXFRAME : int = 3

static var textureatlas : CompressedTexture2D = preload("res://visuals/spritesheets/characters/player.png")

@onready var camera : Camera3D = $cam
@onready var area   : Area3D   = $area
@onready var sprite : Sprite3D = $body
@onready var legs   : Sprite3D = $legs

signal report_click_position(pos:Vector3)

var legstween : Tween
var camerashaketween : Tween

var walking_direction : Vector3
var camerashakepos : Vector2

var camera_near_limit  : float = INF:
	set(x):camera_near_limit=x+3.7
var camera_left_limit  : float = -INF:
	set(x):camera_left_limit=x-2
var camera_right_limit : float = INF:
	set(x):camera_right_limit=x+2
var centered_room_pos : float
var speed : float = 2

var walking : bool = false
var running : bool = false
var legs_tweening : bool = false
var interacted_this_frame : bool = false
var camera_shaking : bool = false
var center_camera_in_room : bool = false

var DEBUG_selected_object : RoomItemInstance
var DEBUG_place_item_type : String
var DEBUG_mode_place_item : bool = false
var DEBUG_place_item_args : Array
var DEBUG_inventory : Array[RoomItem]

func _init()->void:
	Global.player = self

func _process(delta:float)->void:
	interacted_this_frame = false
	if not is_on_floor():
		walking_direction.y -= 2
	velocity = Vector3(walking_direction.x,walking_direction.y,walking_direction.z)
	move_and_slide()
	if walking:
		Global.world3D.set_marker_position(self)
	place_camera()

func _input(event:InputEvent)->void:
	if Global.shooterscene.viewport.has_control():
		if event.is_action_pressed(&"click"):
			left_click()
	
	if event is InputEventMouseMotion:
		mouse_motion()
		
	elif event.is_action(&"e"):
		if Input.is_action_just_pressed(&"e") and not interacted_this_frame:
			e_interaction()
		
	elif event.is_action(&"motion"):
		player_motion()
	
	elif event.is_action_pressed(&"shift"):
		running = true
	elif event.is_action_released(&"shift"):
		running = false
	
	elif event.is_action_pressed(&"space"):
		jump()
	
	if DEBUG_selected_object and is_instance_valid(DEBUG_selected_object):
		if event.is_action_pressed(&"arrow_keys_all"):
			if not Input.is_action_pressed(&"shift"):
				var vec : Vector2 = Input.get_vector(&"ui_left",&"ui_right",&"ui_up",&"ui_down")
				DEBUG_selected_object.apply_central_impulse(Vector3(vec.x,0,vec.y)*0.5)
			else:
				if Input.is_action_just_pressed(&"ui_left"):
					DEBUG_selected_object.apply_torque_impulse(Vector3(0,0.5,0))
				elif Input.is_action_just_pressed(&"ui_right"):
					DEBUG_selected_object.apply_torque_impulse(Vector3(0,-0.5,0))
				elif Input.is_action_just_pressed(&"ui_up"):
					DEBUG_selected_object.apply_torque_impulse(Vector3(0,0,0.5))
				elif Input.is_action_just_pressed(&"ui_down"):
					DEBUG_selected_object.apply_torque_impulse(Vector3(0,0,-0.5))
					
					
		elif event.is_action_pressed(&"ui_text_delete"):
			Global.shooterscene.room3d.objects.remove_at(Global.shooterscene.room3d.objects.find(DEBUG_selected_object))
			DEBUG_selected_object.queue_free(); DEBUG_selected_object = null; DEV_OUTPUT.push_message("item removed")

func left_click()->void:
	var collider : Node3D = get_clicked_object()
	if collider is RoomItemInstance:
		DEBUG_selected_object = collider
	report_click_position.emit(get_cursor_position())

func mouse_motion()->void:
	var mousepos : Vector2 = camera.unproject_position(get_cursor_position())
	var playerpos : Vector2 = camera.unproject_position(global_position+Vector3(0,0.494,0))
	
	if mousepos.x < playerpos.x:
		legs.flip_h = true
		sprite.flip_h = true
	else:
		legs.flip_h = false
		sprite.flip_h = false
	
	match sprite_section:
		SPRITE_SECTIONS.PISTOL:
			mousepos -= playerpos
			mousepos.x = abs(mousepos.x)
			mousepos.y *= -1
			sprite.frame = -floor(((round(playerpos.angle_to(mousepos)*5)+10)/15)*12)+10
		SPRITE_SECTIONS.DEFAULT:
			sprite.frame = 17

func e_interaction()->void:
	if DEBUG_mode_place_item and OS.is_debug_build():
		if not DEBUG_place_item_type:
			DEV_OUTPUT.current.push_message("no item type set"); return
		var scn : PackedScene = load("res://scenes/scn/"+DEBUG_place_item_type+".scn")
		if not scn: return
		var obj : RoomItemInstance = scn.instantiate()
		obj.item_id = RoomItem.item_ids.find(DEBUG_place_item_type)
		obj.pass_args(DEBUG_place_item_args)
		Global.shooterscene.room3d.add_child(obj)
		Global.shooterscene.room3d.objects.append(obj)
		obj.global_position = get_cursor_position()
		#obj.rotation_degrees.y += float(randi_range(0,1))*90
		interacted_this_frame = true
		DEV_OUTPUT.push_message(DEBUG_place_item_type+" created")
		return
	
	var closest : Node3D
	for body : Node3D in area.get_overlapping_areas() + area.get_overlapping_bodies():
		if body is Player3D: continue
		if not closest:
			closest = body; continue
		elif global_position.distance_to(body.global_position) < global_position.distance_to(closest.global_position):
			closest = body
	if closest:
	
		if closest.get_parent() is Door3D:
			closest.get_parent().toggle_door()
			interacted_this_frame = true
			return
		elif closest is RoomItemInstance:
			if closest.is_interactable:
				closest.interact()
				interacted_this_frame = true

func jump()->void:
	return
	if is_on_floor():
		walking_direction.y = 1.5

func player_motion()->void:
	var dir : Vector2 = Input.get_vector(&"a",&"d",&"w",&"s").normalized()*(speed*(1.5 if running else 1))
	walking_direction = Vector3(dir.x,walking_direction.y,dir.y)
	
	if dir != Vector2.ZERO:
		walking = true
		if not legs_tweening:
			legs_tweening = true
			legs.frame = LEGSMINFRAME
			legstween = create_tween().set_parallel()
			legstween.set_trans(Tween.TRANS_LINEAR)
			legstween.tween_property(legs,"frame",LEGSMAXFRAME,0.5)
			legstween.tween_property(sprite,"frame",BODY_BOBFRAME,0.5)
			legstween.finished.connect(
				func()->void:
					legs_tweening=false
					legs.frame=LEGSMINFRAME
					sprite.frame=BODYIDLEFRAME
					player_motion()
			)
	else:
		walking = false
		legs.frame = LEGSIDLEFRAME
		sprite.frame = BODYIDLEFRAME
		if legs_tweening:
			legs_tweening = false
			legstween.stop()
			legstween = null
	
	if get_viewport().get_parent().has_control():
		mouse_motion()

func shake_camera(intensity:float=0.5)->void:
	if camerashaketween:
		camerashaketween.stop()
	
	var disp : Vector2 = Vector2(0.2 if randi_range(0,1) == 1 else -0.2,0.2 if randi_range(0,1) == 1 else -0.2) * intensity
	
	camera_shaking = true
	camerashakepos = Vector2.ZERO
	camerashaketween = create_tween()
	camerashaketween.tween_property(self,"camerashakepos",disp,0.1)
	
	await camerashaketween.finished
	
	camerashaketween = create_tween()
	camerashaketween.set_trans(Tween.TRANS_ELASTIC)
	camerashaketween.set_ease(Tween.EASE_OUT)
	camerashaketween.tween_property(self,"camerashakepos",Vector2.ZERO,0.5)
	
	await camerashaketween.finished
	
	camera_shaking = false

func shoot(at_pos:Vector3)->void:
	Flash3D.new(at_pos)

func place_camera()->void:
	camera.position = CAMERACENTER
	if not center_camera_in_room:
		camera.global_position.x = clampf(camera.global_position.x,camera_right_limit,camera_left_limit)
	else:
		camera.global_position.x = centered_room_pos
	camera.global_position.z = clampf(camera.global_position.z,-INF,camera_near_limit)
	camera.global_position.x += camerashakepos.x
	camera.global_position.y += camerashakepos.y

func get_clicked_object()->Node3D:
	var firstcol : Node3D = cast_ray_for_obj()
	
	if not firstcol:
		return null
	
	if not firstcol is Door3D and not firstcol.get_parent() is Door3D:
		return cast_ray_for_obj(firstcol)
	else:
		return firstcol

func get_cursor_position()->Vector3:
	var firstcol : Node3D = cast_ray_for_obj()
	
	if not firstcol: #place mousepos on player depth plane
		var ray_normal : Vector3 = camera.project_local_ray_normal(get_viewport().get_mouse_position())
		ray_normal *= abs(camera.position.z)/sin(1.57079633-ray_normal.y)
		ray_normal.z = 0
		return ray_normal
	
	if not firstcol is Door3D and not firstcol.get_parent() is Door3D:
		return cast_ray_for_pos3D(firstcol)
	else:
		return cast_ray_for_pos3D()

func cast_ray_for_obj(exclude:Node3D=null)->Node3D:
	var result : Dictionary = cast_ray(exclude)
	if result.has(&"collider"): return result.collider
	return null

func cast_ray_for_pos3D(exclude:Node3D=null)->Vector3:
	var result : Dictionary = cast_ray(exclude)
	if not result.has(&"collider"): return Vector3.ZERO
	return result.position

func cast_ray(exclude:Node3D=null)->Dictionary:
	var mousepos : Vector2 = get_viewport().get_mouse_position()
	var from : Vector3 = camera.project_ray_origin(mousepos)
	var to : Vector3 = from + camera.project_ray_normal(mousepos)*10
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,8)
	
	if exclude:
		query.exclude = [exclude]
	
	return get_world_3d().direct_space_state.intersect_ray(query)

func get_coords_for_3D_view()->Vector3:
	var vec : Vector3 = Vector3(position.z,position.y+1,-position.x)/2
	return vec


func DEBUG_add_item_to_inventory(item:GrabbableItemInstance)->void:
	var icon : Sprite2D = item.get_as_sprite()
	icon.position.x = 100 * DEBUG_inventory.size()
	icon.scale *= 10
	Global.titlescreen.get_node("25d_topbar_root").add_child(icon)
	DEBUG_inventory.append(item.get_data())
