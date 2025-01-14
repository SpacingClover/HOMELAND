extends Node

##left panel
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

##right panel
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

##load game popup
@onready var selectfilescontainer : PanelContainer = %opengamepopup
@onready var fileslist : OptionButton = %loadable_games_list
@onready var selectfilebutton : Button = %load_selected_game
@onready var cancelfileslist : Button = %close_opengamepopup

##right click menu
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

##save file menu
@onready var savegamepopup : PanelContainer = %savegamepopup
@onready var saveaddressinput : LineEdit = %savegame_filename_input
@onready var confirmsave : Button = %savegame_confirm
@onready var cancelsave : Button = %savegame_cancel
@onready var open_rooms_editor : Button = %open_rooms_editor

@onready var open_interior_editor : Button = %open_interior_editor

##playtesting stuff
@onready var bottomright : PanelContainer = %bottomright
@onready var playtest : Button = %launch_game_default
@onready var playtest_debugspawn : Button = %debug_launch

@onready var spawn_room : SpinBox = %spawn_room_display
@onready var spawn_city : SpinBox = %spawn_city_display

@onready var debug_city : SpinBox = %debug_city_display
@onready var debug_room : SpinBox = %debug_room_display

@onready var playtestgui : PanelContainer = %playtestgui
@onready var endplaytest : Button = %quit_playtest

var last_selected_face : RoomInstance3D.RoomInstanceFace

var interacted_room : Room

var room_isolation_mode : bool = false
var interiorview : bool = false
var mapvieweditor : bool = false

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
	switchcity.pressed.connect(switch_city)
	gamename.text_changed.connect(func(s:String)->void:Global.current_game.game_name=s)
	cityname.text_changed.connect(func(s:String)->void:Global.current_region.name=s)
	gamedescription.text_changed.connect(func(s:String)->void:Global.current_game.description=s)
	newcity.pressed.connect(create_new_city)
	saveaddressinput.text_changed.connect(addressbar_changed)
	confirmsave.pressed.connect(save_game)
	cancelsave.pressed.connect(savegamepopup.hide)
	deletecity.pressed.connect(delete_city)
	playtest.pressed.connect(test_level)
	playtest_debugspawn.pressed.connect(test_level.bind(false))
	endplaytest.pressed.connect(exit_playtest)
	spawn_room.value_changed.connect(set_spawn_info)
	spawn_city.value_changed.connect(set_spawn_info)
	default_spawn_setter.pressed.connect(set_room_default_spawn)
	debug_spawn_setter.pressed.connect(set_room_debug_spawn)
	open_mapview_editor.pressed.connect(open_city_editor)
	open_rooms_editor.pressed.connect(open)
	open_interior_editor.pressed.connect(open_roominterior_editor)
	close()

func open()->void:
	leftpanel.show()
	rightpanel.show()
	bottomright.show()
	selectfilescontainer.hide()
	rightclickpopup.hide()
	savegamepopup.hide()
	playtestgui.hide()
	citypanel.show()
	Global.focus_on_screen(Global.SCREENS.TOPRIGHT)
	Global.world3D.playermarker.hide()
	if not Global.current_game:
		create_new_empty_game()
	mapvieweditor = false
	interiorview = false
	update_display()

func close()->void:
	leftpanel.hide()
	rightpanel.hide()
	bottomright.hide()
	selectfilescontainer.hide()
	rightclickpopup.hide()
	savegamepopup.hide()
	playtestgui.hide()
	citypanel.hide()
	Global.unfocus_screens()
	Global.world3D.playermarker.hide()
	if Global.world3D.selecting_faces_directly: edit_faces()

func open_city_editor()->void:
	Global.focus_on_screen(Global.SCREENS.BOTTOMRIGHT)
	Global.mapview.display_map(Global.current_game)
	Global.mapview.show()
	mapvieweditor = true
	update_display()

func open_roominterior_editor()->void:
	if Global.world3D.room_last_selected:
		Global.focus_on_screen(Global.SCREENS.TOPLEFT)
		Global.shooterscene.load_room_interior(Global.world3D.room_last_selected.data_reference)
		interiorview = false
		update_display()

func update_display()->void:
	newbutton.disabled = room_isolation_mode or Global.world3D.selected_room or Global.world3D.selecting_faces_directly or mapvieweditor or interiorview
	roomtype.disabled = newbutton.disabled
	applyscale.disabled = Global.world3D.selecting_faces_directly or mapvieweditor or interiorview or not(Global.world3D.room_last_selected and is_instance_valid(Global.world3D.room_last_selected))
	scalex.disabled = applyscale.disabled
	scaley.disabled = applyscale.disabled
	scalez.disabled = applyscale.disabled
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
		var string : String = file.split(&".")[0] + &"   -----   " + Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(r"user://editor_levels/"+file),true)
		files.append(string)
	for dir : String in files: fileslist.add_item(dir)
	if files.size() != 0: fileslist.selected = 0; selectfilebutton.disabled = false
	else: selectfilebutton.disabled = true

func open_game(dir:String)->void:
	selectfilescontainer.hide()
	Global.current_game = ResourceLoader.load(r"user://editor_levels/"+dir+".res",&"",ResourceLoader.CACHE_MODE_IGNORE)
	Global.current_region = Global.current_game.cities[0]
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	deleteroom.disabled = true
	fill_right_panel()
	display_spawn_info()
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
		debug_spawn_setter.show()
		default_spawn_setter.show()
		if obj.data_reference is CityExit:
			tocityinput.show()
			toexitinput.show()
			cityspinbox.value = obj.data_reference.nextcity
			exitspinbox.value = obj.data_reference.corresponding_exit
			DEV_OUTPUT.push_message(r"this would be better with dropdown menus")
	elif obj is RoomInstance3D.RoomInstanceFace:
		last_selected_face = obj
		interacted_room = obj.room
		rightclicklabel.text = r"Face " + str(City.DIRECTIONS.find(obj.dir))
		rightclicklabel.show()
		if obj.box.has_doorway(obj.dir,true,false):
			lockspinbox.value = obj.box.get_lock(obj.dir)
			lockinput.show()
	
	rightclickpopup.show()
	rightclickpopup.position = get_viewport().get_mouse_position()
	update_display()

