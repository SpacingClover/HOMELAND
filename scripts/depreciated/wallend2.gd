class_name wallend2 extends wallend

func set_type(type:int)->void:
	match type:
		City.Box.OPEN:
			open_door()
			door.frame = 5
			sprite.frame = 1
		City.Box.DOOR:
			close_door()
			door.frame = 2
			sprite.frame = 1
		City.Box.WALL:
			door.hide()
			door.frame = 5
			sprite.frame = 0
		City.Box.HOLE:
			door.hide()
			sprite.frame = 2

func open_door()->void:
	open = true
	if Global.current_region.get_box_at(box_ref.coords+direction):
		var tween : Tween = create_tween()
		tween.tween_property($door,"frame",8,0.5)
		set_box_door_state(Vector3i.ZERO,direction,City.Box.OPEN,box_ref)
		set_box_door_state(box_ref.coords+direction,-direction,City.Box.OPEN)
		tpbox.body_entered.connect(body_in)

func close_door()->void:
	open = false
	if Global.current_region.get_box_at(box_ref.coords+direction):
		var tween : Tween = create_tween()
		tween.tween_property($door,"frame",2,0.5)
		set_box_door_state(Vector3i.ZERO,direction,City.Box.DOOR,box_ref)
		set_box_door_state(box_ref.coords+direction,-direction,City.Box.DOOR)
		tpbox.body_entered.disconnect(body_in)

func _ready()->void:
	position.x -= 8
	set_type(type)
