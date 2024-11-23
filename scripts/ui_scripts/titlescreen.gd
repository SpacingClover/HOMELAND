class_name TitleScreen extends Control

const marker_texture : Texture2D = preload("res://visuals/spritesheets/ui/menu_focus_2.png")

var title : TitleView ## not onready due to potential reordering
var buttons : ButtonsView
var lists : ListsView
var extra : ExtraView
var titlescreen_gui : Array[Control]:
	get: return [title,buttons,lists,extra]
@onready var backdrop : Panel = $Panel
@onready var credits : Control = $credits


var focus_marker : Sprite2D
var markertween : Tween
var zoomtween : Tween

func _init()->void:
	Global.titlescreen = self
	set_process_input(false)
	Global.hide_menu.connect(delete_marker)

func _ready()->void:
	Global.hide_menu.connect(hide_credits)
	game_opening_animation()
	
func game_opening_animation()->void:
	backdrop.hide()
	$credits/titlecredits.hide()
	for i : Control in Global.screenroots + titlescreen_gui: i.hide()
	var opening1 : Label = $credits/opening1
	opening1.show()
	opening1.modulate.a = 0
	var tween : Tween = create_tween()
	tween.tween_property(opening1,"modulate:a",1,1)
	
	await get_tree().create_timer(3).timeout
	
	tween = create_tween()
	backdrop.show()
	backdrop.modulate.a = 0
	tween.tween_property(backdrop,"modulate:a",1,1)
	
	await tween.finished
	
	tween = create_tween()
	tween.set_parallel()
	for i : GameViewExports in Global.screenroots:
		i.show()
		i.modulate.a = 0
		tween.tween_property(i,"modulate:a",1,1)
	
	await tween.finished
	
	open_titlescreen_mode()
	focus_marker = new_marker()

func open_titlescreen_mode()->void:
	title.reveal()
	buttons.reveal()
	set_process_input(true)
	
	await get_tree().create_timer(8).timeout
	var titlecredits : Label = $credits/titlecredits
	titlecredits.show(); titlecredits.modulate.a = 0
	create_tween().tween_property(titlecredits,"modulate:a",1,5)

func close_titlescreen_mode()->void:
	set_process_input(false)

func hide_credits()->void:
	create_tween().tween_property(credits,"modulate:a",0,1)

func new_marker()->Sprite2D:
	var mark : Sprite2D = Sprite2D.new()
	mark.texture = marker_texture
	mark.scale /= 2
	add_child(mark)
	return mark

func send_marker_to(point:Marker2D)->void:
	if not focus_marker:
		focus_marker = new_marker()
	
	if markertween:
		markertween.stop()
	markertween = create_tween()
	
	markertween.set_ease(Tween.EASE_OUT)
	markertween.set_trans(Tween.TRANS_ELASTIC)
	markertween.tween_property(focus_marker,"global_position",point.global_position,0.5)

func delete_marker()->void:
	if not focus_marker:
		return
	focus_marker.queue_free()
	focus_marker = null

func get_screen_roots()->Array[GameViewExports]:
	return [$HBoxContainer/VBoxContainer/GameView1,$HBoxContainer/VBoxContainer/GameView2,$HBoxContainer/VBoxContainer2/GameView3,$HBoxContainer/VBoxContainer2/GameView4]

func zoom_on_screen(screen:int,duration:float=1)->void:
	if zoomtween: if zoomtween.is_running():
		zoomtween.stop()
	zoomtween = create_tween().set_parallel()
	var zoomsize : Vector2 = Vector2(2.087,2.087) if screen < 4 else Vector2(1.5,1.5)
	var zoompos : Vector2 = [Vector2(-466,-201),Vector2(-1700,-201),Vector2(-466,-921),Vector2(-1700,-921),Vector2(-500,0)][screen]
	zoomtween.tween_property(self,"scale",zoomsize,duration)
	zoomtween.tween_property(self,"position",zoompos,duration)
	zoomtween.set_trans(Tween.TRANS_QUAD)
	zoomtween.set_ease(Tween.EASE_IN_OUT)

func exit_zoom(duration:float=1)->void:
	if zoomtween: if zoomtween.is_running():
		zoomtween.stop()
	zoomtween = create_tween().set_parallel()
	var zoomsize : Vector2 = Vector2(1,1)
	var zoompos : Vector2 = Vector2.ZERO
	zoomtween.tween_property(self,"scale",zoomsize,duration)
	zoomtween.tween_property(self,"position",zoompos,duration)
	zoomtween.set_trans(Tween.TRANS_QUAD)
	zoomtween.set_ease(Tween.EASE_IN_OUT)
