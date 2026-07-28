extends Node3D
## Строитель ОГРОМНОГО данжа (Этап 4.1).
## Пол — одна большая тайловая плоскость (без мерцания, быстро). Стены — коробки
## (периметр + перегородки-коридоры, точная коллизия). FBX — колонны/пропы/сундуки/факелы/лестница.

const DUNGEON_DIR := "res://assets/models/dungeon"
const TILE := 2.0
const HALL_RADIUS := 16      # тайлов в каждую сторону (~66×66 м)

var floor_tiles: Array = []
var wall_tiles: Array = []
var column_tiles: Array = []
var torch_tiles: Array = []
var prop_tiles: Array = []
var chest_tiles: Array = []
var stairs_tiles: Array = []

@onready var material: StandardMaterial3D = load("res://materials/dungeon_material.tres")

func _ready() -> void:
	randomize()
	_scan_assets()
	_build_floor()
	_build_perimeter_walls()
	_build_partitions()
	_build_columns_grid()
	_build_torches_grid()
	_scatter_props()
	_spawn_dummies()
	_spawn_chests()
	_spawn_enemies_groups()
	_spawn_traps_grid()
	_build_exit_area()
	GameManager.set_state(GameManager.GameState.PLAYING)
	EventBus.level_loaded.emit()
	print("EMBERFALL: огромный данж построен (радиус %d)." % HALL_RADIUS)

# ---------- сканирование ассетов ----------
func _scan_assets() -> void:
	var dir := DirAccess.open(DUNGEON_DIR)
	if dir == null:
		push_warning("DungeonBuilder: папка ассетов не найдена.")
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.to_lower().ends_with(".fbx"):
			var n := fname.get_basename().to_lower()
			var p := DUNGEON_DIR + "/" + fname
			if n.begins_with("floor"):
				floor_tiles.append(p)
			elif n.begins_with("wall"):
				wall_tiles.append(p)
			elif n.begins_with("column") or n.begins_with("pillar"):
				column_tiles.append(p)
			elif n.begins_with("torch"):
				torch_tiles.append(p)
			elif n.begins_with("chest"):
				chest_tiles.append(p)
			elif n.begins_with("stair") or n.begins_with("stairs"):
				stairs_tiles.append(p)
			elif n.begins_with("barrel") or n.begins_with("box") or n.begins_with("crate") \
				or n.begins_with("banner") or n.begins_with("barrier") or n.begins_with("rubble") \
				or n.begins_with("table") or n.begins_with("bench"):
				prop_tiles.append(p)
		fname = dir.get_next()
	dir.list_dir_end()

# ---------- ПОЛ (одна большая тайловая плоскость) ----------
func _build_floor() -> void:
	var size := (HALL_RADIUS * 2 + 1) * TILE
	# Коллизия пола
	var body := StaticBody3D.new()
	add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 1.0, size)
	col.shape = box
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)
	# Визуал: одна плоскость с тайловой текстурой данжа
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	mi.mesh = plane
	var fmat := StandardMaterial3D.new()
	fmat.albedo_texture = load("res://assets/textures/dungeon_texture.png")
	fmat.uv1_scale = Vector3(16, 16, 1)
	mi.material_override = fmat
	add_child(mi)

