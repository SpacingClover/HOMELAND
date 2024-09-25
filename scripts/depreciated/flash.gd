class_name Flash extends Sprite2D

func flash(coords:Vector2,size:int=1)->void:
	global_position = coords
	await $AudioStreamPlayer2D.finished
	queue_free()
