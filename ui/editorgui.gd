extends Node

##left panel
@onready var leftpanel : PanelContainer = $leftpanel
@onready var newbutton : Button = $leftpanel/VBoxContainer/HBoxContainer/Button
@onready var roomtype : OptionButton = $leftpanel/VBoxContainer/HBoxContainer/OptionButton
@onready var deleteroom : Button = $leftpanel/VBoxContainer/Button3
@onready var scalex : SpinBox = $leftpanel/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var scaley : SpinBox = $leftpanel/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit2
@onready var scalez : SpinBox = $leftpanel/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit3
@onready var applyscale : Button = $leftpanel/VBoxContainer/PanelContainer/VBoxContainer/Button4
@onready var editfaces : Button = $leftpanel/VBoxContainer/Button4
@onready var isolateroom : Button = $leftpanel/VBoxContainer/Button5
@onready var setfacetype : OptionButton = $leftpanel/VBoxContainer/OptionButton
@onready var creategame : Button = $leftpanel/VBoxContainer/Button2
@onready var savegame : Button = $leftpanel/VBoxContainer/Button6
@onready var opengame : Button = $leftpanel/VBoxContainer/Button7
@onready var closeeditor : Button = $leftpanel/VBoxContainer/Button8

##right panel
@onready var rightpanel : PanelContainer = $rightpanel
@onready var gamename : LineEdit = $rightpanel/VBoxContainer/gamename
@onready var gamedescription : TextEdit = $rightpanel/VBoxContainer/description
@onready var cityname : LineEdit = $rightpanel/VBoxContainer/cityname
@onready var pickcity : OptionButton = $rightpanel/VBoxContainer/HBoxContainer/pickcity
@onready var newcity : Button = $rightpanel/VBoxContainer/Button
@onready var switchcity : Button = $rightpanel/VBoxContainer/HBoxContainer/Button
@onready var deletecity : Button = $rightpanel/VBoxContainer/Button2

##load game popup
@onready var selectfilescontainer : PanelContainer = $opengamepopup
@onready var fileslist : OptionButton = $opengamepopup/VBoxContainer/OptionButton
@onready var selectfilebutton : Button = $opengamepopup/VBoxContainer/Button
@onready var cancelfileslist : Button = $opengamepopup/VBoxContainer/Button2

##right click menu
@onready var rightclickpopup : PanelContainer = $rightclickpopup
@onready var popupvbox : VBoxContainer = $rightclickpopup/VBoxContainer
@onready var submitbutton : Button = $rightclickpopup/VBoxContainer/HBoxContainer/Button
@onready var set_tocity : Button = $"rightclickpopup/VBoxContainer/to city/Button"
@onready var set_toexit : Button = $"rightclickpopup/VBoxContainer/to exit/Button"
@onready var rightclicklabel : Label = $rightclickpopup/VBoxContainer/Label
@onready var roomcontents : Button = $rightclickpopup/VBoxContainer/Button
@onready var lockinput : HBoxContainer = $rightclickpopup/VBoxContainer/HBoxContainer
@onready var tocityinput : HBoxContainer = $"rightclickpopup/VBoxContainer/to city"
@onready var toexitinput : HBoxContainer = $"rightclickpopup/VBoxContainer/to exit"
@onready var lockspinbox : SpinBox = $rightclickpopup/VBoxContainer/HBoxContainer/SpinBox
@onready var cityspinbox : SpinBox = $"rightclickpopup/VBoxContainer/to city/SpinBox"
@onready var exitspinbox : SpinBox = $"rightclickpopup/VBoxContainer/to exit/SpinBox"

var last_selected_face : RoomInstance3D.RoomInstanceFace

var room_isolation_mode : bool = false

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
	selectfilebutton.pressed.connect(func()->void:open_game(fileslist.get_item_text(fileslist.selected)))
	cancelfileslist.pressed.connect(selectfilescontainer.hide)
	closeeditor.pressed.connect(Global.close_level_editor)
	creategame.pressed.connect(create_new_empty_game)
	savegame.pressed.connect(save_game)
	submitbutton.pressed.connect(set_face_lock)
	set_tocity.pressed.connect(set_cityexit_nextcity)
	set_toexit.pressed.connect(set_cityexit_corresponding_exit)
	switchcity.pressed.connect(switch_city)
	gamename.text_changed.connect(func(s:String)->void:Global.current_game.game_name=s)
	cityname.text_changed.connect(func(s:String)->void:Global.current_region.name=s)
	gamedescription.text_changed.connect(func(s:String)->void:Global.current_game.description=s)
	newcity.pressed.connect(create_new_city)
	close()

