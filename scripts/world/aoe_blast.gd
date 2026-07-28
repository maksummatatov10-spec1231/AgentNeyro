extends Area3D
## Взрыв (AoE). Этап 2. Унитарная сфера масштабируется до радиуса.

var _radius: float = 4.0
var _damage: float = 60.0
var _owner: Node = null
var _applied: Array = []

@onready var mesh: MeshInstance3D = $Mesh

func setup(pos: Vector3, radius: float, damage: float, owner_node: Node) -> void:
	global_position = pos
	_radius = radius
	_damage = damage
	_owner = owner_node
	# Стартовый масштаб и плавное расширение
	scale = Vector3.ONE * 0.2
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * _radius, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Материал взрыва
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.45, 0.1, 0.7)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.4, 0.05)
	m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if mesh:
		mesh.material_override = m
	await get_tree().create_timer(0.55).timeout
	queue_free()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == _owner or body in _applied:
		return
	_applied.append(body)
	if body.has_method("take_damage"):
		var dist: float = global_position.distance_to((body as Node3D).global_position)
		var falloff: float = clamp(1.0 - dist / _radius, 0.3, 1.0)
		body.take_damage(_damage * falloff, global_position)
