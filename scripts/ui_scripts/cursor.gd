extends MeshInstance2D

func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position()

func _notification(what:int)->void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
