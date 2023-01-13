extends Control

var keybind_actions = ["shoot", "reload", "move_forward", "move_backward", "move_left", "move_right", "jump"]
var keybind_button = preload("res://scenes/keybind_button.tscn")

signal mouse_sensitivity_changed(new_val)
# Called when the node enters the scene tree for the first time.
	
func _ready():
	$GameModes.visible = multiplayer.is_server()

func _on_mouse_sensitivity_drag_ended(_value_changed):
	emit_signal("mouse_sensitivity_changed", $Options/MouseSensitivity.value)
	$Options/MSLabel.text = "Mouse Sensitivity (%s)" % $Options/MouseSensitivity.value


func _on_keybinds_pressed():
	$Options.visible = false
	$GameModes.visible = false
	$KeybindsMenu.visible = true
	$KeybindsMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	#Create keybind options in keybinds menu
	for i in keybind_actions:
		var btn = keybind_button.instantiate()
		btn.action = i
		$KeybindsMenu/KeybindsList.add_child(btn)
	

func _on_hidden():
	$Options.visible = true
	$GameModes.visible = multiplayer.is_server()
	$KeybindsMenu.visible = false
	$KeybindsMenu.process_mode = Node.PROCESS_MODE_DISABLED
	for btn in $KeybindsMenu/KeybindsList.get_children():
		btn.queue_free()
