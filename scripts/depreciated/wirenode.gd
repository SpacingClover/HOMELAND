class_name WireNode extends StaticBody2D

static var texture : GradientTexture1D = preload("res://visuals/materials/new_gradient_texture_1d.tres")#ffa300
static var sphere : SphereMesh = SphereMesh.new()
static var circle : CircleShape2D = CircleShape2D.new()

var wire_drawing : bool = false
var current_wire : Wire
var viewport : GameView
var wires : Array[Wire]
var points : PackedVector2Array

var id : int

func _init(viewport_:GameView)->void:
	viewport = viewport_

func _ready()->void:
	set_process(false)
	var mesh : MeshInstance2D = MeshInstance2D.new()
	mesh.mesh = sphere
	mesh.texture = texture
	add_child(mesh)
	var col : CollisionShape2D = CollisionShape2D.new()
	col.shape = circle
	add_child(col)

func pass_input(event:InputEvent,node:Node=null)->void:
	if node is GameView:
		viewport = node
	if event.is_action_pressed(&"click"):
		if wire_drawing and viewport.wiring:
			if node is WireNode:
				pass
				#connect_wire(1,node)
		else:
			if not viewport.wiring:
				make_wire()
	elif event.is_action_released(&"click"):
		pass
	elif event.is_action_pressed(&"rclick"):
		drop_wire()
	elif event.is_action_released(&"rclick"):
		pass

func drop_wire()->void:
	viewport.wiring = false
	viewport.wirebase = null
	wire_drawing = false
	current_wire.queue_free()
	set_process(false)

func make_wire()->void:
	viewport.wiring = true
	viewport.wirebase = self
	wire_drawing = true
	set_process(true)
	current_wire = Wire.new()
	add_child(current_wire)

func make_wire_path(end:int,astar:AStar2D)->void:
	points = astar.get_point_path(id,end)
	var temppoints : PackedVector2Array = points
	for i : int in range(len(points)):
		temppoints[i] -= global_position/100
		temppoints[i] *= 4
	current_wire.points = temppoints

func connect_wire(end:int,astar:AStar2D,endnode:WireNode=null)->void:
	for i : Vector2 in points:
		i/=4
		var disable_id : int = astar.get_closest_point(i)
		astar.set_point_disabled(disable_id)
	wire_drawing = false
	set_process(false)
	viewport.wiring = false
	viewport.wirebase = null
