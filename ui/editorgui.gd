extends Node

@onready var leftpanel : PanelContainer = %leftpanel
@onready var newbutton : Button = %create_new_room
@onready var roomtype : OptionButton = %create_new_room_options
@onready var deleteroom : Button = %delete_room
@onready var scalex : SpinBox = %scalex
@onready var scaley : SpinBox = %scaley
@onready var scalez : SpinBox = %scalez
@onready var applyscale : Button = %apply_scale
@onready var editfaces : Button = %edit_faces_toggle
@onready var isolateroom : Button = %isolate_room_toggle
@onready var setfacetype : OptionButton = %face_type
@onready var creategame : Button = %new_game
@onready var savegame : Button = %save_game
@onready var opengame : Button = %open_game
@onready var closeeditor : Button = %close_editor
@onready var rightpanel : PanelContainer = %rightpanel
@onready var gamename : LineEdit = %gamename
@onready var gamedescription : TextEdit = %description
@onready var cityname : LineEdit = %cityname
@onready var pickcity : OptionButton = %pickcity_list
@onready var newcity : Button = %create_new_city
@onready var switchcity : Button = %switch_city_confirm
@onready var deletecity : Button = %delete_city
@onready var citypanel : PanelContainer = %citypanel
@onready var open_mapview_editor : Button = %open_mapview_editor
@onready var selectfilescontainer : PanelContainer = %opengamepopup
@onready var fileslist : OptionButton = %loadable_games_list
@onready var selectfilebutton : Button = %load_selected_game
@onready var cancelfileslist : Button = %close_opengamepopup
@onready var rightclickpopup : PanelContainer = %rightclickpopup
@onready var popupvbox : VBoxContainer = %popupvbox
@onready var submitbutton : Button = %set_lock_confirm
@onready var set_tocity : Button = %set_tocity_confirm
@onready var set_toexit : Button = %set_toexit_confirm
@onready var rightclicklabel : Label = %rightclicklabel
@onready var roomcontents : Button = %roomcontents_display
@onready var lockinput : HBoxContainer = %lockinput
@onready var tocityinput : HBoxContainer = %tocityinput
@onready var toexitinput : HBoxContainer = %toexitinput
@onready var lockspinbox : SpinBox = %pick_lock_value
@onready var cityspinbox : SpinBox = %pick_tocity_value
@onready var exitspinbox : SpinBox = %pick_toexit_value
@onready var default_spawn_setter : Button = %set_room_default_spawn
@onready var debug_spawn_setter : Button = %set_room_debug_spawn
@onready var new_connection : Button = %new_connection
@onready var choose_connection : MenuButton = %choose_connection
@onready var remove_connection : Button = %remove_connection
@onready var savegamepopup : PanelContainer = %savegamepopup
@onready var saveaddressinput : LineEdit = %savegame_filename_input
@onready var confirmsave : Button = %savegame_confirm
@onready var cancelsave : Button = %savegame_cancel
@onready var open_rooms_editor : Button = %open_rooms_editor
@onready var open_interior_editor : Button = %open_interior_editor
@onready var bottomright : PanelContainer = %bottomright
@onready var playtest : Button = %launch_game_default
@onready var playtest_debugspawn : Button = %debug_launch
@onready var playtestgui : PanelContainer = %playtestgui
@onready var endplaytest : Button = %quit_playtest
@onready var interiorgui : PanelContainer = %interiorgui
@onready var pickroomitem : OptionButton = %pickroomitem
@onready var createitem : Button = %createitem
@onready var deleteitem : Button = %deleteitem
@onready var move_item : Button = %move_item
@onready var createentity : Button = %createentity
@onready var factionselect : MenuButton = %factionselect
@onready var weaponselect : MenuButton = %weaponselect

var last_selected_face : RoomInstance3D.RoomInstanceFace
var editor_selected_city : City
var selected_item : RoomItemInstance
var selected_npc : NPC
var interacted_room : Room