# ---------- СТЕНЫ (коробки = точная коллизия) ----------
func _wall(center: Vector3, sz: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = sz
	col.shape = box
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = material
	body.add_child(mi)

func _build_perimeter_walls() -> void:
	var span := (HALL_RADIUS * 2 + 1) * TILE
	var half := span * 0.5
	var h := 5.0
	var t := 1.0
	_wall(Vector3(0, h * 0.5, -half), Vector3(span, h, t))
	_wall(Vector3(0, h * 0.5, half), Vector3(span, h, t))
	_wall(Vector3(-half, h * 0.5, 0), Vector3(t, h, span))
	_wall(Vector3(half, h * 0.5, 0), Vector3(t, h, span))

# Перегородки-коридоры: частичные стены (оставляют проходы) → лабиринт коридоров
func _build_partitions() -> void:
	var h := 4.0
	var t := 0.5
	var R := HALL_RADIUS
	# Горизонтальные частичные стены (вдоль X) на разных Z
	_wall(Vector3(-R * 0.7 * TILE, h * 0.5, -R * 0.5 * TILE), Vector3(R * 1.0 * TILE, h, t))
	_wall(Vector3(R * 0.5 * TILE, h * 0.5, -R * 0.1 * TILE), Vector3(R * 0.9 * TILE, h, t))
	_wall(Vector3(-R * 0.6 * TILE, h * 0.5, R * 0.4 * TILE), Vector3(R * 0.8 * TILE, h, t))
	# Вертикальные частичные стены (вдоль Z) на разных X
	_wall(Vector3(-R * 0.4 * TILE, h * 0.5, R * 0.2 * TILE), Vector3(t, h, R * 1.0 * TILE))
	_wall(Vector3(R * 0.3 * TILE, h * 0.5, -R * 0.3 * TILE), Vector3(t, h, R * 0.9 * TILE))
	_wall(Vector3(R * 0.6 * TILE, h * 0.5, R * 0.5 * TILE), Vector3(t, h, R * 0.7 * TILE))

# ---------- FBX-размещение (колонны/пропы/сундуки/факелы/лестница) ----------
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

# ---------- колонны (сетка) ----------
func _build_columns_grid() -> void:
	var pref := _rand_from(column_tiles)
	if pref == "":
		return
	var step := 4
	for x in range(-HALL_RADIUS + 2, HALL_RADIUS, step):
		for z in range(-HALL_RADIUS + 2, HALL_RADIUS, step):
			if (x + z) % 8 == 0:
				_place(pref, Vector3(x * TILE, 0.0, z * TILE), 0.0, 1.0, true)

# ---------- факелы (сетка) ----------
func _build_torches_grid() -> void:
	var pref := _rand_from(torch_tiles)
	var step := 8
	for x in range(-HALL_RADIUS + 1, HALL_RADIUS, step):
		for z in range(-HALL_RADIUS + 1, HALL_RADIUS, step):
			var p := Vector3(x * TILE, 0.0, z * TILE)
			if pref != "":
				_place(pref, p)
			_add_torch_light(p + Vector3(0, 1.8, 0))

func _add_torch_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.66, 0.32)
	light.light_energy = 2.6
	light.omni_range = 20.0
	light.shadow_enabled = false
	add_child(light)

# ---------- декор ----------
func _scatter_props() -> void:
	if prop_tiles.is_empty():
		return
	var placed := 0
	var attempts := 0
	while placed < 40 and attempts < 120:
		attempts += 1
		var x := (randi() % (HALL_RADIUS * 2) - HALL_RADIUS) * TILE
		var z := (randi() % (HALL_RADIUS * 2) - HALL_RADIUS) * TILE
		if abs(x) < TILE * 2 and abs(z) < TILE * 2:
			continue  # не загораживать спавн
		_place(_rand_from(prop_tiles), Vector3(x, 0.0, z), randf() * PI * 2.0, 1.0, true)
		placed += 1

# ---------- разрушаемые бочки ----------
func _spawn_dummies() -> void:
	var dmg_script = load("res://scripts/world/damageable.gd")
	var barrel := ""
	for f in ["barrel_large.fbx", "box_small.fbx", "barrel_small.fbx"]:
		var p: String = DUNGEON_DIR + "/" + f
		if ResourceLoader.exists(p):
			barrel = p
			break
	if barrel.is_empty():
		return
	for i in range(6):
		var s := Vector3((randi() % 20 - 10) * TILE, 0.6, (randi() % 20 - 10) * TILE)
		var rb := RigidBody3D.new()
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

# ---------- сундуки (с охраной-врагом) ----------
func _spawn_chests() -> void:
	var pref := _rand_from(chest_tiles)
	if pref == "":
		return
	var spots := [
		Vector3(-HALL_RADIUS * 0.6 * TILE, 0.0, HALL_RADIUS * 0.6 * TILE),
		Vector3(HALL_RADIUS * 0.6 * TILE, 0.0, HALL_RADIUS * 0.3 * TILE),
		Vector3(-HALL_RADIUS * 0.3 * TILE, 0.0, -HALL_RADIUS * 0.6 * TILE),
	]
	var escript = load("res://scripts/enemy/skeleton_enemy.gd")
	var guard := {
		"path": "res://assets/characters/skeletons/Skeleton_Warrior.glb",
		"hp": 95.0, "speed": 2.0, "dmg": 16.0, "range": 2.0,
	}
	for s in spots:
		_place(pref, s, randf() * PI * 2.0, 1.0, true)
		# охранник рядом
		_spawn_one_enemy(guard, s + Vector3(TILE * 1.5, 0.0, 0.0), escript)

