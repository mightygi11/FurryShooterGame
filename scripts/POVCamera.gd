extends Camera3D

@export var MOUSE_SENSITIVITY = 0.005



@onready var PLAYER = get_parent()

var yaw = 0
var pitch = 0
var mouse_captured = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$"../PauseMenu".connect("mouse_sensitivity_changed", _on_mouse_sensitivity_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func is_local_authority() -> bool:
	return get_multiplayer_authority() == multiplayer.get_unique_id()

func _input(event):
	if !is_local_authority() or get_parent().paused:
		return
	#Camera movement
	if event is InputEventMouseMotion:
		yaw = fmod(yaw - event.relative.x * MOUSE_SENSITIVITY, 360)
		pitch = max(min(pitch - event.relative.y * MOUSE_SENSITIVITY, 1), -1)
		
		PLAYER.rotation.y = yaw
		rotation.x = pitch
	
	#Mouse lock toggle
	if event.is_action_pressed("mouse_toggle"):
		if mouse_captured:
			mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			mouse_captured = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Pause menu shenanigans

func _on_mouse_sensitivity_changed(new_val):
	MOUSE_SENSITIVITY = 0.0001 * new_val
	

