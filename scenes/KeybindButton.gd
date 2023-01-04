extends Button

var action = "shoot"
var waiting = false
var old_text = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	text = action + ": (" + InputMap.action_get_events(action)[0].as_text() + ")"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if !waiting:
		return
	if !(event is InputEventKey) and !(event is InputEventMouseButton):
		return
	if event.as_text() == "Space":
		return
	if event.as_text() == "Delete":
		InputMap.action_erase_events(action)
		waiting = false
		text = action + ": (" + InputMap.action_get_events(action)[0].as_text() + ")"
		return
	elif event.as_text() == "Escape":
		waiting = false
		text = action + ": (" + InputMap.action_get_events(action)[0].as_text() + ")"
		return
	InputMap.action_add_event(action, event)
	text = action + ": (" + event.as_text() + ")"
	waiting = false


func _on_pressed():
	waiting = true
	text = action + ": (Waiting...)"
	await get_tree().create_timer(5).timeout
	if waiting == true:
		waiting = false
		text = action + ": (" + InputMap.action_get_events(action)[0].as_text() + ")"
	
