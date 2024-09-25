extends PanelContainer

const top_left : int = 0
const top_right : int = 1
const bottom_left : int = 2
const bottom_right : int = 3
@export_enum("top_left","top_right","bottom_left","bottom_right") var screen_pos : int

func _init()->void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _ready()->void:
	if screen_pos == top_right:
		$Panel/Button.pressed.connect(resume_button_pressed)
	if screen_pos == bottom_right:
		$Panel/Button.pressed.connect(exit_to_menu)
	Global.pause_game.connect(show)
	Global.resume_game.connect(hide)
	hide()

func resume_button_pressed()->void:
	Global.resume_game.emit()

func exit_to_menu()->void:
	Global.unload_game_and_exit_to_menu()
