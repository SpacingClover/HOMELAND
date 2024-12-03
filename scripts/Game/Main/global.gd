extends Node

const current_debug_load : String = "res://demos/demo_levels_1.res"

var screenroots : Array[GameViewExports]

var circuitboard : WiringView
var shooterscene : PlayerView
var titlescreen : TitleScreen
var world3D : CityView
var mapview : MapView
var music : AudioStreamPlayer

var player : Player3D
var player_controlling : GameView
var mouse_over_view : GameView

var selected_game_dir : String #MUST be set or saving will not work

var current_game : GameData
var current_region : City
var current_room : Room

var local_mouse_pos : Vector2

var locked : bool = false
var menu_hidden : bool = false
var in_game : bool = false
var DEV_MODE : bool = false

signal loading_finished
signal hide_menu ## menu is titlescreen
signal open_menu
signal pause_game
signal resume_game
signal tutorial_called(which:int)
signal tutorial_closed(which:int)
signal transition_begin
signal transition_end

func _init()->void:
	pause_game.connect(pause)
	resume_game.connect(resume)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	print() ##before release, replace all tscn with scn and tres with res

func _ready()->void:
	screenroots = titlescreen.get_screen_roots()
	PopUps.global_ready()
	get_window().grab_focus()

func lock()->void:
	locked = true

func unlock()->void:
	locked = false
	player_controlling = mouse_over_view
	player_controlling.set_process_input(true)

func _input(event:InputEvent)->void:
	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
		if event.is_action_pressed(&"click") or event.is_action_pressed(&"rclick") or event.is_action_pressed(&"middle click"):
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	elif Input.is_action_just_pressed(&"escape") and in_game:
		if get_tree().paused:
			resume_game.emit()
		else:
			pause_game.emit()
	
	
	elif Input.is_action_just_pressed(&"`") and OS.is_debug_build():
		DEV_MODE = not DEV_MODE
		DEV_OUTPUT.current.visible = DEV_MODE
	
	elif Input.is_action_just_pressed(&"ui_page_up") and OS.is_debug_build():
		selected_game_dir = current_debug_load
		enter_game_transition(ResourceLoader.load(selected_game_dir,&"",ResourceLoader.CACHE_MODE_IGNORE))
		DEV_OUTPUT.push_message("load demo")
	
	elif Input.is_action_just_pressed(&"next_room") and OS.is_debug_build():
		if current_game and current_region and current_room:
			var room_idx : int = current_region.rooms.find(current_room)+1
			if room_idx >= current_region.rooms.size(): room_idx = 0
			enter_room(current_region.rooms[room_idx])
			DEV_OUTPUT.push_message("room incremented")

func enter_game_transition(game:GameData)->void:
	debug_reset()
	TransitionHandler.begin_transition(TransitionHandler.ANIM_SQUIGGLES_VERT)
	await get_tree().create_timer(1).timeout
	MusicManager.stop_song()
	
	in_game = true
	current_game = game
	if mapview: mapview.display_map(current_game)
	current_game.open()
	if circuitboard: circuitboard.load_board()
	if world3D: world3D.room_movement_axis = current_game.current_axis
	
	if mapview: mapview.show()
	if shooterscene: shooterscene.show()
	if circuitboard: circuitboard.show()
	if world3D: world3D.show()
	
	hide_menu.emit()
	menu_hidden = true
	
	TransitionHandler.end_transition()
	await get_tree().create_timer(1).timeout
	loading_finished.emit()
	MusicManager.play_song("ambience")

func set_new_city(city_idx:int,room_idx:int=-1,loading_game:bool=false)->void:
	if not loading_game:
		TransitionHandler.begin_transition(TransitionHandler.ANIM_CITY_TRANSITION_0)
		if mapview:
			var header : Label = MapView.current.header
			header.text = "Entering " + current_game.cities[city_idx].name.capitalize()
			header.modulate.a = 0
			create_tween().tween_property(header,"modulate:a",1,1)
			header.show()
		await get_tree().create_timer(1).timeout
	
	if current_region: current_region.exit_city()
	
	if world3D: world3D.reset_3d_view()
	current_region = current_game.cities[city_idx]
	if world3D: world3D.display_rooms()
	if room_idx < 0:
		room_idx = 0
	enter_room(current_region.rooms[room_idx],null,null,loading_game)
	
	current_region.enter_city()
	
	if not loading_game:
		TransitionHandler.end_transition()
		if mapview:
			var header : Label = MapView.current.header
			await get_tree().create_timer(1).timeout
			await create_tween().tween_property(header,"modulate:a",0,3).finished
			header.hide()

func enter_room(room:Room,startbox:Box=null,frombox:Box=null,loading_game:bool=false)->void:
	current_room = room
	if not startbox:
		startbox = current_room.boxes[0]
	if shooterscene:
		#shooterscene.load_room_interior(room,startbox,frombox)
		shooterscene.send_entity_to_room(player,room,startbox,frombox)
	if world3D: if not world3D.is_inside_tree():
		await world3D.tree_entered
	if loading_game and current_game.position != Vector3.ZERO and Global.player:
		Global.player.global_position = current_game.position
	if world3D:
		world3D.loaded_room_marker_offset = Vector3.ZERO
		world3D.loaded_room_marker_PREVIOUS_offset = Vector3.ZERO
		world3D.recenter_camera()
		world3D.set_marker_position(player)

func win_game()->void:
	TransitionHandler.begin_transition(TransitionHandler.MOVEMENTDEMO_COMPLETED)

func null_call()->void:
	pass

func pause()->void:
	get_tree().paused = true
	PopUps.prompt.hide()

func resume()->void:
	get_tree().paused = false
	PopUps.prompt.show()

func unload_game_and_exit_to_menu()->void:
	
	resume_game.emit()
	PopUps.prompt.hide()
	
	current_game = null
	current_region = null
	current_room = null
	
	world3D.reset_3d_view()
	shooterscene.reset()
	circuitboard.clear_board()
	mapview.reset_map()
	debug_reset()
	#titlescreen.extra.hide()
	#titlescreen.lists.hide()
	
	open_menu.emit()
	
	menu_hidden = false
	in_game = false
	
	MusicManager.play_song("action")

func debug_reset()->void:
	
	var inv : Node2D = titlescreen.get_node_or_null("25d_topbar_root")
	if inv:
		for child : Node in inv.get_children():
			child.queue_free()
	if Global.player:
		Global.player.DEBUG_inventory.clear()
