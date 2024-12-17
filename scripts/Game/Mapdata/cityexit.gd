class_name CityExit extends Feature

@export var nextcity : int
@export var corresponding_exit : int
@export var exit_direction : Vector3i

func _init(size:Vector3i=Vector3i.ZERO,pos:Vector3i=Vector3i.ZERO,being_generated:bool=false,exitdirection:Vector3i=City.TOP)->void:
	
	if validated:
		return
	
	if not being_generated:
		return
	
	#if exitdirection.length() == 0:
		#exit_direction = City.BOTTOM
	if size.x == 0: size.x = 1
	if size.y == 0: size.y = 1
	if size.z == 0: size.z = 1
	
	if boxes.size() < (scale.x * scale.y * scale.z):
		super(size,pos,true)

func validate(city_ref:City)->void:
	super(city_ref)
