class_name DirectConnectMenu
extends PanelContainer

signal host_selected(player_name: String, port: int)
signal join_selected(player_name: String, address: String, port: int)
signal address_changed(new_address: String)
signal port_changed(new_port: int)
signal player_name_changed(new_player_name: String)

@onready var _player_name_edit: LineEdit = $%PlayerNameEdit
@onready var _address_edit: LineEdit = $%AddressEdit
@onready var _port_edit: LineEdit = $%PortEdit
@onready var _host_btn: Button = $%HostButton
@onready var _join_btn: Button = $%JoinButton

func _ready() -> void:
	_player_name_edit.text_changed.connect(
		func(new_text: String) -> void:
			player_name_changed.emit(new_text)
	)

	_address_edit.text_changed.connect(
		func(new_text: String) -> void:
			address_changed.emit(new_text)	
	)

	_port_edit.text_changed.connect(
		func(new_text: String) -> void:
			_port_edit.text = new_text
			port_changed.emit(int(new_text))	
	)

	_host_btn.pressed.connect(
		func() -> void: 
			host_selected.emit()
	)
	_join_btn.pressed.connect(
		func() -> void: 
			join_selected.emit()
	)
