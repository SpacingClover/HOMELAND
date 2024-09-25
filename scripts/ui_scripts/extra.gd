class_name ExtraView extends Control

@onready var title       : Label    = $level_screen/VBoxContainer/title
@onready var description : Label    = $level_screen/VBoxContainer/ScrollContainer/description
@onready var datetime    : Label    = $level_screen/VBoxContainer/datetime
@onready var levelscreen : Control  = $level_screen
@onready var leftbutton  : Button   = $level_screen/VBoxContainer/buttons/Button
@onready var rightbutton : Button   = $level_screen/VBoxContainer/buttons/Button2
@onready var playdecal   : Sprite2D = $level_screen/VBoxContainer/buttons/Button/playbutton
@onready var backdeal    : Sprite2D = $level_screen/VBoxContainer/buttons/Button2/backbutton

var mode_choose_game : bool = false

func _init()->void:
	Global.titlescreen.extra = self

func _ready()->void:
	leftbutton.pressed.connect(left_button_pressed)
	leftbutton.focus_entered.connect(enter_focus.bind($level_screen/VBoxContainer/buttons/Button/Marker2D,$level_screen/VBoxContainer/buttons/Button/playbutton,Rect2i(Vector2i(14,0),Vector2i(14,5))))
	leftbutton.focus_exited.connect(exit_focus.bind($level_screen/VBoxContainer/buttons/Button/playbutton,Rect2i(Vector2i.ZERO,Vector2i(14,5))))
	leftbutton.mouse_entered.connect(leftbutton.grab_focus)
	rightbutton.pressed.connect(right_button_pressed)
	rightbutton.focus_entered.connect(enter_focus.bind($level_screen/VBoxContainer/buttons/Button2/Marker2D,$level_screen/VBoxContainer/buttons/Button2/backbutton,Rect2i(Vector2i(22,10),Vector2i(12,5))))
	rightbutton.focus_exited.connect(exit_focus.bind($level_screen/VBoxContainer/buttons/Button2/backbutton,Rect2i(Vector2i(22,5),Vector2i(12,5))))
	rightbutton.mouse_entered.connect(rightbutton.grab_focus)
	levelscreen.hide()

func display_level_data(level:GameData)->void:
	show()
	levelscreen.show()
	mode_choose_game = true
	title.text = level.game_name
	description.text = level.description
	if level.demo:
		datetime.text = &"Created "+level.first_created_date
	else:
		datetime.text = &"Last Played "+level.last_accessed_date
	await get_tree().create_timer(0.1).timeout
	leftbutton.grab_focus()

func display_setting(idx:int)->void:
	pass

func left_button_pressed()->void:
	if mode_choose_game:
		Global.enter_game_transition(ResourceLoader.load(Global.selected_game_dir,&"",ResourceLoader.CACHE_MODE_IGNORE))

func right_button_pressed()->void:
	if mode_choose_game:
		levelscreen.hide()
		mode_choose_game = false
		Global.titlescreen.lists.save_focus_button.grab_focus()

func enter_focus(marker:Marker2D,text:Sprite2D,rect:Rect2i)->void:
	Global.titlescreen.send_marker_to(marker)
	text.region_rect = rect

func exit_focus(text:Sprite2D,rect:Rect2i)->void:
	text.region_rect = rect
