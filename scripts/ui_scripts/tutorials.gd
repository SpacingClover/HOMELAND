extends Node

const tutorials_text : Dictionary = {
	"0":"    To move your character, press the WASD keys, and point the cursor where youre looking (or aiming)",
	"1":"    To interact with a door, stand near it and press E",
	"2":"    To move a room, LEFT CLICK on a room, then slide it along the \"track\", and click again to set it down",
	"3":"    If you realize you don't want to move a room, RIGHT CLICK while you have a room selected to drop it",
	"4":"    Click SPACE to switch which axis the room will be moved along. The compass in the bottom right shows both your orientation and which movement axis is selected, in red",
	"5":"    To rotate the 3d view, hold either MIDDLE CLICK or CTRL while moving the mouse"
}
func get_tutorial_text(idx:int)->String:
	return tutorials_text[str(idx)]

var prompt : Prompt = preload("res://ui/prompt.tscn").instantiate()

var next_tutorial_popup : int = Global.TUTORIAL.TUTORIAL_OVER

var tutorial_enabled : bool = false:
	set(x):tutorial_enabled=x;if(x):next_tutorial_popup=Global.TUTORIAL.MOVEMENT

func global_ready()->void:
	Global.loading_finished.connect(call_tutorial.bind(0))
	Global.tutorial_closed.connect(tutorial_closed_recieved)

func call_tutorial(which:int)->void: ##you might want to add tutorial values do not queue the next one afterwards
	if not tutorial_enabled: return
	
	if next_tutorial_popup == which:
		match next_tutorial_popup:
			Global.TUTORIAL.MOVEMENT:
				create_prompt(Global.SCREENS.SHOOTER,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
			Global.TUTORIAL.INTERACT_DOOR:
				create_prompt(Global.SCREENS.SHOOTER,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
			Global.TUTORIAL.MOVE_ROOM:
				create_prompt(Global.SCREENS.ROOM_MOVE,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
			Global.TUTORIAL.DROP_ROOM:
				create_prompt(Global.SCREENS.ROOM_MOVE,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
			Global.TUTORIAL.SWITCH_AXIS:
				create_prompt(Global.SCREENS.ROOM_MOVE,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
			Global.TUTORIAL.PAN_VIEW:
				create_prompt(Global.SCREENS.ROOM_MOVE,Prompt.PROMPT_MODES.NOTIFY,
				get_tutorial_text(next_tutorial_popup),&"Tutorial")
				next_tutorial_popup += 1
				
		Global.tutorial_called.emit(which)

func get_screen_by_int(screen:int)->Node:
	return Global.screenroots[screen]

func tutorial_closed_recieved(which:int)->void:
	if tutorial_enabled:
		match which:
			Global.TUTORIAL.SWITCH_AXIS:
				call_tutorial(Global.TUTORIAL.SWITCH_AXIS)

func create_prompt( on_screen:int,
					type:int,
					body_text:String=&"",
					title_text:String=&"",
					accept_button_text:String=&"",
					deny_button_text:String=&"",
					accept_callable:Callable=Global.null_call,
					deny_callable:Callable=Global.null_call,
					string_input_placeholder_text:String=&""
					)->void:
	if prompt.is_inside_tree():
		prompt.get_parent().remove_child(prompt)
	get_screen_by_int(on_screen).add_child(prompt)
	prompt.show_prompt(type,body_text,title_text,accept_button_text,accept_callable,deny_button_text,deny_callable,string_input_placeholder_text)
