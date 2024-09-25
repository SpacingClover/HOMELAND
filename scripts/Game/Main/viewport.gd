class_name GameView extends SubViewportContainer

var draggable : bool = false
var orbitable : bool = false #3D
var clicking2d : bool = false
var hasplayer : bool = false
var _2point5D : bool = false #2.5D
var mapview : bool = false #map

var scrolling : bool = false
var scrolling_with_ctrl : bool = false
var wiring : bool = false

@onready var mouseproxy : Marker2D = $SubViewport/mouseproxy
@onready var mouseproxyarea : Area2D = $SubViewport/mouseproxy/area
@onready var subviewport : SubViewport = $SubViewport
var interacting_with : Node
var subroot : Node
var camera_root : Node3D #3D
var game_scene : Node
var menu_root : Control
var wirebase : WireNode
var mousepos : Vector2

func _init()->void:
	Global.hide_menu.connect(hide_menu)
	Global.open_menu.connect(open_menu)

func hide_menu()->void:
	if Global.menu_hidden:
		return
	if menu_root:
		menu_root.get_parent().remove_child(menu_root)
	if game_scene:
		get_child(0).add_child(game_scene)

func open_menu()->void:
	if not Global.menu_hidden:
		return
	if game_scene:
		game_scene.get_parent().remove_child(game_scene)
	if menu_root:
		get_parent().add_child(menu_root)

func _ready()->void:
	var parent : Node = get_parent()
	draggable = parent.omniscroll
	orbitable = parent.orbit3d
	clicking2d = parent.clicking2d
	hasplayer = parent.has_player
	_2point5D = parent.shooterscene
	mapview = parent.mapview
	mouse_entered.connect(pass_mousein)
	mouse_exited.connect(pass_mouseout)
	set_process_input(false)
	
	if clicking2d:
		mouseproxyarea.body_entered.connect(on_interactable)
		mouseproxyarea.body_exited.connect(off_interactable)
	
	await parent.ready #arrange viewport scenes
	if parent.get_child_count() > 1:
		subroot = parent.get_child(1)
		menu_root = parent.get_child(2)
		game_scene = subroot
		
		parent.remove_child(subroot)
		get_child(0).add_child(subroot)
		
		if orbitable:
			subroot.viewport = self
			camera_root = subroot.get_child(0)
			subroot = subroot.get_child(1)
		
		if hasplayer:
			Global.player.mouseproxy = mouseproxy
			mouseproxy.get_child(0).collision_mask = 2
		
		if _2point5D:
			Global.shooterscene = subroot
			subroot.viewport = self
		
		game_scene.get_parent().remove_child(game_scene)
	

func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"middle click") and not scrolling_with_ctrl:
		if draggable or orbitable:
			scrolling = true
			Global.lock()
			
	elif event.is_action_released(&"middle click") and not scrolling_with_ctrl:
		if draggable or orbitable:
			scrolling = false
			Global.unlock()
			if not has_control():
				set_process_input(false)
				
	elif event.is_action_pressed(&"ctrl") and not scrolling:
		if draggable or orbitable:
			scrolling = true
			scrolling_with_ctrl = true
			Global.lock()
			
	elif event.is_action_released(&"ctrl") and scrolling_with_ctrl:
		if draggable or orbitable:
			scrolling = false
			scrolling_with_ctrl = false
			Global.unlock()
			if not has_control():
				set_process_input(false)
		
	elif event.is_action_pressed(&"click") or event.is_action_released(&"click") or event.is_action_pressed(&"rclick") or event.is_action_released(&"rclick"):
		if interacting_with and interacting_with.has_method(&"pass_input"):
			if wiring and interacting_with is WireNode and not interacting_with.wire_drawing:
				wirebase.pass_input(event,interacting_with)
			else:
				interacting_with.pass_input(event,self)#default case
		elif wiring:#drop wire
			wirebase.pass_input(event)
		
	elif event.is_action_pressed(&"e"):
		if interacting_with and interacting_with.has_method(&"action"):
			interacting_with.action()
	
	elif event is InputEventMouseMotion:
		var temp : Vector2 = get_viewport().get_mouse_position()
		var vel : Vector2 = mousepos - temp
		if scrolling:
			if draggable:#wires
				subroot.camera.position += vel * 3
			elif orbitable:#3d view
				Global.world3D.orbit(vel,mapview)
				Global.mapview.orbit(vel,not mapview)
		mousepos = temp
		#place_mouse_proxy()

func pass_mousein()->void:
	Global.mouse_over_view = self
	if not Global.locked:
		Global.player_controlling = self
		set_process_input(true)
	if hasplayer:
		Global.player.getting_mouse = true

func pass_mouseout()->void:
	if not scrolling:
		set_process_input(false)
		if has_control():
			Global.player_controlling = null
	if hasplayer:
		Global.player.getting_mouse = false
	if mapview:
		Global.mapview.markerinfo.hide()
	if orbitable:
		if Global.world3D.hightlighted_room and not Global.world3D.selected_room:
			Global.world3D.hightlighted_room.disable_highlight()

func has_control()->bool:
	return Global.player_controlling == self

func on_interactable(body:Node)->void:
	if not hasplayer:
		interacting_with = body
	else:
		interacting_with = body.get_interactable()

func off_interactable(_x:Node)->void:
	interacting_with = null
	var bodies : Array = mouseproxyarea.get_overlapping_bodies()
	for body : PhysicsBody2D in bodies:
		#create some kind of interaction priority
		interacting_with = body
		return

func place_mouse_proxy()->void: #adapted from https://github.com/godotengine/godot/issues/34805
	var scale_factor : Vector2 = get_scale_factor()
	#mouseproxy.position = get_local_mouse_position() / Vector2(scale_factor)
	#if hasplayer:
		#mouseproxy.position += Global.player.camera.global_position - Vector2(550,324)
	#Global.local_mouse_pos = mouseproxy.global_position

func get_scale_factor()->Vector2: #adapted from https://github.com/godotengine/godot/issues/34805
	var viewport_base_size : Vector2i = (
	mouseproxy.get_viewport().size_2d_override if mouseproxy.get_viewport().size_2d_override > Vector2i(0, 0)
	else mouseproxy.get_viewport().size
	)
	return get_window().size / viewport_base_size 
