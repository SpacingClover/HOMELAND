class_name MusicManager extends Node

static var stream_1 : AudioStreamPlayer

static var songs : Dictionary = {
	"action" : ResourceLoader.load("res://audio/songs/action.wav",&"",ResourceLoader.CACHE_MODE_IGNORE),
	"ambience" : ResourceLoader.load("res://audio/songs/ambience.wav",&"",ResourceLoader.CACHE_MODE_IGNORE)
}

func _init()->void:
	pass

func _ready()->void:
	Global.pause_game.connect(change_pitch.bind(0.85))
	Global.resume_game.connect(change_pitch.bind(1))
	
	stream_1 = get_node("stream_1")
	stream_1.finished.connect(stream_1.play)
	
	play_song("action")

static func play_song(name:String)->void:
	stream_1.stream = get_song(name)
	stream_1.play()

static func stop_song()->void:
	stream_1.stop()

static func get_song(name:String)->AudioStreamWAV:
	return songs[name]

static func change_pitch(to:float)->void:
	stream_1.pitch_scale = to
