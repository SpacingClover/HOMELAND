class_name ListsView extends Control

enum modes{
	games,
	demos,
	settings,
	tips,
	dev_levels,
	editor_levels
}

const demos_dir : String = "res://demos/"

@onready var title : Label = $Control/catagory
@onready var list : VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var lines : Sprite2D = $Control/Sprite2D
@onready var buttontemplate : Button = $Control/ScrollContainer/VBoxContainer/Button

var save_focus_button : Button

var directories : PackedStringArray

var buttoncounter : int = 0
var mode : int = modes.games

func _init()->void:
	Global.titlescreen.lists = self
	hide()

func _ready()->void:
	list.remove_child(buttontemplate)

func display_list(type:modes)->void:
	var filenames : PackedStringArray
	reset_buttons()
	#var tween : Tween = create_tween()
	mode = type
	for child : Button in list.get_children():
		list.remove_child(child)
		child.queue_free()
	
	match mode:
		
		modes.games:
			title.text = "Play Game"
			add_button("open the demos\nmenu (WIP)")
		
		modes.demos:
			title.text = "Demos"
			
			var exported_dir : String = OS.get_executable_path().get_base_dir()
			filenames = DirAccess.get_files_at(demos_dir)
			for filename : String in filenames:
				directories.append(demos_dir+filename)
				add_button(ResourceLoader.load(demos_dir+filename).game_name)
				
		modes.settings:
			title.text = "Settings"
			for catagoryname : String in ["Video","Audio","Controls"]:
				add_button(catagoryname)
		
		modes.tips:
			PopUps.create_prompt(PopUps.SCREENS.CIRCUITBOARD,Prompt.PROMPT_MODES.NOTIFY,true,
			PopUps.get_tutorial_text(0),&"Tutorial")
			return
		
		modes.dev_levels:
			title.text = "Dev Levels"
			
			var exported_dir : String = OS.get_executable_path().get_base_dir()
			filenames = DirAccess.get_files_at("res://dev_levels/")
			for filename : String in filenames:
				directories.append("res://dev_levels/"+filename)
				add_button(filename)
			mode = modes.demos
		
		modes.editor_levels:
			title.text = "Dev Levels"
			
			var exported_dir : String = OS.get_executable_path().get_base_dir()
			filenames = DirAccess.get_files_at("res://editorgames/")
			for filename : String in filenames:
				directories.append("res://editorgames/"+filename)
				add_button(filename)
			mode = modes.demos
	
	title.show()
	list.show()
	show()
	move_selection()

func move_selection()->void:
	var first : Control = list.get_child(0)
	if first: first.grab_focus()

func add_button(name:String)->void:
	var button : Button = buttontemplate.duplicate()
	button.text = name
	button.pressed.connect(button_pressed.bind(buttoncounter))
	button.focus_entered.connect(connect_button.bind(button))
	button.mouse_entered.connect(button.grab_focus)
	list.add_child(button)
	buttoncounter += 1

func connect_button(button:Button)->void:
	Global.titlescreen.send_marker_to(button.get_child(0))
	save_focus_button = button

func button_pressed(idx:int)->void:
	match mode:
		modes.demos:
			Global.selected_game_dir = directories[idx]
			Global.titlescreen.extra.display_level_data(load(Global.selected_game_dir))
		modes.settings:
			Global.titlescreen.extra.display_setting(idx)
		

func reveal()->void:
	list.hide()
	title.hide()
	lines.hide()
	await get_tree().create_timer(7).timeout
	lines.show()

func reset_buttons()->void:
	title.text = ""
	buttoncounter = 0
	for child : Button in list.get_children():
		list.remove_child(child)
		child.queue_free()
	hide()
