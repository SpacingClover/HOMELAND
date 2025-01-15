extends MeshInstance2D

func _ready()->void:
	get_parent().layer = 1025

func _process(delta:float)->void:
	global_position = get_global_mouse_position()

func _notification(what:int)->void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
