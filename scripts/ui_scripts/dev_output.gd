class_name DEV_OUTPUT extends Control

@onready var message_container : VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var scroll_container : ScrollContainer = $VBoxContainer/ScrollContainer
@onready var text_edit : LineEdit = $VBoxContainer/TextEdit

static var current : DEV_OUTPUT

var doormeshlist : Array[MeshInstance3D]

func _init()->void:
	current = self

func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"1"):
		Global.titlescreen.zoom_on_screen(0,4)
	elif event.is_action_pressed(&"2"):
		Global.titlescreen.zoom_on_screen(1,1.5)
	elif event.is_action_pressed(&"3"):
		Global.titlescreen.zoom_on_screen(0,1.5)
	elif event.is_action_pressed(&"4"):
		Global.titlescreen.zoom_on_screen(4)
	if event.is_action_pressed(&"enter"):
		var msg : String = text_edit.text; text_edit.text = &""
		var msg_parts : PackedStringArray = msg.split(" ")
		text_edit.release_focus()
		match msg_parts[0]:
			"set":
				match msg_parts[1]:
					"item":
						var typename : String
						if msg_parts[2].is_valid_int():
							typename = RoomItem.get_item_name_by_id(msg_parts[2].to_int())
						elif RoomItem.item_ids.has(msg_parts[2]):
							typename = msg_parts[2]
						else:
							push_message("invalid item id"); return
						if typename == "":
							push_message("invalid item id"); return
						Global.player.DEBUG_place_item_type = typename
						push_message("set type to "+typename)
						Global.player.DEBUG_place_item_args = []
						if msg_parts.size() >= 4:
							var args : Array
							var i : int = 3
							while i < msg_parts.size():
								args.append(msg_parts[i].to_int())
								i+=1
							Global.player.DEBUG_place_item_args = args
					"mode":
						match msg_parts[2]:
							"place":
								Global.player.DEBUG_mode_place_item = true
								push_message("mode place")
							"none":
								Global.player.DEBUG_mode_place_item = false
								push_message("mode normal")
							_:
								push_message("invalid mode at pos 2")
<<<<<<< Updated upstream
=======
					"all":
						match msg_parts[2]:
							"npc":
								match msg_parts[3]:
									"target_pos":
										match msg_parts[4]:
											"random":
												for object : RoomItemInstance in Global.shooterscene.room3d.objects:
													if object is StaticNPC:
														object.go_to(object.position + Vector3(randf_range(-1,1),0,randf_range(-1,1)))
									"step":
										match msg_parts[4]:
											"reset":
												for object : RoomItemInstance in Global.shooterscene.room3d.objects:
													if object is StaticNPC:
														object.instruction_step_idx = 0
									"inc_step":
										for object : RoomItemInstance in Global.shooterscene.room3d.objects:
											if object is StaticNPC:
												object.inc_instruction()
					"tags":
						match msg_parts[2]:
							"visible":
								show_roomvisual_indices.emit()
					"zoom":
						if msg_parts.size() < 3 or not msg_parts[2].is_valid_int():
							push_message("invalid screen index")
							return
						if msg_parts[2].to_int() == -1:
							Global.titlescreen.exit_zoom()
							return
						if msg_parts[2].to_int() < -1:
							push_message("no usability beyond -1")
							return
						Global.titlescreen.zoom_on_screen(msg_parts[2].to_int())
>>>>>>> Stashed changes
					_:
						push_message("invalid target at pos 1")
			"save":
				if Global.in_game:
					Global.shooterscene.room3d.save_room_objects()
					ResourceSaver.save(Global.current_game,Global.selected_game_dir)
					push_message("game saved")
				else:
					push_message("not in game")
			"get":
				match msg_parts[1]:
					"game":
						match msg_parts[2]:
							"path":
								if Global.in_game:
									push_message(Global.selected_game_dir)
								else:
									push_message("not in game")
					_:
						push_message("invalid target at pos 1")
			"inc":
				match msg_parts[1]:
					"room":
						if Global.in_game:
							push_message("ADD INC ROOM FUNCTIONALITY")
						else:
							push_message("not in game")
					"city":
						if Global.in_game:
							var city_idx : int = Global.current_game.cities.find(Global.current_region)+1
							if city_idx >= Global.current_game.cities.size(): city_idx = 0
							Global.set_new_city(city_idx)
							var city_name : String = Global.current_game.cities[city_idx].name
							if city_name == &"": city_name = "{city "+str(city_idx)+"}"
							push_message("set city "+city_name)
						else:
							push_message("not in game")
			"refresh":
				match msg_parts[1]:
					"3d":
						CityView.current.reset_3d_view()
						CityView.current.display_rooms()
			"clear":
				match msg_parts[1]:
					"3d":
						CityView.current.reset_3d_view()
					"output":
						for child : Label in message_container.get_children():
							message_container.remove_child(child)
			"display":
				match msg_parts[1]:
					"3d":
						CityView.current.display_rooms()
<<<<<<< Updated upstream
=======
					
					"squiggles":
						TransitionHandler.begin_transition(TransitionHandler.ANIM_SQUIGGLES_VERT,0)
			"what":
				match msg_parts[1]:
					"type":
						var idx : int = -INF
						if msg_parts[2].is_valid_int(): idx = msg_parts[2].to_int()
						if idx >= RoomItem.item_ids.size():
							push_message("no item with index \"%s\"" % str(idx))
						else:
							push_message(RoomItem.item_ids[idx])
>>>>>>> Stashed changes
			"breakpoint":
				breakpoint
			"its my birthday":
				push_message("omg happy birthday!!")
			_:
				push_message("invalid keyword at pos 0")

static func push_message(text:String)->void:
	var label : Label = Label.new()
	label.text = " - " + text
	current.message_container.add_child(label)
	await current.get_tree().create_timer(0.01).timeout
	current.scroll_container.scroll_vertical = current.scroll_container.get_v_scroll_bar().max_value
