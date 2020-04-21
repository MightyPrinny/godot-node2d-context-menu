tool
extends EditorPlugin

var menu:PopupMenu
var target_pos:Vector2
var obj:Node2D

var snap_ox = 0
var snap_oy = 0
var snap_sx = 8
var snap_sy = 8

enum {
	MoveHereWithSnap,
	MoveHereWithSnapCeilY,
	MoveHere,
	FlipX,
	FlipY,
	ResetScale,
}

func popup_menu(position):
	target_pos = position
	menu.popup(Rect2(get_editor_interface().get_editor_viewport().get_global_mouse_position(),Vector2(1,1)))
	
func _enter_tree():
	var temp = Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,temp)
	open_configure_snap(temp.get_parent())
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,temp)
	temp.free()
	watch_snap_settings(get_editor_interface().get_base_control())
	menu = PopupMenu.new()
	menu.add_item("Move here with snap", MoveHereWithSnap)
	menu.add_item("Move here with snap(ceil y)", MoveHereWithSnapCeilY)
	menu.add_item("Move here", MoveHere)
	menu.add_item("Flip Horizontally", FlipX)
	menu.add_item("FLip Vertically", FlipY)
	menu.connect("id_pressed", self, "menu_id_pressed")
	print("ced move_here enabled")
	
	get_editor_interface().get_editor_viewport().add_child(menu)

func forward_canvas_gui_input(event):
	if !is_instance_valid(obj):
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT && event.pressed:
			popup_menu(get_editor_interface().get_edited_scene_root().get_global_mouse_position())
			return true
	
func _exit_tree():
	if is_instance_valid(menu):
		menu.queue_free()
	obj = null
	
func open_configure_snap(canvas_toolbar):
	for child in canvas_toolbar.get_children():
		if child is MenuButton:
			if child.text == "":
				var popup = child.get_popup() as PopupMenu
				var id = popup.get_item_index(11)
				if popup.get_item_text(id) == tr("Configure Snap..."):
					print("Scene Palette: configuring snap")
					popup.emit_signal("id_pressed",11)
					return
	print("Node2D Context Menu: Failed find configure snap button")
	
func handles(var potential):
	if potential is Node2D:
		obj = potential
		return true
		
func menu_id_pressed(id):
	if !is_instance_valid(obj):
		return
	match(id):
		MoveHere:
			move_here()
		MoveHereWithSnap:
			move_here_with_snap()
		FlipX:
			flip_x()
		FlipY:
			flip_y()
		MoveHereWithSnapCeilY:
			move_here_with_snap_ceil_y()
				
				
func flip_x():
	var ud = get_undo_redo()
	var new_scale = obj.scale * Vector2(-1,1)
	ud.create_action("flip horizontally")
	ud.add_undo_property(obj,"scale",obj.scale)
	ud.add_do_property(obj,"scale", new_scale)
	obj.scale = new_scale
	ud.commit_action()
	
func flip_y():
	var ud = get_undo_redo()
	var new_scale = obj.scale * Vector2(1,-1)
	ud.create_action("flip vertically")
	ud.add_undo_property(obj,"scale",obj.scale)
	ud.add_do_property(obj,"scale", new_scale)
	obj.scale = new_scale
	ud.commit_action()
	
func move_here():
	var ud = get_undo_redo()
	ud.create_action("move node to mouse")
	ud.add_undo_property(obj,"global_position",obj.global_position)
	ud.add_do_property(obj,"global_position", target_pos)
	obj.global_position = target_pos
	ud.commit_action()
	
func move_here_with_snap():
	var ud = get_undo_redo()
	target_pos = Vector2(floor(target_pos.x/snap_sx)*snap_sy,floor(target_pos.y/snap_sy)*snap_sy) + Vector2(snap_ox,snap_oy)
	ud.create_action("move node to mouse with snap")
	ud.add_undo_property(obj,"global_position",obj.global_position)
	ud.add_do_property(obj,"global_position", target_pos)
	obj.global_position = target_pos
	ud.commit_action()
	
func move_here_with_snap_ceil_y():
	var ud = get_undo_redo()
	target_pos = Vector2(floor(target_pos.x/snap_sx)*snap_sy,ceil(target_pos.y/snap_sy)*snap_sy) + Vector2(snap_ox,snap_oy)
	ud.create_action("move node to mouse with snap")
	ud.add_undo_property(obj,"global_position",obj.global_position)
	ud.add_do_property(obj,"global_position", target_pos)
	obj.global_position = target_pos
	ud.commit_action()
	
func watch_snap_settings(root:Node):
	for child in root.get_children():
		if child is Label:
			if child.text == tr("Grid Offset:"):
				var container:GridContainer = child.get_node("..")
				var snap_dialog:ConfirmationDialog = container.get_node("../..")
				snap_dialog.get_close_button().emit_signal("pressed")
				var off_x:SpinBox = container.get_child(1)
				var off_y:SpinBox = container.get_child(2)
				var step_x:SpinBox = container.get_child(4)
				var step_y:SpinBox = container.get_child(5)
				
				if !off_x.is_connected("value_changed", self, "snap_ox_changed"):
					off_x.connect("value_changed", self, "snap_ox_changed" )
				if !off_y.is_connected("value_changed", self, "snap_oy_changed"):
					off_y.connect("value_changed", self, "snap_oy_changed" )
				if !step_x.is_connected("value_changed", self, "snap_sx_changed"):
					step_x.connect("value_changed", self, "snap_sx_changed" )
				if !step_y.is_connected("value_changed", self, "snap_sy_changed"):
					step_y.connect("value_changed", self, "snap_sy_changed" )
				
				snap_ox = off_x.value
				snap_oy = off_y.value
				snap_sx = step_x.value
				snap_sy = step_y.value
				return
		watch_snap_settings(child)

func snap_ox_changed(value):
	snap_ox = value
	
func snap_oy_changed(value):
	snap_oy = value

func snap_sx_changed(value):
	snap_sx = value
	
func snap_sy_changed(value):
	snap_sy = value
