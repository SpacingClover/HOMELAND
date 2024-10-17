class_name InstructionStep extends Resource

@export var has_dialogue : bool = false
@export var dialogueinfo : PopUpInfo

@export var has_movement_target : bool = false
@export var movement_target_pos : Vector3

@export var has_wait_for_signal : bool = false
@export var is_wait_door_opened_signal : bool = false #only works for doors in current room
@export var door_box  : int = -1
@export var door_face : int = -1
