class_name Flash3D extends Sprite3D

static var image : CompressedTexture2D = preload("res://visuals/spritesheets/effects/muzzleflashes.png")

func _init(pos:Vector3)->void:
	texture = image
	hframes = 2
	vframes = 4
	frame = randi_range(0,3)
	
	layers = 2
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	
	Global.shooterscene.root.add_child(self)
	global_position = pos
	global_position.x += 0.5
	scale *= 5
	
	var timer : Timer = Timer.new()
	add_child(timer)
	timer.start(0.1)
	timer.timeout.connect(queue_free)
