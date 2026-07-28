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
const BINBUN_PROJ := "res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_basic/mprojectile_basic_vfx_01.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_load_visual()

func _load_visual() -> void:
	if ResourceLoader.exists(BINBUN_PROJ):
		var res = load(BINBUN_PROJ)
		if res != null:
			_vfx = res.instantiate()
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
	# Ориентируем VFX по направлению полёта
	if _vfx != null and _velocity.length() > 0.1:
		var t := _vfx.global_transform
		t.basis = Basis.looking_at(_velocity.normalized(), Vector3.UP)
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
