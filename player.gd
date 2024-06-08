class_name Player
extends CharacterBody2D

# TUTORIAL:
# The `MultiplayerSynchronizer` automatically synchronizes EXPORTED values
# that have been registered in the inspector.
# There are 3 Replication options:
#	- Always: self-explanatory; Uses unrelaible transfer method.
#	- On Change: Whenever the value is changed; uses reliable transfer method.

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var display_name: String = ""

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _name_label: Label = $NameLabel

static func new_scene() -> Player:
	var scene: PackedScene = load("res://player.tscn")
	return scene.instantiate()

func _ready() -> void:
	# SUMMARY: Only thing of note in this script is that I disable process 
	# based on who has authority over this node.
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		set_physics_process(false)
	
	_name_label.text = display_name

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
