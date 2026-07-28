extends Node3D
## Универсальная VFX-вспышка: расширяющаяся сфера + угасающий свет.
## Используется для попаданий, взрывов, хила, рывка (разный цвет/масштаб).

@export var color: Color = Color(1, 1, 1, 1)

var _duration: float = 0.4
var _max_scale: float = 1.0
var _time: float = 0.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var light: OmniLight3D = $Light

func setup(pos: Vector3, col: Color, scale_amt: float) -> void:
	global_position = pos
	color = col
	_max_scale = scale_amt
	_build_material()

func _build_material() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if mesh:
		mesh.material_override = m

func _process(delta: float) -> void:
	_time += delta
	var k: float = clamp(_time / _duration, 0.0, 1.0)
	if mesh:
		mesh.scale = Vector3.ONE * _max_scale * (0.4 + k * 1.8)
		var m = mesh.material_override
		if m:
			m.albedo_color.a = 1.0 - k
	if light:
		light.light_color = color
		light.light_energy = lerpf(4.0 * _max_scale, 0.0, k)
	if _time >= _duration:
		queue_free()
