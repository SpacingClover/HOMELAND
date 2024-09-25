extends TileMap

const wallend : PackedScene = preload("res://scenes/wallend.tscn")
const wallend2 : PackedScene = preload("res://scenes/wallend2.tscn")

@onready var frame1 : MeshInstance2D = $"../border/frame"
@onready var frame2 : MeshInstance2D = $"../border/frame2"
@onready var frame3 : MeshInstance2D = $"../border/frame3"
@onready var frame4 : MeshInstance2D = $"../border/frame4"
@onready var col1 : CollisionShape2D = $"../border/col1"
@onready var col2 : CollisionShape2D = $"../border/col2"
@onready var col3 : CollisionShape2D = $"../border/col3"
@onready var col4 : CollisionShape2D = $"../border/col4"

const boxsize : int = 2
const viewporthalfwidth : int = 550
const viewporthalfheight : int = 324
const tilesize : int = 215
const rightcut : int = 112

var objects : Array = []

var room_just_loaded : bool = false:
	set(val):
		if val:
			var timer : Timer = Timer.new()
			timer.one_shot = true
			timer.timeout.connect(func()->void:room_just_loaded = false)
			add_child(timer)
			timer.start(0.1)
		room_just_loaded = val

func load_room(room:City.Room)->void:
	var leftside : float = INF
	var rightside : float = -INF
	var lowest : float = -INF
	var highest : float = INF
	
	clear()
	for i : Node2D in objects:
		i.queue_free()
	objects.clear()
	
	for box : City.Box in room.boxes: #place tiles
		var x : int = box.z * boxsize
		var y : int = box.x * boxsize
		
		for i in range(boxsize): #draw tiles
			for h in range(room.scale.y*boxsize):
				set_cell(0,Vector2i(x+i,y-h),0,Vector2i(3,1)) #walls
				set_cell(0,Vector2i(x+i,y+h+1),0,Vector2i(2,1)) #floors\
				
				var ytest : int = y - h
				if ytest < highest:
					highest = ytest
				if ytest > lowest:
					lowest = ytest
			
			var xtest : int = x
			if xtest < leftside:
				leftside = xtest
			if xtest > rightside:
				rightside = xtest
		
		create_wall(x,y,box,box.door_left,  City.LEFT)
		create_wall(x,y,box,box.door_right, City.RIGHT)
		create_wall(x,y,box,box.door_top,   City.TOP)
		create_wall(x,y,box,box.door_bottom,City.BOTTOM)
		create_wall(x,y,box,box.door_up,    City.UP)
		create_wall(x,y,box,box.door_down,  City.DOWN)
	
	print(rightside)
	
	leftside *= tilesize
	rightside *= tilesize
	highest *= tilesize
	lowest *= tilesize
	lowest += viewporthalfheight
	
	set_display_bounds(leftside,rightside+rightcut,highest,lowest)
	
	leftside += viewporthalfwidth
	rightside -= rightcut
	highest += viewporthalfheight
	
	Global.player.left_limit = leftside
	Global.player.right_limit = rightside
	Global.player.top_limit = highest
	Global.player.lower_limit = lowest
	
	Global.world3D.switch_marker_room(room)
	
	room_just_loaded = true

func create_wall(x:int,y:int,box:City.Box,type:int,direction:Vector3i)->void:
	if type == City.Box.NONE:
		return
	if type == City.Box.WALL and box.x > Global.current_room.get_x_min():
		return
	
	var wall : StaticBody2D
	
	if direction.x != 0: #if is front or back of room
		if type < 3: #not a door
			return
		else: #door or hole
			wall = wallend2.instantiate()
			#if you want to cull the wall, this is the place
			x*= tilesize/13.35
			y*= tilesize/13.35
			x+=40
			if direction == City.TOP:
				y+=16
			else:#direction is City.BOTTOM
				y+= 50
				#wall.get_child(5).position.y += 5
				wall.get_child(3).position.y += 2
			if box.door_left > 1:
				x += 9
			if box.door_right > 1:
				x -= 9
				
	else: #left or right walls
		wall = wallend.instantiate()
		x*= tilesize/13.35
		y*= tilesize/13.35
		x+= 16
		y+=32
		
		if direction == City.RIGHT:
			x += tilesize/13.35
			wall.scale.x *= -1
	
	y -= 32 * box.y #placing it vertically is very easy!
	
	wall.position = Vector2(x,y)
	wall.direction = direction
	wall.box_ref = box
	wall.type = type
	call_deferred(&"add_child",wall)
	objects.append(wall)

func set_display_bounds(left:float,right:float,top:float,bottom:float)->void:
	frame1.mesh.size.y = bottom - top
	
	frame1.position.x = left
	frame2.position.x = right
	print("\n")
	print(right)
	frame3.position.y = bottom + (tilesize*2)
	frame4.position.y = top
	
	col1.position.x = left
	col2.position.x = (right*2) - (rightcut*2)
	col3.position.y = bottom + (tilesize*1.5)
	col4.position.y = top

func _init()->void:
	Global.tilemap = self
