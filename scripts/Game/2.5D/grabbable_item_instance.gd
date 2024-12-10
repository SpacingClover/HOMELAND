class_name GrabbableItemInstance extends RoomItemInstance

@onready var sprite : Sprite3D = get_node_or_null(^"sprite")

func get_as_2d_body()->StaticBody2D:
	return StaticBody2D.new()
	## create a 2d item for the circuitboard/inventory out of the 2.5d sprite
	## attach the RoomItem object!!!

func get_as_sprite()->Sprite2D:
	if not sprite: return null ##the item scn does not have a sprite / is not named "sprite"
	var sprite2d : Sprite2D = Sprite2D.new()
	sprite2d.texture = sprite.texture
	sprite2d.region_enabled = sprite.region_enabled
	#if sprite2d.region_enabled:
		#sprite2d.region_rect = sprite.region_rect
	sprite2d.hframes = sprite.hframes
	sprite2d.vframes = sprite.vframes
	sprite2d.frame = sprite.frame
	return sprite2d
