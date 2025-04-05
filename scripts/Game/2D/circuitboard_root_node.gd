class_name WiringView extends Node2D
static var current : WiringView

@onready var camera : Camera2D = %camera
@onready var inventory : Node2D = %inventory
@onready var raycast : RayCast2D = $RayCast2D

var board : CircuitBoard

var inventoryview : bool = false
var viewingplayerinventory : bool = true
var selecteditem : InventoryItem2DInstance

func _init()->void:
	Global.circuitboard = self
	WiringView.current = self

##TODO: add circuitboards
##TODO: implement circuitry


func _input(event:InputEvent)->void:
	
	if event.is_action_pressed(&"scroll_up"):
		camera.zoom *= 1.1
		if camera.zoom.x > 2.1: camera.zoom = Vector2(2.1,2.1)

	elif event.is_action_pressed(&"scroll_down"):
		camera.zoom *= 0.9
		if camera.zoom.x < 0.78: camera.zoom = Vector2(0.78,0.78)

	elif event.is_action_pressed(&"click") and Input.is_action_pressed(&"shift"):
		if not selecteditem:
			raycast.global_position = get_mouse_position()
			raycast.force_raycast_update()
			if raycast.is_colliding():
				var inventoryitem2d : InventoryItem2DInstance = raycast.get_collider()
				var selecteditemid : int = inventoryitem2d.item_id
				var inventoryitem : InventoryItem = inventoryitem2d.get_data()

				var dselecteditemid : int = inventoryitem.item_id
				var selecteditemname : String = RoomItem.get_item_name_by_id(selecteditemid)
				var scnpath : String = "res://scenes/scn/"
				var path : String = scnpath+selecteditemname+".scn"
				if selecteditemid == -1: return
				if not DirAccess.open(scnpath).file_exists(selecteditemname+".scn"):
					DEV_OUTPUT.push_message(path)
					DEV_OUTPUT.push_message("missing scn file for: "+selecteditemname)
					return
				var scn : PackedScene = ResourceLoader.load(path)
				if not scn: return
				var obj : InventoryItem3DInstance = scn.instantiate()
				obj.item_id = selecteditemid
				Global.shooterscene.room3d.add_child(obj)
				Global.shooterscene.room3d.objects.append(obj)
				obj.global_position = Global.player.global_position
				#obj.pass_args([inventoryitem.inventoryitemid])
				obj.inventoryitemid = inventoryitem.inventoryitemid
				var arr : Array = [inventoryitem.inventoryitemid]
				arr.append_array(inventoryitem.extra_data)
				obj.pass_args(arr)
				
				Global.playeritemsinventory.remove_item_by_inventory_item_idx(inventoryitem.inventoryitemid)
				inventoryitem2d.queue_free()
				
				await get_tree().process_frame
				save_inventory()

	elif event.is_action_pressed(&"click"):
		raycast.global_position = get_mouse_position()
		raycast.force_raycast_update()
		if selecteditem:
			selecteditem = null
			save_inventory()
		elif raycast.is_colliding():
			if not selecteditem:
				selecteditem = raycast.get_collider()
	
	elif event.is_action_pressed(&"rclick"):
		DEV_OUTPUT.push_message("Rclicked")
		if not selecteditem:
			raycast.global_position = get_mouse_position()
			raycast.force_raycast_update()
			if raycast.is_colliding():
				var inventoryitem2d : InventoryItem2DInstance = raycast.get_collider()
				var selecteditemid : int = inventoryitem2d.item_id
				var inventoryitem : InventoryItem = inventoryitem2d.get_data()
				var dselecteditemid : int = inventoryitem.item_id
				
				if Global.player.selectedweapon: if Global.player.selectedweapon.inventoryitemid == inventoryitem2d.inventoryitemid:
					Global.player.selectedweapon = null
					inventoryitem2d.modulate = Color.WHITE
					return
				
				if RoomItem.itemid_is_weapon(dselecteditemid) and viewingplayerinventory:
					Global.player.selectedweapon = inventoryitem2d
					inventoryitem2d.modulate = Color.RED
					DEV_OUTPUT.push_message("weapon selected")
				
				DEV_OUTPUT.push_message("click accepted")

	elif event is InputEventMouseMotion:
		if selecteditem:
			var pos : Vector2 = get_mouse_position().snapped(Vector2(150,150)).clamp(Vector2i.ZERO,Global.playeritemsinventory.gridsize*150)
			for i : Node2D in inventory.get_children():
				if i is InventoryItem2DInstance:
					if pos == i.position:
						return
			selecteditem.position = pos

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
	
	unload_inventory()
	
	var i : int = 0
	for inventoryitem : InventoryItem in Global.playeritemsinventory.inventoryitems:
		var item2d : InventoryItem2DInstance = InventoryItem2DInstance.new(inventoryitem)
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture = preload("res://visuals/spritesheets/misc/icon.svg")
		item2d.add_child(sprite)
		var col : CollisionShape2D = CollisionShape2D.new()
		col.shape = RectangleShape2D.new()
		col.scale *= 6.465
		item2d.add_child(col)
		inventory.add_child(item2d)
		DEV_OUTPUT.push_message(r"item - id: "+str(inventoryitem.inventoryitemid))
		item2d.position = inventoryitem.position * 150
		i += 1
	
	#var back : Panel = Panel.new()
	#back.scale = Vector2(Global.playeritemsinventory.gridsize * 150) + Vector2(150,150)
	#back.z_index = -1
	#back.position = Vector2(Global.playeritemsinventory.gridsize) * 75
	##back.add_theme_stylebox_override(&"",preload("res://visuals/themes/inventorybox.tres"))
	#back.set("theme_override_styles/panel",preload("res://visuals/themes/inventorybox.tres"))
	#inventory.add_child(back)
	
	var back : MeshInstance2D = MeshInstance2D.new()
	back.mesh = QuadMesh.new()
	back.scale = Vector2(Global.playeritemsinventory.gridsize * 150) + Vector2(150,150)
	back.z_index = -1
	back.position = Vector2(Global.playeritemsinventory.gridsize) * 75
	back.modulate = Color.DARK_ORANGE
	inventory.add_child(back)

func unload_inventory()->void:
	#save_inventory()
	for child : Node in inventory.get_children():
		#if child is InventoryItem2DInstance:
		DEV_OUTPUT.push_message("free")
		child.queue_free()
	selecteditem = null

func toggle_display()->void:
	inventoryview = not inventoryview
	refresh_display()

func refresh_display()->void:
	#DEV_OUTPUT.push_message(r"inventory" if inventoryview else r"circuitboard")
	if inventoryview:
		clear_board()
		load_inventory()
	else:
		unload_inventory()
		load_board()

func save_inventory()->void:
	if not Global.playeritemsinventory: return
	Global.playeritemsinventory.inventoryitems.clear()
	for child : Node2D in inventory.get_children():
		if child is InventoryItem2DInstance:
			Global.playeritemsinventory.add_item(InventoryItem.new(child.inventoryitemid,child.item_id,child.position/150))
			DEV_OUTPUT.push_message(r"save - item: "+str(child.inventoryitemid))
