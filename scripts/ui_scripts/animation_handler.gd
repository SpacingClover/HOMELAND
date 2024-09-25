class_name TransitionHandler

enum{
	ANIM_SQUIGGLES_VERT,
	ANIM_CITY_TRANSITION_0
}

static var topleft : ScrollContainer
static var bottomleft : ScrollContainer
static var topright : ScrollContainer
static var bottomright : ScrollContainer

static func begin_transition(transition:int=ANIM_SQUIGGLES_VERT)->void:
	for screen : ScrollContainer in [topleft,bottomleft,topright,bottomright]:
		match transition:
			ANIM_SQUIGGLES_VERT: ##this field should be used to load in the sprites for different animations
				screen.show()
			ANIM_CITY_TRANSITION_0:
				if screen != bottomright: screen.show()
				else: screen.hide()
			_:
				DEV_OUTPUT.push_message("invalid animation id")
			
		screen.sprite_datas.clear()
		for sprite : Node in screen.get_children():
			if sprite is Sprite2D:
				screen.sprite_datas.append(SpriteUnitData.new(sprite,randi_range(1,2)))
				sprite.scale.y *= 1 if randi_range(0,1) == 0 else -1
				sprite.frame = randi_range(screen.MINFRAME,screen.MAXFRAME)
		screen.set_process(true)
		var tween : Tween = screen.create_tween()
		tween.tween_property(screen,"modulate:a",1,1).set_trans(Tween.TRANS_QUAD)
		screen.required_time.start(2)

static func end_transition()->void:
	for screen : ScrollContainer in [topleft,bottomleft,topright,bottomright]:
		screen.end_animation()

class SpriteUnitData extends RefCounted:
	var sprite : Sprite2D
	var speed : int
	func _init(sprite_:Sprite2D,speed_:int)->void:
		sprite = sprite_
		speed = speed_
