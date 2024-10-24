class_name StaticNPC extends RoomItemInstance

@onready var sprite : Sprite3D = $sprite

var walking : bool = false
var walklock : float

@export var instruction_step : int = 0

func _ready()->void:
	run_instruction()
	pass
	# read npc_script and set up signals
	# create some way of the npc identifying the specific door it needs opened, and connecting to its door_opened signal

func _process(delta:float)->void:
	animation(delta)

func pass_args(args:Array=[])->void:
	pass

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[instruction_step])

func interact()->void:
	pass
	#PopUps.load_prompt(pass_dialogue,self)

func go_to(pos:Vector3)->void:
	var tween : Tween = create_tween()
	pos.y = position.y
	tween.tween_property(self,"position",pos,position.direction_to(pos).length())
	walking = true
	await tween.finished
	walking = false

func inc_instruction()->void:
	instruction_step += 1
	run_instruction()

func run_instruction()->void:
	DEV_OUTPUT.push_message("run instruction")
	match instruction_step:
		0:
			pass
		1:
			pass
		2:
			pass

func get_character_name()->String:
	return "Child"

func animation(delta:float)->void:
	if walking:
		if walklock <= 0:
			walklock = 0.1
			if sprite.frame >= 3:
				sprite.frame = 0
			else:
				sprite.frame += 1
		else:
			walklock -= 2 * delta
	else:
		sprite.frame = 0
