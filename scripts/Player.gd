extends CharacterBody3D

@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var bullet_sink = self.get_parent().get_parent()
@onready var camera = $POVCamera
@onready var reload_bar
@onready var bullet_counter = $GUI/BulletCounter
@onready var network = get_node("/root/Main/Network")
@onready var spawnpoints = get_node("/root/Main/World/SpawnpointList")
@onready var animator: AnimationTree = get_node("Character/AnimationTree")
@onready var weapon_mesh: MeshInstance3D = $Character/Armature/Skeleton3D/BoneAttachment3D/Pistol

@export var p_x_multi: float = 1
@export var p_x_add: float = 0
@export var p_y_multi: float = 1
@export var p_y_add: float = 0
@export var p_z_multi: float = 1
@export var p_z_add: float = 0

var footstep_vol_mod = 20

@export var bullet_speed = 10
@export var username: String:
	set(value):
		username = value
		$Username.text = value
		
@export var sync_velocity: Vector3 = Vector3(0,0,0)
@export var sync_position: Vector3 = Vector3(0,0,0)
var last_position: Vector3 = Vector3(0,0,0)

@export var max_health: int = 5
@export var SPEED = 5.0

const JUMP_VELOCITY = 7

var footstep_cooldown = 0
var weapon = Weapon.new()
var reloading = false
var health = max_health
var jumping = true
var paused = false
var current_vehicle: RigidBody3D = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

class Weapon:
	var damage #Damage the weapon deals
	var mag_size #Bullets the weapon can hold
	var mag_loaded #Bullets currently in the weapon
	var reload_time #Time to reload in seconds
	func _init():
		damage = 10
		mag_size = 5
		mag_loaded = mag_size
		reload_time = 2

func send_chat(msg):
	get_node("/root/Main/Network/%s/Player/GUI" % multiplayer.get_unique_id()).send_chat(msg)

func get_user_from_id(id):
	return get_node("/root/Main/Network/%s/Player" % id).username
	
# tell server to update username
func set_username(un):
	var menu = get_node("/root/Main/AllMenus/Menu")
	menu.rpc_id(1, "server_set_username", multiplayer.get_unique_id(), un)
	
# update username locally
@rpc(any_peer, call_local, reliable)
func local_set_username(un):
	username = un
	
# Jump animation function for mp anim syncing
@rpc(call_local, reliable)
func set_jumping(b: bool):
	jumping = b
	if b == true:
		animator["parameters/MovingJumping/blend_amount"] = 1
		animator["parameters/JumpProcess/active"] = true
	else:
		animator["parameters/MovingJumping/blend_amount"] = 0
		animator["parameters/LandShot/active"] = true
		
@rpc(call_local, reliable)
func set_look_vert(look: float):
	animator["parameters/LookUpDownAnim/blend_position"] = look

func is_local_authority() -> bool:
	return get_parent().get_multiplayer_authority() == multiplayer.get_unique_id()

# Sets up most of the multiplayer stuff, and the UI
func _enter_tree():
	# networking
	get_parent().set_multiplayer_authority(get_parent().name.to_int())
	
	print("readying player. authority: %s, current id: %s" % [get_multiplayer_authority(), multiplayer.get_unique_id()])
	if is_local_authority():
		$GUI.visible = true
		var char_mesh: MeshInstance3D = $Character/Armature/Skeleton3D/Character
		char_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		var gun_meshes: BoneAttachment3D = $Character/Armature/Skeleton3D/BoneAttachment3D
		gun_meshes.get_node("MPDisplayPistol").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		gun_meshes.get_node("Pistol").visible = true
		footstep_vol_mod = 0
		collision_layer += 1
		$POVCamera.current = true
		$GUI/BulletCounter.text = str(weapon.mag_loaded)
		reload_bar = $GUI/ReloadBar
					
	if get_multiplayer_authority() != 1:
		username = get_node("/root/Main/AllMenus/Menu/NameEdit").text
		
# Helps set up the usernames, spawns in.
func _ready():
	velocity = Vector3(0,0,0)
	if is_local_authority():
		var menu = get_node("/root/Main/AllMenus/Menu")
		menu.rpc_id(1, "set_username", multiplayer.get_unique_id(), menu.get_node("NameEdit").text)
		
		# Spawning in
		var spawn = spawnpoints.get_child(randi_range(0, spawnpoints.get_child_count()-1))
		global_position = spawn.global_position
			
