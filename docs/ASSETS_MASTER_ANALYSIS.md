# 📚 МАСТЕР-ПАСПОРТ АССЕТОВ (AgentNeyro)

> Дефинитивный технический справочник по всем ассетам.
> Цель: исключить ошибки с размерами, ригами, анимациями, форматами при разработке на Godot 4.7.1.

---

## 0. Сводная таблица (6 наборов)

| Набор | Формат | Кол-во | Анимации | Риг | Текстура | Назначение |
|---|---|---:|---:|---|---|---|
| **KayKit Dungeon** | FBX (бинарн.) | 211 | 0 | — | `dungeon_texture` 1024² | модульное подземелье |
| **Modular City (citybits)** | FBX (бинарн.) | 41 | 0 | — | `citybits_texture` 1024² | модульный город |
| **KayKit Adventurers 2.0** | GLB + FBX | 6 чел + 31 предмет | 26 | **Rig_Medium (23 кости)** | `*_texture` 1024² (по классу) | герои/игроки |
| **KayKit Skeletons 1.1** | GLB + FBX | 4 врага + 13 предметов | 26 | **Rig_Medium (23 кости)** | `skeleton_texture` 1024² | враги |
| **Universal Animation Library 1** | GLB (Godot) | — | **43** | **Mixamo (67 костей)** | — | анимации |
| **Universal Animation Library 2** | GLB (Godot) | — | **43** | **Mixamo (67 костей)** | — | анимации + Mannequin_F |
| **VFX pack (ассеты6)** | tscn/gdshader/tres | 59 сцен | — | — | PNG 1024² | 7 VFX-паков (CC0, Binbun3D) |

**Итого:** 252 модульных модели окружения, 10 игровых персонажей, 44 предмета/оружия, **~112 анимаций**, **59 готовых VFX-эффектов**, все текстуры **1024×1024 RGBA**.

> ✨ **VFX-набор (ассеты6)** — 7 Godot-native паков эффектов (магия, вспышки, взрывы, удары, лучи),
> CC0, без конвертации. Подробности: [`VFX_ANALYSIS.md`](VFX_ANALYSIS.md).

---

## 🚨 КРИТИЧНО — два несовместимых рига (главный источник будущих ошибок)

### Риг A — KayKit «Rig_Medium» (23 кости)
Кости: `root, hips, spine, chest, head, upperarm.l/.r, lowerarm.l/.r, wrist.l/.r, hand.l/.r, handslot.l/.r, upperleg.l/.r, lowerleg.l/.r, foot.l/.r, toes.l/.r`
- Используют: **все 6 авантюристов + все 4 скелета** → скелет общий, **анимации свободно переносятся между всеми 10 KayKit-персонажами**. ✅
- Собственные анимации (Rig_Medium_General + Rig_Medium_MovementBasic):
  - **General (15):** Death_A, Death_A_Pose, Death_B, Death_B_Pose, Hit_A, Hit_B, Idle_A, Idle_B, Interact, PickUp, Spawn_Air, Spawn_Ground, T-Pose, Throw, Use_Item
  - **MovementBasic (11):** Walking_A/B/C, Running_A/B, Jump_Start, Jump_Idle, Jump_Land, Jump_Full_Long, Jump_Full_Short, T-Pose

### Риг B — Quaternius / Mixamo (67 костей)
- Используют: **UAL1/UAL2 (86 анимаций)** + **Female Mannequin**.
- ⚠️ **НЕ переносится напрямую на KayKit-персонажей** (другие имена/кол-во костей).
- Чтобы использовать UAL-анимации на KayKit-героях → **ретаргетинг** в Godot 4.3+ (SkeletonProfileHumanoid + Retarget-документ), либо анимировать только Female Mannequin.

> 💡 Рекомендация: для прототипа использовать **KayKit-анимации (риг A)** на KayKit-героях — всё совместимо «из коробки». Quaternius-анимации оставить для Female Mannequin или подключить через ретаргетинг позже.

---

## 1. KayKit Dungeon Asset Pack
- **211 статичных FBX** (модульные, без рига) + общий атлас `dungeon_texture.png` (1024²).
- Категории: знамёна(42), полы(34), стены(31), лестницы(14), столы(14), бочки, ящики, кровати, свечи, монеты, сундуки, бутылки, мечи, ключи, факелы, обломки и т.д.
- ⚠️ Внутри FBX текстура — **абсолютный Windows-путь** (`C:\Users\Kay Lousberg\...`). В Godot: один общий `dungeon_material.tres` + `material_override`.