func open()->void:
	leftpanel.show()
	rightpanel.show()
	selectfilescontainer.hide()
	rightclickpopup.hide()

func close()->void:
	leftpanel.hide()
	rightpanel.hide()
	selectfilescontainer.hide()
	rightclickpopup.hide()

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

func new_room_selected()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	scalex.value = roomvisual.data_reference.scale.x
	scaley.value = roomvisual.data_reference.scale.y
	scalez.value = roomvisual.data_reference.scale.z
	check_scale_value()
	deleteroom.disabled = false

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

func isolate_room()->void:
	for roomvisual : RoomInstance3D in Global.world3D.root.get_children():
		if roomvisual != Global.world3D.room_last_selected:
			roomvisual.visible = not roomvisual.visible
			roomvisual.toggle_collision()
	room_isolation_mode = not room_isolation_mode
	newbutton.disabled = room_isolation_mode
	deleteroom.disabled = room_isolation_mode
	isolateroom.text = ("disable" if room_isolation_mode else "enable") + " isolate room"

func open_files_menu()->void:
	selectfilescontainer.show()
	fileslist.clear()
	var files : Array[String]
	for file : String in DirAccess.get_files_at("res://demos/"):
		files.append("res://demos/"+file)
	for file : String in DirAccess.get_files_at("res://dev_levels/"):
		files.append("res://dev_levels/"+file)
	for dir : String in files:
		fileslist.add_item(dir)

func open_game(dir:String)->void:
	selectfilescontainer.hide()
	Global.current_game = ResourceLoader.load(dir,&"",ResourceLoader.CACHE_MODE_IGNORE)
	Global.current_region = Global.current_game.cities[0]
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	deleteroom.disabled = true
	fill_right_panel()

func open_rightclick_popup(obj:Node3D)->void:
	if not obj:
		rightclickpopup.hide()
		return
	
	for child : Control in popupvbox.get_children(): child.hide()
	
	if obj is RoomInstance3D:
		rightclicklabel.text = r"Room " + str(obj.data_reference.index)
		rightclicklabel.show()
		var contents : Button = roomcontents
		contents.text = r"Contains " + str(obj.data_reference.items.size()) + r" items"
		contents.show()
		if obj.data_reference is CityExit:
			tocityinput.show()
			toexitinput.show()
			cityspinbox.value = obj.data_reference.nextcity
			exitspinbox.value = obj.data_reference.corresponding_exit
			DEV_OUTPUT.push_message(r"this would be better with dropdown menus")
	elif obj is RoomInstance3D.RoomInstanceFace:
		last_selected_face = obj
		rightclicklabel.text = r"Face " + str(City.DIRECTIONS.find(obj.dir))
		rightclicklabel.show()
		if obj.box.has_doorway(obj.dir,true,false):
			lockspinbox.value = obj.box.get_lock(obj.dir)
			lockinput.show()
	
	rightclickpopup.show()
	rightclickpopup.position = get_viewport().get_mouse_position()

func create_new_empty_game()->void:
	Global.create_empty_game()
	Global.world3D.reset_3d_view()
	Global.world3D.display_rooms()
	fill_right_panel()

func save_game()->void:
	ResourceSaver.save(Global.current_game,"res://editorgames/city.res")

func set_face_lock()->void:
	var val : int = lockspinbox.value
	last_selected_face.box.set_lock(last_selected_face.dir,val)
	match last_selected_face.box.get_door(last_selected_face.dir):
		Box.DOOR:
			last_selected_face.set_face_type(2)
		Box.CITY_EXIT_DOOR:
			last_selected_face.set_face_type(3)

func set_cityexit_nextcity()->void:
	last_selected_face.room.nextcity = cityspinbox.value

func set_cityexit_corresponding_exit()->void:
	last_selected_face.room.corresponding_exit = exitspinbox.value

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

func create_new_city()->void:
	Global.current_game.cities.append(await City.new())
	index_cities()
