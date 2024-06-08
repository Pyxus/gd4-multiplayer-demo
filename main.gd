extends Node

@onready var _dc_menu: DirectConnectMenu = $DirectConnectMenu

func _ready() -> void:
	# NOTE:
	# This UI setup is just a personal preference.
	# I don't think UI should contain non-ui related state, or directl changes external state.
	# But you could just code this directly into your menu if you'd like.

	# SUMMARY: Update address/port/player_name when the UI values change
	_dc_menu.address_changed.connect(func(new_address: String)->void: Network.address = new_address)
	_dc_menu.port_changed.connect(func(port: int)->void:Network.port = port)
	_dc_menu.player_name_changed.connect(func(player_name: String)->void:Network.player_name = player_name)

	# SUMMARY: If a player hosts or joins a network, when the connection menu
	_dc_menu.host_selected.connect(func()->void: if Network.host_server() == OK: _dc_menu.hide())
	_dc_menu.join_selected.connect(func()->void: if Network.join_server() == OK: _dc_menu.hide())
	