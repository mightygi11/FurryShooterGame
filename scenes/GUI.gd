extends Control
var chat_message = preload("res://scenes/chat_message.tscn")



func _process(_delta):
	$FPS.text = ("FPS: "+ str(Engine.get_frames_per_second()))

func reload_anim(reload_time):
	var anim_player: AnimationPlayer = $ReloadBar/AnimationPlayer
	anim_player.playback_speed = 1.0/reload_time
	anim_player.play("reload")
	
func update_health(health):
	if health < $HealthBar.value:
		$HealthBar/AnimationPlayer.play("health_shake")
	$HealthBar.value = health

func send_chat(message):
	var i_message = chat_message.instantiate()
	i_message.text = message
	$ChatContainer.add_child(i_message, true)
	await get_tree().create_timer(5).timeout
	i_message.queue_free()
	
	
	
	
