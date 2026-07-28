extends CharacterBody3D
## Игрок (FPS). Этап 2: движение + ресурсы + способности + реакции урона.
## Способности: меч (лёгкий/тяжёлый), маг.болт, луч, AoE, исцеление, рывок.

# --- Движение ---
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var crouch_speed: float = 2.2
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0025
@export var gravity_factor: float = 2.0

# --- Ресурсы ---
@export var max_hp: float = 100.0
@export var max_mana: float = 100.0
@export var max_stamina: float = 100.0
@export var mana_regen: float = 9.0
@export var stamina_regen: float = 28.0
@export var hp_regen_delay: float = 5.0
@export var hp_regen: float = 5.0

# --- Способности (стоимость/КД/урон) ---
const BOLT_COST := 12.0
const BOLT_SPEED := 22.0
const BOLT_DMG := 25.0
const BEAM_COST_PER_SEC := 18.0
const BEAM_DMG_PER_SEC := 26.0
const BEAM_RANGE := 16.0
const AOE_COST := 35.0
const AOE_DMG := 60.0
const AOE_RADIUS := 4.0
const AOE_CD := 6.0
const HEAL_COST := 30.0
const HEAL_AMOUNT := 35.0
const HEAL_CD := 8.0
const DASH_COST := 15.0
const DASH_DIST := 6.0
const DASH_CD := 2.0
const LIGHT_DMG := 18.0
const HEAVY_DMG := 35.0

var hp: float = 100.0
var mana: float = 100.0
var stamina: float = 100.0

# Внутреннее состояние
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _pitch: float = 0.0
var _mouse_captured: bool = true
var _hp_regen_timer: float = 0.0
var _invuln: bool = false
var _invuln_t: float = 0.0
var _cd_aoe: float = 0.0
var _cd_heal: float = 0.0
var _cd_dash: float = 0.0
var _melee_active: bool = false
var _melee_hits: Array = []
var _beam_active: bool = false
var _shake: float = 0.0

# Ноды
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var melee_area: Area3D = $Head/MeleeArea
@onready var viewmodel: Node3D = $Head/ViewModel
@onready var beam_visual: MeshInstance3D = $Head/BeamVisual

const VFX_BURST: PackedScene = preload("res://scenes/world/vfx_burst.tscn")
const PROJECTILE: PackedScene = preload("res://scenes/world/projectile.tscn")
const AOE_BLAST: PackedScene = preload("res://scenes/world/aoe_blast.tscn")
# Качественные боевые VFX (BattleFX, Binbun3D, CC0)
const BFX_SWING: String = "res://assets/BinbunVFX_Vol2/BattleFX/effects/swing/vfx_blank_swing.tscn"
const BFX_SLASH: String = "res://assets/BinbunVFX_Vol2/BattleFX/effects/slash/vfx_blank_slash.tscn"

func _ready() -> void:
	hp = max_hp
	mana = max_mana
	stamina = max_stamina
	add_to_group("player")
	capture_mouse()
	melee_area.monitoring = false
	melee_area.body_entered.connect(_on_melee_body_entered)
	beam_visual.visible = false
	_load_viewmodel()
	_load_body()
	_emit_stats()

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false

# ---------------- ВВОД ----------------
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

func _process(delta: float) -> void:
	# Кулдауны
	_cd_aoe = max(0.0, _cd_aoe - delta)
	_cd_heal = max(0.0, _cd_heal - delta)
	_cd_dash = max(0.0, _cd_dash - delta)
	# Реген маны и выносливости
	mana = min(max_mana, mana + mana_regen * delta)
	stamina = min(max_stamina, stamina + stamina_regen * delta)
	# Реген HP после задержки без урона
	_hp_regen_timer = max(0.0, _hp_regen_timer - delta)
	if _hp_regen_timer <= 0.0 and hp < max_hp:
		hp = min(max_hp, hp + hp_regen * delta)
	# i-frames рывка
	if _invuln:
		_invuln_t -= delta
		if _invuln_t <= 0.0:
			_invuln = false
	# Тряска камеры
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 2.5)
		head.rotation = Vector3(_pitch + randf_range(-_shake, _shake), randf_range(-_shake, _shake) * 0.3, 0.0)
	else:
		head.rotation.x = _pitch
	# Способности
	_handle_abilities()
	_emit_stats()

