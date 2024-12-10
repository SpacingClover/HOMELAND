extends PanelContainer

const top_left : int = 0
const top_right : int = 1
const bottom_left : int = 2
const bottom_right : int = 3
@export_enum("top_left","top_right","bottom_left","bottom_right") var screen_pos : int

@onready var sprite1 : Sprite2D = get_node_or_null(^"Panel/sprite1")
@onready var sprite2 : Sprite2D = get_node_or_null(^"Panel/sprite2")
@onready var sprite3 : Sprite2D = get_node_or_null(^"Panel/sprite3")
@onready var sprite4 : Sprite2D = get_node_or_null(^"Panel/sprite4")

var sprites : Array[Sprite2D]:
	get: return [sprite1,sprite2,sprite3,sprite4]

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

func _notification(what:int)->void:
	if what == NOTIFICATION_PAUSED:
		if screen_pos == top_left:
			sprite1.frame = randi_range(0,20)
			sprite2.frame = sprite1.frame
			sprite3.frame = randi_range(0,20)
			sprite4.frame = sprite3.frame
			
			var flip : bool = bool(randi_range(0,1))
			if flip:
				sprite1.scale.y *= -1
				sprite2.scale.y *= -1
			flip = bool(randi_range(0,1))
			if flip:
				sprite3.scale.y *= -1
				sprite4.scale.y *= -1

func resume_button_pressed()->void:
	Global.resume_game.emit()

func exit_to_menu()->void:
	Global.unload_game_and_exit_to_menu()

func _process(delta:float)->void:
	if screen_pos == top_left:
		for sprite : Sprite2D in sprites:
			if not sprite: continue
			sprite.frame += 1
			if sprite.frame >= 31:
				sprite.frame = 0