var debug_city : City
var debug_room : Room
var debug_position : Vector3

var loaded_path : String

var room_isolation_mode : bool = false
var interiorview : bool = false
var mapvieweditor : bool = false
var placeitemmode : bool = false
var placeentitymode : bool = false
var moving_item_inside_room : bool = false

func _ready()->void:
	newbutton.pressed.connect(func()->void:Global.world3D.create_room(roomtype.selected))
	deleteroom.pressed.connect(Global.world3D.delete_room)
	applyscale.pressed.connect(rescale_room)
	editfaces.pressed.connect(edit_faces)
	isolateroom.pressed.connect(isolate_room)
	scalex.value_changed.connect(check_scale_value)
	scaley.value_changed.connect(check_scale_value)
	scalez.value_changed.connect(check_scale_value)
	opengame.pressed.connect(open_files_menu)
	selectfilebutton.pressed.connect(func()->void:open_game(fileslist.get_item_text(fileslist.selected).split(&" ")[0]))
	cancelfileslist.pressed.connect(selectfilescontainer.hide)
	closeeditor.pressed.connect(Global.close_level_editor)
	creategame.pressed.connect(create_new_empty_game)
	savegame.pressed.connect(open_save_game_popup)
	submitbutton.pressed.connect(set_face_lock)
	set_tocity.pressed.connect(set_cityexit_nextcity)
	set_toexit.pressed.connect(set_cityexit_corresponding_exit)
	gamename.text_submitted.connect(func(s:String)->void:Global.current_game.game_name=s;gamename.release_focus())
	cityname.text_submitted.connect(func(s:String)->void:Global.current_region.name=s;index_cities();cityname.release_focus())
	gamedescription.text_changed.connect(func(s:String)->void:Global.current_game.description=s)
	saveaddressinput.text_submitted.connect(func(s:String)->void:addressbar_changed(s);saveaddressinput.release_focus())
	newcity.pressed.connect(create_new_city)
	confirmsave.pressed.connect(save_game)
	cancelsave.pressed.connect(savegamepopup.hide)
	deletecity.pressed.connect(delete_city)
	playtest.pressed.connect(test_level)
	playtest_debugspawn.pressed.connect(test_level.bind(false))
	endplaytest.pressed.connect(exit_playtest)
	default_spawn_setter.pressed.connect(set_room_default_spawn)
	debug_spawn_setter.pressed.connect(set_room_debug_spawn)
	open_mapview_editor.pressed.connect(open_city_editor)
	open_rooms_editor.pressed.connect(open)
	open_interior_editor.pressed.connect(open_roominterior_editor)
	pickcity.item_selected.connect(switch_city)
	new_connection.pressed.connect(func()->void:Global.current_game.city_connections_register.create_new_connection(Global.current_region,Global.world3D.room_last_selected.data_reference);rightclickpopup.hide())
	choose_connection.about_to_popup.connect(populate_connection_list)
	choose_connection.get_popup().id_pressed.connect(func(id:int)->void:Global.current_game.city_connections_register.connections[id].connect_city(Global.current_region,Global.world3D.room_last_selected.data_reference);rightclickpopup.hide())
	remove_connection.pressed.connect(func()->void:Global.current_game.city_connections_register.remove_whole_connection(editor_selected_city);rightclickpopup.hide())
	deleteitem.pressed.connect(func()->void:if selected_item:selected_item.queue_free();selected_item=null;rightclickpopup.hide();
	elif selected_npc:selected_npc.queue_free();selected_npc=null;rightclickpopup.hide())
	createitem.pressed.connect(func()->void:placeitemmode=true)
	move_item.pressed.connect(func()->void:start_object_movement();moving_item_inside_room=true;rightclickpopup.hide())
	createentity.pressed.connect(func()->void:placeitemmode=true;placeentitymode=true)
	factionselect.get_popup().id_pressed.connect(switch_npc_faction)
	weaponselect.get_popup().id_pressed.connect(set_npc_combatmode)
	close()

