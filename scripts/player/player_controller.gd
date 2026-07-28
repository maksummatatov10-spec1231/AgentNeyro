extends CharacterBody3D
## FPS-контроллер игрока. Этап 1: движение WASD, мышь, прыжок, спринт, присед.
## Бой/способности/анимации — следующие этапы.

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var crouch_speed: float = 2.2
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0025
@export var gravity_factor: float = 2.0
@export var acceleration: float = 12.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _pitch: float = 0.0
var _mouse_captured: bool = true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	capture_mouse()

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-88.0), deg_to_rad(88.0))
		head.rotation.x = _pitch
	elif event.is_action_pressed("pause"):
		if _mouse_captured:
			release_mouse()
		else:
			capture_mouse()

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y -= _gravity * gravity_factor * delta

	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var speed := walk_speed
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	elif Input.is_action_pressed("crouch"):
		speed = crouch_speed

	if input_dir.length() > 0.1:
		# Активный ввод — сразу целевая скорость (отзывчивое управление)
		var target := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized() * speed
		velocity.x = target.x
		velocity.z = target.z
	else:
		# Нет ввода — плавное торможение
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 6.0 * delta)

	move_and_slide()
