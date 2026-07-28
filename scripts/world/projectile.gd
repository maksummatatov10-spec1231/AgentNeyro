extends Area3D
## Магический снаряд (болт). Этап 2.

var _velocity := Vector3.ZERO
var _damage := 25.0
var _owner: Node = null
var _life := 3.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var light: OmniLight3D = $Light

const VFX: PackedScene = preload("res://scenes/world/vfx_burst.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if mesh:
		mesh.material_override = load("res://materials/projectile_core.tres")

func setup(vel: Vector3, damage: float, owner_node: Node) -> void:
	_velocity = vel
	_damage = damage
	_owner = owner_node
	# Лёгкое самонаведение «взглядом» уже задано направлением камеры при спавне.

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, global_position)
	_burst()

func _burst() -> void:
	var v = VFX.instantiate()
	get_tree().current_scene.add_child(v)
	v.setup(global_position, Color(0.4, 0.65, 1.0), 0.55)
	queue_free()