func open()->void:
	Global.player.hide()
	Global.player.position = Vector3(INF,INF,INF)
	leftpanel.show()
	rightpanel.show()
	bottomright.show()
	selectfilescontainer.hide()
	rightclickpopup.hide()
	savegamepopup.hide()
	playtestgui.hide()
	citypanel.show()
	interiorgui.show()
	Global.focus_on_screen(Global.SCREENS.TOPRIGHT)
	Global.world3D.playermarker.hide()
	if not Global.current_game:
		create_new_empty_game()
	mapvieweditor = false
	if interiorview:
		Global.world3D.recenter_camera(0)
		if Global.shooterscene.room3d:
			save_room_interior_items()
	interiorview = false
	update_display()
	DEV_OUTPUT.current.visible = true
	Global.set_camera_layer(1,1)	
	Global.set_camera_layer(0,2)
	Global.shooterscene.reset()
	Global.world3D.room_last_selected = null
	Global.shooterscene.show()

func close()->void:
	leftpanel.hide()
	rightpanel.hide()
	bottomright.hide()
	selectfilescontainer.hide()
	rightclickpopup.hide()
	savegamepopup.hide()
	playtestgui.hide()
	citypanel.hide()
	interiorgui.hide()
	Global.unfocus_screens()
	Global.world3D.playermarker.hide()
	if Global.world3D.selecting_faces_directly: edit_faces()
	DEV_OUTPUT.current.visible = false
	Global.set_camera_layer(1,1)
	Global.set_camera_layer(0,2)
	Global.shooterscene.reset()
	Global.world3D.room_last_selected = null

func open_city_editor()->void:
	mapvieweditor = false
	if interiorview:
		Global.world3D.recenter_camera(0)
		if Global.shooterscene.room3d:
			save_room_interior_items()
	Global.focus_on_screen(Global.SCREENS.BOTTOMRIGHT)
	Global.mapview.display_map(Global.current_game)
	Global.mapview.show()
	mapvieweditor = true
	update_display()
	Global.shooterscene.reset()

func open_roominterior_editor()->void:
	if Global.world3D.room_last_selected:
		DEV_OUTPUT.push_message(r"yas room")
		interiorview = true
		Global.focus_on_screen(Global.SCREENS.TOPRIGHT)
		var room : RoomInterior3D = Global.shooterscene.load_room_interior(Global.world3D.room_last_selected.data_reference,true)
		Global.world3D.recenter_camera(0,room.get_roominterior_center(),true)
		Global.set_camera_layer(1,2)
		update_display()
		for child : Node3D in room.get_children():
			if child is PhysicsBody3D:
				child.set_collision_layer_value(1,true)
		pickroomitem.clear()
		for i : int in RoomItem.item_ids.size():
			if RoomItem.item_ids[i] != &"":
				pickroomitem.add_item(RoomItem.item_ids[i],i)
		rightclickpopup.hide()

func update_display()->void:
	newbutton.disabled = room_isolation_mode or Global.world3D.selecting_faces_directly or mapvieweditor or interiorview
	roomtype.disabled = newbutton.disabled
	applyscale.disabled = Global.world3D.selecting_faces_directly or mapvieweditor or interiorview or not(Global.world3D.room_last_selected and is_instance_valid(Global.world3D.room_last_selected))
	scalex.editable = not applyscale.disabled
	scaley.editable = not applyscale.disabled
	scalez.editable = not applyscale.disabled
	editfaces.disabled = mapvieweditor or interiorview or not(Global.world3D.room_last_selected and is_instance_valid(Global.world3D.room_last_selected))
	isolateroom.disabled = editfaces.disabled

