extends Panel

@onready var newroom : Button = $VBoxContainer/Button
@onready var deleteroom : Button = $VBoxContainer/Button3
@onready var scalex : LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var scaley : LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit2
@onready var scalez : LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit3
@onready var applyscale : Button = $VBoxContainer/PanelContainer/VBoxContainer/Button4
@onready var editfaces : Button = $VBoxContainer/Button4
@onready var isolateroom : Button = $VBoxContainer/Button5

func _ready()->void:
	newroom.pressed.connect(Global.world3D.create_room)
	deleteroom.pressed.connect(Global.world3D.delete_room)
	applyscale.pressed.connect(rescale_room)
	editfaces.pressed.connect(edit_faces)
	isolateroom.pressed.connect(isolate_room)

func rescale_room()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	if not (scalex.text.is_valid_int() and scaley.text.is_valid_int() and scalez.text.is_valid_int()):
		scalex.text = str(roomvisual.data_reference.scale.x)
		scaley.text = str(roomvisual.data_reference.scale.y)
		scalez.text = str(roomvisual.data_reference.scale.z)
	else:
		var room : Room = roomvisual.data_reference
		Global.world3D.drop_selected_visual()
		roomvisual.queue_free()
		roomvisual.data_reference.scale = Vector3i(scalex.text.to_int(),scaley.text.to_int(),scalez.text.to_int())
		roomvisual.data_reference.validated = false
		roomvisual.data_reference.validate()
		Global.world3D.display_room(room)
		Global.world3D.room_last_selected = room.roomvisual

func new_room_selected()->void:
	var roomvisual : RoomInstance3D = Global.world3D.room_last_selected
	if not roomvisual:
		return
	scalex.text = str(roomvisual.data_reference.scale.x)
	scaley.text = str(roomvisual.data_reference.scale.y)
	scalez.text = str(roomvisual.data_reference.scale.z)

func edit_faces()->void:
	Global.world3D.selecting_faces_directly = not Global.world3D.selecting_faces_directly

func isolate_room()->void:
	for roomvisual : RoomInstance3D in Global.world3D.root.get_children():
		if roomvisual != Global.world3D.room_last_selected:
			roomvisual.visible = not roomvisual.visible
			roomvisual.toggle_collision()
