--!nocheck
-- Stellar UI Library Test Suite
-- Comprehensive testing of all components and features

-- Load Stellar Library from GitHub with multiple fallback options
local Library
local success = false

-- First try: Load from GitHub master with cache-busting
local url = 'https://raw.githubusercontent.com/PureIsntHere/Stellar/master/Library.lua?cache=' .. tostring(math.random(1000000, 9999999))
success, Library = pcall(function()
    local code = game:HttpGet(url)
    if not code or code == "" then
        error("Failed to download from GitHub master")
    end
    local loadFunc = loadstring(code)
    if not loadFunc then
        error("Failed to compile downloaded code from master")
    end
    return loadFunc()
end)

-- Second try: Direct commit URL (most recent version)
if not success then
    local commitUrl = 'https://raw.githubusercontent.com/PureIsntHere/Stellar/6a2d7aa/Library.lua'
    success, Library = pcall(function()
        local code = game:HttpGet(commitUrl)
        if not code or code == "" then
            error("Failed to download from commit URL")
        end
        local loadFunc = loadstring(code)
        if not loadFunc then
            error("Failed to compile code from commit URL")
        end
        return loadFunc()
    end)
end

if not success then
    error("Failed to load Stellar Library from all GitHub sources: " .. tostring(Library))
end

if not Library then
    error("Stellar Library loaded but returned nil - likely a syntax error in Library.lua")
end

-- Show loading splash screen
local splash = Library:ShowLoadingSplash({
    Title = "STELLAR TEST SUITE",
    Footer = "Loading test environment..."
})

-- Simulate loading steps
task.wait(0.5)
splash:SetProgress(0.3, "Loading theme manager...")
task.wait(0.3)

-- Load ThemeManager
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/PureIsntHere/Stellar/master/ThemeManager.lua'))()()
ThemeManager:SetLibrary(Library)

splash:SetProgress(0.6, "Applying theme...")
task.wait(0.3)

-- Apply default theme
ThemeManager:SetTheme("Rose Pine")

splash:SetProgress(0.9, "Finalizing...")
task.wait(0.3)

splash:SetProgress(1, "Complete!")
task.wait(0.3)
splash:Close()

-- Request authorization
Library:RequestAuth({
    Title = "AUTHORIZATION REQUIRED",
    Subtitle = "Enter your access key to continue (use 'stellar' for demo)",
    ValidateKey = function(key)
        return key == "stellar" or key == "test123" or key == "demo"
    end,
    OnSuccess = function(key)
        Library:Notify({ Title = "Welcome!", Text = "Access granted - Starting test suite", Duration = 3 })
        CreateTestUI()
    end,
    OnFail = function(key)
        -- Auth failed, user can try again
    end
})