func rescale_room()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	var room : Room = roomvisual.data_reference
	Global.world3D.drop_selected_visual()
	roomvisual.queue_free()
	roomvisual.data_reference.scale = Vector3i(scalex.value,scaley.value,scalez.value)
	roomvisual.data_reference.validated = false
	roomvisual.data_reference.validate(Global.current_region)
	Global.world3D.display_room(room)
	Global.world3D.room_last_selected = room.roomvisual
	check_scale_value()
	update_display()

func new_room_selected()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	scalex.value = roomvisual.data_reference.scale.x
	scaley.value = roomvisual.data_reference.scale.y
	scalez.value = roomvisual.data_reference.scale.z
	check_scale_value()
	deleteroom.disabled = false
	update_display()

func check_scale_value(value:float=0.0)->void:
	var roominstance : RoomInstance3D = Global.world3D.room_last_selected
	if roominstance and is_instance_valid(roominstance):
		var disable : bool = Global.world3D.room_last_selected.data_reference.scale == Vector3i(scalex.value,scaley.value,scalez.value)
		applyscale.disabled = disable

func edit_faces()->void:
	Global.world3D.selecting_faces_directly = not Global.world3D.selecting_faces_directly
	for roominstance : Node3D in Global.world3D.root.get_children():
		if roominstance is RoomInstance3D:
			roominstance.set_faces_selectable(Global.world3D.selecting_faces_directly)
	DEV_OUTPUT.push_message(str(Global.world3D.selecting_faces_directly))
	newbutton.disabled = Global.world3D.selecting_faces_directly
	deleteroom.disabled = Global.world3D.selecting_faces_directly
	check_scale_value()
	scalex.editable = not Global.world3D.selecting_faces_directly
	scaley.editable = not Global.world3D.selecting_faces_directly
	scalez.editable = not Global.world3D.selecting_faces_directly
	isolateroom.disabled = Global.world3D.selecting_faces_directly
	editfaces.text = ("disable" if Global.world3D.selecting_faces_directly else "enable") + " edit faces"
	setfacetype.disabled = not Global.world3D.selecting_faces_directly
	update_display()

func isolate_room()->void:
	for roomvisual : RoomInstance3D in Global.world3D.root.get_children():
		if roomvisual != Global.world3D.room_last_selected:
			roomvisual.visible = not roomvisual.visible
			roomvisual.toggle_collision()
	room_isolation_mode = not room_isolation_mode
	newbutton.disabled = room_isolation_mode
	deleteroom.disabled = room_isolation_mode
	isolateroom.text = ("disable" if room_isolation_mode else "enable") + " isolate room"
	update_display()

func open_files_menu()->void:
	selectfilescontainer.show()
	fileslist.clear()
	if not DirAccess.dir_exists_absolute(r"user://editor_levels/"):
		DirAccess.make_dir_absolute(r"user://editor_levels/")
	var files : Array[String]
	for file : String in DirAccess.get_files_at(r"user://editor_levels/"):
		if file == "temp.res": continue
		var string : String = file.split(&".")[0] + &"   -----   " + Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(r"user://editor_levels/"+file),true)
		files.append(string)
	for dir : String in files: fileslist.add_item(dir)
	if files.size() != 0: fileslist.selected = 0; selectfilebutton.disabled = false
	else: selectfilebutton.disabled = true

func open_game(dir:String,save_path:bool=true)->void:
	selectfilescontainer.hide()
	var path : String = r"user://editor_levels/"+dir+r".res"
	if save_path: loaded_path = path
	Global.current_game = ResourceLoader.load(path,&"",ResourceLoader.CACHE_MODE_IGNORE)
	Global.current_region = Global.current_game.cities[0]
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	deleteroom.disabled = true
	fill_right_panel()
	update_display()

