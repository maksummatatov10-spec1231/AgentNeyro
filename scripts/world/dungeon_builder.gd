extends Node3D
## Строитель тестового данжа (Этап 1).
## ВСЕГДА создаёт гарантированный пол + периметр коллизии (плоскость из примитивов),
## а сверху по возможности выкладывает реальные FBX-тайлы KayKit + свет/декор.
## Если ассеты не импортировались — игра всё равно запустится и будет играбельна.

const DUNGEON_DIR := "res://assets/models/dungeon"
const TILE := 2.0            # шаг сетки тайлов (м)
const HALL_RADIUS := 5       # тайлов в каждую сторону от центра

var floor_tiles: Array = []
var wall_tiles: Array = []
var column_tiles: Array = []
var torch_tiles: Array = []
var prop_tiles: Array = []

@onready var material: StandardMaterial3D = load("res://materials/dungeon_material.tres")

func _ready() -> void:
	_scan_assets()
	_build_guaranteed_floor()
	_build_guaranteed_walls()
	_build_floor_tiles()
	_build_wall_ring()
	_build_columns()
	_build_torches()
	_scatter_props()
	_spawn_dummies()
	_spawn_enemies()
	_spawn_traps()
	_spawn_exit()
	GameManager.set_state(GameManager.GameState.PLAYING)
	EventBus.level_loaded.emit()
	print("EMBERFALL: данж построен. пол=%d стен=%d колон=%d факел=%d декор=%d" %
		[floor_tiles.size(), wall_tiles.size(), column_tiles.size(), torch_tiles.size(), prop_tiles.size()])

# ---------- сканирование доступных ассетов ----------
func _scan_assets() -> void:
	var dir := DirAccess.open(DUNGEON_DIR)
	if dir == null:
		push_warning("DungeonBuilder: папка ассетов не найдена — будет только базовый пол.")
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.to_lower().ends_with(".fbx"):
			var tile_name := fname.get_basename().to_lower()
			var path := DUNGEON_DIR + "/" + fname
			if tile_name.begins_with("floor"):
				floor_tiles.append(path)
			elif tile_name.begins_with("wall"):
				wall_tiles.append(path)
			elif tile_name.begins_with("column") or tile_name.begins_with("pillar"):
				column_tiles.append(path)
			elif tile_name.begins_with("torch"):
				torch_tiles.append(path)
			elif tile_name.begins_with("barrel") or tile_name.begins_with("box") or tile_name.begins_with("crate") \
				or tile_name.begins_with("banner") or tile_name.begins_with("chest") or tile_name.begins_with("barrier") \
				or tile_name.begins_with("rubble"):
				prop_tiles.append(path)
		fname = dir.get_next()
	dir.list_dir_end()

# ---------- ГАРАНТИРОВАННАЯ геометрия (примитивы) ----------
func _build_guaranteed_floor() -> void:
	var size := (HALL_RADIUS * 2 + 1) * TILE
	# Только коллизия пола (один сплошной бокс). Визуальный пол — из соединённых
	# FBX-тайлов (см. _build_floor_tiles), без дублирующей плоскости → нет мерцания.
	var body := StaticBody3D.new()
	add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 1.0, size)
	col.shape = box
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)

func _build_guaranteed_walls() -> void:
	var span := (HALL_RADIUS * 2 + 1) * TILE
	var half := span * 0.5
	var h := 4.0
	var thickness := 1.0
	# 4 стены по периметру
	_add_perimeter_wall(Vector3(0, h * 0.5, -half), Vector3(span, h, thickness))
	_add_perimeter_wall(Vector3(0, h * 0.5, half), Vector3(span, h, thickness))
	_add_perimeter_wall(Vector3(-half, h * 0.5, 0), Vector3(thickness, h, span))
	_add_perimeter_wall(Vector3(half, h * 0.5, 0), Vector3(thickness, h, span))

