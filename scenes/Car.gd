extends VehicleBody3D

@export var acceleration = 50
@export var turning = 30
#Set rider with an ID. If it's a valid rider swap:
#  network authority gets changed to server or the rider
#  rider gets set to the actual player node
#  rider's "current_vehicle" gets changed to self
var rider = null:
	set(value):
		print("setting vehicle owner, value = %s" % value)
		#Set network authority
		if value == null:
			steering = 0
			engine_force = 0
			get_node("/root/Main/AllMenus/Menu").rpc("set_car_authority", self, 1)
			if rider:
				rider.current_vehicle = null
				rider.global_position += Vector3(0, 1.5, 0)
				rider = null
		elif rider == null:
			get_node("/root/Main/AllMenus/Menu").rpc("set_car_authority", self, value)
			rider = get_node("/root/Main/Network/%s/Player" % value)
			rider.current_vehicle = self
		
			
		if value == multiplayer.get_unique_id():
			freeze = false
		else:
			if value == null and multiplayer.get_unique_id() == 1:
				freeze = false
			else:
				freeze = true

var max_rpm = 500
var max_torque = 200

func do_car_input(inputs, delta):
	steering = lerp(-inputs.y * 0.7, steering, 0.95)
	engine_force = -inputs.x * 1000
#	var acceleration = inputs.x * 0.2
#	for wheel in [$BRWheel, $BLWheel]:
#		var rpm = wheel.get_rpm()
#		wheel.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
		
	
#	var direction = (transform.basis * Vector3(inputs.x, 0, 0))
#	apply_central_force(Vector3(direction.x, 0, direction.z) * acceleration * delta * 144)
#	apply_torque(Vector3(0, -inputs.y, 0) * turning * direction.length() * delta * 144)
#
	
	
@rpc(any_peer, call_local, reliable)
func set_rider(id):
	rider = id
# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		return
	if linear_velocity.length() > 20:
		linear_velocity /= linear_velocity.length() / 20
	if global_position.y < -2:
		rpc("set_rider", null)
		global_position = Vector3(0, 10, 0)
	# rpc("sync_transform", global_position, global_rotation)