func open_rightclick_popup(obj:Node3D)->void:
	if not obj:
		rightclickpopup.hide()
		return
	
	for child : Control in popupvbox.get_children(): child.hide()
	
	if obj is RoomInstance3D:
		interacted_room = obj.data_reference
		rightclicklabel.text = r"Room " + str(obj.data_reference.index)
		rightclicklabel.show()
		var contents : Button = roomcontents
		contents.text = r"Contains " + str(obj.data_reference.items.size()) + r" items"
		contents.show()
		#set_room_debug_spawn()
		#playtest_debugspawn.show()
		#debug_position = Vector3.ZERO
		default_spawn_setter.show()
		deleteroom.show()
		deleteroom.disabled = false
		open_interior_editor.show()
		if obj.data_reference is CityExit:
			rightclicklabel.text = r"CityExit " + str(obj.data_reference.index)
			new_connection.show()
			choose_connection.show()
			remove_connection.show()
	elif obj is RoomInstance3D.RoomInstanceFace:
		last_selected_face = obj
		interacted_room = obj.room
		rightclicklabel.text = r"Face " + str(City.DIRECTIONS.find(obj.dir))
		rightclicklabel.show()
		if obj.box.has_doorway(obj.dir,true,false):
			lockspinbox.value = obj.box.get_lock(obj.dir)
			lockinput.show()
	elif obj is CityMarker3D:
		rightclicklabel.text = obj.city.get_city_string()
		rightclicklabel.show()
		editor_selected_city = obj.city
		deletecity.show()
	elif obj is RoomItemInstance:
		selected_item = obj
		rightclicklabel.text = RoomItem.get_item_name_by_id(obj.item_id)
		move_item.show()
		deleteitem.show()
	elif obj is Entity:
		rightclicklabel.text = Entity.get_faction_string(obj.get_faction())
		factionselect.show()
		factionselect.get_popup().clear()
		for i : int in Entity.FACTIONS_SIZE:
			factionselect.get_popup().add_item(Entity.get_faction_string(i),i)
		weaponselect.show()
		move_item.show()
		deleteitem.show()
		selected_npc = obj
	elif obj is RoomInterior3D:
		set_room_debug_spawn()
		debug_position = Global.world3D.get_click_pos()
		debug_room = Global.shooterscene.room3d.roomdata
		DEV_OUTPUT.push_message(r"set pos")
		playtest_debugspawn.show()
	
	rightclickpopup.show()
	rightclickpopup.position = get_viewport().get_mouse_position()
	update_display()

func create_new_empty_game()->void:
	Global.create_empty_game()
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	fill_right_panel()
	update_display()

func open_save_game_popup()->void:
	saveaddressinput.clear()
	saveaddressinput.text = loaded_path
	savegamepopup.show()

func addressbar_changed(s:String)->void:
	pass
	#confirmsave.disabled = saveaddressinput.text.is_empty()

func save_game()->void:
	var game_save : GameData = Global.current_game.save()
	if saveaddressinput.text.split(&".")[1] != &"res":
		DEV_OUTPUT.push_message(r"nice try")
		savegamepopup.hide()
		return
	DEV_OUTPUT.push_message(error_string(ResourceSaver.save(game_save,saveaddressinput.text)))
	savegamepopup.hide()
	update_display()

func set_face_lock()->void:
	var val : int = lockspinbox.value
	last_selected_face.box.set_lock(last_selected_face.dir,val)
	match last_selected_face.box.get_door(last_selected_face.dir):
		Box.DOOR:
			last_selected_face.set_face_type(2)
		Box.CITY_EXIT_DOOR:
			last_selected_face.set_face_type(3)
	update_display()

func set_cityexit_nextcity()->void:
	interacted_room.nextcity = cityspinbox.value

func set_cityexit_corresponding_exit()->void:
	interacted_room.corresponding_exit = exitspinbox.value

func fill_right_panel()->void:
	if Global.current_game:
		gamename.text = Global.current_game.game_name
		gamedescription.text = Global.current_game.description
	else:
		gamename.text = &""
		gamedescription.text = &""
	
	if Global.current_region:
		cityname.text = Global.current_region.name
	else:
		cityname.text = &""
	index_cities()

