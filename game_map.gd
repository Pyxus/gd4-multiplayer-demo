class_name GameMap
extends Node2D

@onready var _player_spawner: MultiplayerSpawner = $PlayerSpawner

var _server: ServerScope = null

func _ready() -> void:
    Network.connected.connect(_on_Network_connected, CONNECT_ONE_SHOT)
    
    # TUTORIAL:
    # The purpose of the MultiplayerSpawner is to replicate scenes between clients.
    # There are 2 ways of 'registering' a scene to be replicated.
    # In both cases the reigstered scene will automatically be ADDED or REMOVED
    # When they are added or removed from the AUTHORITY (server by default).
    #
    # Method 1 (Auto Spawn):
    #   Add scene to "Auto Spawn List" in the inspector.
    #   Then when the scene is added with "add_child" like normal It will be replicated.
    #   Important!: 
    #       Use add_child(inst, true). Godot's High level multiplayer DEPENDS on node paths
    #       being the same across clients. Passing true for the second argument forces 
    #       a human readnable name.
    #
    #   Note: 
    #       The replicated scene will only contain default values.
    #       Any property set on the server WILL NOT automatically be synched.
    #       You'll need to sync them either with RPCs, a MultiplayerSynchronizer, 
    #       or on spawn with a custom spawn aka Method 2.
    #
    # Method 2 (Custom Spawn):
    #   This is the method I'm doing below. A custom spawner will allow you to send config
    #   data to replicated scenes on spawn.
    #   All you need to do is assign a callable of type `func(Variant) -> Node`
    #   to `spawner.spawn_function`.
    #   This spawn_function must be set on all clients which is why I declared it here and not
    #   in the server scope.
    _player_spawner.spawn_function = _spawn_player

func _on_Network_connected() -> void:
    # NOTE:
    # I had to fight a bug because originally this was in _ready().
    # Always make sure you save your `is_server()` checks for after
    # you know you're part of a network.
    # When you're offline this always returns true.
    if multiplayer.is_server():
        _server = ServerScope.new(self)

# TUTORIAL:
# For a synchronizer to work the server and client
# must be in agreement of who owns it.
# By default the server will own the player's synchronizer.
# Which at the moment is set to synchronize the player's `position`.
# If the server thinks it is the authority and the player attempts to update
# position the server essentially says "You're not allowed to do that".
# Simmarly if the server thinks a player has authority but the player thinks it does not
# you'll run into an error.
# Bottomline, the server is the source of truth and make sure your authorities line up.

# WARNING:
# This is supposed to be a simple demonstrate but there is a huge downside
# to giving a client authority to tell the server what to sync.
# In principle a player could modify their client and lie to the server.
# Is this were a racing game, for example, the player could tell the server
# there position is at the finish line.
# If security is a concern the server should control the synchronizer.
# Then the player should ONLY send inputs to the server, the server then decides where the player is
# and informs the player, not the other way around.
# This can have down-sides if there is latency, then you may need to look into things such as
# client-side prediction. However the bottom-line is the server should be the only source of truth,
# and never trust the client.
#
# However, in a setup where a player is the host the host could still get away with cheating.
# Though i'd argue this a non-issue outside of competitive games.
#
# Related, when sending info to a client consider asking "could the client use this to cheat".
# for example in my card game only the server knows the state of the deck.
# The server only shares the cards in a client's hand, and only to the client who owns that information.
# On the flip-side all clients know what's in the discard pile since that is public knowledge. 
func _spawn_player(config: Dictionary) -> Player:
    var player := Player.new_scene()
    player.set_multiplayer_authority(config.player_id)
    player.display_name = config.player_name
    return player

class ServerScope:
    var _client: GameMap = null

    func _init(client: GameMap) -> void:
        _client = client
        Network.notified_player_joined.connect(_on_Network_player_joined)
    
    func _on_Network_player_joined(player_id: int) -> void:
        # NOTE:
        # You can see my 'with_server' in action here.
        # If you like the ServerScope concept but aren't a fan of this.
        # You could opt to reference server variable directly:
        # Network.server.assign_player_obj(...)
        Network.with_server(
            func(it: Network.ServerScope)->void:
                # TUTORIAL:
                # To invoke the spawn_function set earlier you just have to call
                # the spawner's `spawn` function.
                # Do note spawn will automatically add the node to the scene.
                # It should not be done manually. You can also the config data is set here.
                # Reminder we only need to spawn on the server since the spawner
                # it self handles replicating to clients.
                
                # WARNING: `spawn` is networked. Arguments must be primivite Godot types.
                # This includes String, int, float, Array of primitives, Dictionary of primitives, etc. 
                var player: Player = _client._player_spawner.spawn({
                    player_id=player_id, 
                    player_name=it.get_player_name(player_id)
                })
                it.assign_player_obj(player_id, player)
        )
    