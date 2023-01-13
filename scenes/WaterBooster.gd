extends Area3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for player in get_overlapping_bodies():
		if player.is_in_group("player"):
			player.velocity += Vector3(0.5, 0, -0.5)
