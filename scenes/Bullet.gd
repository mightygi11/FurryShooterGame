extends Node3D

var shooter
var shooter_id
var bullet_speed = 1
var timer = 0
var collided = false

	
# Called by the player to set values
func initialize(i_shooter, i_shooter_id, i_pos, i_rot, i_bullet_speed):
	set_multiplayer_authority(i_shooter_id)
	shooter = i_shooter
	shooter_id = i_shooter_id
	global_position = i_pos
	global_rotation = i_rot
	bullet_speed = i_bullet_speed
	global_translate(global_transform.basis.z * -1)

# Move and possibly delete the bullet
func _process(delta):
	if collided == true: # If collided and playing particle animation:
		if $Particles.emitting == false and $Hitmarker.emitting == false:
			queue_free()
		return
		
	timer += delta
	$BulletRay.target_position = Vector3(5,0,0) * delta * bullet_speed
	global_translate(global_transform.basis.z * -delta * bullet_speed)
	
	if timer > 3:
		queue_free()
		
	if $BulletRay.is_colliding():
		var collider = $BulletRay.get_collider()
		if collider.is_in_group("map") or collider.is_in_group("object"):
			position = $BulletRay.get_collision_point()
			global_transform = look_at_with_y(global_transform, $BulletRay.get_collision_normal(),Vector3.UP)
			$BulletMesh.visible = false
			$ImpactMesh/ImpactAnimator.play("bullet_impact")
			collided = true
			$Particles.restart()
		elif collider.is_in_group("player"):
			
			# only call ONCE, on the shooter's end, NOT the victims
			# liable to lag switches. if want to be thorough, send to
			# the server with position and double check that the server's
			# position of victim and shooter's pos of victim are close enough
			
			if shooter_id == multiplayer.get_unique_id():
				# get rid of bullet
				collided = true
				position = $BulletRay.get_collision_point()
				$BulletMesh.visible = false
				# give the shooter some hit feedback :)
				$Hitmarker.restart()
				$HitAudio.play()
				# call the damage method in player, ON THE VIC'S END ONLY
				collider.rpc_id(collider.get_multiplayer_authority(),"damage", shooter_id)
				
				
func look_at_with_y(trans,new_y,v_up):
	if new_y == Vector3(0,1,0) or new_y == Vector3(0,-1,0):
		trans.basis.x = Vector3(1,0,0)
		trans.basis.y = new_y
		trans.basis.z = Vector3(0,0,1)
		return trans
	#Y vector
	trans.basis.y=new_y
	trans.basis.z=v_up*-1
	trans.basis.x = trans.basis.z.cross(trans.basis.y).normalized();
	trans.basis.z = trans.basis.y.cross(trans.basis.x).normalized();
	trans.basis.x = trans.basis.x * -1
	return trans
	


