<div align="center">

<img width="120" height="120" alt="Stellar Logo" src="https://github.com/user-attachments/assets/552ef40e-c287-43da-b938-6d3ee2f7ca35" />

# Stellar UI Library

*A pretty cool UI library*

<img width="800" alt="Stellar Collage" src="https://github.com/user-attachments/assets/90849041-9cb4-48d1-b811-cc6077c2acae" />

[Documentation](../../wiki) • [API Reference](../../wiki/API-Reference) • [Examples](../../wiki/Examples)

</div>

---

## Features

**UI Components** — Toggles, sliders, dropdowns, buttons, text inputs, hotkeys  
**Themes** — 17+ built-in themes with runtime switching  
**Visual Effects** — Scanlines, grids, sweep animations  
**Notifications** — 8 position options with customizable effects  
**Mobile Support** — Responsive dock system  
**Configuration** — Auto-save settings across sessions

## Quick Start

```lua
local Library = loadstring(game:HttpGet(
    'https://raw.githubusercontent.com/PureIsntHere/Stellar/master/Library.lua'
))()

local Window = Library:CreateWindow({
    Title = "My Script",
    Size = Vector2.new(600, 400)
})

Window:AddTab("Main")
Window:SelectTab("Main")

Window:AddToggle({
    Text = "Enable Feature",
    Value = false,
    Callback = function(value)
        print("Feature:", value)
    end
})

Window:AddButton({
    Text = "Activate",
    Callback = function()
        Library:Notify({Title = "Success", Text = "Activated!", Duration = 2})
    end
})
```

## Themes

```lua
local ThemeManager = loadstring(game:HttpGet(
    'https://raw.githubusercontent.com/PureIsntHere/Stellar/master/ThemeManager.lua'
))()()

ThemeManager:SetLibrary(Library)
ThemeManager:SetTheme("Tokyo Night")
```

**Available:** Tokyo Night • Dracula • Nord • Monokai • Gruvbox • Catppuccin • Rose Pine • One Dark • Material • Ayu • Solarized • GitHub Dark • Cyberpunk • Synthwave • Oceanic • Everforest • October

## Documentation

**[View Full Documentation](../../wiki)**

[Installation](../../wiki/Installation) • [Your First Window](../../wiki/Your-First-Window) • [Component System](../../wiki/Component-System) • [Theme System](../../wiki/Theme-System) • [Visual Effects](../../wiki/Visual-Effects) • [Configuration System](../../wiki/Configuration-System)

## License
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
---