func _add_perimeter_wall(pos: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	col.shape = box
	body.add_child(col)
	# Визуал
	var mi := MeshInstance3D.new()
	var boxmesh := BoxMesh.new()
	boxmesh.size = box_size
	mi.mesh = boxmesh
	mi.material_override = material
	body.add_child(mi)

# ---------- реальные FBX-тайлы (с защитой) ----------
func _apply_material_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = material
	for c in node.get_children():
		_apply_material_recursive(c)

func _place(path: String, pos: Vector3, rot_y: float = 0.0, sc: float = 1.0, make_collision: bool = false) -> Node:
	if path.is_empty():
		return null
	var res = load(path)
	if res == null:
		push_warning("DungeonBuilder: не удалось загрузить %s" % path)
		return null
	var inst = res.instantiate()
	inst.position = pos
	inst.rotation.y = rot_y
	if sc != 1.0:
		inst.scale = Vector3.ONE * sc
	add_child(inst)
	_apply_material_recursive(inst)
	if make_collision:
		_add_collision(inst)
	return inst

# Качественная коллизия: OBB-бокс по ЛОКАЛЬНОМУ AABB объекта, дочерний к тайлу
# → вращается вместе с объектом (не раздувается вокруг повёрнутых стен).
# Бокс-формы быстрые и надёжные → без лагов.
func _add_collision(tile_root: Node) -> void:
	var aabb := _local_aabb(tile_root)
	if aabb.size.length() < 0.05:
		return
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	col.shape = box
	col.position = aabb.get_center()
	body.add_child(col)
	tile_root.add_child(body)

func _local_aabb(node: Node) -> AABB:
	var result := AABB()
	var found := false
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			result = mi.get_aabb()
			found = true
	for c in node.get_children():
		var ca := _local_aabb(c)
		if ca.size.length() > 0.001:
			if not found:
				result = ca
				found = true
			else:
				result = result.merge(ca)
	return result

func _rand_from(arr: Array) -> String:
	if arr.is_empty():
		return ""
	return arr[randi() % arr.size()]

func _build_floor_tiles() -> void:
	if floor_tiles.is_empty():
		return
	for x in range(-HALL_RADIUS, HALL_RADIUS + 1):
		for z in range(-HALL_RADIUS, HALL_RADIUS + 1):
			var p := _rand_from(floor_tiles)
			_place(p, Vector3(x * TILE, 0.0, z * TILE), randf() * PI * 0.5)

func _build_wall_ring() -> void:
	var pref := ""
	for w in wall_tiles:
		if w.get_file().get_basename().to_lower() == "wall":
			pref = w
			break
	if pref == "" and not wall_tiles.is_empty():
		pref = wall_tiles[0]
	if pref == "":
		return
	var span := HALL_RADIUS
	for i in range(-span, span + 1):
		_place(pref, Vector3(i * TILE, 0.0, -span * TILE), 0.0, 1.0, true)
		_place(pref, Vector3(i * TILE, 0.0, span * TILE), PI, 1.0, true)
	for i in range(-span + 1, span):
		_place(pref, Vector3(-span * TILE, 0.0, i * TILE), PI * 0.5, 1.0, true)
		_place(pref, Vector3(span * TILE, 0.0, i * TILE), -PI * 0.5, 1.0, true)

func _build_columns() -> void:
	var pref := _rand_from(column_tiles)
	if pref == "":
		return
	var span := HALL_RADIUS
	for sx in [-span, span]:
		for sz in [-span, span]:
			_place(pref, Vector3(sx * TILE, 0.0, sz * TILE), 0.0, 1.0, true)

func _build_torches() -> void:
	var pref := _rand_from(torch_tiles)
	var span := HALL_RADIUS - 1
	var positions := [
		Vector3(0, 0, -span * TILE), Vector3(0, 0, span * TILE),
		Vector3(-span * TILE, 0, 0), Vector3(span * TILE, 0, 0),
		Vector3(span * 0.5 * TILE, 0, span * 0.5 * TILE),
		Vector3(-span * 0.5 * TILE, 0, -span * 0.5 * TILE),
	]
	for p in positions:
		if pref != "":
			_place(pref, p)
		_add_torch_light(p + Vector3(0, 1.6, 0))

func _add_torch_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.66, 0.32)
	light.light_energy = 3.0
	light.omni_range = 14.0
	light.shadow_enabled = true
	add_child(light)

func _scatter_props() -> void:
	if prop_tiles.is_empty():
		return
	var placed := 0
	var attempts := 0
	while placed < 10 and attempts < 40:
		attempts += 1
		var x := (randi() % (HALL_RADIUS * 2 - 1) - (HALL_RADIUS - 1)) * TILE
		var z := (randi() % (HALL_RADIUS * 2 - 1) - (HALL_RADIUS - 1)) * TILE
		if abs(x) < TILE and abs(z) < TILE:
			continue  # не загораживать спавн игрока
		_place(_rand_from(prop_tiles), Vector3(x, 0.0, z), randf() * PI * 2.0, 1.0, true)
		placed += 1

# ---------- разрушаемые цели (тест боя) ----------
func _spawn_dummies() -> void:
	var dmg_script = load("res://scripts/world/damageable.gd")
	var barrel := ""
	for f in ["barrel_large.fbx", "box_small.fbx", "barrel_small.fbx", "crate.fbx"]:
		var p: String = DUNGEON_DIR + "/" + f
		if ResourceLoader.exists(p):
			barrel = p
			break
	if barrel.is_empty():
		return
	var spots := [
		Vector3(TILE * 2, 0.6, TILE * 2),
		Vector3(-TILE * 2, 0.6, TILE * 3),
		Vector3(TILE * 3, 0.6, -TILE * 2),
		Vector3(0, 0.6, TILE * 4),
		Vector3(-TILE * 4, 0.6, -TILE * 3),
	]
	for s in spots:
		var rb := RigidBody3D.new()
		# локальная позиция (до add_child) — не вызывает предупреждения global_transform
		rb.position = s
		rb.mass = 4.0
		rb.linear_damp = 0.6
		rb.angular_damp = 0.6
		rb.can_sleep = true
		var col := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.45
		cyl.height = 1.0
		col.shape = cyl
		rb.add_child(col)
		var res = load(barrel)
		if res:
			var inst = res.instantiate()
			rb.add_child(inst)
			_apply_material_recursive(inst)
		rb.set_script(dmg_script)
		add_child(rb)

