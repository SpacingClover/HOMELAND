extends Node3D

var normal_shader : StandardMaterial3D
var highlighted_axis_shader : StandardMaterial3D

@onready var meshes : Array[MeshInstance3D] = [$x,$y,$z]

func _ready()->void:
	normal_shader = RoomInstance3D.boxmaterial.duplicate()
	normal_shader.albedo_color = Color.DARK_ORANGE
	normal_shader.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	highlighted_axis_shader = normal_shader.duplicate()
	highlighted_axis_shader.albedo_color = Color("FF1a1a")
	global_rotation = Vector3.ZERO

func set_axis(axis:int)->void:
	for i : int in range(3):
		meshes[i].material_override = highlighted_axis_shader if i == axis else normal_shader
