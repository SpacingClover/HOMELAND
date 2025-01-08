@tool
extends EditorPlugin

const FILEPATH : String = "res://sorted_scripts_storage.scn"

var scripts_list : ItemList

func _enter_tree()->void:
	
	await get_tree().create_timer(1).timeout #wait for the editor to initialize
	
	var scripteditor : ScriptEditor = EditorInterface.get_script_editor()
	if not scripteditor:
		push_error("PLUGIN ERROR: plugin \"SortedScripts\" could not access ScriptEditor via method \"EditorInterface.get_script_editor()\"")
		return
	
	var scripteditorbase : ScriptEditorBase = scripteditor.get_current_editor()
	if not scripteditorbase:
		push_error("PLUGIN ERROR: plugin \"SortedScripts\" could not access ScriptEditorBase via method \"ScriptEditor.get_current_editor()\"")
		return
	
	scripts_list = find_script_list(scripteditor)
	if not scripts_list:
		push_error("PLUGIN ERROR: plugin \"SortedScripts\" could not locate script list gui")
		return
	
	#loading goes here
	
	scripts_list.gui_input.connect(save_script_order)

func save_script_order(event:InputEvent)->void:
	pass

func organize_script_list()->void:
	pass

func find_script_list(branch:Node)->ItemList:
	return search_tree(branch)
#this level is just to keep the "first_call" variable away from a possible user

func search_tree(branch:Node,first_call:bool=true)->ItemList:
	var itemslists_list : Array[ItemList]
	for child : Node in branch.get_children():
		if child is ItemList:
			itemslists_list.append(child)
			return child
		else:
			var recursechild : Node = search_tree(child,false)
			if recursechild is ItemList:
				itemslists_list.append(recursechild)
				return recursechild
	
	if not first_call:
		return null
	#i sectioned it like this so that "itemslists_list" is freed after
	
	var chosen_list : ItemList = itemslists_list[0]
	for itemlist : ItemList in itemslists_list:
		if itemlist.item_count > chosen_list.item_count:
			chosen_list = itemlist
	#this loop exists because the script list should always be the largest
	#item list at this location, but in future versions it may not be the first
	
	return chosen_list
