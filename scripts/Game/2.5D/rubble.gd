extends StaticBody3D

@onready var sprite0 : Sprite3D = $Sprite3D
@onready var sprite1 : Sprite3D = $Sprite3D2
@onready var sprite2 : Sprite3D = $Sprite3D3
@onready var sprite3 : Sprite3D = $Sprite3D4

var sprites : Array[Sprite3D]:
	get: return [sprite0,sprite1,sprite2,sprite3]

var frame : int = 0

func _ready()->void:
	for sprite : Sprite3D in sprites:
		sprite.frame = 1
		sprite.layers = 2
