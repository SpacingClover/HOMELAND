extends ScrollContainer

enum{
	ANIM_SQUIGGLES_VERT,
	ANIM_CITY_TRANSITION_0
}

const MINFRAME : int = 0
const MAXFRAME : int = 30

@export_enum("top_left","bottom_left","top_right","bottom_right") var corner : int

@onready var label : Label = $CenterContainer/Label

var sprite_datas : Array[TransitionHandler.SpriteUnitData]
var required_time : Timer ## a time buffer that garuntees the transition isnt too fast

var anim_locked : bool = false

func _init()->void:
	required_time = Timer.new(); add_child(required_time)
	set_process(false)
	modulate.a = 0
	hide()

func _ready()->void:
	match corner:
		0: TransitionHandler.topleft = self
		1: TransitionHandler.bottomleft = self
		2: TransitionHandler.topright = self
		3: TransitionHandler.bottomright = self


func end_animation()->void:
	if not required_time.is_stopped():
		await required_time.timeout
	
	var tween : Tween = create_tween()
	tween.tween_property(self,"modulate:a",0,1).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	set_process(false)
	label.hide()
	hide()

func _process(_delta:float)->void:
	if anim_locked: return
	
	for spritedata : TransitionHandler.SpriteUnitData in sprite_datas:
		spritedata.sprite.frame += spritedata.speed
		if spritedata.sprite.frame > MAXFRAME:
			spritedata.sprite.frame -= MAXFRAME
	
	anim_locked = true
	await get_tree().create_timer(0.05).timeout
	anim_locked = false

func display_text(text:String)->void:
	label.text = text
	label.show()
