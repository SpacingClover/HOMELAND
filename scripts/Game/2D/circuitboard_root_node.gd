class_name WiringView extends Node2D
static var current : WiringView

@onready var camera : Camera2D = $camera
var board : CircuitBoard

func _init()->void:
	Global.circuitboard = self
	WiringView.current = self

func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"scroll_up"):
		camera.zoom *= 1.1
		if camera.zoom.x > 2.1: camera.zoom = Vector2(2.1,2.1)
	if event.is_action_pressed(&"scroll_down"):
		camera.zoom *= 0.9
		if camera.zoom.x < 0.78: camera.zoom = Vector2(0.78,0.78)
		DEV_OUTPUT.push_message(str(camera.zoom))

func load_board()->void:
	board = CircuitBoard.new()
	add_child(board)

func clear_board()->void:
	board.queue_free()
	board = null

func get_mouse_position()->Vector2:
	var mouse_pos : Vector2
	mouse_pos = get_viewport().get_mouse_position()#relative to subviewport
	mouse_pos /= camera.zoom
	mouse_pos += camera.position
	mouse_pos -= Vector2(get_viewport().size)/camera.zoom/2
	return mouse_pos
