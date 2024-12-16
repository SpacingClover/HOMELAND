extends PanelContainer

@onready var newroom : Button = $VBoxContainer/Button
@onready var deleteroom : Button = $VBoxContainer/Button3
@onready var scalex : SpinBox = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var scaley : SpinBox = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit2
@onready var scalez : SpinBox = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit3
@onready var applyscale : Button = $VBoxContainer/PanelContainer/VBoxContainer/Button4
@onready var editfaces : Button = $VBoxContainer/Button4
@onready var isolateroom : Button = $VBoxContainer/Button5
@onready var setfacetype : OptionButton = $VBoxContainer/OptionButton
@onready var creategame : Button = $VBoxContainer/Button2
@onready var savegame : Button = $VBoxContainer/Button6
@onready var opengame : Button = $VBoxContainer/Button7
@onready var selectfilescontainer : PanelContainer = $Node/PanelContainer
@onready var fileslist : OptionButton = $Node/PanelContainer/VBoxContainer/OptionButton
@onready var selectfilebutton : Button = $Node/PanelContainer/VBoxContainer/Button
@onready var cancelfileslist : Button = $Node/PanelContainer/VBoxContainer/Button2

var room_isolation_mode : bool = false

func _ready()->void:
	newroom.pressed.connect(Global.world3D.create_room)
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

func rescale_room()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	var room : Room = roomvisual.data_reference
	Global.world3D.drop_selected_visual()
	roomvisual.queue_free()
	roomvisual.data_reference.scale = Vector3i(scalex.value,scaley.value,scalez.value)
	roomvisual.data_reference.validated = false
	roomvisual.data_reference.validate()
	Global.current_region.validate_city()
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
	newroom.disabled = Global.world3D.selecting_faces_directly
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
	newroom.disabled = room_isolation_mode
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
