class_name StaticNPC extends RoomItemInstance

var walking : bool = false

func _process(delta:float)->void:
	if walking:
		pass #animate feet

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