# Character movement, animation, a lot of stuff happens here.
func _process(delta):
	
	if !is_local_authority():
		if current_vehicle != null:
			position = current_vehicle.position + Vector3(0, 0, 0)
		else:
			velocity = sync_velocity
			position = sync_position
			
			animator["parameters/MovementDirection/blend_position"].x = sync_velocity.z
			animator["parameters/MovementDirection/blend_position"].y = sync_velocity.x
			animator["parameters/Lean/blend_position"].x = sync_velocity.z
			animator["parameters/Lean/blend_position"].y = sync_velocity.x
			# If using sync variables:
			# - Set the current position and such to the sync variable
			# - NOT move_and_slide()
			# - NOT update the sync variables to keep syncing with others
			return
		
	# Respawn if too low
	if global_position.y < -2:
		rpc("die", multiplayer.get_unique_id())
		
	# Car controls
	if current_vehicle != null:
		position = current_vehicle.position + Vector3(0, 0, 0)

		if !paused:
			current_vehicle.do_car_input(Input.get_vector("move_backward", "move_forward", "move_left", "move_right"), delta)
		return
		
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * 2 * delta

	# Handle jump if unpaused
	if Input.is_action_just_pressed("jump") and is_on_floor() and !paused:
		velocity.y = JUMP_VELOCITY
		rpc("set_jumping", true)
	
	# Get the input direction and handle the movement if unpaused
	if !paused:
		var input_dir = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
		if direction.length() > 1:
			direction = direction.normalized()
		if direction:
			velocity.x += direction.x * SPEED * 0.08
			velocity.z += direction.z * SPEED * 0.08
	velocity.x *= 0.95
	velocity.z *= 0.95

	move_and_slide()
	
	# Set extra animation parameters
	
	if jumping == true and is_on_floor():
		rpc("set_jumping", false)
	
	var anim_velocity = Vector3(velocity.x, 0, velocity.z).rotated(Vector3.UP, -rotation.y) * 0.15
	if anim_velocity.length() > 1:
		anim_velocity = anim_velocity.normalized()
		
	# Update pos and velocity on clients
	sync_velocity = anim_velocity
	sync_position = position
	
	animator["parameters/MovementDirection/blend_position"].x = anim_velocity.z
	animator["parameters/MovementDirection/blend_position"].y = anim_velocity.x
	animator["parameters/Lean/blend_position"].x = anim_velocity.z
	animator["parameters/Lean/blend_position"].y = anim_velocity.x
	
	rpc("set_look_vert", camera.pitch)
	weapon_mesh.position.x = p_x_add + camera.pitch * p_x_multi
	weapon_mesh.position.y = p_y_add + camera.pitch * p_y_multi
	weapon_mesh.position.z = p_z_add + camera.pitch * p_z_multi
	
	#Footstep noises, play on all clients
	footstep_cooldown += delta * velocity.length()
	if is_on_floor() and footstep_cooldown > 1.75:
		print("Footstep + " + str(velocity.length()))
		footstep_cooldown = 0
		rpc("audio_footstep", velocity.length())
	
	

	
func _input(event):
	if !is_local_authority():
		return
		# Pause game. Hide gui, show pause menu, stop accepting input
	if event.is_action_pressed("pause"):
		$PauseMenu.visible = $GUI.visible
		$GUI.visible = !$GUI.visible
		paused = $PauseMenu.visible
		if paused:
			camera.mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			camera.mouse_captured = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if paused:
		return
	if event.is_action_pressed("shoot"):
		if reloading:
			return
		if weapon.mag_loaded > 0:
			rpc("shoot", camera.global_position, camera.global_rotation)
			weapon.mag_loaded -= 1
			bullet_counter.text = str(weapon.mag_loaded)
		else:
			rpc("reload")
	elif event.is_action_pressed("reload"):
		if weapon.mag_loaded != weapon.mag_size:
			rpc("reload")
	if event.is_action_pressed("control_vehicle"):
		if current_vehicle != null:
			
			current_vehicle.rpc("set_rider", null)
			collision_layer += 1
		else:
			print("trying to get in vehicle...")
			var bodies = $VehicleArea.get_overlapping_bodies()
			if len(bodies) != 0:
				var car = bodies[0]
				print(car)
				print(car.get_groups())
				if car.is_in_group("car"):
					collision_layer -= 1
					car.rpc("set_rider", multiplayer.get_unique_id())
					print("getting in vehicle %s" % current_vehicle)
					
	elif event.is_action_pressed("DEBUG_remove_player"):
		multiplayer.multiplayer_peer = null
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_node("/root/Main/AllMenus/Menu").visible = true
		get_node("/root/Main/AllMenus/Menu/StartServer").disabled = false
		get_node("/root/Main/AllMenus/Menu/StartClient").disabled = false
		get_parent().queue_free()
		
		
	
		
@rpc(any_peer, call_local, reliable)
func shoot(i_location, i_rotation):
	#Instantiate the bullet and decrease bullets in gun
	var i_bullet = bullet_scene.instantiate()
	get_node("/root/Main/Network").add_child(i_bullet, true)
	i_bullet.initialize(self, get_multiplayer_authority(), i_location, i_rotation, bullet_speed)
	
	#Animations and sound
	animator["parameters/FireSeek/seek_position"] = 0
	animator["parameters/FireShot/active"] = true
	
	$GunshotAudio.play()
	
@rpc(any_peer, call_local, reliable)
#Only called if this is the client
func damage(shooter_id):
	health -= 1
	$GUI.update_health(health)
	if health <= 0:
		rpc("die", shooter_id)
		
@rpc(any_peer, call_local, reliable)
#Called on all
func die(shooter_id):
	print("%s died! They were shot by %s." % [username, get_user_from_id(shooter_id)])
	get_node("/root/Main/Network/%s/Player/GUI" % multiplayer.get_unique_id()).send_chat("%s died! They were shot by %s." % [username, get_user_from_id(shooter_id)])
	if current_vehicle != null:
		current_vehicle.rpc("set_rider", null)
	respawn()	

func respawn():
	print("%s is respawning..." % username)
	get_node("/root/Main/Network/%s/Player/GUI" % multiplayer.get_unique_id()).send_chat("%s is respawning..." % username)
	var spawn = spawnpoints.get_child(randi_range(0, spawnpoints.get_child_count()-1))
	global_position = spawn.global_position
	velocity = Vector3(0,0,0)
	health = max_health
	$GUI.update_health(max_health)
	reload()
	
@rpc(call_local, reliable)
func reload():
	reloading = true
	animator["parameters/ReloadShot/active"] = true
	animator["parameters/FireShot/active"] = false
	$ReloadAudio.play()
	$GUI.reload_anim(weapon.reload_time)
	await $GUI/ReloadBar/AnimationPlayer.animation_finished
	weapon.mag_loaded = weapon.mag_size
	bullet_counter.text = str(weapon.mag_loaded)
	reloading = false
	
@rpc(call_local, reliable)
func audio_footstep(volume):
	$FootstepAudio.volume_db = (volume * 3 - 55) + footstep_vol_mod * 100
	$FootstepAudio.play()