## 2. Modular City (citybits)
- **41 статичный FBX** + атлас `citybits_texture.png` (1024²).
- Категории: здания(16, A–F + `_withoutBase`), дороги(6), машины(5), светофоры(3), ящики(2), мусорки(2) + скамейка, куст, гидрант, фонарь, водонапорная башня, base.

## 3. KayKit Adventurers 2.0 (FREE) — игроки
6 персонажей на **Rig_Medium**: **Barbarian, Knight, Mage, Ranger, Rogue, Rogue_Hooded** (мульти-меш 7–9, 1 материал, своя текстура 1024²).
**31 предмет/оружие:** sword_1h/2h (+color), axe_1h/2h, dagger, staff, wand, bow, bow_withString, crossbow_1h/2h, arrow_bow/crossbow (+bundle), quiver, shield_badge/round/spikes/square (+color, round_barbarian), spellbook_open/closed, mug_empty/full, smokebomb.
Папки: `Characters/{fbx,gltf}`, `Assets/{fbx,fbx(unity),gltf,obj}`, `Animations/gltf/Rig_Medium/`, `Textures/`, `Samples/`.

## 4. KayKit Skeletons 1.1 (FREE) — враги
4 персонажа на **Rig_Medium**: **Skeleton_Mage, Skeleton_Minion, Skeleton_Rogue, Skeleton_Warrior** (мульти-меш 9–10, 2 материала, `skeleton_texture` 1024²).
**13 предметов:** Skeleton_Arrow (+Broken, +Broken_Half, +Half), Axe, Blade, Crossbow, Quiver, Shield_Large_A/B, Shield_Small_A/B, Staff.
> «Broken/Half»-варианты = **визуальные состояния повреждения** (HP врага).

## 5. Universal Animation Library 1+2 (Quaternius, CC0)
- **86 анимаций** на Mixamo-риге (67 костей), версии `.glb` в папке `Unreal-Godot/` (есть `Godot_Setup.png`).
- `_RM` = root motion вшит; без `_RM` — root motion отключён.
- UAL1 (43): ходьба/бег/спринт/прыжок/перекат, плавание, меч/пистолет/магия, удары/реакции/смерти, сидение/разговор/вождение/фарм/рубка.
- UAL2 (43): комбо меча (A/B/C, Dash, Heavy_Combo, Block), щит, ниндзя-прыжок/слайд, хук, бросок, карабканье, **зомби (idle/walk/scratch)**, переноска, разговор по телефону и др.
- **Female Mannequin** (`Mannequin_F.glb`) — референс-меш под эти анимации (67 нод, 0 анимаций).

---

## ✅ Правила работы с ассетами (шпаргалка против ошибок)
1. **Формат:** для персонажей/анимаций предпочтительнее **.glb** (чистый импорт в Godot 4.7); FBX импортируется через ufbx. В наборах есть оба — брать `.glb`.
2. **Текстуры:** все 1024×1024 RGBA. Создать **отдельные материалы** на каждый набор (`dungeon_material`, `city_material`, по одному на класс героя, `skeleton_material`). НЕ полагаться на авто-поиск по абсолютным путям в FBX.
3. **Риг:** KayKit-героев анимировать **только Rig_Medium-анимациями** (26 шт., общие для всех 10). UAL/Mannequin — отдельная экосистема.
4. **Оружие:** крепится к кости `handslot.l/.r` (есть в Rig_Medium) →_attach через `BoneAttachment3D`.
5. **Окружение:** статика (без рига) → коллизии генерить через `MeshInstance3D > Create Trimesh/Single Convex` или `BoxShape3D` для тайлов.
6. **Масштаб:** unit-scale учтён ufbx (см→м), тайлы выровнены под сетку (≈1 м).
7. **Лицензии:** UAL = CC0 ✅. KayKit FREE — указать автора (Kay Lousberg) и проверить условия FREE-версии.

## 🗂️ Структура Godot-проекта
```
assets/
├── models/{dungeon,city}/        ← статичные тайлы + материалы
├── characters/adventurers/       ← 6 .glb (Rig_Medium)
├── characters/skeletons/         ← 4 .glb (Rig_Medium)
├── props/{weapons_adventurers,weapons_skeletons}/
├── animations/rig_medium/        ← KayKit General + MovementBasic (.glb)
└── animations/ual/               ← UAL1/UAL2 + Mannequin_F (Mixamo rig)
materials/{dungeon_material,city_material,knight_material,...}.tres
```