func _handle_abilities() -> void:
	if Input.is_action_just_pressed("attack_light"):
		_melee_light()
	if Input.is_action_just_pressed("attack_heavy"):
		_melee_heavy()
	if Input.is_action_just_pressed("cast_bolt"):
		_cast_bolt()
	if Input.is_action_just_pressed("cast_aoe"):
		_cast_aoe()
	if Input.is_action_just_pressed("heal"):
		_heal()
	if Input.is_action_just_pressed("dash"):
		_dash()
	if Input.is_action_just_pressed("test_self_damage"):
		take_damage(18.0, global_position + Vector3.FORWARD)
	# Луч (удержание)
	var want_beam := Input.is_action_pressed("cast_beam")
	if want_beam and mana > 0.0:
		if not _beam_active:
			_beam_active = true
	elif not want_beam:
		_beam_active = false
		beam_visual.visible = false

# ---------------- ФИЗИКА ----------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_factor * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var speed := walk_speed
	if Input.is_action_pressed("sprint") and stamina > 0.0:
		speed = sprint_speed
		stamina = max(0.0, stamina - 20.0 * delta)
	elif Input.is_action_pressed("crouch"):
		speed = crouch_speed
	# Плавное (frame-rate независимое) ускорение/торможение по горизонтали
	var target := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized() * speed
	var smoothing: float = 1.0 - exp(-12.0 * delta)
	velocity.x = lerpf(velocity.x, target.x, smoothing)
	velocity.z = lerpf(velocity.z, target.z, smoothing)
	move_and_slide()
	# Толкаем RigidBody3D (например, бочки) при столкновении телом
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is RigidBody3D:
			var push_dir: Vector3 = -c.get_normal()
			(collider as RigidBody3D).apply_impulse(push_dir * 5.0, c.get_position() - collider.global_position)
	# Луч: трата маны + урон
	if _beam_active:
		_process_beam(delta)

# ---------------- СПОСОБНОСТИ ----------------
func _melee_light() -> void:
	_start_swing(LIGHT_DMG, "light")
	EventBus.ability_cast.emit("sword_light")

func _melee_heavy() -> void:
	if stamina < 25.0:
		return
	stamina -= 25.0
	_start_swing(HEAVY_DMG, "heavy")
	EventBus.ability_cast.emit("sword_heavy")

func _start_swing(dmg: float, kind: String) -> void:
	_melee_dmg = dmg
	_melee_kind = kind
	_melee_active = true
	_melee_hits.clear()
	melee_area.monitoring = true
	# Визуал замаха клинка
	_swing_viewmodel(kind)
	_spawn_battle_fx(BFX_SWING, melee_area.global_position, -head.global_transform.basis.z, 0.4, Color(1.0, 0.95, 0.6), 0.4)
	# Окно хита
	await get_tree().create_timer(0.18).timeout
	melee_area.monitoring = false
	await get_tree().create_timer(0.12).timeout
	_melee_active = false

var _melee_dmg: float = 0.0
var _melee_kind: String = "light"

func _on_melee_body_entered(body: Node) -> void:
	if not _melee_active or body in _melee_hits or body == self:
		return
	_melee_hits.append(body)
	if body.has_method("take_damage"):
		var hit_pos: Vector3 = (body as Node3D).global_position
		body.take_damage(_melee_dmg, head.global_position)
		_spawn_battle_fx(BFX_SLASH, hit_pos, head.global_position.direction_to(hit_pos), 0.45, Color(1.0, 0.95, 0.6), 0.6 if _melee_kind == "heavy" else 0.4)
		_shake = max(_shake, 0.025 if _melee_kind == "light" else 0.06)

