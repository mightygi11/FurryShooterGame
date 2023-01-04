extends ProgressBar

signal reloaded()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_reload(timer: Timer, reload_time: float):
	visible = true
	while timer.time_left > 0:
		value = int((reload_time - timer.time_left) * 100)
	visible = false


func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.
