# 🗺️ Карта ассетов → роли в игре (EMBERFAYLL)

> Точный маппинг: какой файл ассета где используется. Чтобы не путать риги, текстуры, эффекты.

---

## 0. ВАЖНО (повтор из мастер-паспорта)
- **Rig_Medium (23 кости)** = KayKit-персонажи (авантюристы + скелеты) + 26 их анимаций.
- **Mixamo (67 костей)** = Quaternius UAL + Mannequin_F. В игре НЕ смешивать с Rig_Medium без ретаргетинга.
- Все текстуры **1024×1024 RGBA**. В FBX-окружении пути к текстуре — абсолютные Windows → используем **общие материалы** (`dungeon_material`, `skeleton_material`, `*_texture`).

---

## 1. Окружение — подземелье (`assets/models/dungeon/*.fbx`, статика)

| Группа файлов | Использование |
|---|---|
| `floor_*` (34) | пол комнат/коридоров (тайлы по сетке 1 м) |
| `wall*`, `wall_half*`, `wall_corner*`, `wall_endcap*`, `wall_Tsplit*`, `wall_sloped*` | стены/перегородки |
| `wall_gated` / `wall_window_*` | гейт (запертый выход/проход), окна-проёмы для света |
| `wall_cracked` | разрушаемая/секретная стена |
| `column`, `pillar`, `wall_pillar` | колонны (укрытия, опоры) |
| `stairs*` (14) | вертикальная навигация между уровнями |
| `ceiling_tile` | потолок (закрытые коридоры) |
| `torch`, `candle*`, `candle_lit*` | **источники света** (PointLight3D + частицы) |
| `banner*`, `barrel*`, `box*`, `crate*`, `bottle*`, `plate*`, `table*`, `chair`, `stool`, `bed*`, `shelf*`, `shelves*` | декор комнат, укрытия, препятствия |
| `coin*`, `chest*`, `key`, `keyring` | лут/объекты (ману/HP-дроп визуал) |
| `barrier*`, `rubble*` | заграждения, обломки |
| `sword` (в паке данжа) | декор на стенах |

**Материал:** `materials/dungeon_material.tres` (StandardMaterial3D ← `assets/textures/dungeon_texture.png`).
Применяется через `material_override` при инстансинге (путь в FBX игнорируем).

> Городской набор (`city/`) в этой игре НЕ используется (сохраним на будущее).

---

## 2. Персонажи — игрок и друзья (`assets/characters/adventurers/*.glb`)

| Файл (GLB, Rig_Medium) | Роль |
|---|---|
| `Knight.glb` (+ knight_texture) | **герой** (по умолчанию) — тело для отражений/теней; друзья у выхода |
| `Barbarian.glb` | друг у выхода / выбор героя |
| `Mage.glb` | друг у выхода (кастует в финальной сцене) |
| `Ranger.glb` | друг у выхода |
| `Rogue.glb`, `Rogue_Hooded.glb` | резерв: друзья / выбор |

> FPS-герой: тело почти не видно, но нужно для теней и для вида от 3-го лица (опц.).
> Анимации друзей: `Idle_A`, `Idle_B`, `Wave` (через `Throw`/`Use_Item` как приветствие).

---

## 3. Враги — скелеты (`assets/characters/skeletons/*.glb`, Rig_Medium)

| Файл (GLB) | Враг | Поведение |
|---|---|---|
| `Skeleton_Minion.glb` | Minion | рой, лезет вплотную |
| `Skeleton_Warrior.glb` | Warrior / **Bone Lord** (масштаб ×1.6) | танк/мини-босс |
| `Skeleton_Rogue.glb` | Rogue | быстрый, флангует |
| `Skeleton_Mage.glb` | Mage | дальний бой (кастует MagicProjectiles/DarkMagic) |

**Материал/текстура:** `assets/textures/skeleton_texture.png` → `materials/skeleton_material.tres`.

---

## 4. Анимации (`assets/animations/rig_medium/`, Rig_Medium — общие для всех KayKit-персонажей)

| Файл | Анимации | Использование |
|---|---|---|
| `Rig_Medium_General.glb` | Death_A/B(+Pose), Hit_A/B, Idle_A/B, Interact, PickUp, Spawn_Air/Ground, T-Pose, Throw, Use_Item | idle, реакция урона (**Hit_A/B**), смерть (**Death_A/B**), спавн, приветствие друзей |
| `Rig_Medium_MovementBasic.glb` | Walking_A/B/C, Running_A/B, Jump_* | преследование, патруль |

> Загружать как `AnimationLibrary` (импорт GLB → анимации), назначать на `AnimationPlayer` персонажа.
> Т.к. риг общий, **одна библиотека подходит и авантюристам, и скелетам**. ✅

---

## 5. Оружие/предметы (ассеты KayKit, опционально)

- `sword_1handed.fbx` → **viewmodel героя** (ближний бой).
- `staff.fbx` / `wand.fbx` → viewmodel магии (луч/болт).
- `arrow*`, `bow*`, `crossbow*` → **стреломёт-ловушка**.
- `shield_*` → блок/визуал.
- `quiver`, `mug_*`, `smokebomb`, `spellbook_*` → декор/механика (опц.).

> Эти FBX лежат в исходных паках; при необходимости копируем в `assets/props/`.

---

## 6. VFX (`assets/vfx/`, Godot-native, CC0, Binbun3D)

| Папка | Эффекты | Где в игре |
|---|---|---|
| `MagicProjectilesVFX` | ядро/голова/хвост снаряда | **магический болт** игрока и касты Skeleton_Mage |
| `GodotBeamVFX` | луч core/outer/flare/ball/glow | **магический луч** (F) |
| `ExplosionFXFree` | взрыв core/rings/impact | **огненный взрыв** (Q), взрывы ловушек, смерть Mage |
| `HitFXFree` | slash/impact/flare/streaks | **попадания мечом/снарядом**, урон по игроку |
| `ElementalMagicFXFree` | стихийное ядро | огненная струя-ловушка, хил |
| `DarkMagicFXFree` | тёмный вихрь/шар | некромантия Skeleton_Mage, призыв миньонов (Spawn) |
| `MuzzleFlashVFX` | вспышки front/long/side | стреломёт (опц.) |

> ВАЖНО: эффекты зависят от своих скриптов (`VFXEmitterBB.gd`, `VFXControllerBB.gd`, …) и `.ptex`.
> Копировать **всю папку** целиком, инстансить `.tscn` эффекта. Для гарантии — игровые эффекты
> (вспышка/искра) продублированы лёгкими самописными сценами (OmniLight+GPUParticles3D).

---

## 7. Текстуры (итог)
| Файл | Размер | Материал |
|---|---|---|
| `dungeon_texture.png` | 1024² RGBA | `dungeon_material` |
| `skeleton_texture.png` | 1024² RGBA | `skeleton_material` |
| `knight/barbarian/mage/ranger/rogue_texture.png` | 1024² RGBA | по классу (друзья/герой) |
| VFX PNG (flash_*, icons) | 1024²/128² | в материалах VFX |