func _cast_bolt() -> void:
	if not _can_cast(BOLT_COST):
		return
	mana -= BOLT_COST
	var p = PROJECTILE.instantiate()
	var root := get_tree().current_scene
	root.add_child(p)
	p.global_position = head.global_position + head.global_transform.basis.z * -0.6
	p.setup(-head.global_transform.basis.z * BOLT_SPEED, BOLT_DMG, self)
	EventBus.ability_cast.emit("magic_bolt")

func _process_beam(delta: float) -> void:
	var cost := BEAM_COST_PER_SEC * delta
	if mana < cost:
		_beam_active = false
		beam_visual.visible = false
		return
	mana -= cost
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * BEAM_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var end_pos := to
	if hit and hit.has("position"):
		end_pos = hit["position"]
		var col = hit.get("collider")
		if col and col.has_method("take_damage"):
			col.take_damage(BEAM_DMG_PER_SEC * delta, from)
	# Визуал луча
	var mid := (from + end_pos) * 0.5
	var dist := from.distance_to(end_pos)
	beam_visual.global_position = mid
	beam_visual.look_at(end_pos)
	beam_visual.scale.z = dist
	beam_visual.visible = true

func _cast_aoe() -> void:
	if _cd_aoe > 0.0 or not _can_cast(AOE_COST):
		return
	mana -= AOE_COST
	_cd_aoe = AOE_CD
	var target := _aim_point(AOE_RADIUS * 0.9 + 6.0)
	var blast = AOE_BLAST.instantiate()
	get_tree().current_scene.add_child(blast)
	blast.setup(target, AOE_RADIUS, AOE_DMG, self)
	_spawn_vfx(target, Color(1.0, 0.45, 0.1), 1.0)
	_shake = max(_shake, 0.08)
	EventBus.ability_cast.emit("fireball_aoe")

func _heal() -> void:
	if _cd_heal > 0.0 or not _can_cast(HEAL_COST) or hp >= max_hp:
		return
	mana -= HEAL_COST
	_cd_heal = HEAL_CD
	hp = min(max_hp, hp + HEAL_AMOUNT)
	_spawn_vfx(global_position + Vector3.UP * 1.0, Color(0.3, 1.0, 0.4), 0.8)
	EventBus.player_healed.emit(HEAL_AMOUNT)
	EventBus.ability_cast.emit("heal")

func _dash() -> void:
	if _cd_dash > 0.0 or not _can_cast(DASH_COST):
		return
	mana -= DASH_COST
	_cd_dash = DASH_CD
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir: Vector3
	if input_dir.length() > 0.1:
		dir = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	else:
		dir = -global_transform.basis.z
	# Безопасный телепорт с проверкой столкновения
	var dest := global_position + dir * DASH_DIST
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, dest + Vector3.UP, 0xFFFFFFFF, [self])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.has("position"):
		dest = hit["position"] - dir * 0.6
	global_position = dest
	_invuln = true
	_invuln_t = 0.25
	_spawn_vfx(global_position, Color(0.5, 0.7, 1.0), 0.4)
	EventBus.ability_cast.emit("dash")

# ---------------- УРОН ИГРОКА ----------------
func take_damage(amount: float, _source_pos: Vector3) -> void:
	if _invuln or hp <= 0.0:
		return
	hp = max(0.0, hp - amount)
	_hp_regen_timer = hp_regen_delay
	_shake = max(_shake, 0.04 + amount * 0.003)
	EventBus.player_hurt.emit(amount)
	_spawn_vfx(head.global_position, Color(1.0, 0.2, 0.2), 0.4)
	if hp <= 0.0:
		EventBus.player_died.emit()

# ---------------- ХЕЛПЕРЫ ----------------
func _can_cast(cost: float) -> bool:
	return mana >= cost

func _aim_point(max_dist: float) -> Vector3:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.has("position"):
		return hit["position"]
	return to

