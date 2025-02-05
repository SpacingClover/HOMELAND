class_name DEV_OUTPUT extends Control

@onready var message_container : VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var scroll_container : ScrollContainer = $VBoxContainer/ScrollContainer
@onready var text_edit : LineEdit = $VBoxContainer/TextEdit

static var current : DEV_OUTPUT

var doormeshlist : Array[MeshInstance3D]

signal show_roomvisual_indices

func _init()->void:
	current = self

func _input(event:InputEvent)->void:
	if event.is_action_pressed(&"enter"):
		var msg : String = text_edit.text.to_lower(); text_edit.text = &""
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
						Global.player.DEBUG_place_item_args = get_args_int(msg_parts,3)
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
					"navtarget":
						match msg_parts[2]:
							"click":
								for child : Node3D in Global.shooterscene.room3d.get_children():
									if child is NPC:
										push_message("found NPC")
										child.update_target_location(await Global.player.report_click_position)
							"room":
								var args : PackedInt64Array = get_args_int(msg_parts,3)
								if args.size() >= 1:
									for child : Node3D in Global.shooterscene.room3d.get_children():
										if child is NPC:
											#child.go_to_room(args[0])
											child.pathfind_between_rooms_to_room(args[0])
							"rand":
								for child : Node3D in Global.shooterscene.room3d.get_children():
									if child is NPC:
										child.pick_random_target_vec()
					"cam":
						var args : PackedInt64Array = get_args_int(msg_parts,2)
						if args.size() >= 2:
							Global.set_camera_layer(args[0],args[1])
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
					"room":
						match msg_parts[2]:
							"idx":
								push_message("room "+str(Global.current_region.rooms.find(Global.current_room)))
					"doorto":
						var args : PackedInt64Array = get_args_int(msg_parts,2)
						if args.size() == 1:
							var door : Door3D = Global.current_room.roominterior.get_door_leads_to_room(args[0],Global.current_region)
							if door: door.hide(); await get_tree().create_timer(1).timeout; door.show()
							else: push_message("cant find door to room "+str(args[0]))
						else:
							push_message("to which room?")
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
							push_message("set city "+Global.current_game.cities[city_idx].get_city_string())
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
					"npcs":
						for child : Node3D in Global.shooterscene.room3d.get_children():
							if child is NPC:
								child.queue_free()
			"display":
				match msg_parts[1]:
					"3d":
						CityView.current.display_rooms()
					"squiggles":
						TransitionHandler.begin_transition(TransitionHandler.ANIM_SQUIGGLES_VERT,0)
			"blockout":
				match msg_parts[1]:
					"room":
						var scene : PackedScene = PackedScene.new()
						scene.pack(Global.shooterscene.room3d)
			"what":
				match msg_parts[1]:
					"type":
						var idx : int = -INF
						if msg_parts[2].is_valid_int(): idx = msg_parts[2].to_int()
						if idx >= RoomItem.item_ids.size():
							push_message("no item with index \"%s\"" % str(idx))
						else:
							push_message(RoomItem.item_ids[idx])
			"breakpoint":
				breakpoint
			"its my birthday":
				push_message("omg happy birthday!!")
			"goto":
				var args : PackedInt64Array = get_args_int(msg_parts,1)
				if args.size() == 0: push_message("missing arguments")
				elif args.size() == 1: push_message("missing room index")
				else: Global.set_new_city(args[0],args[1])
			"spawn":
				match msg_parts[1]:
					"npc":
						var npc : NPC = load("res://scenes/tscn/npc.tscn").instantiate()
						Global.shooterscene.room3d.add_child(npc)
						npc.global_position = Global.player.global_position
						npc.scale /= 2
						if msg_parts.size() > 2:
							var args : PackedInt64Array = get_args_int(msg_parts,2)
							if args.size() >= 2:
								npc.faction = args[0]
								npc.combatmode = args[1]
								npc.configure(args[0],args[1])
			"list":
				match msg_parts[1]:
					"dev_levels":
						Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.dev_levels)
					"editor_levels":
						Global.titlescreen.lists.display_list(Global.titlescreen.lists.modes.editor_levels)
			"launch":
				match msg_parts[1]:
					"editor":
						Global.launch_level_editor()
			"close":
				match msg_parts[1]:
					"editor":
						Global.close_level_editor()
			"new":
				match msg_parts[1]:
					"room":
						var args : PackedInt64Array = get_args_int(msg_parts,2)
						if args.size() < 3:
							push_message("args x y z")
						else:
							Global.world3D.create_room(0)
			"bake":
				match msg_parts[1]:
					"navmesh":
						Global.shooterscene.room3d.bake_navigation_mesh()
						await Global.shooterscene.room3d.bake_finished
						push_message(r"bake finished")

static func push_message(text:String)->void:
	var label : Label = Label.new()
	label.text = " - " + text
	current.message_container.add_child(label)
	await current.get_tree().create_timer(0.01).timeout
	current.scroll_container.scroll_vertical = current.scroll_container.get_v_scroll_bar().max_value

func get_args_int(msg_parts:PackedStringArray,start_at_pos:int)->PackedInt64Array:
	if msg_parts.size() <= start_at_pos: return PackedInt64Array()
	var args : Array
	var i : int = start_at_pos
	while i < msg_parts.size():
		if msg_parts[i].is_valid_int(): args.append(msg_parts[i].to_int())
		i+=1
	return PackedInt64Array(args)
