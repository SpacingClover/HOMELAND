extends StaticBody2D

func _ready()->void:
	$pot.frame = randi_range(4,7)
	$plant.frame = randi_range(0,3)

func shatter(hit_from_right:bool)->void:
	$plant.hide()
	$pot.hide()
	$AudioStreamPlayer2D.play()
	$shatter.show()
	if not hit_from_right:
		$shatter.flip_h = true
		$shatter.position.x = -$shatter.position.x
	var tween : Tween = create_tween()
	tween.tween_property($shatter,"frame",3,0.1)
	$CollisionShape2D.disabled = true

func shoot(hit_from_right:bool)->void:
	shatter(hit_from_right)
