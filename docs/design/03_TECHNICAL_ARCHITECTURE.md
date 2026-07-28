# 🏗️ Техническая архитектура (EMBERFALL)

> Структура кода, автозагрузки, граф сцен, системы. Godot 4.7.1, GDScript.

---

## 1. Автозагрузки (Singletons)

| Синглтон | Файл | Ответственность |
|---|---|---|
| `GameManager` | `scripts/autoload/game_manager.gd` | состояние игры (MENU/PLAY/PAUSE/WIN/LOSE), переход сцен, чекпоинты, пауза |
| `SettingsManager` | `scripts/autoload/settings_manager.gd` | загрузка/сохранение `config.cfg`, значения настроек |
| `GraphicsManager` | `scripts/autoload/graphics_manager.gd` | применение пресетов графики к Environment/ProjectSettings/Viewport |
| `AudioManager` | `scripts/autoload/audio_manager.gd` | шины (Master/Music/SFX/UI), play_sfx/play_3d/play_music |
| `EventBus` | `scripts/autoload/event_bus.gd` | глобальные сигналы (player_hurt, enemy_died, mana_changed, …) |

---

## 2. Граф сцен (дерево проекта)

```
main_menu.tscn            (Control)  — стартовая сцена проекта
settings_menu.tscn        (Control)  — настройки (табы Геймплей/Звук/Управление/Графика)
graphics_menu.tscn        (Control)  — большое меню графики (вкладка или отдельная)
level_dungeon.tscn        (Node3D)   — игровой уровень
├─ WorldEnvironment
├─ DirectionalLight3D (слабкий, имитация света из проёмов)
├─ Player (CharacterBody3D) ← player.tscn
│   ├─ CollisionShape3D (капсула)
│   ├─ Camera3D (head, FOV 90)
│   │   └─ ViewModel (sword_1handed + staff)  + DamageVignette-точки
│   ├─ InteractionRayCast (RayCast3D)
│   └─ HurtDetector (Area3D)
├─ Dungeon (Node3D) ← DungeonBuilder (скрипт собирает тайлы)
│   ├─ Floors / Walls / Props / Lights / Traps
│   └─ NavigationRegion3D (NavMesh для врагов)
├─ Enemies (Node3D)  — спавн skeleton_enemy.tscn
├─ Projectiles (Node3D) — пул снарядов
├─ VFX (Node3D) — пул эффектов
├─ Exit (Area3D) → Freunde spawn (Knight/Mage/Ranger)
└─ CanvasLayer (HUD)
    ├─ Crosshair, HP/MP/STA бары, Способность, Цель, Компас
    └─ DamageVignette (ColorRect + шейдер), LowHealthPulse
win_screen.tscn / death_screen.tscn / pause_menu.tscn
```

---

## 3. Скрипты (по модулям)

### Автозагрузки (`scripts/autoload/`)
- `game_manager.gd` — enum State, `change_state()`, `load_level()`, `pause/resume`, `respawn()`.
- `settings_manager.gd` — `ConfigFile`, секции [audio][gameplay][graphics][controls]; `get/set/save`.
- `graphics_manager.gd` — `apply_preset(tier)`, `apply_custom(dict)`; маппинг → Environment/ProjectSettings.
- `audio_manager.gd` — AudioStreamPlayer’ы + шины; `sfx(name, pitch)`, `sfx_3d(name, pos)`.
- `event_bus.gd` — `signal player_hurt(amount), player_healed, mana_changed, enemy_died(pos), checkpoint_reached, …`.

### Игрок (`scripts/player/`)
- `player_controller.gd` (CharacterBody3D) — движение WASD, прыжок, спринт, присед, mouse-look, head-bob, стамина.
- `player_health.gd` — HP, получение урона, реген, смерть; дёргает EventBus + vignette/shake.
- `player_combat.gd` — состояние боя; делегирует `MeleeWeapon` и `MagicSystem`.
- `melee_weapon.gd` — light/heavy комбо, конус-хит, knockback; viewmodel-анимация; HitFX.
- `magic_system.gd` —bolt/beam/aoe/heal/dash; расход маны, КД; спавн Projectile/Beam.
- `player_viewmodel.gd` — анимация меча/посоха на камере, emissive-trail.
- `interaction.gd` — RayCast для дверей/рычагов/предметов.

