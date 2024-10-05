class_name StaticNPC extends RoomItemInstance

func interact()->void:
	DEV_OUTPUT.push_message("npc interacted")
	
	PopUps.create_prompt(PopUps.SCREENS.SHOOTER,Prompt.PROMPT_MODES.NOTIFY,false,
	"hello there, it seems the dialogue system is working!","Child","Excellent!")
