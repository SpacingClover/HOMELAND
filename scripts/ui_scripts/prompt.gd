class_name Prompt extends Control

enum PROMPT_MODES{
	NOTIFY,
	ACCEPT_DENY,
	INPUT_STRING
}
var mode : int
var saved_prompt_id : int

@onready var title : Label = $Control/Panel2/PanelContainer/title
@onready var body : Label = $Control/Panel/MarginContainer/VBoxContainer/ScrollContainer/body
@onready var accept : Button = $Control/Panel/MarginContainer/VBoxContainer/HSplitContainer/accept
@onready var deny : Button = $Control/Panel/MarginContainer/VBoxContainer/HSplitContainer/deny
@onready var textinput : LineEdit = $Control/Panel/MarginContainer/VBoxContainer/HSplitContainer/textinput
@onready var textaccept : Button = $Control/Panel/MarginContainer/VBoxContainer/HSplitContainer/string_accept
@onready var prev : Button = $Control/prev
@onready var next : Button = $Control/next


var accept_call : Callable
var deny_call : Callable

func _ready()->void:
	accept.pressed.connect(accept_button_pressed)
	textaccept.pressed.connect(accept_button_pressed)
	deny.pressed.connect(deny_button_pressed)
	next.pressed.connect(next_button)
	prev.pressed.connect(prev_button)

func show_prompt(prompt_type:Prompt.PROMPT_MODES,prev_next_visible:bool=false,body_text:String=&"",title_text:String=&"",accept_button_text:String=&"",accept_callable:Callable=Global.null_call,deny_button_text:String=&"",deny_callable:Callable=Global.null_call,string_input_placeholder_text:String=&"")->void:
	mode = prompt_type
	next.visible = prev_next_visible
	prev.visible = prev_next_visible
	match mode:
		PROMPT_MODES.NOTIFY:
			if title_text == &"":
				make_title_visible(false)
			else:
				title.text = title_text
				make_title_visible(true)
			body.text = body_text
			body.show()
			if accept_button_text == &"":
				accept.text = "Continue"
				if not Global.in_game:
					accept.text = "Exit"
			else:
				accept.text = accept_button_text
			accept.show()
			deny.hide()
			accept_call = accept_callable
			if PopUps.tutorial_enabled:
				saved_prompt_id = PopUps.next_tutorial_popup
				accept.pressed.connect(func()->void:Global.tutorial_closed.emit(PopUps.next_tutorial_popup),CONNECT_ONE_SHOT)
				if prev_next_visible:
					if Global.in_game:
						next.hide()
					if saved_prompt_id > 0:
						prev.show()
					else:
						prev.hide()
		PROMPT_MODES.ACCEPT_DENY:
			pass
		PROMPT_MODES.INPUT_STRING:
			pass
		_:
			return
	if Global.in_game:
		get_tree().paused = true
	show()

func make_title_visible(yes:bool=true)->void:
	title.get_parent().visible = yes

func accept_button_pressed()->void:
	if accept_call:
		accept_call.call()
	prompt_closed()

func deny_button_pressed()->void:
	if deny_call:
		deny_call.call()
	prompt_closed()

func prompt_closed()->void:
	get_tree().paused = false
	get_parent().remove_child(self)

func next_button()->void:
	if PopUps.tutorial_enabled or not Global.in_game:
		if (saved_prompt_id + 1 < PopUps.next_tutorial_popup and Global.in_game) or (saved_prompt_id + 1 < PopUps.TUTORIAL.TUTORIAL_OVER and not Global.in_game):
			saved_prompt_id += 1
			body.text = PopUps.get_tutorial_text(saved_prompt_id)
			if saved_prompt_id + 1 >= PopUps.next_tutorial_popup:
				next.hide()
			prev.show()

func prev_button()->void:
	if PopUps.tutorial_enabled or not Global.in_game:
		if saved_prompt_id - 1 >= 0:
			saved_prompt_id -= 1
			body.text = PopUps.get_tutorial_text(saved_prompt_id)
			if saved_prompt_id - 1 < 0:
				prev.hide()
			next.show()