### Враги (`scripts/enemy/`)
- `enemy_base.gd` (CharacterBody3D + NavigationAgent3D) — State-машина, HP, chase, attack.
- `enemy_combat.gd` — контактная/дальняя атака по КД.
- `enemy_health.gd` — получение урона (flash, Hit_A/B, knockback), смерть (Death_A, dissolve, drop).
- `skeleton_data.gd` (Resource) — параметры типа (hp/speed/dmg/anim/VFX/ассет-путь).

### Снаряды/магия (`scripts/world/`)
- `projectile.gd` (RigidBody3D/Area3D) — полёт, попадание, AoE, удаление/пул.
- `beam_controller.gd` — RayCast-луч, DoT, визуал GodotBeam.
- `aoe_blast.gd` — взрыв, радиус-урон, DoT, ExplosionFX.

### Ловушки (`scripts/world/traps/`)
- `trap_base.gd` — активация (таймер/триггер), телеграф, урон-зона.
- `spike_trap.gd`, `flame_trap.gd`, `arrow_trap.gd`, `crusher_trap.gd`, `gas_trap.gd`.

### Мир (`scripts/world/`)
- `dungeon_builder.gd` — сборка уровня из FBX-тайлов (load() по имени), расстановка света/врагов/ловушек/выхода; общий материал.
- `shared_material.gd` — создание/кеширование StandardMaterial3D (dungeon_texture).
- `checkpoint.gd`, `exit_zone.gd` (друзья/победа), `pickup.gd` (мана/HP).

### UI (`scripts/ui/`)
- `main_menu.gd`, `settings_menu.gd`, `graphics_menu.gd` (пресеты+ползунки+apply).
- `hud.gd` (бары, цель, компас), `pause_menu.gd`, `win_screen.gd`, `death_screen.gd`.

---

## 4. Поток данных

- **Настройки:** UI → `SettingsManager.set()` → `config.cfg`; графика → `GraphicsManager.apply()`.
- **Бой игрок→враг:** `player_combat` → конус/Area → `enemy_health.take_damage()` → EventBus `enemy_hurt/died` → HUD/VFX/Audio.
- **Магия:** `magic_system` → `Projectile.instantiate()` в группу `Projectiles` → `projectile.gd` → on hit → `enemy_health`/стена.
- **Враг→игрок:** `enemy_combat` (Area3D игрока `HurtDetector`) → `player_health.take_damage()` → EventBus `player_hurt` → vignette/shake/HUD.
- **Победа:** `exit_zone` (Area3D) → спавн друзей → `GameManager.change_state(WIN)` → `win_screen`.
- **Смерть:** `player_health` HP=0 → `GameManager.change_state(LOSE)` → `death_screen`.

---

## 5. Ввод (Input Map, в project.godot)

| Действие | Клавиши |
|---|---|
| `move_forward/back/left/right` | W/S/A/D + стрелки |
| `jump` | Space |
| `sprint` | Shift (удерж.) |
| `crouch` | Ctrl/C |
| `interact` | E |
| `attack_light` | ЛКМ |
| `attack_heavy` | R или удерж. ЛКМ |
| `cast_bolt` | ПКМ |
| `cast_beam` | F |
| `cast_aoe` | Q |
| `heal` | H |
| `dash` | двойной Shift / E (контекст) |
| `switch_weapon` | 1/2 / колесо |
| `pause` | Esc |
| `ui_*` | стандартные |

Чуств. мыши, инверсия, FOV — в настройках геймплея.

---

## 6. Производительность

- **Occlusion culling** (BVH) включён; комнаты-коридоры = естественная отсечка.
- **Пул** снарядов/VFX/частиц (не `queue_free` каждый кадр).
- **LOD/мердж:** статичные тайлы можно мерджить (MultiMesh/merge) для батчинга.
- Ограничение активных огней по пресету; дальние факелы → приближённые/дешёвые.
- NavMesh烘焙 один раз; враги — NavigationAgent3D (дёшево).

---

## 7. Сохранение/чтекпоинты

- Прогресс уровня: текущая комната/чекпоинт, HP/MP — в `config.cfg` или сессионно.
- Чекпоинты = «костры» (свеча/torch) у входов в комнаты; активируются проходом.
