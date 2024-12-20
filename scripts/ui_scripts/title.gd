class_name TitleView extends Control

@onready var effect : Sprite2D = $BackBufferCopy/text/effect
@onready var effect2: Sprite2D = $BackBufferCopy/text2/effect2
@onready var effect3: Sprite2D = $BackBufferCopy/text3/effect3

func _init()->void:
	Global.titlescreen.title = self

func reveal()->void:
	show()
	effect.frame = 1
	effect2.frame = 1
	effect3.frame = 1
	var tween : Tween = create_tween()
	tween.tween_property(effect,"frame",1,1)
	tween.tween_property(effect,"frame",21,1.5)
	tween.tween_property(effect2,"frame",21,1)
	tween.tween_property(effect3,"frame",21,0.75)
