class_name ScriptListItem extends Resource
#this class is proof that godot would benefit from structs
@export var idx : int
@export var text : String
@export var is_label : bool

func _init(idx_:int=-1,text_:String=&"",is_label_:bool=false)->void:
	idx = idx_; text = text_; is_label = is_label_
