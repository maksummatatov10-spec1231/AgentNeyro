# 📦 Полная опись ассетов — 4 набора

> Источник: коммиты `458be35` и `9d96fb0` на ветке `main` репозитория `AgentNeyro`

| # | Архив | Размер | Тип | Набор | Автор/лицензия |
|---|---|---:|---|---|---|
| 1 | `Архив ZIP - WinRAR.zip` | 3.8 МБ | среда | **KayKit Dungeon Asset Pack** | Kay Lousberg (KayKit) |
| 2 | `ассеты2часть1.zip` | 15.9 МБ | анимации | **Universal Animation Library 1** | @Quaternius — **CC0** |
| 3 | `ассеты2часть2.zip` | 18.7 МБ | анимации + персонаж | **Universal Animation Library 2** | @Quaternius — **CC0** |
| 4 | `ассеты3.zip` | 875 КБ | среда | **Modular City pack (citybits)** | (атлас `citybits_texture`) |

---

## 1. 🏰 KayKit Dungeon Asset Pack (набор 1)
**211 моделей FBX (бинарный)** + атлас `dungeon_texture.png` (**1024×1024 RGBA**), общий для всех.
Модульный лоуполи-пак подземелья: стены (31), полы (34), лестницы (14), столы (14),
знамёна (42), бочки/ящики/кровати/свечи/монеты/сундуки/бутылки/мечи/ключи/факелы и т.д.
→ сборка модульных подземелий по сетке.

## 2 & 3. 🏃 Universal Animation Library (UAL 1 + 2) — Quaternius, CC0
Готовые **человекообразные анимации** для Godot: версии `.glb` лежат в папке `Unreal-Godot/`
(плюс есть `Godot_Setup.png` с инструкцией импорта). Скелет — 67 нод (стандартный гуманоидный).
Версия `_RM` = root motion вшит в анимацию; обычная — root motion отключён.

- **UAL1 — 43 анимации**, **UAL2 — 43 анимации** → **итого 86 анимаций** ✅
- В UAL2 есть **Female Mannequin** (`Mannequin_F.blend/.fbx/.glb`) — референс-скелет/меш (67 нод) для ретаргетинга.

### Все 86 анимаций (имена)
**UAL1 (43):** A_TPose, Crouch_Fwd_Loop, Crouch_Idle_Loop, Dance_Loop, Death01, Driving_Loop,
Fixing_Kneeling, Hit_Chest, Hit_Head, Idle_Loop, Idle_Talking_Loop, Idle_Torch_Loop, Interact,
Jog_Fwd_Loop, Jump_Land, Jump_Loop, Jump_Start, PickUp_Table, Pistol_Aim_Down, Pistol_Aim_Neutral,
Pistol_Aim_Up, Pistol_Idle_Loop, Pistol_Reload, Pistol_Shoot, Punch_Cross, Punch_Jab, Push_Loop,
Roll, Sitting_Enter, Sitting_Exit, Sitting_Idle_Loop, Sitting_Talking_Loop, Spell_Simple_Enter,
Spell_Simple_Exit, Spell_Simple_Idle_Loop, Spell_Simple_Shoot, Sprint_Loop, Swim_Fwd_Loop,
Swim_Idle_Loop, Sword_Attack, Sword_Idle, Walk_Formal_Loop, Walk_Loop

**UAL2 (43):** A_TPose, Chest_Open, ClimbUp_1m, Consume, Farm_Harvest, Farm_PlantSeed,
Farm_Watering, Hit_Knockback, Idle_FoldArms_Loop, Idle_Lantern_Loop, Idle_No_Loop, Idle_Rail_Call,
Idle_Rail_Loop, Idle_Shield_Break, Idle_Shield_Loop, Idle_TalkingPhone_Loop, LayToIdle, Melee_Hook,
Melee_Hook_Rec, NinjaJump_Idle_Loop, NinjaJump_Land, NinjaJump_Start, OverhandThrow, Shield_Dash,
Shield_OneShot, Slide_Exit, Slide_Loop, Slide_Start, Sword_Block, Sword_Dash, Sword_Heavy_Combo,
Sword_Regular_A/B/C (+_Rec), Sword_Regular_Combo, TreeChopping_Loop, Walk_Carry_Loop, Yes,
**Zombie_Idle_Loop, Zombie_Scratch, Zombie_Walk_Fwd_Loop** 🧟

> 🎯 Анимации намекают на жанр: **action-RPG / dungeon-crawler / выживание** — мечевые комбо,
> пистолет, магия, щит, перекаты/слайды/ниндзя-прыжки, плавание/карабканье, реакции на удары,
> смерти, фармы/рубка дерева, вождение, сидение/разговор, **и даже зомби** (враги!).

## 4. 🏙️ Modular City pack (набор 4, «citybits»)
**41 модель FBX** + атлас `citybits_texture.png` (**1024×1024 RGBA**), общий.
Категории: **здания** (16, с вариантами `building_A..F` + `_withoutBase`), **дороги** (6),
**машины** (5), светофоры (3), ящики (2), мусорки (2), + скамейка, куст, гидрант, фонарь,
водонапорная башня, base.
→ модульный лоуполи-город (тайл-сет улиц/зданий/транспорта).

---

## 🧩 Что это даёт для игры
- **Персонаж** — Female Mannequin (база), на него ретаргетятся 86 анимаций (ходьба, бег, бой, и т.д.).
- **Боёвка** — есть готовые мечевые комбо/блок/даш, пистолет, магия, щит, рукопашные удары.
- **Враги** — зомби-анимации (idle/walk/scratch) — можно сделать противников.
- **Окружение** — два сеттинга: подземелье (dungeon) и город (city).
- **Лицензии** — UAL = **CC0** (можно свободно использовать). Dungeon/City — проверить лицензию
  конкретных наборов и указать атрибуцию в `credits`.

## ⚙️ Рекомендуемая структура в Godot-проекте
```
assets/
├── models/
│   ├── dungeon/     ← 211 FBX + dungeon_material
│   └── city/        ← 41 FBX + city_material
├── characters/
│   └── mannequin_f.glb   ← базовый персонаж (скелет 67 нод)
└── animations/
    ├── ual1_standard.glb ← 43 анимации (импортировать как библиотеку)
    └── ual2_standard.glb ← 43 анимации
materials/
├── dungeon_material.tres
└── city_material.tres
```
Все ассеты в форматах, нативно поддерживаемых Godot 4.7 (FBX через ufbx, GLB напрямую). ✅
