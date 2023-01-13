extends Control

@onready var network_node = get_node("/root/Main/Network")
var player_scene = preload("res://scenes/player_full.tscn")
var username = "Player"
var usernames_list = {}

# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _ready():
	multiplayer.server_disconnected.connect(self.server_disconnect)

func _on_start_server_pressed():
	var network = ENetMultiplayerPeer.new()
	network.create_server(4242)
	
	multiplayer.peer_connected.connect(self.create_player) # CONNECTS A SIGNAL TO A FUNCTION!!!!!
	multiplayer.peer_disconnected.connect(self.delete_player)
	
	multiplayer.multiplayer_peer = network
	create_player(1)
	$StartServer.disabled = true
	$StartClient.disabled = true
	visible = false

func _on_start_client_pressed():
	var network = ENetMultiplayerPeer.new()
	network.create_client($IpEdit.text, 4242)
	multiplayer.multiplayer_peer = network
	$StartServer.disabled = true
	$StartClient.disabled = true
	visible = false
	
func create_player(id):
	print("Client connected: %s" % id)
	var p = player_scene.instantiate()
	p.name = str(id)
	p.get_node("Player").username = $NameEdit.text
	if multiplayer.get_unique_id() == 1:
		usernames_list[id] = $NameEdit.text
	network_node.add_child(p)
	rpc("mp_connect", id)
	
func delete_player(id):
	print("Deleting player %s" % id)
	rpc("mp_disconnect", id)
	if multiplayer.get_unique_id() == 1:
		usernames_list.erase(id)
	network_node.get_node(str(id)).queue_free()
	
	
@rpc(any_peer, call_local, reliable)
func set_username(id, un):
	usernames_list[id] = un
	rpc("update_usernames", usernames_list)	
	
@rpc(any_peer, call_local, reliable)
func update_usernames(i_usernames_list):
	usernames_list = i_usernames_list
	for un in usernames_list:
		var user = get_node("/root/Main/Network/%s/Player" % un)
		user.rpc("local_set_username", usernames_list[un])
		
func server_disconnect():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("/root/Main/AllMenus/Menu").visible = true
	get_node("/root/Main/AllMenus/Menu/StartServer").disabled = false
	get_node("/root/Main/AllMenus/Menu/StartClient").disabled = false
	
# FIX LATER!!!
# Cannot sync car nodes between players.
# Current workaround is it just finds the car node by its name
# Means no spawning new cars, or even having more than 1 until fixed
@rpc(any_peer, call_local, reliable)
func set_car_authority(car, id):
	car = get_node("/root/Main/Car") # Remove later and fix
	car.set_multiplayer_authority(id)
	print("Authority of %s is now %s" % [car, id])
	
@rpc(call_local, reliable)
func mp_disconnect(id):
	print("disconnected, " + str(id))
	var p = get_node("/root/Main/Network/%s/Player" % multiplayer.get_unique_id())
	var p2 = get_node("/root/Main/Network/%s/Player" % id)
	p.get_node("GUI").send_chat("%s is leaving." % p2.username)	
	
@rpc(call_local, reliable)
func mp_connect(id):
	print("connected, " + str(id))
	var p = get_node("/root/Main/Network/%s/Player" % multiplayer.get_unique_id())
	var p2 = get_node("/root/Main/Network/%s/Player" % id)
	p.get_node("GUI").send_chat("%s is joining." % p2.username)	