func index_cities()->void:
	pickcity.clear()
	var idx : int = 0
	for city : City in Global.current_game.cities:
		pickcity.add_item(city.get_city_string(),idx)
		if city == Global.current_region:
			pickcity.select(idx)
		idx += 1

func switch_city(idx:int)->void:
	var nextcity : City = Global.current_game.cities[idx]
	if Global.current_region != nextcity:
		Global.current_region = nextcity
		Global.world3D.reset_3d_view()
		Global.world3D.display_rooms()
		fill_right_panel()
		update_display()

func create_new_city()->int:
	var city : City = await Global.current_game.create_new_city()
	switch_city(city.index)
	index_cities()
	update_display()
	return 0

func delete_city()->void:
	if Global.current_game.cities.size() == 1:
		create_new_city()
	Global.current_game.remove_city(editor_selected_city)
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	editor_selected_city.mapvisual.queue_free()
	index_cities()
	update_display()
	rightclickpopup.hide()

func test_level(default_spawn:bool=true)->void:
	save_room_interior_items()
	open()
	if Global.current_game.cities.size() == 0 or (Global.current_game.cities.size() == 1 and Global.current_game.cities[0].rooms.size() == 0):
		DEV_OUTPUT.push_message(r"come on, make something!")
		return
	close()
	
	DEV_OUTPUT.push_message(error_string(ResourceSaver.save(Global.current_game.save(),"user://editor_levels/temp.res")))
	
	if default_spawn:
		Global.current_game.first_starting = true
	else:
		Global.current_game.current_city = debug_city
		Global.current_game.current_room = debug_room
		Global.current_game.startcity = Global.current_game.current_city
		Global.current_game.startroom = Global.current_game.current_room
		Global.current_game.position = debug_position
	Global.enter_game_transition(Global.current_game)
	playtestgui.show()
	update_display()

func exit_playtest()->void:
	Global.end_play_session()
	open()
	open_game("temp",false)

func set_room_default_spawn()->void:
	var room : Room = interacted_room
	Global.current_game.startcity = Global.current_region
	Global.current_game.startroom = room
	Global.current_game.position = Vector3.ZERO
	rightclickpopup.hide()
	update_display()

func set_room_debug_spawn()->void:
	var room : Room = interacted_room
	debug_city = Global.current_region
	debug_room = room
	debug_position = Vector3.ZERO
	rightclickpopup.hide()
	update_display()

func populate_connection_list()->void:
	choose_connection.get_popup().clear()
	for connection : CityConnection in Global.current_game.city_connections_register.get_open_connections():
		choose_connection.get_popup().add_item(connection.get_connection_string(),connection.get_index())

func save_room_interior_items()->void:
	if Global.shooterscene.room3d:
		Global.shooterscene.room3d.save_room_objects()
		Global.shooterscene.room3d.save_room_entities()

func start_object_movement()->void:
	var item : PhysicsBody3D = selected_item
	if not item: item = selected_npc
	else: selected_npc = null
	if item:
		for child : Node in item.get_children():
			if child is CollisionShape3D:
				child.disabled = true
	if item is RigidBody3D: item.freeze = true

func place_moving_object()->void:
	var item : PhysicsBody3D = selected_item
	if not item: item = selected_npc
	if item:
		for child : Node in item.get_children():
			if child is CollisionShape3D:
				child.disabled = false
	moving_item_inside_room = false
	if item is RigidBody3D: item.freeze = false
	selected_item = null
	selected_npc = null

func switch_npc_faction(faction:int)->void:
	selected_npc.configure(faction)
	rightclicklabel.hide()

func set_npc_combatmode(to:int)->void:
	selected_npc.configure(selected_npc.faction,to)
	rightclicklabel.hide()
