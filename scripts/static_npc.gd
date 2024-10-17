class_name StaticNPC extends RoomItemInstance

@onready var sprite : Sprite3D = $sprite

var walking : bool = false
var walklock : float

@export var instruction_step_idx : int
@export var instructions : Array[InstructionStep]
var current_step : InstructionStep:
	get: return instructions[instruction_step_idx]
	set(x): breakpoint

func _ready()->void:
	run_instruction()
	pass
	# read npc_script and set up signals
	# create some way of the npc identifying the specific door it needs opened, and connecting to its door_opened signal

func _process(delta:float)->void:
	animation(delta)

func pass_args(args:Array=[])->void:
	if instructions.size() > 0:
		instructions.append_array(args[0])
		instruction_step_idx = args[1]

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[instructions,instruction_step_idx])

func interact()->void:
	if current_step.has_dialogue and current_step.dialogueinfo:
		PopUps.load_prompt(current_step.dialogueinfo)

func go_to(pos:Vector3)->void:
	var tween : Tween = create_tween()
	pos.y = position.y
	tween.tween_property(self,"position",pos,position.direction_to(pos).length())
	walking = true
	await tween.finished
	walking = false

func inc_instruction()->void:
	instruction_step_idx += 1
	run_instruction()

func run_instruction()->void:
	if current_step.has_movement_target:
		DEV_OUTPUT.push_message("step: goto target")
		go_to(current_step.movement_target_pos)
	if current_step.has_wait_for_signal:
		DEV_OUTPUT.push_message("step: wait for door")

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
