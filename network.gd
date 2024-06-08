extends Node

signal connected()
signal notified_player_joined(peer_id: int)
signal notified_player_left(peer_id: int)

var player_name: String = "Batman"
var address: String = "127.0.0.1"
var port: int = 9999

var _server: ServerScope = null

func host_server() -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port)

	if err == OK:
		_server = ServerScope.new(self)

		# TUTORIAL:
		# All nodes in the tree have the same 'multiplayer' reference
		# Assigning a 'multiplayer_peer' to it essentially enables
		# networking for the entire tree.
		multiplayer.multiplayer_peer = peer

		# NOTE: 
		# This is Server space. The _server can never connect to it self so I manually call this.
		_on_Multiplayer_connected_to_server()
	
	return err

func join_server() -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)

	if err == OK:
		Network.multiplayer.multiplayer_peer = peer

		# NOTE: 
		# This is Client space. We must wait for the client to fully connect before we
		# try communicating with the _server.
		multiplayer.connected_to_server.connect(_on_Multiplayer_connected_to_server, CONNECT_ONE_SHOT)
	
	return err

# NOTE:
# This is a convention related to my server scope concept (Explained below).
# I personally just like making it painfully obvious when I'm accessing
# something that should only exist in server space.
func with_server(callback: Callable) -> void:
	if _server:
		callback.call(_server)

func _on_Multiplayer_connected_to_server() -> void:
	connected.emit()

	# TUTORIAL:
	# This is how RPC functions are invoked. 1 is ALWAYS the id of the _server.
	# This can be read as "call 'request_join_lobby' on the _server"
	request_join_lobby.rpc_id(1, player_name)

# TUTORIAL:
# RPC (Remote Procedure Call) can effectively be used to call a function on one machine from another.
# RPC abstracts away the details of interpreting packets representing it as a simple function call.

# TUTORIAL:
# RPCs have 3 main configurations, they essentially determine:
#
# Who can Remotely call this? 
#   - authority (who ever has authority; typically the _server but not always)
#   - any_peer (anyone)
# If called remotely can this run locally?
#   - call_remote (no)
#   - call_local (yes)
# How badly do you do you need this RPC?
#   - unreliable (I want it but it's not the end of the world if I never get it)
#   - unreliable_ordered (Whenever, but it needs to be in order. If something comes out of order ignore it)   
#   - reliable (This is mission critical, I really need this and it has to be in order.)

# NOTE:
# This is a personal convention where 'request' means it is called by the client and executed on the _server.
# Likewise 'notify' means it is called by the _server and executed on the client

# BREAKDOWN: In this example I use... 
# - 'any_peer' because I want to allow any client call this remotely.
# - 'call_local' because the _server is technically a client so I want it to be able to rpc it self.
# - 'reliable' because, in general, if something is not updating rapidly (like movement) you want to use reliable.
@rpc("any_peer", "call_local", "reliable")
func request_join_lobby(p_name: String) -> void:
	if _server:
		_server.request_join_lobby(p_name)

# BREAKDOWN: I use 'authority' because I only want the _server calling this remotely
# I don't actually use this in this demo but wanted to demonstrate.
@rpc("authority", "call_local", "reliable")
func notify_player_joined(peer_id: int) -> void:
	notified_player_joined.emit(peer_id)

# NOTE:
# This is setup purely a personal convention!
# I like to seperate the client from _server as much as possible
# Everything in ServerScope exists ONLY on the _server.
# Everything outside exists on both Client and Server.
# I only use scopes when I need to maintain server state.
# Otherwise I just use `if multiplayer.is_server()` blocks.
class ServerScope:
	const Network_T = preload("res://network.gd")

	var _client: Network_T
	var _player_by_id: Dictionary # Dictionary<peer_id: int, Player>
	var _name_by_id: Dictionary # Dictionary<peer_id: int, name: String>

	func _init(client: Network_T) -> void:
		_client = client
		_client.multiplayer.peer_disconnected.connect(_on_Multiplayer_peer_disconnected)
	
	func request_join_lobby(player_name: String) -> void:
		var sender_id := _client.multiplayer.get_remote_sender_id()
	
		if not _player_by_id.has(sender_id):
			_player_by_id[sender_id] = null
			_name_by_id[sender_id] = player_name
		
		# TUTORIAL:
		# '.rpc()' will call on all peers
		_client.notify_player_joined.rpc(sender_id)
	
	func assign_player_obj(player_id: int, player: Player) -> void:
		if _player_by_id.has(player_id) and _player_by_id[player_id] == null:
			_player_by_id[player_id] = player

	func get_player_name(player_id: int) -> String:
		return _name_by_id.get(player_id, "")

	func _on_Multiplayer_peer_disconnected(peer_id: int) -> void:
		if _player_by_id.has(peer_id):
			var player: Player = _player_by_id[peer_id]
			player.queue_free()
			_player_by_id.erase(peer_id)
			_name_by_id.erase(peer_id)
	
