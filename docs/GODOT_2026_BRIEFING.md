# 🎮 Godot 2026 — Брифинг для разработки AgentNeyro

> Сводка актуального состояния Godot на **28 июля 2026**, чтобы писать код без устаревших API.
> Источники: godotengine.org (релизы 4.4–4.7), официальные миграционные гайды, GitHub-PR.

---

## 1. Актуальная версия

| Версия | Дата | Статус |
|---|---|---|
| **4.7.1** | 13–14 июля 2026 | ✅ **latest stable (целевая)** |
| 4.7 | 18 июня 2026 | stable, кодовое имя **«Lights, Camera, Action!»** |
| 4.6 | 25 января 2026 | поддерживается (4.6.3 — 20 мая 2026) |
| 4.5 | 15 сентября 2025 | активная поддержка окончена |
| 4.4 | 2 марта 2025 | поддержка окончена |
| 3.6 | сентябрь 2024 | LTS (3.6.2) |

**Целевая версия проекта: Godot 4.7.1 (stable).**

---

## 2. Что нового произошло с момента моих данных (≈ конец 2024 = 4.3)

### Godot 4.4 (март 2025)
- **Jolt Physics** встроен в движок (как опция).
- Встроенное окно игры (embedded game window) + интерактивное редактирование на лету.
- **`LookAtModifier3D`** — частично заменяет **устаревший `SkeletonIK3D`**.
- .NET 8 (проекты автоматически мигрируют), typed dictionaries.
- **Ubershaders**, AgX-тонмаппинг, нативный **Metal** (вместо MoltenVK).
- Масштабное ускорение импорта текстур (компрессор Betsy).
- ⚠️ Поведение: `print(1.0)` теперь печатает **`1.0`** (а не `1`) — влияет на сериализацию float в текст.

### Godot 4.5 (сентябрь 2025)
- Wayland, NativeAOT для .NET, 16 KB-страницы Android.
- Stencil buffer, specular occlusion, precompiling шейдеров.
- Переработка 3D physics interpolation, доступность (accessibility).
- ⚠️ Breaking: `Node.get_rpc_config` → **`get_node_rpc_config`**; `Node.set_name` параметр `String`→`StringName`; `JSONRPC.set_scope`→`set_method`.

### Godot 4.6 (январь 2026)
- **Jolt Physics = физика по умолчанию для НОВЫХ 3D-проектов** (PR #105737).
- Новый Modern-редактор (тёмная нейтральная тема), плавающие/отделяемые доки.
- **Новый IK-фреймворк** (`IKModifier3D` + солверы/констрейнты), `SkeletonIK3D` устарел.
- libgodot (движок как библиотека), ObjectDB-профайлер, rotation snapping.
- Glow теперь композится ДО тонмаппинга, улучшены SSR и reflection probes.

### Godot 4.7 (июнь 2026)
- **`AreaLight3D`** — новый узел прямоугольных источников света (мягкие тени, блики).
- **HDR-вывод** (Windows/macOS/Linux-Wayland/iOS/visionOS).
- **`DrawableTexture2D`** — рисование прямо по текстуре.
- **Offset-transform для `Control`** — анимация UI без поломки контейнеров (как CSS `transform`).
- Инлайн-превью текстовых шейдеров, новый **Asset Store** (Asset Library помечен устаревшим).
- ⚠️ В **4.7 Jolt становится абсолютным дефолтом** 3D-физики (PR #105762).
- Breaking в 4.7 (всё GDScript-совместимо ✔ или не касается нас): `Object.is_class` параметр `String`→`StringName`; `get_format()` перенесён с `ImageTexture`/`PortableCompressedTexture2D` в базовый `Texture2D`; мелкие опциональные параметры в particle/ZIP/EXR методах.

---

## 3. Что это значит для НАШЕЙ игры (3D на FBX-ассетах) — критичные выводы

### ✅ Импорт FBX — без проблем
- С 4.3 по умолчанию используется **ufbx** (нативный, без внешнего `FBX2glTF`).
- Наши 211 FBX — «новые» → импортируются через ufbx.
- **Лишнего узла `RootNode` не будет**; конвертация единиц (см→м) применяется к мешу, а не к масштабу узла.
- ⚠️ Внутри FBX текстура прописана **абсолютным Windows-путём** → Godot её не найдёт авто. Решение: **один общий материал** (`StandardMaterial3D` с `dungeon_texture.png`) + `material_override`, либо положить текстуру рядом с FBX.

### ✅ Физика — Jolt по умолчанию, API тот же
- В 4.7 Jolt — дефолт 3D-физики. Для нас это «бесплатно»: быстрее и стабильнее.
- **API `CharacterBody3D` не изменился** — это drop-in замена бэкенда. Узлы/методы те же.

### ✅ Шаблон `CharacterBody3D` — актуальный и стабильный (4.x → 4.7)
```gdscript
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if dir:
        velocity.x = dir.x * SPEED
        velocity.z = dir.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)
        velocity.z = move_toward(velocity.z, 0.0, SPEED)
    move_and_slide()
```
- `velocity` (свойство), `move_and_slide()` (**без аргументов**), `is_on_floor()` — всё актуально.
- `move_and_slide()` возвращает `bool` (столкновение); детали — `get_last_slide_collision()`, `get_real_velocity()`.

### ⚠️ Чего НЕ использовать (устарело/изменено) — чтобы не было ошибок
| Старое | Правильно сейчас |
|---|---|
| `SkeletonIK3D` | Новый IK-фреймворк (`IKModifier3D` и солверы, 4.6+) |
| `auto_translate` (свойство) | `auto_translate_mode` (4.3+) |
| `Node.get_rpc_config()` | `get_node_rpc_config()` (4.5+) |
| `Godot Physics 3D` (по умолчанию) | **Jolt** (4.7). Старый ещё доступен, но планируется к удалению |
| Расчёт на `print(1.0)` == `"1"` | Теперь `"1.0"` — учитывать при текстовой сериализации float |

### 🆕 Чем можем выгодно воспользоваться
- **`AreaLight3D`** — мягкий свет от окон/факелов/свечей (атмосфера подземелья).
- **`DrawableTexture2D`** — динамические текстуры (например, мини-карта, эффекты).
- **Control offset-transform** — сочная анимация UI (меню, HUD).
- **Inline-превью шейдеров** — быстрее писать кастомные шейдеры.

---

## 4. Готовность

- Целевая версия зафиксирована: **Godot 4.7.1**.
- Импорт FBX (ufbx), физика (Jolt), шаблон персонажа — подтверждены как актуальные.
- Карта устаревших/переименованных API собрана → ошибок с модулями/функциями не будет.

**Готов принимать промт по игре.** 🚀
