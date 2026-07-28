extends RigidBody3D
## Damageable — тестовая разрушаемая цель (бочка/ящик). Этап 2.
## Этап 3 заменит эти заглушки полноценными врагами-скелетами с AI.

@export var max_hp: float = 60.0
var hp: float = 60.0

var _spawn_pos: Vector3 = Vector3.ZERO
var _spawn_rot: Basis = Basis.IDENTITY
@onready var _meshes: Array = _collect_meshes(self)

const VFX: PackedScene = preload("res://scenes/world/vfx_burst.tscn")

func _ready() -> void:
	hp = max_hp
	_spawn_pos = global_position
	_spawn_rot = global_transform.basis

func take_damage(amount: float, source_pos: Vector3) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	_flash()
	_damage_number(amount)
	# Отбрасывание — умеренное (бочка откатывается и кувыркается, но не улетает в космос)
	var dir: Vector3 = global_position - source_pos
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		apply_central_impulse(dir * 3.5 + Vector3.UP * 1.1)
		apply_torque_impulse(Vector3(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)))

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Ограничение скорости, чтобы физика не «выстреливала» бочку
	if state.linear_velocity.length() > 14.0:
		state.linear_velocity = state.linear_velocity.normalized() * 14.0
	if hp <= 0.0:
		_die()

func _flash() -> void:
	var snap: Dictionary = {}
	for m in _meshes:
		snap[m] = m.material_override
		var f := StandardMaterial3D.new()
		f.albedo_color = Color.WHITE
		f.emission_enabled = true
		f.emission = Color.WHITE
		f.emission_energy_multiplier = 5.0
		m.material_override = f
	await get_tree().create_timer(0.07).timeout
	for m in _meshes:
		m.material_override = snap[m]

func _damage_number(amount: float) -> void:
	var l := Label3D.new()
	l.text = str(int(round(amount)))
	l.font_size = 56
	l.modulate = Color(1.0, 0.9, 0.35, 1.0)
	l.outline_modulate = Color(0, 0, 0, 1)
	l.outline_size = 8
	l.pixel_size = 0.012
	l.no_depth_test = true
	# Сначала в дерево, потом — глобальная позиция (иначе предупреждение !is_inside_tree)
	get_tree().current_scene.add_child(l)
	l.global_position = global_position + Vector3.UP * 1.6
	var tw := create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func _die() -> void:
	var v = VFX.instantiate()
	get_tree().current_scene.add_child(v)
	v.setup(global_position + Vector3.UP * 0.6, Color(0.8, 0.3, 1.0), 0.9)
	freeze = true
	visible = false
	await get_tree().create_timer(2.2).timeout
	hp = max_hp
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = Transform3D(_spawn_rot, _spawn_pos)
	freeze = false
	visible = true

func _collect_meshes(n: Node) -> Array:
	var a: Array = []
	if n is MeshInstance3D:
		a.append(n)
	for c in n.get_children():
		a += _collect_meshes(c)
	return a
