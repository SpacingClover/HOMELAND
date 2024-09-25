class_name CircuitBoard extends Node2D

static var SCALEFACTOR : float = 100
static var POINTMESH : MeshInstance2D
static var WIRECOLOR : Color = Color("ffa300")
static var WIREGLOW  : Color = Color("e70061")

@onready var astar : AStar2D = AStar2D.new()

var current_wire : Wire2D

var points : Array[CircuitPointData]
var pointmeshes : Array[MeshInstance2D]

var size : Vector2i = Vector2i(10,10)
var width : int:
	get:return size.x
	set(x):size.x=x
var height : int:
	get:return size.y
	set(y):size.y=y

var wiring : bool = false
var current_first_point_was_disabled : bool = false

static func _static_init()->void:
	POINTMESH = MeshInstance2D.new()
	POINTMESH.mesh = SphereMesh.new()
	POINTMESH.scale *= 25

func _init(width_:int=10,height_:int=10)->void:
	size = Vector2i(width_,height_)

func _ready()->void:
	#create points
	for x : int in range(width):
		for y : int in range(height):
			
			var point : CircuitPointData = CircuitPointData.new(Vector2(x,y),astar.get_available_point_id())
			points.append(point)
			astar.add_point(point.id,point.coords)
			
			var point_mesh_instance : MeshInstance2D = POINTMESH.duplicate()
			point_mesh_instance.position = point.coords * SCALEFACTOR
			point_mesh_instance.set_meta(&"pointdata",point)
			point_mesh_instance.modulate = WIRECOLOR
			add_child(point_mesh_instance)
			pointmeshes.append(point_mesh_instance)
	
	#connect points in envelope shape
	for point1 : CircuitPointData in points:
		for point2 : CircuitPointData in points:
			var dist : Vector2 = abs(point2.coords - point1.coords)
			if dist.x <= 1 and dist.y <= 1 and point1 != point2 and not astar.are_points_connected(point1.id,point2.id):
				astar.connect_points(point1.id,point2.id)

func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"click"):
		if not wiring:
			var start_point : CircuitPointData = get_nearest_pointdata_to_mouse()
			if not start_point: return
			wiring = true #create new wire
			current_first_point_was_disabled = astar.is_point_disabled(start_point.id)
			astar.set_point_disabled(start_point.id,false)
			var wire : Wire2D = Wire2D.new(start_point)
			wire.position = start_point.coords * SCALEFACTOR
			add_child(wire)
			current_wire = wire
		else:
			wiring = false #connect wire
			var end_point : CircuitPointData = get_nearest_pointdata_to_mouse()
			if not end_point: return
			current_wire.cement_path(astar)
		
	elif event.is_action_pressed(&"rclick"):
		if wiring:
			wiring = false #drop wire
			astar.set_point_disabled(current_wire.start_point.id,current_first_point_was_disabled)
			current_wire.queue_free()
			current_wire = null
		
	elif event is InputEventMouseMotion:
		if wiring:
			var end_point : CircuitPointData = get_nearest_pointdata_to_mouse()
			if not end_point: return
			var current_end_point_was_disabled : bool = astar.is_point_disabled(end_point.id)
			astar.set_point_disabled(end_point.id,false)
			current_wire.create_path(astar,end_point,points,SCALEFACTOR)
			astar.set_point_disabled(end_point.id,current_end_point_was_disabled)

func get_nearest_pointdata_to_mouse()->CircuitPointData:
	var nearest : MeshInstance2D = pointmeshes[0]
	var mousepos : Vector2 = WiringView.current.get_mouse_position()
	var nearestdist : float
	var pointmeshdist : float
	for pointmesh : MeshInstance2D in pointmeshes:
		nearestdist = mousepos.distance_to(nearest.global_position)
		pointmeshdist = mousepos.distance_to(pointmesh.global_position)
		if nearestdist > pointmeshdist:
			nearest = pointmesh
	if nearestdist > 60:
		return null
	return nearest.get_meta(&"pointdata")
	#return get_pointdata_from_id(astar.get_closest_point(get_viewport().get_mouse_position()/SCALEFACTOR))

func get_pointdata_from_id(id:int)->CircuitPointData:
	for point : CircuitPointData in points:
		if point.id == id:
			return point
	return null

class CircuitPointData extends RefCounted:
	var coords : Vector2
	var x : float:
		get: return coords.x
		set(val): coords.x = val
	var y : float:
		get: return coords.y
		set(val): coords.y = val
	var id : int
	
	func _init(coords_:Vector2,id_:int)->void:
		coords = coords_
		id = id_

class Wire2D extends Line2D:
	var start_point : CircuitPointData
	var points_datas : Array[CircuitPointData]
	var disabled_connections : Array[WirePointConnection]
	
	func _init(point:CircuitPointData)->void:
		start_point = point
		width = 25
		modulate = CircuitBoard.WIRECOLOR
	
	func create_path(astar:AStar2D,end_point:CircuitPointData,point_datas:Array[CircuitPointData],SCALEFACTOR:float)->void:
		points = astar.get_point_path(start_point.id,end_point.id)
		var path_ids : PackedInt64Array = astar.get_id_path(start_point.id,end_point.id)
		
		for i : int in range(len(points)):
			points[i] -= start_point.coords
			points[i] *= SCALEFACTOR
		
		points_datas.clear()
		for id : int in path_ids:
			for point_data : CircuitPointData in point_datas:
				if point_data.id == id:
					points_datas.append(point_data)
	
	func cement_path(astar:AStar2D)->void:
		
		if len(points) < 2:
			queue_free()
			return
		
		for point : CircuitPointData in points_datas:
			astar.set_point_disabled(point.id,true)
			
		var point : CircuitPointData = null
		var next : CircuitPointData = null
			
		for i : int in range(len(points_datas)):
			point = points_datas[i]
			if i+1 >= len(points_datas): break
			next = points_datas[i+1]
			
			if next.x - point.x != 0 and next.y - point.y != 0: #if connection is diagonal
				var rot_point1 : int = astar.get_closest_point(Vector2(next.x,point.y),true)
				var rot_point2 : int = astar.get_closest_point(Vector2(point.x,next.y),true)
				astar.disconnect_points(rot_point1,rot_point2)
				
				disabled_connections.append(WirePointConnection.new(rot_point1,rot_point2))
				
	
	class WirePointConnection extends RefCounted:
		var start : int
		var end : int
		
		func _init(start_:int,end_:int)->void:
			start = start_
			end = end_