# ---------- враги (группы) ----------
func _spawn_enemies_groups() -> void:
	var escript = load("res://scripts/enemy/skeleton_enemy.gd")
	var minion := {"path": "res://assets/characters/skeletons/Skeleton_Minion.glb", "hp": 40.0, "speed": 2.8, "dmg": 9.0, "range": 1.8}
	var rogue := {"path": "res://assets/characters/skeletons/Skeleton_Rogue.glb", "hp": 55.0, "speed": 3.2, "dmg": 12.0, "range": 1.8}
	var groups := [
		Vector3(-HALL_RADIUS * 0.5 * TILE, 0.0, -HALL_RADIUS * 0.2 * TILE),
		Vector3(HALL_RADIUS * 0.4 * TILE, 0.0, HALL_RADIUS * 0.5 * TILE),
		Vector3(0.0, 0.0, HALL_RADIUS * 0.7 * TILE),
		Vector3(-HALL_RADIUS * 0.7 * TILE, 0.0, -HALL_RADIUS * 0.5 * TILE),
	]
	for gi in range(groups.size()):
		var center: Vector3 = groups[gi]
		for j in range(3):
			var off := Vector3((j - 1) * TILE, 0.0, (randi() % 3 - 1) * TILE)
			_spawn_one_enemy(minion if gi % 2 == 0 else rogue, center + off, escript)

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
	enemy.max_hp = float(d["hp"])
	enemy.speed = float(d["speed"])
	enemy.attack_damage = float(d["dmg"])
	enemy.attack_range = float(d["range"])
	add_child(enemy)

# ---------- ловушки (сетка в коридорах) ----------
func _spawn_traps_grid() -> void:
	var script = load("res://scripts/world/spike_trap.gd")
	var spots := [
		Vector3(-HALL_RADIUS * 0.4 * TILE, 0.06, 0.0),
		Vector3(HALL_RADIUS * 0.2 * TILE, 0.06, -HALL_RADIUS * 0.4 * TILE),
		Vector3(0.0, 0.06, -HALL_RADIUS * 0.6 * TILE),
		Vector3(HALL_RADIUS * 0.5 * TILE, 0.06, HALL_RADIUS * 0.2 * TILE),
		Vector3(-HALL_RADIUS * 0.2 * TILE, 0.06, HALL_RADIUS * 0.5 * TILE),
		Vector3(HALL_RADIUS * 0.3 * TILE, 0.06, -HALL_RADIUS * 0.1 * TILE),
	]
	for s in spots:
		var trap := Area3D.new()
		trap.position = s
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.6, 1.0, 1.6)
		col.position = Vector3(0, 0.5, 0)
		col.shape = box
		trap.add_child(col)
		trap.set_script(script)
		add_child(trap)

# ---------- выход + лестница + друзья ----------
func _build_exit_area() -> void:
	var pos := Vector3(0.0, 0.0, -(HALL_RADIUS - 1) * TILE)
	# Лестница к выходу (визуал)
	var stair := _rand_from(stairs_tiles)
	if stair != "":
		_place(stair, pos + Vector3(0, 0, 1.5 * TILE), PI)
	# Светящийся портал-выход
	var portal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 3.4
	portal.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 1.0, 0.7)
	m.emission_enabled = true
	m.emission = Color(0.4, 1.0, 0.7)
	m.emission_energy_multiplier = 3.0
	portal.material_override = m
	portal.position = pos + Vector3(0, 1.7, 0)
	add_child(portal)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 2.2, 0)
	light.light_color = Color(0.4, 1.0, 0.7)
	light.light_energy = 5.0
	light.omni_range = 18.0
	add_child(light)
	# Зона-триггер победы
	var zone := Area3D.new()
	zone.position = pos + Vector3(0, 1.0, 0)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 3.4, 2.5)
	col.shape = box
	zone.add_child(col)
	zone.set_script(load("res://scripts/world/exit_zone.gd"))
	add_child(zone)
	# Друзья
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
		fr.position = pos + Vector3((i - 1) * 1.4, 0.0, 2.2 * TILE)
		fr.rotation.y = PI
		add_child(fr)
		i += 1
