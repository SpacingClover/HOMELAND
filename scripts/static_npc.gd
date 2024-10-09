class_name StaticNPC extends RoomItemInstance

@onready var sprite : Sprite3D = $sprite

var walking : bool = false
var walklock : float

@export var npc_script : Dictionary

func _ready()->void:
	pass
	# read npc_script and set up signals
	# create some way of the npc identifying the specific door it needs opened, and connecting to its door_opened signal
	# the dict needs to contain a counter for which step it is on

func _process(delta:float)->void:
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

func interact()->void:
	DEV_OUTPUT.push_message("npc interacted")
	
	PopUps.create_prompt(PopUps.SCREENS.SHOOTER,Prompt.PROMPT_MODES.NOTIFY,false,
	"hello there, it seems the dialogue system is working!","Child","Excellent!")

func go_to(pos:Vector3)->void:
	var tween : Tween = create_tween()
	tween.tween_property(self,"position",pos,position.direction_to(pos).length())
	walking = true
	await tween.finished
	walking = false
