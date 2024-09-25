class_name Elevator extends Feature

func _init(size:Vector3i=Vector3i.ZERO,pos:Vector3i=Vector3i.ZERO,being_generated:bool=false)->void:
	if being_generated:
		super(size,pos,being_generated)