func create_new_empty_game()->void:
	Global.create_empty_game()
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	fill_right_panel()
	display_spawn_info()
	update_display()

func open_save_game_popup()->void:
	saveaddressinput.clear()
	#confirmsave.disabled = true
	savegamepopup.show()

func addressbar_changed(s:String)->void:
	pass
	#confirmsave.disabled = saveaddressinput.text.is_empty()

func save_game()->void:
	var game_save : GameData = Global.current_game
	var filename : String = saveaddressinput.text
	if filename.is_valid_filename():
		DEV_OUTPUT.push_message(error_string(ResourceSaver.save(game_save,r"user://editor_levels/"+filename+r".res")))
		savegamepopup.hide()
		#DEV_OUTPUT.push_message("if you cant find your file, search \"Godot user path\"")
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
		var string : String
		if city.name == &"":
			string = r"city " + str(idx)
		else:
			string = city.name
		pickcity.add_item(string,idx)
		if city == Global.current_region:
			pickcity.select(idx)
		idx += 1

func switch_city()->void:
	var nextcity : City = Global.current_game.cities[pickcity.selected]
	if Global.current_region != nextcity:
		Global.current_region = nextcity
		Global.world3D.reset_3d_view()
		Global.world3D.display_rooms()
		fill_right_panel()
		update_display()

func create_new_city()->int:
	await Global.current_game.create_new_city()
	index_cities()
	display_spawn_info()
	update_display()
	return 0

func delete_city()->void: ####################### doesnt FREAKING work
	if Global.current_game.cities.size() == 1:
		create_new_city()
	Global.current_game.remove_city(Global.current_region)
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	index_cities()
	display_spawn_info()
	update_display()

func test_level(default_spawn:bool=true)->void:
	if Global.current_game.cities.size() == 0 or (Global.current_game.cities.size() == 1 and Global.current_game.cities[0].rooms.size() == 0):
		DEV_OUTPUT.push_message(r"come on, make something!")
		return
	close()
	ResourceSaver.save(Global.current_game,"user://temp.res")
	if default_spawn:
		Global.current_game.first_starting = true
	else:
		Global.current_game.current_city = Global.current_game.cities[debug_city.value]
		Global.current_game.current_room = Global.current_game.startcity.rooms[debug_room.value]
		Global.current_game.startcity = Global.current_game.current_city
		Global.current_game.startroom = Global.current_game.current_room
	Global.current_game.position = Vector3.ZERO
	Global.enter_game_transition(Global.current_game)
	playtestgui.show()
	update_display()

func exit_playtest()->void:
	Global.end_play_session()
	open()
	Global.current_region.clear_visuals()
	Global.current_game = ResourceLoader.load("user://temp.res",&"",ResourceLoader.CACHE_MODE_IGNORE)
	Global.current_region = Global.current_game.cities[0]
	Global.current_room = Global.current_region.rooms[0]
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	update_display()

func display_spawn_info()->void:
	if Global.current_game.cities.size() != 0:
		spawn_city.max_value = Global.current_game.cities.size() - 1
		debug_city.max_value = Global.current_game.cities.size() - 1
		if Global.current_game.startcity:
			spawn_city.value = Global.current_game.cities.find(Global.current_game.startcity)
		else:
			spawn_city.value = 0
			Global.current_game.startcity = Global.current_game.cities[0]
		var startcity : City = Global.current_game.cities[spawn_city.value]
		if startcity.rooms.size() != 0:
			spawn_room.max_value = startcity.rooms.size() - 1
			debug_room.max_value = startcity.rooms.size() - 1
			if Global.current_game.startroom:
				spawn_room.value = startcity.rooms.find(Global.current_game.startroom)
			else:
				spawn_room.value = 0
				Global.current_game.startroom = startcity.rooms[0]
		else:
			spawn_room.value = 0
			spawn_room.max_value = 0
			debug_room.value = 0
			debug_room.max_value = 0
	else:
		spawn_city.value = 0
		spawn_city.max_value = 0
		debug_city.value = 0
		debug_city.max_value = 0
	
func set_spawn_info(v:int=-1)->void:
	if spawn_city.value != Global.current_game.cities.find(Global.current_game.startcity):
		Global.current_game.startcity = Global.current_game.cities[spawn_city.value]
		Global.current_game.startroom = null
	elif spawn_room.value != Global.current_game.startcity.rooms.find(Global.current_game.startroom):
		Global.current_game.startroom = Global.current_game.startcity.rooms[spawn_room.value]
	display_spawn_info()
	update_display()

func set_room_default_spawn()->void:
	var room : Room = interacted_room
	spawn_city.value = Global.current_game.cities.find(Global.current_region)
	spawn_room.value = Global.current_region.rooms.find(room)
	set_spawn_info()
	rightclickpopup.hide()
	update_display()

func set_room_debug_spawn()->void:
	var room : Room = interacted_room
	debug_city.value = Global.current_game.cities.find(Global.current_region)
	debug_room.value = Global.current_region.rooms.find(room)
	set_spawn_info()
	rightclickpopup.hide()
	update_display()
