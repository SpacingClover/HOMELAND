class_name WiringView extends Node2D
static var current : WiringView

@onready var camera : Camera2D = %camera
var board : CircuitBoard

var inventoryview : bool = false

func _init()->void:
	Global.circuitboard = self
	WiringView.current = self




##TODO: add circuitboards
##TODO: implement circuitry






func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"scroll_up"):
		camera.zoom *= 1.1
		if camera.zoom.x > 2.1: camera.zoom = Vector2(2.1,2.1)
	if event.is_action_pressed(&"scroll_down"):
		camera.zoom *= 0.9
		if camera.zoom.x < 0.78: camera.zoom = Vector2(0.78,0.78)

func load_board()->void:
	clear_board()
	board = CircuitBoard.new()
	add_child(board)

func clear_board()->void:
	if board:
		board.queue_free()
		board = null

func get_mouse_position()->Vector2:
	var mouse_pos : Vector2
	mouse_pos = get_viewport().get_mouse_position()#relative to subviewport
	mouse_pos /= camera.zoom
	mouse_pos += camera.position
	mouse_pos -= Vector2(get_viewport().size)/camera.zoom/2
	return mouse_pos


func load_inventory()->void:
	if board:
		clear_board()
	
	for inventoryitem : InventoryItem in Global.playeritemsinventory.inventoryitems:
		var item2d : InventoryItem2DInstance = InventoryItem2DInstance.new(inventoryitem)
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture = preload("res://visuals/spritesheets/misc/icon.svg")
		item2d.add_child(sprite)
		%inventory.add_child(item2d)
		DEV_OUTPUT.push_message(r"item - id: "+str(inventoryitem.inventoryitemid))

func unload_inventory()->void:
	save_inventory()
	for child : InventoryItem2DInstance in %inventory.get_children():
		child.queue_free()

func toggle_display()->void:
	inventoryview = not inventoryview
	refresh_display()

func refresh_display()->void:
	DEV_OUTPUT.push_message(r"inventory" if inventoryview else r"circuitboard")
	if inventoryview:
		clear_board()
		load_inventory()
	else:
		unload_inventory()
		load_board()

func save_inventory()->void:
	Global.playeritemsinventory.inventoryitems.clear()
	for child : InventoryItem2DInstance in %inventory.get_children():
		Global.playeritemsinventory.add_item(InventoryItem.new(child.inventoryitemid,child.position))
		DEV_OUTPUT.push_message(r"save - item: "+str(child.inventoryitemid))