function CreateTestUI()
    local Window = Library:CreateWindow({ 
        Title = "Stellar Test Suite", 
        Size = Vector2.new(600, 400) 
    })

    -- Setup keybind to toggle GUI visibility
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            Window.ScreenGui.Enabled = not Window.ScreenGui.Enabled
        end
    end)

    -- Basic Controls Tab
    Window:AddTab("Basic Controls")
    Window:SelectTab("Basic Controls")
    
    Window:AddButton({
        Text = "Simple Button",
        Callback = function()
            Library:Notify({ Title = "Button Test", Text = "Simple button clicked!", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Notification Test",
        Callback = function()
            Library:Notify({ 
                Title = "Notification Test", 
                Text = "This is a test notification with longer text to see wrapping", 
                Duration = 4 
            })
        end
    })
    
    Window:AddToggle({
        Text = "Enable Feature A",
        Flag = "FeatureA",
        Value = false,
        Callback = function(value)
            Library:Notify({ 
                Title = "Toggle Changed", 
                Text = "Feature A is now " .. (value and "enabled" or "disabled"), 
                Duration = 2 
            })
        end
    })
    
    Window:AddToggle({
        Text = "Enable Feature B (Default On)",
        Flag = "FeatureB",
        Value = true,
        Callback = function(value)
            -- Feature B callback
        end
    })
    
    Window:AddSlider({
        Text = "Speed Multiplier",
        Flag = "SpeedMultiplier",
        Min = 0,
        Max = 100,
        Step = 1,
        Value = 50,
        Callback = function(value)
            -- Speed slider callback
        end
    })
    
    Window:AddSlider({
        Text = "Decimal Slider",
        Flag = "DecimalSlider",
        Min = 0,
        Max = 1,
        Step = 0.01,
        Value = 0.5,
        Callback = function(value)
            -- Decimal slider callback
        end
    })

    -- Text Inputs Tab
    Window:AddTab("Text Inputs")
    
    Window:AddTextbox({
        Text = "",
        Placeholder = "Enter your name...",
        Callback = function(text, enterPressed)
            if enterPressed and text ~= "" then
                Library:Notify({ Title = "Name Set", Text = "Your name is: " .. text, Duration = 3 })
            end
        end
    })
    
    Window:AddTextbox({
        Text = "",
        Placeholder = "Enter a number...",
        Callback = function(text, enterPressed)
            local num = tonumber(text)
            if enterPressed and num then
                Library:Notify({ Title = "Number", Text = "You entered: " .. num, Duration = 2 })
            end
        end
    })

    -- Dropdowns Tab
    Window:AddTab("Dropdowns")
    
    Window:AddDropdown({
        Text = "Select Weapon",
        Options = {"Sword", "Bow", "Staff", "Dagger", "Axe"},
        Value = "Sword",
        Callback = function(value)
            Library:Notify({ Title = "Weapon Changed", Text = "Selected: " .. value, Duration = 2 })
        end
    })
    
    Window:AddDropdown({
        Text = "Select Quality",
        Options = {"Low", "Medium", "High", "Ultra", "Extreme"},
        Value = "Medium",
        Callback = function(value)
            -- Quality dropdown callback
        end
    })

    -- Multi-Selection Dropdowns
    Window:AddMultiDropdown({
        Text = "Select Abilities",
        Options = {"Fire", "Ice", "Lightning", "Earth", "Wind", "Water", "Dark", "Light"},
        Values = {"Fire", "Ice"}, -- Pre-select multiple values
        MaxSelections = 3, -- Limit to 3 selections
        Callback = function(selectedValues)
            local count = #selectedValues
            local text = count == 0 and "No abilities selected" or count .. " abilities: " .. table.concat(selectedValues, ", ")
            Library:Notify({ 
                Title = "Abilities Updated", 
                Text = text, 
                Duration = 3 
            })
        end
    })

    Window:AddMultiDropdown({
        Text = "Choose Game Modes",
        Options = {"PvP", "PvE", "Survival", "Creative", "Hardcore", "Peaceful", "Adventure"},
        Values = {"PvE", "Creative"}, -- Pre-select some values
        Callback = function(selectedValues)
            local text = #selectedValues == 0 and "No modes selected" or "Active modes: " .. table.concat(selectedValues, ", ")
            print("Game Modes Changed:", text)
        end
    })

    Window:AddMultiDropdown({
        Text = "Select Features (Unlimited)",
        Options = {"Auto Farm", "Auto Sell", "Speed Boost", "Jump Boost", "Infinite Ammo", "God Mode", "Fly", "Noclip", "ESP", "Aimbot"},
        Values = {}, -- Start with nothing selected
        Callback = function(selectedValues)
            print("Features selected:", #selectedValues > 0 and table.concat(selectedValues, ", ") or "None")
        end
    })

    -- Hotkeys Tab
    Window:AddTab("Hotkeys")
    
    Window:AddButton({
        Text = "Hotkey System Info",
        Callback = function()
            Library:Notify({ 
                Title = "Hotkey Info", 
                Text = "Add hotkeys to toggles or buttons for keyboard shortcuts", 
                Duration = 4 
            })
        end
    })
    
    Window:AddHotkey({
        Text = "Toggle ESP (F1)",
        Value = Enum.KeyCode.F1,
        Callback = function(isActive)
            Library:Notify({ 
                Title = "ESP Hotkey", 
                Text = "Pressed - Active: " .. tostring(isActive), 
                Duration = 2 
            })
        end
    })
    
    Window:AddHotkey({
        Text = "Fly Mode (F2)",
        Value = Enum.KeyCode.F2,
        Callback = function(isActive)
            Library:Notify({ 
                Title = "Fly Mode", 
                Text = "Toggled: " .. tostring(isActive), 
                Duration = 2 
            })
        end
    })

    -- Themes Tab
    Window:AddTab("Themes")
    
    local themes = ThemeManager:ListThemes()
    
    Window:AddDropdown({
        Text = "Select Theme Preset",
        Options = themes,
        Value = "Rose Pine",
        Callback = function(themeName)
            local success, error = pcall(function()
                ThemeManager:SetTheme(themeName)
                Library:RefreshAll()
            end)
            
            if success then
                Library:Notify({ Title = "Theme Changed", Text = "Applied: " .. themeName, Duration = 2 })
            else
                Library:Notify({ 
                    Title = "Theme Error", 
                    Text = "Failed to apply " .. themeName .. ": " .. tostring(error), 
                    Duration = 4 
                })
                -- Fallback to Rose Pine if theme fails
                ThemeManager:SetTheme("Rose Pine")
                Library:RefreshAll()
            end
        end
    })
    
    Window:AddButton({
        Text = "Theme Customization Info",
        Callback = function()
            Library:Notify({ 
                Title = "Theme System", 
                Text = "Customize overlay colors, scrollbar appearance, and more below", 
                Duration = 4 
            })
        end
    })
    
    Window:AddSlider({
        Text = "Overlay Transparency",
        Flag = "OverlayTransparency",
        Min = 0,
        Max = 100,
        Step = 5,
        Value = 30,
        Callback = function(value)
            local transparency = value / 100
            Library.Theme.Overlays = Library.Theme.Overlays or {}
            Library.Theme.Overlays.Transparency = transparency
            Library:Notify({ 
                Title = "Overlay Updated", 
                Text = "Transparency: " .. value .. "% (reload splash/auth to see)", 
                Duration = 2 
            })
        end
    })
    
    Window:AddSlider({
        Text = "Scrollbar Thickness",
        Flag = "ScrollbarThickness",
        Min = 1,
        Max = 8,
        Step = 1,
        Value = 2,
        Callback = function(value)
            Library.Theme.Scrollbar = Library.Theme.Scrollbar or {}
            Library.Theme.Scrollbar.Thickness = value
            Library:RefreshAll()
            Library:Notify({ Title = "Scrollbar Updated", Text = "Thickness: " .. value .. "px", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Test Loading Splash",
        Callback = function()
            local testSplash = Library:ShowLoadingSplash({
                Title = "THEME TEST",
                Footer = "Testing overlay transparency..."
            })
            task.wait(0.5)
            testSplash:SetProgress(0.5, "Halfway there...")
            task.wait(0.5)
            testSplash:SetProgress(1, "Complete!")
            task.wait(0.3)
            testSplash:Close()
        end
    })

    -- Notifications Tab
    Window:AddTab("Notifications")
    
    local notifSettings = {
        Duration = 3,
        Position = "TopRight"
    }
    
    Window:AddSlider({
        Text = "Notification Duration",
        Flag = "NotifDuration",
        Min = 1,
        Max = 10,
        Step = 1,
        Value = 3,
        Callback = function(value)
            notifSettings.Duration = value
        end
    })
    
    Window:AddDropdown({
        Text = "Notification Position",
        Options = {"TopRight", "TopMiddle", "TopLeft", "RightMiddle", "BottomRight", "LeftMiddle", "BottomLeft", "BottomMiddle"},
        Value = "TopRight",
        Callback = function(value)
            notifSettings.Position = value
            Library:Notify({ 
                Title = "Position Changed", 
                Text = "Notifications will now appear at: " .. value, 
                Duration = notifSettings.Duration,
                Position = value
            })
        end
    })
    
    Window:AddButton({
        Text = "Test Notification",
        Callback = function()
            Library:Notify({ 
                Title = "Test", 
                Text = "Duration: " .. notifSettings.Duration .. "s | Position: " .. notifSettings.Position, 
                Duration = notifSettings.Duration,
                Position = notifSettings.Position
            })
        end
    })
    
    Window:AddButton({
        Text = "Long Text Notification",
        Callback = function()
            Library:Notify({ 
                Title = "Long Text Test", 
                Text = "This is a very long notification message to test text wrapping and display capabilities", 
                Duration = notifSettings.Duration,
                Position = notifSettings.Position
            })
        end
    })
    
    Window:AddButton({
        Text = "Test All Positions",
        Callback = function()
            local positions = {"TopRight", "TopMiddle", "TopLeft", "RightMiddle", "BottomRight", "LeftMiddle", "BottomLeft", "BottomMiddle"}
            for i, pos in ipairs(positions) do
                task.wait(0.5)
                Library:Notify({ 
                    Title = pos, 
                    Text = "Testing position " .. i .. " of " .. #positions, 
                    Duration = 2,
                    Position = pos
                })
            end
        end
    })

    -- Dock System Tab
    Window:AddTab("Dock System")
    
    Window:AddButton({
        Text = "Dock System Info",
        Callback = function()
            Library:Notify({ 
                Title = "Dock System (Enhanced!)", 
                Text = "Multiple dock modes available! Scale-based auto-dock, manual control, always on/off, and more!", 
                Duration = 4 
            })
        end
    })
    
    Window:AddButton({
        Text = "Set Mode: Manual",
        Callback = function()
            Window:SetDockMode("Manual")
            Library:Notify({ Title = "Manual Mode", Text = "User controls dock with ≡ button", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Set Mode: Scale Auto",
        Callback = function()
            Window:SetDockMode("Scale")
            Library:Notify({ 
                Title = "Scale Auto Mode", 
                Text = "Dock appears when window scale < 80%. Try resizing the window!", 
                Duration = 4 
            })
        end
    })
    
    Window:AddButton({
        Text = "Set Mode: Always On",
        Callback = function()
            Window:SetDockMode("AlwaysOn")
            Library:Notify({ Title = "Always On", Text = "Dock is now always visible", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Set Mode: Never Show",
        Callback = function()
            Window:SetDockMode("Never")
            Library:Notify({ Title = "Never Mode", Text = "Dock will never appear", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Set Mode: Dock + Top Bars",
        Callback = function()
            Window:SetDockMode("DockAndTop")
            Library:Notify({ 
                Title = "Dock + Top Mode", 
                Text = "Scale-based dock but keeps top tabs visible", 
                Duration = 3 
            })
        end
    })
    
    Window:AddButton({
        Text = "Toggle Dock Manually",
        Callback = function()
            Window:ToggleDock()
            Library:Notify({ Title = "Manual Toggle", Text = "Works in any mode for testing", Duration = 2 })
        end
    })

    Window:AddButton({
        Text = "Run Dock Persistence Smoke Test",
        Callback = function()
            local ok, err = pcall(function()
                -- Save original values (best-effort)
                local _origMode = Window._dockMode
                local _origSnapped = Window._dockSnapped
                local _origVisible = Window._dockVisible

                -- Set a deterministic state and save
                Window:SetDockMode("Manual")
                pcall(function() Window:_setDockSnapped(true) end)
                if not Window._dockVisible then Window:ToggleDock() end
                pcall(function() if Window._saveDockState then Window:_saveDockState() end end)

                -- Mutate state then reload from disk
                Window._dockSnapped = not Window._dockSnapped
                Window._dockVisible = not Window._dockVisible
                pcall(function() if Window._loadDockState then Window:_loadDockState() end end)

                -- Verify
                local pass = (Window._dockMode == "Manual") and (Window._dockSnapped == true)
                Library:Notify({ Title = "Dock Persistence Test", Text = pass and "PASS" or "FAIL", Duration = 4 })
            end)
            if not ok then
                Library:Notify({ Title = "Dock Persistence Test", Text = "ERROR: " .. tostring(err), Duration = 6 })
            end
        end
    })

    Window:AddSlider({
        Text = "Scale Threshold",
        Flag = "DockThreshold",
        Min = 50,
        Max = 100,
        Step = 5,
        Value = 80,
        Callback = function(value)
            Window:SetDockThreshold(value / 100) -- Convert to 0-1 scale
            Library:Notify({ 
                Title = "Scale Threshold", 
                Text = "Dock appears when window scale < " .. value .. "%", 
                Duration = 3 
            })
        end
    })

    -- Announcements Tab
    Window:AddTab("Announcements")
    
    Window:AddButton({
        Text = "Simple Announcement",
        Callback = function()
            Library:ShowAnnouncement({
                Title = "IMPORTANT",
                Message = "This is a simple announcement with a single button.",
                Buttons = {
                    {Text = "OK", Primary = true}
                }
            })
        end
    })
    
    Window:AddButton({
        Text = "Two Button Announcement",
        Callback = function()
            Library:ShowAnnouncement({
                Title = "CONFIRMATION",
                Message = "Do you want to proceed with this action? This change cannot be undone.",
                Buttons = {
                    {Text = "Cancel", Primary = false},
                    {Text = "Proceed", Primary = true, Callback = function()
                        Library:Notify({ Title = "Confirmed", Text = "Action confirmed!", Duration = 2 })
                    end}
                }
            })
        end
    })
    
    Window:AddButton({
        Text = "Long Message Announcement",
        Callback = function()
            Library:ShowAnnouncement({
                Title = "UPDATE NOTES",
                Message = "Version 2.6.0 is now available!\n\nNew Features:\n• Enhanced theme system with 17+ themes\n• Completely redesigned dock system\n• Improved error handling and stability\n• Better content positioning and animations\n• Fixed dock behavior issues\n\nThank you for using Stellar UI!",
                Buttons = {
                    {Text = "Got it!", Primary = true}
                }
            })
        end
    })

    -- FX Effects Tab
    Window:AddTab("FX Effects")
    
    Window:AddButton({
        Text = "Enable Window Scanlines",
        Callback = function()
            Library.Theme.EnableScanlines = true
            Library:RefreshAll()
            Library:Notify({ Title = "FX", Text = "Window scanlines enabled!", Duration = 3 })
        end
    })
    
    Window:AddButton({
        Text = "Enable Window Grid Background",
        Callback = function()
            Library.Theme.EnableGridBG = true
            Library:RefreshAll()
            Library:Notify({ Title = "FX", Text = "Window grid background enabled!", Duration = 3 })
        end
    })
    
    Window:AddButton({
        Text = "Disable All Window FX",
        Callback = function()
            Library.Theme.EnableScanlines = false
            Library.Theme.EnableTopSweep = false
            Library.Theme.EnableGridBG = false
            Library:RefreshAll()
            Library:Notify({ Title = "FX", Text = "All window FX disabled", Duration = 2 })
        end
    })
    
    Window:AddButton({
        Text = "Test Notification with FX",
        Callback = function()
            Library:Notify({ 
                Title = "FX Notification", 
                Text = "This notification has scanline effects!", 
                Duration = 4,
                FX = {
                    Scanlines = {
                        Color = Color3.fromRGB(255, 0, 255),
                        Speed = 80
                    }
                }
            })
        end
    })

    -- System Info Tab
    Window:AddTab("System Info")
    
    Window:AddButton({
        Text = "Show Library Version",
        Callback = function()
            Library:Notify({ 
                Title = "Stellar Library", 
                Text = "Version: " .. Library.Core.Version, 
                Duration = 3 
            })
        end
    })
    
    Window:AddButton({
        Text = "Print Debug Info (Console)",
        Callback = function()
            print("=== STELLAR DEBUG INFO ===")
            print("Version:", Library.Core.Version)
            print("Total Windows:", #Library.Windows)
            print("Total Components:", #Window._components)
            print("Current Tab:", Window._currentTab and Window._currentTab.Name or "None")
            print("==========================")
            Library:Notify({ 
                Title = "Debug Info", 
                Text = "Check console for detailed information", 
                Duration = 2 
            })
        end
    })
    
    Window:AddButton({
        Text = "Test All Themes (Cycle)",
        Callback = function()
            local themes = ThemeManager:ListThemes()
            local currentIndex = 1
            
            local function cycleTheme()
                if currentIndex <= #themes then
                    local themeName = themes[currentIndex]
                    local success, _error = pcall(function()
                        ThemeManager:SetTheme(themeName)
                        Library:RefreshAll()
                    end)
                    
                    if success then
                        Library:Notify({ 
                            Title = "Theme " .. currentIndex .. "/" .. #themes, 
                            Text = themeName, 
                            Duration = 1.5 
                        })
                    else
                        Library:Notify({ 
                            Title = "Theme Error " .. currentIndex .. "/" .. #themes, 
                            Text = themeName .. " failed", 
                            Duration = 1.5 
                        })
                    end
                    
                    currentIndex = currentIndex + 1
                    task.wait(1.5)
                    cycleTheme()
                else
                    ThemeManager:SetTheme("Rose Pine")
                    Library:RefreshAll()
                    Library:Notify({ 
                        Title = "Theme Test Complete", 
                        Text = "Reset to Rose Pine", 
                        Duration = 2 
                    })
                end
            end
            
            cycleTheme()
        end
    })
    
    Window:AddButton({
        Text = "Create Dynamic Window",
        Callback = function()
            local testWindow = Library:CreateWindow({
                Title = "Dynamic Test Window",
                Size = Vector2.new(400, 300)
            })
            testWindow:AddTab("Test")
            testWindow:SelectTab("Test")
            testWindow:AddButton({
                Text = "Dynamic Window Created!",
                Callback = function()
                    Library:Notify({ Title = "Success", Text = "Dynamic window works!", Duration = 2 })
                end
            })
            testWindow:AddButton({
                Text = "Destroy This Window",
                Callback = function()
                    Library:Notify({ Title = "Window Destroyed", Text = "Dynamic window will close in 1 second", Duration = 1 })
                    task.wait(1)
                    testWindow:Destroy()
                end
            })
            Library:Notify({ Title = "Window Created", Text = "Check for new window with destroy button!", Duration = 3 })
        end
    })

    -- Switch back to first tab
    Window:SelectTab("Basic Controls")

    Library:Notify({ 
        Title = "Test Suite Ready", 
        Text = "All features loaded - 10 tabs with comprehensive examples!", 
        Duration = 3 
    })
end