# EasyStateMachine

[![Godot 4](https://img.shields.io/badge/Godot-4.X-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Version](https://img.shields.io/badge/version-1.0.0-8435c4)](./plugin.cfg)

**EasyStateMachine** is a modular, self-contained **Finite State Machine (FSM)** addon for [**Godot 4**](https://godotengine.org/). Attach a single custom node to any entity in your scene, define states as child nodes, and start writing clean, decoupled behaviour logic in minutes — with no autoload required and no assumptions about your project structure.

Whether you are building a 2D platformer player, a 3D enemy with AI, a UI screen flow, or any other stateful entity, EasyStateMachine gives you a complete transition API, a state stack for layered behaviours (pause menus, hitstop, dialogue), a built-in debug logger, and a live inspector panel that wires everything together with zero boilerplate.

---

## 📑 Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Documentation](#documentation)
- [Project layout](#project-layout)
- [Credits](#credits)

---

## ✨ Features

| | |
| :--- | :--- |
| **Custom nodes** | Two registered editor types — **`EasyStateMachine`** and **`EasyState`** — each with their own icon and full `@tool` support. |
| **No autoload** | Every `EasyStateMachine` instance is completely self-contained. Drop as many as you need on any node, in any scene, without touching `project.godot`. |
| **Universal** | Attaches to `CharacterBody2D`, `CharacterBody3D`, `RigidBody3D`, `Area2D`, `Node` — any node type, any dimension. |
| **State stack** | `push_state()` / `pop_state()` let you overlay states without destroying the one below — perfect for pause menus, inventory screens, hitstop, and dialogue. |
| **Complete API** | Full set of getters, setters, signals, and utilities: `transition_to`, `restart`, `is_in_state`, `get_state_history`, `register_state`, and more. |
| **Inspector panel** | Custom `EditorInspectorPlugin` renders an **Initial State** dropdown auto-populated from child `EasyState` nodes, with undo/redo support and live updates. |
| **State lifecycle** | Five virtual hooks per state: `_on_enter`, `_on_update`, `_on_physics_update`, `_on_unhandled_input`, `_on_exit`. Delegate seamlessly to `_process`, `_physics_process`, and `_unhandled_input`. |
| **`host` property** | Every state exposes a typed `host` shortcut pointing directly to the parent entity — no `get_parent().get_parent()` chains. |
| **Debug logger** | Contextual `SMLogger` with `NONE / ERROR / WARN / INFO / DEBUG` levels, prefixed per machine instance for easy multi-machine tracing. |
| **Config resource** | `SMConfig` centralizes `initial_state`, history size, stack depth, and debug settings — share a single `.tres` across scenes or configure inline. |

---

## 📋 Requirements

| Item | Required? | Notes |
| :--- | :---: | :--- |
| **Godot 4.0+** | Yes | Uses Godot 4 APIs (`class_name`, `@tool`, typed signals, `@export`, etc.). |
| **Godot 4.2+** | Recommended | Best editor experience with the custom inspector panel. |
| **GDScript** | Yes | All addon files are written in GDScript. No C# or GDExtension required. |

Expected install path in your project:

```text
res://addons/easystatemachine/
```

---

## 📦 Installation

1. Copy the `easystatemachine` folder into your Godot project under **`res://addons/easystatemachine/`**.
2. Open **Project → Project Settings → Plugins**.
3. Find **EasyStateMachine** in the list and toggle **Enable**.
4. Confirm activation in the Output panel:
   ```
   [EasyStateMachine v1.0.0] Plugin enabled.
   ```
5. The **`EasyStateMachine`** and **`EasyState`** node types are now available in the Add Node dialog.

No autoload is registered. No changes to `project.godot` beyond the plugin entry.

---

## 🚀 Quick start

### 1️⃣ Build the scene tree

Add **EasyStateMachine** as a direct child of your entity, then add one **EasyState** child node per state. The node name becomes the state identifier.

```
CharacterBody2D
├── CollisionShape2D
├── AnimatedSprite2D
└── EasyStateMachine        ← add this
    ├── IdleState            ← add EasyState nodes
    ├── RunState
    └── JumpState
```

### 2️⃣ Set the initial state

Select the **EasyStateMachine** node. The inspector panel shows a live **Initial State** dropdown populated from its `EasyState` children — pick the one your entity should start in.

### 3️⃣ Write your state scripts

Attach a script to each `EasyState` node. **Extend `EasyState`**, not `Node`, and override the hooks you need:

```gdscript
# idle_state.gd
extends EasyState

func _on_enter(previous_state: EasyState) -> void:
    host.get_node("AnimatedSprite2D").play("idle")

func _on_update(delta: float) -> void:
    if Input.get_axis("ui_left", "ui_right") != 0.0:
        transition_to("RunState")
    if Input.is_action_just_pressed("jump"):
        transition_to("JumpState")
```

```gdscript
# run_state.gd
extends EasyState

const SPEED := 220.0

func _on_physics_update(delta: float) -> void:
    var dir := Input.get_axis("ui_left", "ui_right")
    if dir == 0.0:
        transition_to("IdleState")
        return
    host.velocity.x = dir * SPEED
    host.move_and_slide()
```

### 4️⃣ Control the machine from your entity

```gdscript
# player.gd
extends CharacterBody2D

@onready var fsm: EasyStateMachine = $EasyStateMachine

func take_damage() -> void:
    fsm.transition_to("HurtState")

func open_pause() -> void:
    fsm.push_state("PauseMenuState")   # current state pauses, no _on_exit called

func close_pause() -> void:
    fsm.pop_state()                    # resumes previous state, no _on_enter called

func _ready() -> void:
    fsm.state_changed.connect(func(from, to):
        print("State: %s → %s" % [from, to])
    )
```

### 5️⃣ Enable debug logging

In the inspector, set **Config → Debug Enabled = true** and **Log Level = DEBUG** to trace every state transition in the Output panel:

```
[ESM|EasyStateMachine][DEBUG] Entered state: IdleState
[ESM|EasyStateMachine][DEBUG] Exited state: IdleState
[ESM|EasyStateMachine][DEBUG] Entered state: RunState
```

---

## 📚 Documentation

The **official documentation** is available as an interactive website with full navigation, EN / ES language toggle, and quick search:

**[EasyStateMachine Official Documentation](https://iuxgames.github.io/EasyStateMachine_WebSite/)**

The docs cover every node, property, signal, method, and lifecycle hook in detail, along with practical examples for 2D platformers, enemy AI, pause menus, advanced usage, and more.

---

## 🗂 Project layout

```text
addons/easystatemachine/
├── plugin.cfg                         Plugin metadata
├── plugin.gd                          EditorPlugin — inspector registration
├── icons/
│   ├── icon_easy_state_machine.svg    EasyStateMachine node icon
│   └── icon_easy_state.svg            EasyState node icon
├── core/
│   ├── sm_enums.gd                    SMEnums — TransitionMode, StateStatus, LogLevel
│   └── sm_events.gd                   SMEvents — internal per-instance signal bus
├── nodes/
│   ├── easy_state_machine.gd          EasyStateMachine — main controller node
│   ├── easy_state.gd                  EasyState — base class for all states
│   └── editor/
│       ├── sm_inspector_plugin.gd     EditorInspectorPlugin
│       └── sm_initial_state_picker.gd Initial State dropdown UI
├── config/
│   └── sm_config.gd                   SMConfig — serializable configuration resource
└── debug/
    └── sm_logger.gd                   SMLogger — contextual leveled logger
```

---

## 🙏 Credits

- **EasyStateMachine** — **IUX Games**, **Isaackiux** · version **1.0.0** (see [`plugin.cfg`](./plugin.cfg)).
- Built entirely in GDScript for Godot 4, with no external dependencies.