func _spawn_vfx(pos: Vector3, color: Color, scale_amt: float) -> void:
	var v = VFX_BURST.instantiate()
	get_tree().current_scene.add_child(v)
	v.setup(pos, color, scale_amt)

# Качественный боевой эффект (BattleFX) с запасным вариантом (vfx_burst)
func _spawn_battle_fx(path: String, pos: Vector3, face: Vector3, lifetime: float, fb_color: Color, fb_scale: float) -> void:
	var node: Node = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res != null:
			node = res.instantiate()
	if node != null:
		get_tree().current_scene.add_child(node)
		node.global_position = pos
		if face.length() > 0.01:
			node.global_transform.basis = Basis.looking_at(face.normalized(), Vector3.UP)
		get_tree().create_timer(lifetime).timeout.connect(node.queue_free)
	else:
		_spawn_vfx(pos, fb_color, fb_scale)

func _emit_stats() -> void:
	EventBus.player_hp_changed.emit(hp, max_hp)
	EventBus.player_mana_changed.emit(mana, max_mana)
	EventBus.player_stamina_changed.emit(stamina, max_stamina)

# ---------------- VIEWMODEL ----------------
func _load_body() -> void:
	# Видимое тело персонажа (видно при взгляде вниз) + отбрасывает тень.
	var path := "res://assets/characters/adventurers/Knight.glb"
	if not ResourceLoader.exists(path):
		return
	var res = load(path)
	if res == null:
		return
	var body = res.instantiate()
	add_child(body)
	# Гарантируем, что меши тела отбрасывают тень
	_ensure_shadow(body)

func _ensure_shadow(n: Node) -> void:
	if n is MeshInstance3D:
		# cast_shadow: 1 = ON (рендер + тень). Числом, чтобы не зависеть от имени enum.
		(n as MeshInstance3D).cast_shadow = 1
	for c in n.get_children():
		_ensure_shadow(c)

func _load_viewmodel() -> void:
	var path := "res://assets/props/sword_1handed.fbx"
	# Ассета может не быть на месте — пробуем загрузить безопасно
	if not ResourceLoader.exists(path):
		# попытаемся найти меч среди пропов/ассетов
		path = _find_first_fbx("sword")
	if path.is_empty():
		return
	var res = load(path)
	if res == null:
		return
	var inst = res.instantiate()
	viewmodel.add_child(inst)
	_apply_mat(inst)
	viewmodel.position = Vector3(0.36, -0.42, -0.72)
	viewmodel.rotation = Vector3(deg_to_rad(-22), deg_to_rad(34), deg_to_rad(16))
	viewmodel.scale = Vector3(0.7, 0.7, 0.7)

func _apply_mat(n: Node) -> void:
	if n is MeshInstance3D:
		n.material_override = load("res://materials/viewmodel_sword.tres")
	for c in n.get_children():
		_apply_mat(c)

func _find_first_fbx(prefix: String) -> String:
	for d in ["res://assets/props", "res://assets/models/dungeon"]:
		var dir := DirAccess.open(d)
		if dir:
			dir.list_dir_begin()
			var fn := dir.get_next()
			while fn != "":
				if fn.to_lower().ends_with(".fbx") and fn.to_lower().begins_with(prefix):
					dir.list_dir_end()
					return d + "/" + fn
				fn = dir.get_next()
			dir.list_dir_end()
	return ""

func _swing_viewmodel(kind: String) -> void:
	if viewmodel == null:
		return
	var base_rot := Vector3(deg_to_rad(-22), deg_to_rad(34), deg_to_rad(16))
	var peak := base_rot + Vector3(deg_to_rad(-80), deg_to_rad(12), deg_to_rad(-20))
	var dur := 0.14 if kind == "light" else 0.22
	var tw := create_tween()
	tw.tween_property(viewmodel, "rotation", peak, dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(viewmodel, "rotation", base_rot, dur).set_ease(Tween.EASE_IN)
