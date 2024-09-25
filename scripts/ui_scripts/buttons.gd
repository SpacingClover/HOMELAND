class_name ButtonsView extends Control

@onready var effect1 : Sprite2D = $BackBufferCopy/effect2
@onready var effect2 : Sprite2D = $BackBufferCopy/effect3
@onready var effect3 : Sprite2D = $BackBufferCopy/effect4
@onready var effect4 : Sprite2D = $BackBufferCopy/effect5
@onready var effect5 : Sprite2D = $BackBufferCopy/effect6
@onready var playbutton     : Button = $interactables/Button
@onready var playdemobutton : Button = $interactables/Button2
@onready var settingsbutton : Button = $interactables/Button3
@onready var tipsbutton     : Button = $interactables/Button4
@onready var quitbutton     : Button = $interactables/Button5

var playselected     : bool = false
var playdemoselected : bool = false
var settingsselected : bool = false
var tipsselected     : bool = false
var quitselected     : bool = false

func _init()->void:
	Global.titlescreen.buttons = self

func _ready()->void:
	reset_frames()
	playbutton.pressed.connect(press_play)
	playbutton.focus_entered.connect(enter_focus.bind($interactables/Button/Marker2D,$BackBufferCopy/effect2))
	playbutton.focus_exited.connect(exit_focus.bind($BackBufferCopy/effect2))
	
	playdemobutton.pressed.connect(press_playdemo)
	playdemobutton.focus_entered.connect(enter_focus.bind($interactables/Button2/Marker2D,$BackBufferCopy/effect3))
	playdemobutton.focus_exited.connect(exit_focus.bind($BackBufferCopy/effect3))
	
	settingsbutton.pressed.connect(press_settings)
	settingsbutton.focus_entered.connect(enter_focus.bind($interactables/Button3/Marker2D,$BackBufferCopy/effect4))
	settingsbutton.focus_exited.connect(exit_focus.bind($BackBufferCopy/effect4))
	
	tipsbutton.pressed.connect(press_tips)
	tipsbutton.focus_entered.connect(enter_focus.bind($interactables/Button4/Marker2D,$BackBufferCopy/effect5))
	tipsbutton.focus_exited.connect(exit_focus.bind($BackBufferCopy/effect5))
	
	quitbutton.pressed.connect(press_exit)
	quitbutton.focus_entered.connect(enter_focus.bind($interactables/Button5/Marker2D,$BackBufferCopy/effect6))
	quitbutton.focus_exited.connect(exit_focus.bind($BackBufferCopy/effect6))

func reveal()->void:
	show()
	var playtween     : Tween = create_tween()
	var playdemotween : Tween = create_tween()
	var settingstween : Tween = create_tween()
	var tipstween     : Tween = create_tween()
	var exittween     : Tween = create_tween()
	
	reset_frames()
	
	exittween.tween_property(effect5,"frame",1,4)
	exittween.tween_property(effect5,"frame",21,1)
	
	tipstween.tween_property(effect4,"frame",1,4.5)
	tipstween.tween_property(effect4,"frame",21,1)
	
	settingstween.tween_property(effect3,"frame",1,5)
	settingstween.tween_property(effect3,"frame",21,1)
	
	playdemotween.tween_property(effect2,"frame",1,5.5)
	playdemotween.tween_property(effect2,"frame",21,1)
	playdemotween.finished.connect(reveal_finished)
	
	playtween.tween_property(effect1,"frame",1,6)
	playtween.tween_property(effect1,"frame",21,1)

func reveal_finished()->void:
	playdemobutton.grab_focus()
	playbutton.mouse_entered.connect(playbutton.grab_focus)
	playdemobutton.mouse_entered.connect(playdemobutton.grab_focus)
	settingsbutton.mouse_entered.connect(settingsbutton.grab_focus)
	tipsbutton.mouse_entered.connect(tipsbutton.grab_focus)
	quitbutton.mouse_entered.connect(quitbutton.grab_focus)

func reset_frames()->void:
	effect1.frame = 1
	effect2.frame = 1
	effect3.frame = 1
	effect4.frame = 1
	effect5.frame = 1

func enter_focus(point:Marker2D,effect:Sprite2D)->void:
	Global.titlescreen.send_marker_to(point)
	effect.frame = 22

func exit_focus(effect:Sprite2D)->void:
	effect.frame = 21

func press_play()->void:
	if playselected:
		Global.titlescreen.lists.move_selection()
		return
	if effect1.frame <= 15:
		return
	playselected     = true
	playdemoselected = false
	settingsselected = false
	tipsselected     = false
	Tutorials.prompt.hide()
	Global.titlescreen.extra.levelscreen.hide()
	Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.games)

func press_playdemo()->void:
	if playdemoselected:
		Global.titlescreen.lists.move_selection()
		return
	if effect2.frame <= 15:
		return
	playselected     = false
	playdemoselected = true
	settingsselected = false
	tipsselected     = false
	Tutorials.prompt.hide()
	Global.titlescreen.extra.levelscreen.hide()
	Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.demos)

func press_settings()->void:
	if settingsselected:
		Global.titlescreen.lists.move_selection()
		return
	if effect3.frame <= 15:
		return
	playselected     = false
	playdemoselected = false
	settingsselected = true
	tipsselected     = false
	Tutorials.prompt.hide()
	Global.titlescreen.extra.levelscreen.hide()
	Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.settings)

func press_tips()->void:
	if tipsselected:
		return
	if effect4.frame <= 15:
		return
	playselected     = false
	playdemoselected = false
	settingsselected = false
	tipsselected     = true
	Global.titlescreen.extra.levelscreen.hide()
	Tutorials.next_tutorial_popup = Global.TUTORIAL.TUTORIAL_OVER
	Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.tips)

func press_exit()->void:
	if effect5.frame > 15:
		get_tree().quit()

func reset_buttons()->void:
	playselected     = false
	playdemoselected = false
	settingsselected = false
	tipsselected     = false
