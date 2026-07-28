extends CharacterBody3D
## Скелет-враг (Этап 3.1). Преследует игрока + ближний бой + анимации Rig_Medium.

@export var max_hp: float = 40.0
@export var speed: float = 2.8
@export var attack_range: float = 1.8
@export var attack_damage: float = 9.0
@export var attack_cd: float = 1.1

var hp: float = 40.0
var _dead: bool = false
var _atk_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: Node = null
var _anim: AnimationPlayer = null
var _moving: bool = false

const VFX := preload("res://scenes/world/vfx_burst.tscn")
const ANIM_GLB := [
	"res://assets/animations/rig_medium/Rig_Medium_MovementBasic.glb",
	"res://assets/animations/rig_medium/Rig_Medium_General.glb",
]

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	_setup_animation()
	EventBus.enemy_spawned.emit(self)

# ---------- анимация ----------
func _setup_animation() -> void:
	# Треки Rig_Medium имеют путь "Rig_Medium/Skeleton3D:bone" относительно
	# корня GLB. Поэтому root_node AnimationPlayer = РОДИТЕЛЬ узла "Rig_Medium".
	var rig = _find_node_by_name(self, "Rig_Medium")
	if rig == null:
		return
	var anim_root = rig.get_parent()
	_anim = AnimationPlayer.new()
	add_child(_anim)
	_anim.root_node = _anim.get_path_to(anim_root)
	# Собираем все анимации Rig_Medium в одну библиотеку "rig"
	var riglib := AnimationLibrary.new()
	for path in ANIM_GLB:
		if not ResourceLoader.exists(path):
			continue
		var scn = load(path)
		if scn == null:
			continue
		var inst = scn.instantiate()
		var src = _find_node_of_type(inst, "AnimationPlayer")
		if src != null:
			for libname in src.get_animation_library_list():
				var lib = src.get_animation_library(libname)
				for an in lib.get_animation_list():
					if an != "RESET" and not riglib.has_animation(an):
						riglib.add_animation(an, lib.get_animation(an))
		inst.queue_free()
	_anim.add_animation_library("rig", riglib)
	_play("Idle_A")

func _find_node_by_name(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var r = _find_node_by_name(c, nm)
		if r != null:
			return r
	return null

func _play(anim_name: String) -> void:
	if _anim == null or _dead:
		return
	var full := "rig/" + anim_name
	if _anim.has_animation(full) and _anim.current_animation != full:
		_anim.play(full)

func _find_node_of_type(n: Node, type_name: String) -> Node:
	if type_name == "Skeleton3D" and n is Skeleton3D:
		return n
	if type_name == "AnimationPlayer" and n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r = _find_node_of_type(c, type_name)
		if r != null:
			return r
	return null

# ---------- поведение ----------
func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if not is_on_floor():
		velocity.y -= _gravity * 2.0 * delta
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	_moving = false
	if dist > attack_range:
		var dir: Vector3 = to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(_player.global_position.x, global_position.y, _player.global_position.z), Vector3.UP)
		_moving = true
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_try_attack(delta)
	_play("Walking_A" if _moving else "Idle_A")
	move_and_slide()

func _try_attack(delta: float) -> void:
	_atk_timer -= delta
	if _atk_timer <= 0.0:
		_atk_timer = attack_cd
		if _player.has_method("take_damage"):
			_player.take_damage(attack_damage, global_position)

func take_damage(amount: float, _source_pos: Vector3) -> void:
	if _dead:
		return
	hp -= amount
	_flash()
	if hp <= 0.0:
		_die()
	else:
		_play("Hit_A")

func _flash() -> void:
	var meshes: Array = _collect(self)
	if meshes.is_empty():
		return
	var snap: Dictionary = {}
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color.WHITE
	flash_mat.emission_enabled = true
	flash_mat.emission = Color.WHITE
	flash_mat.emission_energy_multiplier = 6.0
	for m in meshes:
		snap[m] = m.material_override
		m.material_override = flash_mat
	await get_tree().create_timer(0.07).timeout
	for m in meshes:
		if is_instance_valid(m):
			m.material_override = snap[m]

func _die() -> void:
	_dead = true
	EventBus.enemy_died.emit(global_position)
	var v = VFX.instantiate()
	get_tree().current_scene.add_child(v)
	v.setup(global_position + Vector3.UP * 0.8, Color(0.8, 0.3, 1.0), 0.9)
	_play("Death_A")
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _collect(n: Node) -> Array:
	var a: Array = []
	if n is MeshInstance3D:
		a.append(n)
	for c in n.get_children():
		a += _collect(c)
	return a
