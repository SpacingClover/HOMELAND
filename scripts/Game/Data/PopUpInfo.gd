class_name PopUpInfo extends Resource

@export var on_screen : int
@export var type : int
@export var prev_next : bool = false
@export var body_text : String = &""
@export var title_text : String = &""
@export var accept_button_text : String = &""
@export var deny_button_text : String = &""
@export var accept_call : String = &""
@export var deny_call : String = &""
@export var string_input_placeholder_text : String = &""

func _init(on_screen_:int=0,type_:int=0,prev_next_:bool=false,body_text_:String=&"",title_text_:String=&"",accept_button_text_:String=&"",deny_button_text_:String=&"",accept_callable_:String=&"",deny_callable_:String=&"",string_input_placeholder_text_:String = &"")->void:
	on_screen = on_screen_
	type = type_
	prev_next = prev_next_
	body_text = body_text_
	title_text = title_text_
	accept_button_text = accept_button_text_
	deny_button_text = deny_button_text_
	accept_call = accept_callable_
	deny_call = deny_callable_
	string_input_placeholder_text = string_input_placeholder_text_
