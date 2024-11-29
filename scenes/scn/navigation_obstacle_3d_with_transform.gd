extends NavigationObstacle3D

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var new_vertices : Array[Vector3] = Array(vertices).map(
			func(vertex:Vector3)->Vector3:
				return global_transform.basis * vertex
		)
		vertices = PackedVector3Array(new_vertices)
