extends Area3D
## Магический снаряд (болт). Этап 2.5: визуал из BinbunVFX (MagicProjectiles).
## Если ассет недоступен — запасной светящийся шар.

var _velocity := Vector3.ZERO
var _damage := 25.0
var _owner: Node = null
var _life := 3.0
var _vfx: Node = null

@onready var mesh: MeshInstance3D = $Mesh
@onready var light: OmniLight3D = $Light

const VFX := preload("res://scenes/world/vfx_burst.tscn")
const BINBUN_PROJ: PackedScene = preload("res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_basic/mprojectile_basic_vfx_01.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_load_visual()

func _load_visual() -> void:
	if BINBUN_PROJ != null:
		_vfx = BINBUN_PROJ.instantiate()
		_vfx.scale = Vector3(0.6, 0.6, 0.6)
		add_child(_vfx)
		if mesh:
			mesh.visible = false
		return
	# Запасной вариант — светящийся шар
	if mesh:
		mesh.material_override = load("res://materials/projectile_core.tres")

func setup(vel: Vector3, damage: float, owner_node: Node) -> void:
	_velocity = vel
	_damage = damage
	_owner = owner_node

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	# Ориентируем VFX: голова снаряда (на +X) смотрит по направлению полёта
	if _vfx != null and _velocity.length() > 0.1:
		var dir := _velocity.normalized()
		var up := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		var z_axis := dir.cross(up).normalized()
		var y_axis := z_axis.cross(dir).normalized()
		var t: Transform3D = _vfx.global_transform
		t.basis = Basis(dir, y_axis, z_axis)
		_vfx.global_transform = t
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