# ---------- враги-скелеты (Этап 3): Миньоны + Воины ----------
func _spawn_enemies() -> void:
	var script = load("res://scripts/enemy/skeleton_enemy.gd")
	# Миньон: быстрый, слабый
	var minion := {
		"path": "res://assets/characters/skeletons/Skeleton_Minion.glb",
		"hp": 40.0, "speed": 2.8, "dmg": 9.0, "range": 1.8,
	}
	# Воин: танк, медленный, сильный
	var warrior := {
		"path": "res://assets/characters/skeletons/Skeleton_Warrior.glb",
		"hp": 95.0, "speed": 2.0, "dmg": 16.0, "range": 2.0,
	}
	var spots_minion := [Vector3(TILE * 3, 0.0, TILE * 3), Vector3(-TILE * 3, 0.0, -TILE * 3)]
	var spots_warrior := [Vector3(TILE * 4, 0.0, -TILE * 2), Vector3(-TILE * 4, 0.0, TILE * 2)]
	for s in spots_minion:
		_spawn_one_enemy(minion, s, script)
	for s in spots_warrior:
		_spawn_one_enemy(warrior, s, script)

func _spawn_one_enemy(d: Dictionary, spot: Vector3, script: Resource) -> void:
	if not ResourceLoader.exists(d["path"]):
		return
	var res = load(d["path"])
	if res == null:
		return
	var enemy := CharacterBody3D.new()
	enemy.position = spot
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.8, 0)
	enemy.add_child(col)
	var mesh = res.instantiate()
	enemy.add_child(mesh)
	enemy.set_script(script)
	# характеристики типа врага
	enemy.max_hp = float(d["hp"])
	enemy.speed = float(d["speed"])
	enemy.attack_damage = float(d["dmg"])
	enemy.attack_range = float(d["range"])
	add_child(enemy)

# ---------- ловушки-шипы (Этап 4) ----------
func _spawn_traps() -> void:
	var script = load("res://scripts/world/spike_trap.gd")
	var spots := [
		Vector3(TILE, 0.06, TILE * 2),
		Vector3(-TILE * 2, 0.06, -TILE * 2),
		Vector3(TILE * 2, 0.06, -TILE),
	]
	for s in spots:
		var trap := Area3D.new()
		trap.position = s
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.5, 1.0, 1.5)
		col.position = Vector3(0, 0.5, 0)
		col.shape = box
		trap.add_child(col)
		trap.set_script(script)
		add_child(trap)

# ---------- выход + друзья (Этап 4) ----------
func _spawn_exit() -> void:
	var pos := Vector3(0.0, 0.0, -(HALL_RADIUS - 1) * TILE)
	# Светящийся портал-выход
	var portal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.radius = 1.4
	cyl.height = 3.0
	portal.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 1.0, 0.7)
	m.emission_enabled = true
	m.emission = Color(0.4, 1.0, 0.7)
	m.emission_energy_multiplier = 3.0
	portal.material_override = m
	portal.position = pos + Vector3(0, 1.5, 0)
	add_child(portal)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 2.0, 0)
	light.light_color = Color(0.4, 1.0, 0.7)
	light.light_energy = 4.0
	light.omni_range = 14.0
	add_child(light)
	# Зона-триггер победы
	var zone := Area3D.new()
	zone.position = pos + Vector3(0, 1.0, 0)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 3.0, 2.0)
	col.shape = box
	zone.add_child(col)
	zone.set_script(load("res://scripts/world/exit_zone.gd"))
	add_child(zone)
	_spawn_friends(pos)

func _spawn_friends(exit_pos: Vector3) -> void:
	# Друзья-авантюристы у выхода (статичны; анимация Idle — позже)
	var files := ["Knight.glb", "Mage.glb", "Ranger.glb"]
	var i := 0
	for fn in files:
		var p: String = "res://assets/characters/adventurers/" + fn
		if not ResourceLoader.exists(p):
			continue
		var res = load(p)
		if res == null:
			continue
		var fr = res.instantiate()
		fr.position = exit_pos + Vector3((i - 1) * 1.2, 0.0, 1.8)
		fr.rotation.y = PI  # лицом к игроку (к центру)
		add_child(fr)
		i += 1
