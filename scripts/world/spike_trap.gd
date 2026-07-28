extends Area3D
## Шипованная ловушка (Этап 4). Цикл: покой → телеграф (жёлтый) → активна (красный, урон).
## Визуал строится в коде (плита), урон — по всем телам в зоне в активной фазе.

@export var period: float = 2.6
@export var telegraph_time: float = 0.5
@export var active_time: float = 0.8
@export var damage_per_sec: float = 32.0

var _timer: float = 0.0
var _state: int = 0  # 0=покой, 1=телеграф, 2=активна
var _plate: MeshInstance3D
var _plate_mat: StandardMaterial3D

const COL_IDLE := Color(0.28, 0.24, 0.2)
const COL_TELE := Color(1.0, 0.78, 0.2)
const COL_ACT := Color(1.0, 0.16, 0.16)

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_plate = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.12, 1.6)
	_plate.mesh = box
	_plate.position = Vector3.ZERO
	_plate_mat = StandardMaterial3D.new()
	_plate_mat.albedo_color = COL_IDLE
	_plate_mat.emission_enabled = true
	_plate_mat.emission = COL_IDLE
	_plate_mat.emission_energy_multiplier = 0.4
	_plate.material_override = _plate_mat
	add_child(_plate)

func _physics_process(delta: float) -> void:
	_timer += delta
	match _state:
		0:
			_set_color(COL_IDLE, 0.4)
			if _timer >= period:
				_timer = 0.0
				_state = 1
		1:
			_set_color(COL_TELE, 1.6)
			if _timer >= telegraph_time:
				_timer = 0.0
				_state = 2
		2:
			_set_color(COL_ACT, 2.5)
			for b in get_overlapping_bodies():
				if b.has_method("take_damage"):
					b.take_damage(damage_per_sec * delta, global_position)
			if _timer >= active_time:
				_timer = 0.0
				_state = 0

func _set_color(c: Color, energy: float) -> void:
	if _plate_mat:
		_plate_mat.albedo_color = c
		_plate_mat.emission = c
		_plate_mat.emission_energy_multiplier = energy
