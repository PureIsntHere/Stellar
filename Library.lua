--!nocheck
-- Stellar UI Library v2.5.1
-- Single-file Roblox UI library with Linoria-style API

-- Core module
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

-- Cached commonly-used TweenInfo instances to avoid reallocations
local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local _TWEEN_QUICK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local _TWEEN_LINEAR = TweenInfo.new(0.3, Enum.EasingStyle.Linear)

local Core = {
    Version = "2.6.6",
    Debug = false
}

Core.Theme = {
    -- Rose Pine default theme
    Background = Color3.fromRGB(25, 23, 36),      -- #191724
    Background2 = Color3.fromRGB(31, 29, 46),     -- #1F1D2E
    Background3 = Color3.fromRGB(27, 25, 40),     -- darker variant of bg2
    TextColor = Color3.fromRGB(224, 222, 244),    -- #E0DEF4
    SubTextColor = Color3.fromRGB(144, 140, 170), -- #908CAA
    DisabledText = Color3.fromRGB(128, 124, 155), -- sub, slightly dimmer
    Accent = Color3.fromRGB(196, 167, 231),       -- #C4A7E7
    AccentDim = Color3.fromRGB(127, 109, 150),    -- darkened accent
    Border = Color3.fromRGB(38, 35, 58),          -- #26233A

    -- Global scrollbar defaults
    Scrollbar = {
        Color = Color3.fromRGB(96, 98, 104),
        Thickness = 2,
    },

    -- Global overlay defaults for splash/auth modals
    Overlays = {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.3,
    },

    Rounding = 6,
    Padding = 6,
    LineThickness = 1,

    Font = Enum.Font.Gotham,
    FontMono = Enum.Font.Code,

    EnableScanlines = false,
    EnableTopSweep = false,
    EnableBrackets = true,
    EnableGridBG = false,

    Window = {
        Background = Color3.fromRGB(25, 23, 36),
        TitleText = Color3.fromRGB(224, 222, 244),
        SubtitleText = Color3.fromRGB(144, 140, 170),
        Border = Color3.fromRGB(38, 35, 58),
        CornerBrackets = Color3.fromRGB(84, 80, 112),
    },

    Tab = {
        IdleFill = Color3.fromRGB(31, 29, 46),
        ActiveFill = Color3.fromRGB(25, 23, 36),
        IdleText = Color3.fromRGB(144, 140, 170),
        ActiveText = Color3.fromRGB(224, 222, 244),
        Border = Color3.fromRGB(38, 35, 58),
        PillHeight = 22,
        Uppercase = false,
    },

    FX = {
        PulseBase = 0.45,
        PulseAmp = 0.35,
        PulseHz = 1.6,

        CornerBrackets = Color3.fromRGB(84, 80, 112),
        CornerBracketThickness = 1,

        ScanlineColor = Color3.fromRGB(224, 222, 244),
        ScanlineTransparency = 0.85,
        ScanlineSpeed = 60,

        TopSweepColor = Color3.fromRGB(84, 80, 112),
        TopSweepThickness = 2,
        TopSweepSpeed = 180,
        TopSweepGap = 24,
        TopSweepLength = 120,

        GridColor = Color3.fromRGB(38, 35, 58),
        GridAlpha = 0.06,
        GridGap = 16,
    }
}

Core.Config = {
    new = function(options)
        local self = setmetatable({}, {__index = Core.Config})
        local opts = options or {}
        self._configFolder = opts.folder or "StellarConfigs"
        self._configFile = opts.filename or "settings.json"
        self._configName = opts.name or "StellarConfig"
        self._fullPath = self._configFolder .. "/" .. self._configFile
        self._data = Core.Safety.createSecureConfigTable()
        self._isExecutor = Core.Safety.isExecutor()
        self:Load()
        return self
    end,
    Set = function(self, key, value)
        self._data[key] = value
        self._needsSave = true
    end,
    Get = function(self, key, default)
        local val = self._data[key]
        if val == nil then return default end
        return val
    end,
    Save = function(self)
        if self._isExecutor then
            return self:_saveToFile()
        end
        return false
    end,
    Load = function(self)
        if self._isExecutor then
            return self:_loadFromFile()
        end
        return false
    end,
    _saveToFile = function(self)
        if not self._needsSave then return true end
        
        local success, error = pcall(function()
            -- Ensure the config folder exists
            if not isfolder(self._configFolder) then
                makefolder(self._configFolder)
            end
            
            -- Convert data to JSON and write to file
            local httpService = game:GetService("HttpService")
            local jsonData = httpService:JSONEncode(self._data)
            writefile(self._fullPath, jsonData)
            self._needsSave = false
        end)
        
        if not success then
            if Core.Debug then
                local executorInfo = Core.Safety.getExecutorInfo()
                warn("Stellar Config Save Error:", error)
                warn("Executor:", executorInfo.name, "v" .. executorInfo.version)
            end
            return false, error
        end
        
        return true
    end,
    _loadFromFile = function(self)
        local success, result = pcall(function()
            -- Check if file exists
            if not isfile(self._fullPath) then
                return {} -- Return empty data if file doesn't exist
            end
            
            -- Read and parse JSON data
            local fileContent = readfile(self._fullPath)
            if not fileContent or fileContent == "" then
                return {}
            end
            
            local httpService = game:GetService("HttpService")
            return httpService:JSONDecode(fileContent)
        end)
        
        if success then
            -- Create a new secure table and transfer the loaded data
            local secureData = Core.Safety.createSecureConfigTable()
            if result then
                for key, value in pairs(result) do
                    secureData[key] = value
                end
            end
            self._data = secureData
            return true
        else
            if Core.Debug then
                local executorInfo = Core.Safety.getExecutorInfo()
                warn("Stellar Config Load Error:", result)
                warn("Executor:", executorInfo.name, "v" .. executorInfo.version)
            end
            self._data = Core.Safety.createSecureConfigTable()
            return false, result
        end
    end,
}

Core.Safety = {
    isExecutor = function()
        -- Check for essential filesystem functions directly
        -- Modern executors hide functions from _G for security/anti-detection
        local hasReadFile = typeof(readfile) == "function"
        local hasWriteFile = typeof(writefile) == "function"
        local hasIsFile = typeof(isfile) == "function"
        local hasIsFolder = typeof(isfolder) == "function"
        local hasMakeFolder = typeof(makefolder) == "function"
        
        return hasReadFile and hasWriteFile and hasIsFile and hasIsFolder and hasMakeFolder
    end,
    hasSecureTable = function()
        return typeof(newtable) == "function"
    end,
    createSecureTable = function(arraySize, hashSize)
        -- Create a table with hidden memory for security
        -- Benefits: Helps obfuscate data from memory scanning tools
        -- Recommended for storing sensitive information like tokens, configs, etc.
        if typeof(newtable) == "function" then
            -- Use recommended minimum sizes for effective memory hiding
            local narray = math.max(arraySize or 33, 33)
            local nhash = math.max(hashSize or 17, 17)
            return newtable(narray, nhash)
        else
            -- Fallback to regular table if newtable not available
            return {}
        end
    end,
    createSecureConfigTable = function()
        -- Create a secure table specifically for configuration data
        -- Uses larger sizes to better hide config values
        return Core.Safety.createSecureTable(50, 25)
    end,
    getExecutorInfo = function()
        -- Get executor information if available (check directly)
        if typeof(identifyexecutor) == "function" then
            local success, name, version = pcall(identifyexecutor)
            if success and name then
                return {
                    name = name or "Unknown",
                    version = version or "Unknown",
                    identified = true
                }
            end
        end
        
        -- Fallback - try to identify based on available globals
        -- Check direct globals (modern executors don't expose via _G)
        local executorName = "Unknown"
        
        -- Desktop Executors
        if SynapseZ then
            executorName = "Synapse Z"
        elseif Xeno then
            executorName = "Xeno"
        elseif Wave then
            executorName = "Wave"
        elseif Ronix then
            executorName = "Ronix"
        elseif Zenith then
            executorName = "Zenith"
        elseif Swift then
            executorName = "Swift"
        elseif Volcano then
            executorName = "Volcano"
        
        -- Mobile Executors (iOS/Android)
        elseif Arceus then
            executorName = "Arceus"
        elseif Codex then
            executorName = "Codex"
        elseif KRNL_LOADED then
            executorName = "Krnl"
        elseif VegaX or Vega_X then
            executorName = "Vega X"
        elseif Delta or DELTA then
            executorName = "Delta"
        
        -- Generic fallback checks
        elseif request then
            executorName = "Generic Executor"
        end
        
        return {
            name = executorName,
            version = "Unknown",
            identified = false
        }
    end,
    GetRoot = function()
        -- Check for gethui directly (modern executors don't expose via _G)
        local hiddenUI
        if typeof(gethui) == "function" then
            local ok, res = pcall(gethui)
            if ok then hiddenUI = res end
        end
        if hiddenUI then return hiddenUI end
        return game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end,
    ProtectInstance = function(inst)
        local synGlobal = rawget(_G, "syn")
        if synGlobal and synGlobal.protect_gui then
            synGlobal.protect_gui(inst)
        else
            local protect = rawget(_G, "protect_gui")
            if protect then protect(inst) end
        end
    end,
    RandomString = function(length)
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local str = ""
        for i = 1, length or 8 do
            local rand = math.random(1, #chars)
            str = str .. string.sub(chars, rand, rand)
        end
        return str
    end,
}

Core.FX = {
    CreateScanlines = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "Scanlines"
        holder.Size = UDim2.fromScale(1, 1)
        holder.BackgroundTransparency = 1
        holder.ClipsDescendants = true
        holder.Parent = parent

        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(1, 0, 0, 2)
        line.BackgroundColor3 = theme.FX.ScanlineColor
        line.BackgroundTransparency = theme.FX.ScanlineTransparency
        line.BorderSizePixel = 0
        line.Parent = holder

        local running = true
        task.spawn(function()
            while running and holder.Parent do
                local speed = theme.FX.ScanlineSpeed
                local height = holder.AbsoluteSize.Y
                local duration = height / speed
                line.Position = UDim2.fromOffset(0, -2)
                local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(line, tweenInfo, {Position = UDim2.fromOffset(0, height)})
                tween:Play()
                task.wait(duration)
            end
        end)

        return {
            Destroy = function()
                running = false
                holder:Destroy()
            end
        }
    end,

    CreateTopSweep = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "TopSweep"
        holder.Size = UDim2.new(1, 0, 0, theme.FX.TopSweepThickness)
        holder.Position = UDim2.fromOffset(0, 0)
        holder.BackgroundTransparency = 1
        holder.ClipsDescendants = true
        holder.Parent = parent

        local sweep = Instance.new("Frame")
        sweep.Name = "Sweep"
        sweep.Size = UDim2.new(0, theme.FX.TopSweepLength, 1, 0)
        sweep.BackgroundColor3 = theme.FX.TopSweepColor
        sweep.BackgroundTransparency = 0.7
        sweep.BorderSizePixel = 0
        sweep.Parent = holder

        local gradient = Instance.new("UIGradient")
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.5),
            NumberSequenceKeypoint.new(0.5, 0.25),
            NumberSequenceKeypoint.new(0.8, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        gradient.Parent = sweep

        local running = true
        task.spawn(function()
            while running and holder.Parent do
                local width = holder.AbsoluteSize.X
                local speed = theme.FX.TopSweepSpeed
                local duration = (width + theme.FX.TopSweepLength) / speed
                sweep.Position = UDim2.new(0, -theme.FX.TopSweepLength, 0, 0)
                local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(sweep, tweenInfo, {Position = UDim2.new(0, width, 0, 0)})
                tween:Play()
                task.wait(duration + theme.FX.TopSweepGap / speed)
            end
        end)

        return {
            Destroy = function()
                running = false
                holder:Destroy()
            end
        }
    end,

    CreateGrid = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "GridBackground"
        holder.Size = UDim2.fromScale(1, 1)
        holder.BackgroundTransparency = 1
        holder.ZIndex = -1
        holder.Parent = parent

        local verticals = Instance.new("Frame")
        verticals.Name = "VerticalLines"
        verticals.Size = UDim2.fromScale(1, 1)
        verticals.BackgroundTransparency = 1
        verticals.Parent = holder

        local vPattern = Instance.new("Frame")
        vPattern.Name = "Pattern"
        vPattern.Size = UDim2.new(0, 1, 1, 0)
        vPattern.BackgroundColor3 = theme.FX.GridColor
        vPattern.BackgroundTransparency = 1 - theme.FX.GridAlpha
        vPattern.BorderSizePixel = 0

        local horizontals = Instance.new("Frame")
        horizontals.Name = "HorizontalLines"
        horizontals.Size = UDim2.fromScale(1, 1)
        horizontals.BackgroundTransparency = 1
        horizontals.Parent = holder

        local hPattern = Instance.new("Frame")
        hPattern.Name = "Pattern"
        hPattern.Size = UDim2.new(1, 0, 0, 1)
        hPattern.BackgroundColor3 = theme.FX.GridColor
        hPattern.BackgroundTransparency = 1 - theme.FX.GridAlpha
        hPattern.BorderSizePixel = 0

        local _pending = false
        local function performUpdate()
            -- Clear existing lines
            for _, child in pairs(verticals:GetChildren()) do child:Destroy() end
            for _, child in pairs(horizontals:GetChildren()) do child:Destroy() end
            local width = holder.AbsoluteSize.X
            local height = holder.AbsoluteSize.Y
            local gap = theme.FX.GridGap
            for x = gap, width, gap do
                local line = vPattern:Clone()
                line.Position = UDim2.fromOffset(x, 0)
                line.Parent = verticals
            end
            for y = gap, height, gap do
                local line = hPattern:Clone()
                line.Position = UDim2.fromOffset(0, y)
                line.Parent = horizontals
            end
        end

        local function scheduleUpdate()
            if _pending then return end
            _pending = true
            task.defer(function()
                _pending = false
                if holder.Parent then performUpdate() end
            end)
        end

        local connection = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleUpdate)
        performUpdate()
        return {
            Destroy = function()
                connection:Disconnect()
                holder:Destroy()
            end,
            Update = performUpdate
        }
    end,

    -- Apply FX to any element with custom configuration
    Apply = function(element, fxConfig, theme)
        if not fxConfig then return {} end
        
        local effects = {}
        
        -- Apply scanlines if enabled
        if fxConfig.Scanlines then
            local config = type(fxConfig.Scanlines) == "table" and fxConfig.Scanlines or {}
            local fxTheme = {
                FX = {
                    ScanlineColor = config.Color or theme.FX.ScanlineColor,
                    ScanlineTransparency = config.Transparency or theme.FX.ScanlineTransparency,
                    ScanlineSpeed = config.Speed or theme.FX.ScanlineSpeed
                }
            }
            effects.scanlines = Core.FX.CreateScanlines(element, fxTheme)
        end
        
        -- Apply top sweep if enabled
        if fxConfig.TopSweep then
            local config = type(fxConfig.TopSweep) == "table" and fxConfig.TopSweep or {}
            local fxTheme = {
                FX = {
                    TopSweepThickness = config.Thickness or theme.FX.TopSweepThickness,
                    TopSweepLength = config.Length or theme.FX.TopSweepLength,
                    TopSweepColor = config.Color or theme.FX.TopSweepColor,
                    TopSweepSpeed = config.Speed or theme.FX.TopSweepSpeed,
                    TopSweepGap = config.Gap or theme.FX.TopSweepGap
                }
            }
            effects.topsweep = Core.FX.CreateTopSweep(element, fxTheme)
        end
        
        -- Apply grid background if enabled
        if fxConfig.Grid then
            local config = type(fxConfig.Grid) == "table" and fxConfig.Grid or {}
            local fxTheme = {
                FX = {
                    GridColor = config.Color or theme.FX.GridColor,
                    GridAlpha = config.Alpha or theme.FX.GridAlpha,
                    GridGap = config.Gap or theme.FX.GridGap
                }
            }
            effects.grid = Core.FX.CreateGrid(element, fxTheme)
        end
        
        return effects
    end,
}

Core.Behaviors = {
    MakeDraggable = function(handle, frame)
    local UserInputService = UserInputService
        local dragging = false
        local dragStart, frameStart
        local connections = {}

        table.insert(connections, handle.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                dragging = true
                dragStart = Core.Util.GetInputPosition(input)
                frameStart = frame.Position
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and Core.Util.IsTouchMovement(input.UserInputType) then
                local currentPos = Core.Util.GetInputPosition(input)
                local delta = currentPos - dragStart
                frame.Position = UDim2.new(
                    frameStart.X.Scale, 
                    frameStart.X.Offset + delta.X, 
                    frameStart.Y.Scale, 
                    frameStart.Y.Offset + delta.Y
                )
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then 
                dragging = false 
            end
        end))

        return {
            Destroy = function()
                for _, c in ipairs(connections) do
                    pcall(function() c:Disconnect() end)
                end
            end
        }
    end,

    AddResizeGrip = function(frame, theme, minSize, maxSize)
        minSize = minSize or Vector2.new(200, 150)
        maxSize = maxSize or Vector2.new(math.huge, math.huge)
    local UserInputService = UserInputService
        
        local grip = Instance.new("TextButton")
        grip.Name = "ResizeGrip"
        grip.Size = UDim2.fromOffset(20, 20)
        grip.Position = UDim2.fromScale(1, 1)
        grip.AnchorPoint = Vector2.new(1, 1)
        grip.Text = ""
        grip.BackgroundTransparency = 1
        grip.Parent = frame
        grip.ZIndex = 100
        
        local indicators = Instance.new("Frame")
        indicators.Name = "Indicators"
        indicators.Size = UDim2.fromOffset(12, 12)
        indicators.Position = UDim2.fromScale(0.5, 0.5)
        indicators.AnchorPoint = Vector2.new(0.5, 0.5)
        indicators.BackgroundTransparency = 1
        indicators.ZIndex = 101
        indicators.Parent = grip
        
        for i = 1, 4 do
            for j = 1, 4-i do
                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.Size = UDim2.fromOffset(2, 2)
                dot.Position = UDim2.fromOffset(j * 3, i * 3)
                dot.BorderSizePixel = 0
                -- Enhanced initial color selection with better fallback
                local initialColor
                if theme and theme.Accent then
                    initialColor = theme.Accent
                elseif theme and theme.TextColor then
                    initialColor = theme.TextColor
                else
                    initialColor = Color3.fromRGB(150, 150, 150)
                end
                dot.BackgroundColor3 = initialColor
                dot.BackgroundTransparency = 0.3  -- More visible default
                dot.ZIndex = 102
                dot.Parent = indicators
            end
        end
        
        local resizing = false
        local startPos, startSize
        local connections = {}

        -- Support both mouse and touch input
        table.insert(connections, grip.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                resizing = true
                startPos = Core.Util.GetInputPosition(input)
                startSize = frame.AbsoluteSize
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if resizing and Core.Util.IsTouchMovement(input.UserInputType) then
                local currentPos = Core.Util.GetInputPosition(input)
                local delta = currentPos - startPos
                local newSize = Vector2.new(
                    math.clamp(startSize.X + delta.X, minSize.X, maxSize.X), 
                    math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
                )
                frame.Size = UDim2.fromOffset(newSize.X, newSize.Y)
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) and resizing then
                resizing = false
            end
        end))
        
        table.insert(connections, grip.MouseEnter:Connect(function()
            for _, dot in ipairs(indicators:GetChildren()) do
                TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            end
        end)
        )

        table.insert(connections, grip.MouseLeave:Connect(function()
            if not resizing then
                for _, dot in ipairs(indicators:GetChildren()) do
                    TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
                end
            end
        end))
        
        return {
            Grip = grip,
            SetMinSize = function(size) minSize = size end,
            SetMaxSize = function(size) maxSize = size end,
            Destroy = function()
                -- Disconnect input connections and destroy grip
                for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
                if grip and grip.Parent then grip:Destroy() end
            end,
            UpdateColors = function(newTheme)
                for _, dot in ipairs(indicators:GetChildren()) do
                    if dot.Name == "Dot" then
                        -- Enhanced safety check with better fallback logic
                        local accentColor
                        if newTheme and newTheme.Accent then
                            accentColor = newTheme.Accent
                        elseif newTheme and newTheme.TextColor then
                            accentColor = newTheme.TextColor -- Fallback to text color
                        else
                            accentColor = Color3.fromRGB(150, 150, 150) -- Neutral gray fallback
                        end
                        
                        -- Ensure the color is actually a Color3
                        if typeof(accentColor) == "Color3" then
                            dot.BackgroundColor3 = accentColor
                        else
                            dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        }
    end,
}

Core.Util = {
    Create = function(className, properties)
        local inst = Instance.new(className)
        for k, v in pairs(properties or {}) do
            inst[k] = v
        end
        return inst
    end,
    Tween = function(object, properties, duration, style, direction)
        local info
        if not duration and not style and not direction then
            info = TWEEN_FAST
        else
            info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
        end
        local tween = TweenService:Create(object, info, properties)
        tween:Play()
        return tween
    end,
    ColorToHex = function(color)
        return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
    end,
    HexToColor = function(hex)
        hex = hex:gsub("#", "")
        return Color3.fromRGB(tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16))
    end,
    -- Mobile detection and input helpers
    IsMobile = function()
        local UIS = game:GetService("UserInputService")
        return UIS.TouchEnabled and not UIS.KeyboardEnabled
    end,
    IsTouch = function(inputType)
        return inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1
    end,
    IsTouchMovement = function(inputType)
        return inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseMovement
    end,
    GetInputPosition = function(input)
        -- Returns position for both mouse and touch inputs
        if input.UserInputType == Enum.UserInputType.Touch then
            return input.Position
        else
            return game:GetService("UserInputService"):GetMouseLocation()
        end
    end,
}

-- UI module
local function BuildUI(Theme)
    local UI = { Version = "2.6.0" }
    local TweenService = game:GetService("TweenService")

    -- BaseComponent
    local BaseComponent = {}
    BaseComponent.__index = BaseComponent
    function BaseComponent.new(props)
        local self = setmetatable({}, BaseComponent)
        self.Name = props.Name or "Component"
        self._theme = props.Theme or Theme or Core.Theme
        self._visible = true
        self._destroyed = false
        -- generic connection tracker for any RBXScriptConnection stored on the object
        self._connections = {}
        return self
    end
    function BaseComponent:_track(conn)
        if not conn then return end
        if not self._connections then self._connections = {} end
        table.insert(self._connections, conn)
        return conn
    end

    function BaseComponent:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        -- Disconnect any tracked connections
        if self._connections then
            for _, c in ipairs(self._connections) do
                pcall(function() if c and c.Disconnect then c:Disconnect() end end)
            end
            self._connections = nil
        end
        if self.Root then self.Root:Destroy() end
        if self._fx then for _, effect in pairs(self._fx) do effect:Destroy() end end
    end
    function BaseComponent:SetVisible(visible)
        self._visible = visible
        if self.Root then self.Root.Visible = visible end
    end
    function BaseComponent:RefreshTheme() end

    -- Window
    local Window = setmetatable({}, {__index = BaseComponent})
    Window.__index = Window
    function Window.new(props)
        local self = BaseComponent.new({ Name = "Window", Theme = props.Theme or Theme })
        setmetatable(self, Window)
        self._components = {}
        
        -- Store dock configuration options
        self._configDockThreshold = props.DockThreshold  -- Optional: custom threshold
        self._configDockWidth = props.DockWidth          -- Optional: custom dock width
        
        -- Create ScreenGui container
        self.ScreenGui = Core.Util.Create("ScreenGui", {
            Name = "StellarUI_" .. Core.Safety.RandomString(8),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = Core.Safety.GetRoot()
        })
        Core.Safety.ProtectInstance(self.ScreenGui)
        
        self.Root = Core.Util.Create("Frame", {
            Name = "Window",
            Size = UDim2.fromOffset(props.Width or (props.Size and props.Size.X) or 800, props.Height or (props.Size and props.Size.Y) or 500),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = self._theme.Window.Background,
            BorderSizePixel = 0,
            Parent = self.ScreenGui
        })
        self:_createTitleBar(props.Title, props.SubTitle)
        self:_createContentArea()
        self._fx = {}
        if self._theme.EnableScanlines then self._fx.scanlines = Core.FX.CreateScanlines(self.Root, self._theme) end
        if self._theme.EnableTopSweep then self._fx.topsweep = Core.FX.CreateTopSweep(self.Root, self._theme) end
        if self._theme.EnableGridBG then self._fx.grid = Core.FX.CreateGrid(self.Root, self._theme) end
        
        -- Add resize grip
        self._resizeGrip = Core.Behaviors.AddResizeGrip(
            self.Root, 
            self._theme, 
            Vector2.new(300, 200),  -- Min size
            Vector2.new(1200, 800)  -- Max size
        )
        
    self._titleDrag = Core.Behaviors.MakeDraggable(self.TitleBar, self.Root)
        
        if Core.Debug then
            print("[Stellar] Window created:", props.Title or "Untitled", "Parent:", self.ScreenGui.Parent:GetFullName())
        end
        
        return self
    end
    function Window:_createTitleBar(title, subtitle)
        self.TitleBar = Core.Util.Create("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = self._theme.Window.Background,
            Parent = self.Root
        })
        self.Title = Core.Util.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = title or "Window",
            TextColor3 = self._theme.Window.TitleText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = self._theme.Font,
            TextSize = 14,
            Parent = self.TitleBar
        })
        if subtitle then
            self.Subtitle = Core.Util.Create("TextLabel", {
                Name = "Subtitle",
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = subtitle,
                TextColor3 = self._theme.Window.SubtitleText,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = self._theme.Font,
                TextSize = 14,
                Parent = self.TitleBar
            })
        end
        
        -- Create dock toggle icon in title bar
        self.DockIcon = Core.Util.Create("TextButton", {
            Name = "DockIcon",
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -26, 0.5, -10),
            BackgroundColor3 = Color3.new(),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "≡", -- Triple bar symbol (better compatibility)
            TextColor3 = self._theme.Window and self._theme.Window.TitleText or self._theme.TextColor,
            TextScaled = false,
            TextSize = 16,
            Font = Enum.Font.SourceSans, -- Use a reliable font
            Parent = self.TitleBar
        })
        
        -- Add rounded corners for better appearance
    local _corner = Core.Util.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = self.DockIcon
        })
        
        -- Connect dock icon click event (mobile-compatible) and track connections
        if self._track then
            self:_track(self.DockIcon.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:ToggleDock()
                end
            end))

            -- Hover effects for dock icon
            self:_track(self.DockIcon.MouseEnter:Connect(function()
                self.DockIcon.BackgroundColor3 = self._theme.Accent
                self.DockIcon.BackgroundTransparency = 0.8
            end))

            self:_track(self.DockIcon.MouseLeave:Connect(function()
                if self._dockVisible then
                    self.DockIcon.BackgroundColor3 = self._theme.Accent
                    self.DockIcon.BackgroundTransparency = 0.2
                else
                    self.DockIcon.BackgroundColor3 = Color3.new()
                    self.DockIcon.BackgroundTransparency = 1
                end
            end))
        else
            self.DockIcon.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:ToggleDock()
                end
            end)
        end
    end
    function Window:_createContentArea()
        self.Content = Core.Util.Create("Frame", {
            Name = "Content",
            Size = UDim2.new(1, 0, 1, -32),
            Position = UDim2.fromOffset(0, 32),
            BackgroundColor3 = self._theme.Background,
            Parent = self.Root
        })
        
        -- Initialize dock state (simplified)
        self._dockVisible = false
        self._dockMode = "Manual" -- Start with manual mode
        self._dockThreshold = 0.8 -- Scale threshold for auto-dock (80% scale)
        self._dockWidth = 150
    end
    function Window:AddTab(name, icon)
        if self._destroyed then return end
        if not self.TabContainer then
            -- Top tab bar: full-width horizontal scroller so tabs never get cut off
            self.TabContainer = Core.Util.Create("ScrollingFrame", {
                Name = "TabContainer",
                Size = UDim2.new(1, 0, 0, self._theme.Tab.PillHeight),
                Position = UDim2.fromOffset(0, 32),
                BackgroundColor3 = self._theme.Background,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2,
                ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border,
                ScrollingDirection = Enum.ScrollingDirection.X,
                CanvasSize = UDim2.fromOffset(0, self._theme.Tab.PillHeight),
                Parent = self.Root
            })
            -- Add border to match other sections
            Core.Util.Create("UIStroke", { 
                Color = self._theme.Border, 
                Thickness = 1, 
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = self.TabContainer 
            })
            self.Content.Size = UDim2.new(1, 0, 1, -(32 + self._theme.Tab.PillHeight))
            self.Content.Position = UDim2.fromOffset(0, 32 + self._theme.Tab.PillHeight)
            self.TabList = Core.Util.Create("Frame", { 
                Name = "TabList", 
                Size = UDim2.new(0, 0, 1, 0), 
                BackgroundTransparency = 1, 
                ClipsDescendants = true,
                Parent = self.TabContainer 
            })
            self.Pages = Core.Util.Create("Frame", { Name = "Pages", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = self.Content })
            self._tabs = {}
            self._currentTab = nil
            
            -- Create side dock
            self:_createDock()
            
            -- Initialize content positioning
            self:_updateContentPosition()
            
            -- Add scale monitoring for auto-dock modes
            self:_setupScaleMonitoring()
        end
        local tabButton = Core.Util.Create("TextButton", {
            Name = name,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = self._theme.Tab.IdleFill,
            Text = self._theme.Tab.Uppercase and string.upper(name) or name,
            TextColor3 = self._theme.Tab.IdleText,
            Font = self._theme.Font,
            TextSize = 14,
            AutoButtonColor = false,
            Parent = self.TabList
        })
        if icon then
            local _iconImage = Core.Util.Create("ImageLabel", { Name = "Icon", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Image = icon, ImageColor3 = self._theme.Tab.IdleText, Parent = tabButton })
            tabButton.TextPadding = UDim2.fromOffset(32, 0)
        end
    local textSize = TextService:GetTextSize(tabButton.Text, 14, self._theme.Font, Vector2.new(1000, 20))
        tabButton.Size = UDim2.new(0, textSize.X + 24, 1, 0)
    local page = Core.Util.Create("ScrollingFrame", { Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2, ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border, Visible = false, Parent = self.Pages })
        Core.Util.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = page })
        local layout = Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = page })
        
        -- Keep page scroll height in sync with content so users can reach the very bottom,
        -- including dynamic elements added after initial render.
        local function updatePageCanvas()
            local padding = 16 -- top(8) + bottom(8)
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + padding)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
        -- Initial update
        task.defer(updatePageCanvas)
        tabButton.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                self:SelectTab(name)
            end
        end)
        local tab = { Name = name, Button = tabButton, Page = page, Icon = icon }
        table.insert(self._tabs, tab)
        local xOffset = 0
        for _, t in ipairs(self._tabs) do
            t.Button.Position = UDim2.fromOffset(xOffset, 0)
            xOffset = xOffset + t.Button.AbsoluteSize.X + 6
        end
        -- Resize the inner tab list and update horizontal canvas size
        self.TabList.Size = UDim2.new(0, math.max(xOffset, self.TabContainer.AbsoluteSize.X), 1, 0)
        self.TabContainer.CanvasSize = UDim2.fromOffset(xOffset, self._theme.Tab.PillHeight)
        if #self._tabs == 1 then self:SelectTab(name) end
        
        -- Update dock buttons
        self:_updateDockButtons()
        
        return page
    end
    function Window:SelectTab(name)
        if self._destroyed then return end
        if not self._tabs then return end
        local tab
        for _, t in ipairs(self._tabs) do
            if t.Name == name then
                tab = t
                break
            end
        end
        if not tab then return end
        if self._currentTab then
            local current = self._currentTab
            current.Button.BackgroundColor3 = self._theme.Tab.IdleFill
            current.Button.TextColor3 = self._theme.Tab.IdleText
            if current.Icon then current.Button.Icon.ImageColor3 = self._theme.Tab.IdleText end
            current.Page.Visible = false
        end
        self._currentTab = tab
        tab.Button.BackgroundColor3 = self._theme.Tab.ActiveFill
        tab.Button.TextColor3 = self._theme.Tab.ActiveText
        if tab.Icon then tab.Button.Icon.ImageColor3 = self._theme.Tab.ActiveText end
        tab.Page.Visible = true
        if self._theme.EnableBrackets then
            if not tab.Brackets then
                tab.Brackets = {
                    TopLeft = Core.Util.Create("Frame", { Name = "TopLeft", Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(-1, -1), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    TopRight = Core.Util.Create("Frame", { Name = "TopRight", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(1, -3, 0, -1), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    BottomLeft = Core.Util.Create("Frame", { Name = "BottomLeft", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(0, -1, 1, -3), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    BottomRight = Core.Util.Create("Frame", { Name = "BottomRight", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(1, -3, 1, -3), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                }
                for _, bracket in pairs(tab.Brackets) do
                    Core.Util.Create("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = self._theme.Tab.ActiveFill, BorderSizePixel = 0, Parent = bracket })
                end
            end
            for _, bracket in pairs(tab.Brackets) do
                bracket.BackgroundTransparency = 1
                Core.Util.Tween(bracket, { BackgroundTransparency = 0 }, 0.2)
            end
        end
        
        -- Update dock buttons to reflect current selection
        self:_updateDockButtons()
    end
    
    -- Create floating dock panel (can snap to main window)
    function Window:_createDock()
        local width = self._configDockWidth or 150

        -- Determine initial floating position near the main window
        local mainPos = self.Root.AbsolutePosition
        local mainSize = self.Root.AbsoluteSize
        local margin = 8
        local initX = (mainPos.X >= (width + margin)) and (mainPos.X - width - margin) or (mainPos.X + mainSize.X + margin)
        local initY = mainPos.Y

        -- Create a top-level container so the dock floats independently
        self.DockContainer = Core.Util.Create("Frame", {
            Name = "DockContainer",
            Size = UDim2.fromOffset(0, mainSize.Y), -- start collapsed, full height of window
            Position = UDim2.fromOffset(initX, initY),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 100, -- float above window
            Parent = self.ScreenGui
        })
        
        -- Create the actual dock panel inside the container
        self.Dock = Core.Util.Create("Frame", {
            Name = "Dock",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = self._theme.Background2,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = self.DockContainer
        })
        
        -- Right border to separate dock from main content
        Core.Util.Create("Frame", {
            Name = "RightBorder",
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = self._theme.Border,
            BorderSizePixel = 0,
            Parent = self.Dock
        })
        
        -- Initialize dock state
        self._dockVisible = false
        self._dockWidth = width
        self._dockSnapped = false
        self._dockSnapSide = "Left" -- future: allow Right

        -- Dock header (drag handle)
        local dockHeader = Core.Util.Create("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = self._theme.Background,
            BorderSizePixel = 0,
            Parent = self.Dock
        })
        
        local _headerTitle = Core.Util.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = "TABS",
            TextColor3 = self._theme.TextColor,
            Font = self._theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dockHeader
        })

        -- Snap toggle button
        local snapBtn = Core.Util.Create("TextButton", {
            Name = "SnapButton",
            Size = UDim2.fromOffset(60, 22),
            Position = UDim2.new(1, -66, 0.5, -11),
            BackgroundColor3 = self._theme.Background2,
            Text = "Snap",
            TextColor3 = self._theme.TextColor,
            Font = self._theme.Font,
            TextSize = 12,
            AutoButtonColor = true,
            Parent = dockHeader
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = snapBtn })
        
        -- Dock content (scrollable tab list)
        self.DockContent = Core.Util.Create("ScrollingFrame", {
            Name = "Content",
            Size = UDim2.new(1, -8, 1, -74),
            Position = UDim2.fromOffset(4, 34),
            BackgroundTransparency = 1,
            ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2,
            ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border,
            BorderSizePixel = 0,
            Parent = self.Dock
        })
        
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = self.DockContent
        })
        
        Core.Util.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            Parent = self.DockContent
        })
        
        -- Dock mode selector at bottom
        local dockFooter = Core.Util.Create("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 1, -36),
            BackgroundColor3 = self._theme.Background,
            BorderSizePixel = 0,
            Parent = self.Dock
        })

        -- Mode buttons in footer
        local modeContainer = Core.Util.Create("Frame", {
            Name = "ModeContainer",
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1,
            Parent = dockFooter
        })
        
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 2),
            Parent = modeContainer
        })
        
        local modes = {
            {name = "Manual", mode = "Manual", tooltip = "Manual dock control"},
            {name = "Scale", mode = "Scale", tooltip = "Auto-show when window scaled small"},
            {name = "Always", mode = "AlwaysOn", tooltip = "Dock always visible"},
            {name = "Never", mode = "Never", tooltip = "Dock never shows"},
            {name = "Dock+Top", mode = "DockAndTop", tooltip = "Dock + keep top tabs"}
        }
        
        for _, modeData in ipairs(modes) do
            local btn = Core.Util.Create("TextButton", {
                Name = modeData.mode,
                Size = UDim2.new(0.2, -2, 1, 0),
                BackgroundColor3 = self._theme.Background,
                Text = modeData.name,
                TextColor3 = self._theme.TextColor,
                Font = self._theme.Font,
                TextSize = 10,
                Parent = modeContainer
            })
            
            Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = btn })
            
            btn.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:SetDockMode(modeData.mode)
                end
            end)
        end
        
        -- Interaction: dragging and resizing (when not snapped)
        -- Custom draggable that respects snapped state
        do
            local UserInputService = game:GetService("UserInputService")
            local dragging = false
            local dragStart
            local startPos
            local dockDragConnections = {}

            table.insert(dockDragConnections, dockHeader.InputBegan:Connect(function(input)
                if self._dockSnapped then return end
                if Core.Util.IsTouch(input.UserInputType) then
                    dragging = true
                    dragStart = Core.Util.GetInputPosition(input)
                    startPos = self.DockContainer.Position
                end
            end))

            table.insert(dockDragConnections, UserInputService.InputChanged:Connect(function(input)
                if self._dockSnapped then return end
                if dragging and Core.Util.IsTouchMovement(input.UserInputType) then
                    local current = Core.Util.GetInputPosition(input)
                    local delta = current - dragStart
                    self.DockContainer.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end))

            table.insert(dockDragConnections, UserInputService.InputEnded:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    dragging = false
                    pcall(function() if self._saveDockState then self:_saveDockState() end end)
                end
            end))

            self._dockDragConnections = dockDragConnections
        end

        -- Resize grip on container (constrain height when snapped)
        self._dockResizeGrip = Core.Behaviors.AddResizeGrip(self.DockContainer, self._theme, Vector2.new(120, 120), Vector2.new(800, 900))

        -- Snap button behavior
        local function updateSnapButton()
            if self._dockSnapped then
                snapBtn.Text = "UnSnap"
                snapBtn.BackgroundColor3 = self._theme.Accent
                snapBtn.TextColor3 = self._theme.TextColor
            else
                snapBtn.Text = "Snap"
                snapBtn.BackgroundColor3 = self._theme.Background2
                snapBtn.TextColor3 = self._theme.TextColor
            end
        end
        updateSnapButton()
        snapBtn.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                self:_setDockSnapped(not self._dockSnapped)
                updateSnapButton()
            end
        end)
        -- Attempt to load persisted dock state (if available)
        pcall(function() if self._loadDockState then self:_loadDockState() end end)
    end
    
    -- Update dock button in dock content when tab is added
    function Window:_updateDockButtons()
        if not self.DockContent then return end
        
        -- Clear existing buttons
        for _, child in ipairs(self.DockContent:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Create button for each tab
        for i, tab in ipairs(self._tabs) do
            local dockBtn = Core.Util.Create("TextButton", {
                Name = "DockTab_" .. tab.Name,
                Size = UDim2.new(1, -4, 0, 32),
                BackgroundColor3 = self._theme.Background,
                Text = tab.Name,
                TextColor3 = self._theme.TextColor,
                Font = self._theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center, -- Fix vertical centering
                LayoutOrder = i,
                Parent = self.DockContent
            })
            
            Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dockBtn })
            Core.Util.Create("UIPadding", { 
                PaddingLeft = UDim.new(0, 8), 
                PaddingTop = UDim.new(0, 2), 
                PaddingBottom = UDim.new(0, 2), 
                Parent = dockBtn 
            })
            
            dockBtn.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:SelectTab(tab.Name)
                    -- Don't auto-close dock - let user close it manually if needed
                    -- This prevents the dock from disappearing when selecting tabs
                end
            end)
            
            -- Highlight current tab
            if self._currentTab and self._currentTab.Name == tab.Name then
                dockBtn.BackgroundColor3 = self._theme.Accent
                dockBtn.TextColor3 = self._theme.TextColor
            end
        end
        
        -- Update canvas size
        local contentHeight = #self._tabs * 36
        self.DockContent.CanvasSize = UDim2.fromOffset(0, contentHeight)
    end
    
    -- Dock toggle with smooth width and transparency animations
    function Window:ToggleDock()
        if not self.DockContainer then 
            if Core.Debug then
                print("DEBUG: No DockContainer found")
            end
            return 
        end
        
        -- Toggle state
        self._dockVisible = not self._dockVisible
        if Core.Debug then
            print("DEBUG: Dock toggled to:", self._dockVisible)
        end
        
        -- Update dock icon appearance
        if self.DockIcon then
            if self._dockVisible then
                self.DockIcon.BackgroundColor3 = self._theme.Accent
                self.DockIcon.BackgroundTransparency = 0.3
            else
                self.DockIcon.BackgroundColor3 = Color3.new()
                self.DockIcon.BackgroundTransparency = 1
            end
        end
        
        -- Animate show/hide
        if self._dockVisible then
            self:_showDock()
        else
            self:_hideDock()
        end

        -- persist dock visibility change
        pcall(function() if self._saveDockState then self:_saveDockState() end end)
    end
    
    -- Show dock with width expand and transparency fade-in
    function Window:_showDock()
        if not self.DockContainer then return end
        
        local dockWidth = self._dockWidth
        
        if Core.Debug then
            print("DEBUG: Showing dock with width animation to:", dockWidth)
        end
        
        -- If snapped, align to window and set correct height before expanding
        if self._dockSnapped then
            -- Set target position/height next to the window
            self:_repositionDockToWindow()
            -- Collapse width for animation
            self.DockContainer.Size = UDim2.fromOffset(0, self.Root.AbsoluteSize.Y)
        else
            -- Keep current height/position, collapse width only
            self.DockContainer.Size = UDim2.fromOffset(0, self.DockContainer.AbsoluteSize.Y)
        end
        
        if self.Dock then
            self.Dock.BackgroundTransparency = 1 -- Start dock faded
        end
        
        -- Animate dock width and background simultaneously
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local expandTween = TweenService:Create(self.DockContainer, tweenInfo, {
            Size = UDim2.fromOffset(dockWidth, self.DockContainer.Size.Y.Offset)
        })
        expandTween:Play()
        
        if self.Dock then
            TweenService:Create(self.Dock, tweenInfo, { BackgroundTransparency = 0 }):Play()
        end
        
        self._dockVisible = true
    end
    
    -- Hide dock with width collapse and transparency fade-out
    function Window:_hideDock()
        if not self.DockContainer then return end
        
        if Core.Debug then
            print("DEBUG: Hiding dock with width animation")
        end
        
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local collapseTween = TweenService:Create(self.DockContainer, tweenInfo, {
            Size = UDim2.new(0, 0, 1, 0) -- Collapse to 0 width
        })
        collapseTween:Play()
        
        if self.Dock then
            TweenService:Create(self.Dock, tweenInfo, { BackgroundTransparency = 1 }):Play()
        end
        
        self._dockVisible = false
        
        if Core.Debug then
            print("DEBUG: Dock hidden completely")
        end
    end
    
    -- Setup scale monitoring for auto-dock modes
    function Window:_setupScaleMonitoring()
        local function checkScale()
            if not self.Root or not self.DockContainer then return end
            
            local currentScale = self.Root.AbsoluteSize.X / self.Root.Parent.AbsoluteSize.X
            local belowThreshold = currentScale < self._dockThreshold
            
            if self._dockMode == "Scale" then
                -- Show dock when scale is below threshold
                if belowThreshold and not self._dockVisible then
                    self:_showDock()
                elseif not belowThreshold and self._dockVisible then
                    self:_hideDock()
                end
            elseif self._dockMode == "AlwaysOn" then
                -- Always show dock
                if not self._dockVisible then
                    self:_showDock()
                end
            elseif self._dockMode == "Never" then
                -- Never show dock
                if self._dockVisible then
                    self:_hideDock()
                end
            elseif self._dockMode == "DockAndTop" then
                -- Show dock when scale is below threshold, but keep top tabs
                if belowThreshold and not self._dockVisible then
                    self:_showDock()
                elseif not belowThreshold and self._dockVisible then
                    self:_hideDock()
                end
                -- TODO: Keep top tabs visible (for future implementation)
            end
            -- Manual mode does nothing automatic
        end
        
        -- Monitor window size changes for automatic dock modes
        if self.Root then
            -- Store connections for cleanup
            self._scaleConnections = self._scaleConnections or {}
            
            table.insert(self._scaleConnections, 
                self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(checkScale)
            )
            
            -- Initial check
            task.spawn(function()
                task.wait(0.1) -- Small delay for initialization
                checkScale()
            end)
        end
    end

    -- Snap management
    -- Dock state persistence helpers
    function Window:_dockStateFile()
        local base = "stellar_dock_"
        local id = (self.ScreenGui and self.ScreenGui.Name) or tostring(self)
        return base .. id .. ".json"
    end

    function Window:_saveDockState()
        -- Save minimal dock state if file API available
    if type(writefile) ~= "function" then return end
    local ok, httpService = pcall(function() return game:GetService("HttpService") end)
        if not ok or not httpService then return end
        local state = {
            dockVisible = self._dockVisible,
            dockSnapped = self._dockSnapped,
            dockMode = self._dockMode,
            dockWidth = self._dockWidth,
        }
        -- store position/size if present
        if self.DockContainer then
            local pos = self.DockContainer.AbsolutePosition
            local size = self.DockContainer.AbsoluteSize
            state.position = { x = pos.X, y = pos.Y }
            state.size = { x = size.X, y = size.Y }
        end
        local file = self:_dockStateFile()
        local okenc, json = pcall(function() return httpService:JSONEncode(state) end)
        if okenc and json then
            pcall(writefile, file, json)
        end
    end

    function Window:_loadDockState()
    if type(readfile) ~= "function" then return end
        local file = self:_dockStateFile()
    if type(isfile) == "function" and not isfile(file) then return end
    local ok, contents = pcall(readfile, file)
        if not ok or not contents then return end
        local okdec, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(contents)
        end)
        if not okdec or type(decoded) ~= "table" then return end
        -- apply saved state
        if decoded.dockMode then pcall(function() self:SetDockMode(decoded.dockMode) end) end
        if decoded.dockSnapped ~= nil then self._dockSnapped = decoded.dockSnapped end
        if decoded.dockWidth then self._dockWidth = decoded.dockWidth end
        if decoded.position and self.DockContainer then
            pcall(function()
                self.DockContainer.Position = UDim2.fromOffset(decoded.position.x, decoded.position.y)
            end)
        end
        if decoded.size and self.DockContainer then
            pcall(function()
                self.DockContainer.Size = UDim2.fromOffset(decoded.size.x, decoded.size.y)
            end)
        end
        if decoded.dockVisible then
            pcall(function() self:_showDock() end)
        else
            pcall(function() self:_hideDock() end)
        end
    end

    function Window:_repositionDockToWindow()
        if not (self.DockContainer and self.Root) then return end
        local pos = self.Root.AbsolutePosition
        local size = self.Root.AbsoluteSize
        local margin = 0 -- snapped should be flush to the window
        local width = self._dockWidth or 150
        local x
        if self._dockSnapSide == "Left" then
            x = pos.X - width - margin
        else
            x = pos.X + size.X + margin
        end
        self.DockContainer.Position = UDim2.fromOffset(x, pos.Y)
        self.DockContainer.Size = UDim2.fromOffset(width, size.Y)
    end

    function Window:_attachDockFollowing()
        self:_detachDockFollowing()
        self._dockFollowConnections = {}
        local function follow()
            if self._dockSnapped then
                self:_repositionDockToWindow()
                -- lock height via resize grip while snapped
                if self._dockResizeGrip then
                    local h = self.Root.AbsoluteSize.Y
                    self._dockResizeGrip.SetMinSize(Vector2.new(120, h))
                    self._dockResizeGrip.SetMaxSize(Vector2.new(1000, h))
                end
            end
        end
        table.insert(self._dockFollowConnections, self.Root:GetPropertyChangedSignal("AbsolutePosition"):Connect(follow))
        table.insert(self._dockFollowConnections, self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(follow))
        -- Initial
        follow()
    end

    function Window:_detachDockFollowing()
        if self._dockFollowConnections then
            for _, c in ipairs(self._dockFollowConnections) do
                pcall(function() c:Disconnect() end)
            end
            self._dockFollowConnections = nil
        end
        -- restore resize flexibility
        if self._dockResizeGrip then
            self._dockResizeGrip.SetMinSize(Vector2.new(120, 120))
            self._dockResizeGrip.SetMaxSize(Vector2.new(800, 900))
        end
    end

    function Window:_setDockSnapped(snap)
        if self._dockSnapped == snap then return end
        self._dockSnapped = snap
        if snap then
            self:_attachDockFollowing()
        else
            self:_detachDockFollowing()
        end
        -- persist dock state
        pcall(function() if self._saveDockState then self:_saveDockState() end end)
    end
    
    -- Simplified dock mode (mostly for compatibility)
    function Window:SetDockMode(mode)
        self._dockMode = mode
        if Core.Debug then
            print("DEBUG: SetDockMode to", mode)
        end
        
        -- Update mode button highlights if dock exists
        if self.Dock then
            local footer = self.Dock:FindFirstChild("Footer")
            local modeContainer = footer and footer:FindFirstChild("ModeContainer")
            if modeContainer then
                for _, child in ipairs(modeContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        if child.Name == mode then
                            child.BackgroundColor3 = self._theme.Accent
                            child.TextColor3 = self._theme.TextColor
                        else
                            child.BackgroundColor3 = self._theme.Background
                            child.TextColor3 = self._theme.TextColor
                        end
                    end
                end
            end
        end
        
        -- Trigger immediate scale check for new mode
        task.spawn(function()
            task.wait(0.1)
            if self._setupScaleMonitoring then
                local currentScale = self.Root.AbsoluteSize.X / self.Root.Parent.AbsoluteSize.X
                local belowThreshold = currentScale < self._dockThreshold
                
                if mode == "Scale" or mode == "DockAndTop" then
                    if belowThreshold then self:_showDock() else self:_hideDock() end
                elseif mode == "AlwaysOn" then
                    self:_showDock()
                elseif mode == "Never" then
                    self:_hideDock()
                end
                -- Manual mode does nothing automatic
            end
        end)
        -- persist dock mode change
        pcall(function() if self._saveDockState then self:_saveDockState() end end)
    end
    
    -- Simple dock threshold (for compatibility)
    function Window:SetDockThreshold(scale)
        self._dockThreshold = math.clamp(scale or 0.8, 0.1, 1.0) -- Ensure valid scale range
        if Core.Debug then
            print("DEBUG: Dock threshold set to", self._dockThreshold, "scale")
        end
        
        -- Trigger immediate check if in Scale mode
        if self._dockMode == "Scale" and self.Root then
            task.spawn(function()
                task.wait(0.1)
                local currentScale = self.Root.AbsoluteSize.X / self.Root.Parent.AbsoluteSize.X
                if currentScale < self._dockThreshold then 
                    self:_showDock() 
                else 
                    self:_hideDock() 
                end
            end)
        end
    end
    
    -- Dock is floating; content area always fills the main window
    
    -- Update content area position (no offset for floating dock)
    function Window:_updateContentPosition()
        if not self.Content then return end
        local topOffset = self.TabContainer and self.TabContainer.Visible and (32 + (self._theme.Tab.PillHeight or 22)) or 32
        self.Content.Position = UDim2.fromOffset(0, topOffset)
        self.Content.Size = UDim2.new(1, 0, 1, -topOffset)
    end
    
    function Window:RefreshTheme()
        if self._destroyed then return end

        -- cache locals to reduce repeated table lookups
        local theme = self._theme or {}
        local thW = theme.Window or {}
        local thT = theme.Tab or {}
        local scrollbar = theme.Scrollbar or {}
        local bg = theme.Background
        local bg2 = theme.Background2
        local text = theme.TextColor
    local _subText = theme.SubTextColor
        local accent = theme.Accent
        local border = theme.Border

        local function safeColor(color, fallback)
            return (color and typeof(color) == 'Color3') and color or (fallback or Color3.fromRGB(100,100,255))
        end

        -- Window chrome
        self.Root.BackgroundColor3 = safeColor(thW.Background, bg)
        self.TitleBar.BackgroundColor3 = safeColor(thW.Background, bg)
        self.Title.TextColor3 = safeColor(thW.TitleText, text)
        self.Content.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25))

        -- Tabs
        if self.TabContainer then
            self.TabContainer.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25))
            if self.TabContainer:IsA('ScrollingFrame') then
                self.TabContainer.ScrollBarImageColor3 = scrollbar.Color or border
                self.TabContainer.ScrollBarThickness = scrollbar.Thickness or self.TabContainer.ScrollBarThickness
            end
            if self._tabs then
                local idleFill = thT.IdleFill
                local activeFill = thT.ActiveFill
                local idleText = thT.IdleText
                local activeText = thT.ActiveText
                for _, t in ipairs(self._tabs) do
                    local active = (self._currentTab and self._currentTab.Name == t.Name)
                    t.Button.BackgroundColor3 = safeColor(active and activeFill or idleFill, bg2)
                    t.Button.TextColor3 = safeColor(active and activeText or idleText, text)
                    if t.Icon then
                        t.Button.Icon.ImageColor3 = safeColor(active and activeText or idleText, text)
                    end
                    if t.Brackets then
                        for _, b in pairs(t.Brackets) do
                            b.BackgroundColor3 = safeColor(thW.CornerBrackets, border)
                            local inner = b:FindFirstChildOfClass('Frame')
                            if inner then inner.BackgroundColor3 = safeColor(thT.ActiveFill, bg) end
                        end
                    end
                end
            end
        end

        -- Pages
        if self.Pages then
            local sbCol = scrollbar.Color or border
            local sbTh = scrollbar.Thickness
            for _, child in ipairs(self.Pages:GetChildren()) do
                if child:IsA('ScrollingFrame') then
                    child.ScrollBarImageColor3 = sbCol
                    child.ScrollBarThickness = sbTh or child.ScrollBarThickness
                end
            end
        end

        -- Dock
        if self.Dock then
            self.Dock.BackgroundColor3 = safeColor(bg2, Color3.fromRGB(30,30,30))
            local header = self.Dock:FindFirstChild('Header')
            if header then header.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25)) end
            local footer = self.Dock:FindFirstChild('Footer')
            if footer then footer.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25)) end
            local rightBorder = self.Dock:FindFirstChild('RightBorder')
            if rightBorder then rightBorder.BackgroundColor3 = safeColor(border, Color3.fromRGB(60,60,60)) end
            if self.DockContent then
                self.DockContent.ScrollBarImageColor3 = scrollbar.Color or border
                self.DockContent.ScrollBarThickness = scrollbar.Thickness or self.DockContent.ScrollBarThickness
                for _, btn in ipairs(self.DockContent:GetChildren()) do
                    if btn:IsA('TextButton') then
                        local isActive = (self._currentTab and ('DockTab_' .. self._currentTab.Name) == btn.Name)
                        btn.BackgroundColor3 = safeColor(isActive and accent or bg, Color3.fromRGB(50,50,50))
                        btn.TextColor3 = safeColor(text, Color3.fromRGB(200,200,200))
                    end
                end
            end
            if footer then
                local modeContainer = footer:FindFirstChild('ModeContainer')
                if modeContainer then
                    for _, btn in ipairs(modeContainer:GetChildren()) do
                        if btn:IsA('TextButton') then
                            local isActive = (btn.Name == self._dockMode)
                            btn.BackgroundColor3 = safeColor(isActive and accent or bg, Color3.fromRGB(50,50,50))
                            btn.TextColor3 = safeColor(text, Color3.fromRGB(200,200,200))
                        end
                    end
                end
            end
        end

        -- Dock icon
        if self.DockIcon then
            self.DockIcon.TextColor3 = safeColor(thW.TitleText, text)
            if self._dockVisible then
                self.DockIcon.BackgroundColor3 = safeColor(accent, Color3.fromRGB(100,100,255))
                self.DockIcon.BackgroundTransparency = 0.2
            else
                self.DockIcon.BackgroundColor3 = Color3.new()
                self.DockIcon.BackgroundTransparency = 1
            end
        end

        -- Resize grip
        if self._resizeGrip and self._resizeGrip.UpdateColors then
            if Core.Debug then
                print('DEBUG: Updating resize grip colors with theme:', accent)
            end
            self._resizeGrip:UpdateColors(self._theme)
        elseif Core.Debug then
            print('DEBUG: Resize grip not found or no UpdateColors function')
        end
    end
    function Window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        
        -- Cleanup all connections to prevent memory leaks
        if self._scaleConnections then
            for _, connection in ipairs(self._scaleConnections) do
                connection:Disconnect()
            end
            self._scaleConnections = nil
        end

        -- Cleanup dock follow connections
        if self._dockFollowConnections then
            for _, connection in ipairs(self._dockFollowConnections) do
                connection:Disconnect()
            end
            self._dockFollowConnections = nil
        end
        
        -- Cleanup resize grip
        if self._resizeGrip then
            self._resizeGrip.Destroy()
            self._resizeGrip = nil
        end

        -- Cleanup dock resize grip
        if self._dockResizeGrip then
            self._dockResizeGrip.Destroy()
            self._dockResizeGrip = nil
        end

        -- Cleanup title drag handle
        if self._titleDrag and self._titleDrag.Destroy then
            pcall(function() self._titleDrag:Destroy() end)
            self._titleDrag = nil
        end

        -- Cleanup dock drag connections
        if self._dockDragConnections then
            for _, c in ipairs(self._dockDragConnections) do pcall(function() c:Disconnect() end) end
            self._dockDragConnections = nil
        end
        
        -- Cleanup FX effects
        if self._fx then 
            for _, effect in pairs(self._fx) do 
                if effect and effect.Destroy then
                    effect.Destroy() 
                end
            end 
            self._fx = nil
        end
        
        -- Cleanup all child components
        if self._components then
            for _, component in pairs(self._components) do
                if component and component.Destroy and not component._destroyed then
                    component:Destroy()
                end
            end
            self._components = nil
        end
        
        -- Finally destroy the GUI
        if self.ScreenGui then 
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end

    -- Button
    local Button = setmetatable({}, {__index = BaseComponent})
    Button.__index = Button
    function Button.new(props)
        local self = BaseComponent.new({ Name = "Button", Theme = props.Theme or Theme })
        setmetatable(self, Button)
        self.Root = Core.Util.Create("TextButton", { Name = "Button", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = self._theme.Background2, Text = props.Text or "Button", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, Parent = props.Parent })
        self:_setupInteractions()
        self._callback = props.Callback
        
        -- Apply FX if provided
        if props.FX then
            self._fx = Core.FX.Apply(self.Root, props.FX, self._theme)
        end
        
        return self
    end
    function Button:_setupInteractions()
        self.Root.MouseEnter:Connect(function()
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Accent }, 0.2)
        end)
        self.Root.MouseLeave:Connect(function()
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Background2 }, 0.2)
        end)
        self.Root.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                if self._callback then self._callback() end
            end
        end)
    end
    function Button:SetText(text) self.Root.Text = text end
    function Button:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.Root.TextColor3 = self._theme.TextColor
    end

    -- Toggle
    local Toggle = setmetatable({}, {__index = BaseComponent})
    Toggle.__index = Toggle
    function Toggle.new(props)
        local self = BaseComponent.new({ Name = "Toggle", Theme = props.Theme or Theme })
        setmetatable(self, Toggle)
        self.Root = Core.Util.Create("Frame", { Name = "Toggle", Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = props.Parent })
        self:_createLabel(props.Text)
        self:_createIndicator()
        self._value = props.Value or false
        self._callback = props.Callback
        self:SetValue(self._value, false)
        return self
    end
    function Toggle:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = text or "Toggle", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Toggle:_createIndicator()
        self.Indicator = Core.Util.Create("Frame", { Name = "Indicator", Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.Background2, Parent = self.Root })
        self.Knob = Core.Util.Create("Frame", { Name = "Knob", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.TextColor, Parent = self.Indicator })
        self.Indicator.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then self:SetValue(not self._value) end
        end)
    end
    function Toggle:SetValue(value, animate)
        self._value = value
        local knobPosition = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local indicatorColor = value and self._theme.Accent or self._theme.Background2
        if animate ~= false then
            Core.Util.Tween(self.Knob, { Position = knobPosition }, 0.2)
            Core.Util.Tween(self.Indicator, { BackgroundColor3 = indicatorColor }, 0.2)
        else
            self.Knob.Position = knobPosition
            self.Indicator.BackgroundColor3 = indicatorColor
        end
        if self._callback then self._callback(value) end
    end
    function Toggle:GetValue() return self._value end
    function Toggle:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Knob.BackgroundColor3 = self._theme.TextColor
        self:SetValue(self._value, false)
    end

    -- Slider
    local Slider = setmetatable({}, {__index = BaseComponent})
    Slider.__index = Slider
    function Slider.new(props)
        local self = BaseComponent.new({ Name = "Slider", Theme = props.Theme or Theme })
        setmetatable(self, Slider)
        self.Root = Core.Util.Create("Frame", { Name = "Slider", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = props.Parent })
        self:_createLabel(props.Text)
        self:_createTrack()
        self:_createValue()
        self._min = props.Min or 0
        self._max = props.Max or 100
        self._step = props.Step or 1
        self._callback = props.Callback
        self._dragging = false
        self:SetValue(props.Value or self._min, false)
        return self
    end
    function Slider:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -50, 0, 20), BackgroundTransparency = 1, Text = text or "Slider", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Slider:_createTrack()
        self.Track = Core.Util.Create("Frame", { Name = "Track", Size = UDim2.new(1, -50, 0, 4), Position = UDim2.new(0, 0, 0, 28), BackgroundColor3 = self._theme.Background2, Parent = self.Root })
        self.Fill = Core.Util.Create("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Accent, Parent = self.Track })
        self.Knob = Core.Util.Create("Frame", { Name = "Knob", Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self._theme.TextColor, Parent = self.Track })
        local function update(input)
            local trackPos = self.Track.AbsolutePosition.X
            local trackWidth = self.Track.AbsoluteSize.X
            local mousePos = input.Position.X
            local pos = math.clamp(mousePos - trackPos, 0, trackWidth)
            local percentage = pos / trackWidth
            local value = self._min + (self._max - self._min) * percentage
            value = math.floor(value / self._step) * self._step
            self:SetValue(value)
        end
        self.Track.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                self._dragging = true
                update(input)
            end
        end)
        local UIS = game:GetService("UserInputService")
        -- Store connections so they can be disconnected later
        self._sliderConnections = self._sliderConnections or {}
        table.insert(self._sliderConnections, UIS.InputChanged:Connect(function(input)
            if Core.Util.IsTouchMovement(input.UserInputType) and self._dragging then update(input) end
        end))
        table.insert(self._sliderConnections, UIS.InputEnded:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then self._dragging = false end
        end))
    end
    function Slider:_createValue()
        self.Value = Core.Util.Create("TextLabel", { Name = "Value", Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(self._min), TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Right, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Slider:SetValue(value, animate)
        value = math.clamp(value, self._min, self._max)
        self._value = value
        local percentage = (value - self._min) / (self._max - self._min)
        if animate ~= false then
            Core.Util.Tween(self.Fill, { Size = UDim2.new(percentage, 0, 1, 0) }, 0.2)
            Core.Util.Tween(self.Knob, { Position = UDim2.new(percentage, 0, 0.5, 0) }, 0.2)
        else
            self.Fill.Size = UDim2.new(percentage, 0, 1, 0)
            self.Knob.Position = UDim2.new(percentage, 0, 0.5, 0)
        end
        self.Value.Text = tostring(math.floor(value))
        if self._callback then self._callback(value) end
    end
    function Slider:GetValue() return self._value end
    function Slider:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Value.TextColor3 = self._theme.TextColor
        self.Track.BackgroundColor3 = self._theme.Background2
        self.Fill.BackgroundColor3 = self._theme.Accent
        self.Knob.BackgroundColor3 = self._theme.TextColor
    end

    function Slider:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if self._sliderConnections then
            for _, c in ipairs(self._sliderConnections) do pcall(function() c:Disconnect() end) end
            self._sliderConnections = nil
        end
        if self.Root then self.Root:Destroy() end
    end

    -- TextInput
    local TextInput = setmetatable({}, {__index = BaseComponent})
    TextInput.__index = TextInput
    function TextInput.new(props)
        local self = BaseComponent.new({ Name = "TextInput", Theme = props.Theme or Theme })
        setmetatable(self, TextInput)
        self.Root = Core.Util.Create("Frame", { Name = "TextInput", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = self._theme.Background2, Parent = props.Parent })
        self:_createTextBox(props)
        self._callback = props.Callback
        self._placeholder = props.Placeholder
        return self
    end
    function TextInput:_createTextBox(props)
        self.TextBox = Core.Util.Create("TextBox", { Name = "TextBox", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = props.Text or "", PlaceholderText = props.Placeholder or "Type here...", TextColor3 = self._theme.TextColor, PlaceholderColor3 = self._theme.DisabledText, Font = self._theme.Font, TextSize = 14, ClearTextOnFocus = false, Parent = self.Root })
        self.TextBox.Focused:Connect(function() Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Accent }, 0.2) end)
        self.TextBox.FocusLost:Connect(function(enterPressed)
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Background2 }, 0.2)
            if self._callback then self._callback(self.TextBox.Text, enterPressed) end
        end)
    end
    function TextInput:SetText(text) self.TextBox.Text = text or "" end
    function TextInput:GetText() return self.TextBox.Text end
    function TextInput:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.TextBox.TextColor3 = self._theme.TextColor
        self.TextBox.PlaceholderColor3 = self._theme.DisabledText
    end

    -- Dropdown
    local Dropdown = setmetatable({}, {__index = BaseComponent})
    Dropdown.__index = Dropdown
    function Dropdown.new(props)
        local self = BaseComponent.new({ Name = "Dropdown", Theme = props.Theme or Theme })
        setmetatable(self, Dropdown)
        self.Root = Core.Util.Create("Frame", { Name = "Dropdown", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = self._theme.Background2, Parent = props.Parent })
        self._parent = props.Parent
        self:_createHeader(props.Text)
        self:_createList()
        self._options = props.Options or {}
        self._callback = props.Callback
        self._open = false
        if props.Value and table.find(self._options, props.Value) then self:SetValue(props.Value, false) else self:SetValue(self._options[1] or "None", false) end
        return self
    end
    function Dropdown:_createHeader(text)
        self.Header = Core.Util.Create("TextLabel", { Name = "Header", Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = text or "Dropdown", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, ClipsDescendants = true, Parent = self.Root })
        self.Arrow = Core.Util.Create("TextLabel", { Name = "Arrow", Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        self.Root.InputBegan:Connect(function(input) if Core.Util.IsTouch(input.UserInputType) then self:Toggle() end end)
    end
    function Dropdown:_createList()
        self.List = Core.Util.Create("Frame", { Name = "List", Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Background2, ClipsDescendants = true, Parent = self.Root })
        -- Use ScrollingFrame instead of Frame for proper scrolling
        self.Options = Core.Util.Create("ScrollingFrame", { 
            Name = "Options", 
            Size = UDim2.new(1, 0, 1, 0), 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(1, 0, 0, 0),
            ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 4,
            ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent,
            Parent = self.List 
        })
    end
    function Dropdown:SetOptions(options)
        self._options = options
        for _, child in pairs(self.Options:GetChildren()) do 
            if not child:IsA("UIListLayout") then
                child:Destroy() 
            end
        end
        local height = 0
        for i, option in ipairs(options) do
            local button = Core.Util.Create("TextButton", { Name = option, Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, height), BackgroundColor3 = self._theme.Background2, Text = option, TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, Parent = self.Options })
            button.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:SetValue(option)
                    self:Toggle(false)
                end
            end)
            height = height + 32
        end
        -- Update CanvasSize for scrolling
        self.Options.CanvasSize = UDim2.new(1, 0, 0, height)
    end
    function Dropdown:Toggle(state)
        if state ~= nil then self._open = state else self._open = not self._open end
        local numOptions = #self._options
        local maxHeight = math.min(numOptions * 32, 160)
        local size = self._open and UDim2.new(1, 0, 0, maxHeight) or UDim2.new(1, 0, 0, 0)
        TweenService:Create(self.List, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size}):Play()
        TweenService:Create(self.Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = self._open and 180 or 0}):Play()
        if self._open and self._value then
            for i, option in ipairs(self._options) do
                if option == self._value then
                    local optionPosition = (i - 1) * 32
                    local scrollPosition = math.clamp(optionPosition - maxHeight/2, 0, math.max(0, numOptions * 32 - maxHeight))
                    TweenService:Create(self.Options, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, scrollPosition)}):Play()
                    break
                end
            end
        end
        if self._open then
            self.Root.ZIndex = 100
            self.List.ZIndex = 101
            self.Options.ZIndex = 102
            -- Bring option buttons to front
            for _, button in pairs(self.Options:GetChildren()) do
                if button:IsA("TextButton") then
                    button.ZIndex = 103
                end
            end
        else
            task.delay(0.2, function()
                if not self._open then
                    self.Root.ZIndex = 1
                    self.List.ZIndex = 2
                    self.Options.ZIndex = 1
                    for _, button in pairs(self.Options:GetChildren()) do
                        if button:IsA("TextButton") then
                            button.ZIndex = 1
                        end
                    end
                end
            end)
        end
    end
    function Dropdown:SetValue(value, animate)
        if not table.find(self._options, value) then return end
        self._value = value
        self.Header.Text = value
        if self._callback then self._callback(value) end
    end
    function Dropdown:GetValue() return self._value end
    function Dropdown:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.Header.TextColor3 = self._theme.TextColor
        self.Arrow.TextColor3 = self._theme.TextColor
        self.List.BackgroundColor3 = self._theme.Background2
    self.Options.ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent
    self.Options.ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or self.Options.ScrollBarThickness
        for _, button in pairs(self.Options:GetChildren()) do
            if button:IsA("TextButton") then
                button.BackgroundColor3 = self._theme.Background2
                button.TextColor3 = self._theme.TextColor
            end
        end
    end

    -- MultiDropdown (Multiple Selection Support)
    local MultiDropdown = setmetatable({}, {__index = BaseComponent})
    MultiDropdown.__index = MultiDropdown
    function MultiDropdown.new(props)
        local self = BaseComponent.new({ Name = "MultiDropdown", Theme = props.Theme or Theme })
        setmetatable(self, MultiDropdown)
        self.Root = Core.Util.Create("Frame", { Name = "MultiDropdown", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = self._theme.Background2, Parent = props.Parent })
        self._parent = props.Parent
        self:_createHeader(props.Text)
        self:_createList()
        self._options = props.Options or {}
        self._callback = props.Callback
        self._open = false
        self._selectedValues = {} -- Store multiple selected values
        self._maxSelections = props.MaxSelections or math.huge -- Optional limit
        self._originalText = props.Text or "MultiDropdown" -- Store original text
        
        -- Initialize with provided values
        if props.Values and type(props.Values) == "table" then
            for _, value in ipairs(props.Values) do
                if table.find(self._options, value) then
                    table.insert(self._selectedValues, value)
                end
            end
        elseif props.Value and table.find(self._options, props.Value) then
            table.insert(self._selectedValues, props.Value)
        end
        
        self:_updateHeaderText()
        return self
    end
    
    function MultiDropdown:_createHeader(text)
        self.Header = Core.Util.Create("TextLabel", { 
            Name = "Header", 
            Size = UDim2.new(1, -32, 1, 0), 
            BackgroundTransparency = 1, 
            Text = text or "MultiDropdown", 
            TextColor3 = self._theme.TextColor, 
            TextXAlignment = Enum.TextXAlignment.Left, 
            Font = self._theme.Font, 
            TextSize = 14, 
            ClipsDescendants = true, 
            Parent = self.Root 
        })
        self.Arrow = Core.Util.Create("TextLabel", { 
            Name = "Arrow", 
            Size = UDim2.fromOffset(32, 32), 
            Position = UDim2.new(1, -32, 0, 0), 
            BackgroundTransparency = 1, 
            Text = "▼", 
            TextColor3 = self._theme.TextColor, 
            Font = self._theme.Font, 
            TextSize = 14, 
            Parent = self.Root 
        })
        self.Root.InputBegan:Connect(function(input) 
            if input.UserInputType == Enum.UserInputType.MouseButton1 then 
                self:Toggle() 
            end 
        end)
    end
    
    function MultiDropdown:_createList()
        self.List = Core.Util.Create("Frame", { 
            Name = "List", 
            Size = UDim2.new(1, 0, 0, 0), 
            Position = UDim2.new(0, 0, 1, 0), 
            BackgroundColor3 = self._theme.Background2, 
            ClipsDescendants = true, 
            Parent = self.Root 
        })
        
        -- Scrolling frame for options
        self.Options = Core.Util.Create("ScrollingFrame", { 
            Name = "Options", 
            Size = UDim2.new(1, 0, 1, 0), 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(1, 0, 0, 0),
            ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 4,
            ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent,
            Parent = self.List 
        })
        
        -- Add layout for better organization
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.Options
        })
    end
    
    function MultiDropdown:_updateHeaderText()
        local numSelected = #self._selectedValues
        if numSelected == 0 then
            self.Header.Text = self._originalText -- Use original text instead of "None selected"
        elseif numSelected == 1 then
            self.Header.Text = self._selectedValues[1]
        elseif numSelected <= 3 then
            self.Header.Text = table.concat(self._selectedValues, ", ")
        else
            self.Header.Text = string.format("%d items selected", numSelected)
        end
    end
    
    function MultiDropdown:SetOptions(options)
        self._options = options
        
        -- Clear existing options
        for _, child in pairs(self.Options:GetChildren()) do 
            if not child:IsA("UIListLayout") then
                child:Destroy() 
            end
        end
        
        local height = 0
        for i, option in ipairs(options) do
            local isSelected = table.find(self._selectedValues, option) ~= nil
            
            local optionFrame = Core.Util.Create("Frame", {
                Name = "Option_" .. option,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = self._theme.Background2,
                BorderSizePixel = 0,
                LayoutOrder = i,
                Parent = self.Options
            })
            
            -- Checkbox for selection state
            local checkbox = Core.Util.Create("Frame", {
                Name = "Checkbox",
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 8, 0.5, -8),
                BackgroundColor3 = isSelected and self._theme.Accent or self._theme.Background,
                BorderColor3 = self._theme.Accent,
                BorderSizePixel = 1,
                Parent = optionFrame
            })
            
            -- Checkmark
            local _checkmark = Core.Util.Create("TextLabel", {
                Name = "Checkmark",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = isSelected and "✓" or "",
                TextColor3 = self._theme.TextColor,
                TextScaled = true,
                Font = self._theme.Font,
                Parent = checkbox
            })
            
            -- Option text
            local _optionText = Core.Util.Create("TextLabel", {
                Name = "Text",
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 32, 0, 0),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = self._theme.TextColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = self._theme.Font,
                TextSize = 14,
                Parent = optionFrame
            })
            
            -- Click handler
            local button = Core.Util.Create("TextButton", {
                Name = "Button",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = optionFrame
            })
            
            button.InputBegan:Connect(function(input)
                if Core.Util.IsTouch(input.UserInputType) then
                    self:ToggleValue(option)
                end
            end)
            
            -- Hover effects
            button.MouseEnter:Connect(function()
                optionFrame.BackgroundColor3 = self._theme.Accent
                optionFrame.BackgroundTransparency = 0.8
            end)
            
            button.MouseLeave:Connect(function()
                optionFrame.BackgroundColor3 = self._theme.Background2
                optionFrame.BackgroundTransparency = 0
            end)
            
            height = height + 32
        end
        
        -- Update canvas size
        self.Options.CanvasSize = UDim2.new(1, 0, 0, height)
    end
    
    function MultiDropdown:ToggleValue(value)
        local index = table.find(self._selectedValues, value)
        
        if index then
            -- Remove value if already selected
            table.remove(self._selectedValues, index)
        else
            -- Add value if not selected (check max limit)
            if #self._selectedValues < self._maxSelections then
                table.insert(self._selectedValues, value)
            end
        end
        
        -- Update UI
        self:_updateHeaderText()
        self:SetOptions(self._options) -- Refresh to update checkboxes
        
        -- Call callback with current selections
        if self._callback then 
            self._callback(self._selectedValues) 
        end
    end
    
    function MultiDropdown:Toggle(state)
        if state ~= nil then 
            self._open = state 
        else 
            self._open = not self._open 
        end
        
        local numOptions = #self._options
        local maxHeight = math.min(numOptions * 32, 160)
        local size = self._open and UDim2.new(1, 0, 0, maxHeight) or UDim2.new(1, 0, 0, 0)
        
        TweenService:Create(self.List, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size}):Play()
        TweenService:Create(self.Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = self._open and 180 or 0}):Play()
        
        -- Z-index management
        if self._open then
            self.Root.ZIndex = 100
            self.List.ZIndex = 101
            self.Options.ZIndex = 102
            for _, child in pairs(self.Options:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("Option_") then
                    child.ZIndex = 103
                    for _, subchild in pairs(child:GetChildren()) do
                        subchild.ZIndex = 104
                    end
                end
            end
        else
            task.delay(0.2, function()
                if not self._open then
                    self.Root.ZIndex = 1
                    self.List.ZIndex = 2
                    self.Options.ZIndex = 1
                    for _, child in pairs(self.Options:GetChildren()) do
                        if child:IsA("Frame") then
                            child.ZIndex = 1
                            for _, subchild in pairs(child:GetChildren()) do
                                subchild.ZIndex = 1
                            end
                        end
                    end
                end
            end)
        end
    end
    
    function MultiDropdown:SetValues(values, animate)
        self._selectedValues = {}
        if values and type(values) == "table" then
            for _, value in ipairs(values) do
                if table.find(self._options, value) and #self._selectedValues < self._maxSelections then
                    table.insert(self._selectedValues, value)
                end
            end
        end
        self:_updateHeaderText()
        self:SetOptions(self._options) -- Refresh UI
        if self._callback then self._callback(self._selectedValues) end
    end
    
    function MultiDropdown:GetValues() 
        return self._selectedValues 
    end
    
    function MultiDropdown:ClearSelection()
        self._selectedValues = {}
        self:_updateHeaderText()
        self:SetOptions(self._options) -- Refresh UI
        if self._callback then self._callback(self._selectedValues) end
    end
    
    function MultiDropdown:SetMaxSelections(max)
        self._maxSelections = max or math.huge
        -- Remove excess selections if needed
        while #self._selectedValues > self._maxSelections do
            table.remove(self._selectedValues)
        end
        self:_updateHeaderText()
        self:SetOptions(self._options) -- Refresh UI
    end
    
    function MultiDropdown:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.Header.TextColor3 = self._theme.TextColor
        self.Arrow.TextColor3 = self._theme.TextColor
        self.List.BackgroundColor3 = self._theme.Background2
        self.Options.ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent
        self.Options.ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or self.Options.ScrollBarThickness
        
        -- Refresh option styling
        for _, child in pairs(self.Options:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("Option_") then
                child.BackgroundColor3 = self._theme.Background2
                local checkbox = child:FindFirstChild("Checkbox")
                local text = child:FindFirstChild("Text")
                if checkbox then
                    local isSelected = checkbox:FindFirstChild("Checkmark") and checkbox.Checkmark.Text == "✓"
                    checkbox.BackgroundColor3 = isSelected and self._theme.Accent or self._theme.Background
                    checkbox.BorderColor3 = self._theme.Accent
                    if checkbox:FindFirstChild("Checkmark") then
                        checkbox.Checkmark.TextColor3 = self._theme.TextColor
                    end
                end
                if text then
                    text.TextColor3 = self._theme.TextColor
                end
            end
        end
    end

    -- Hotkey
    local Hotkey = setmetatable({}, {__index = BaseComponent})
    Hotkey.__index = Hotkey
    function Hotkey.new(props)
        local self = BaseComponent.new({ Name = "Hotkey", Theme = props.Theme or Theme })
        setmetatable(self, Hotkey)
        self.Root = Core.Util.Create("Frame", { Name = "Hotkey", Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = props.Parent })
        self:_createLabel(props.Text)
        self:_createButton()
        self._callback = props.Callback
        self._listening = false
        self:SetValue(props.Value or "None", false)
        return self
    end
    function Hotkey:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = text or "Hotkey", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Hotkey:_createButton()
        self.Button = Core.Util.Create("TextButton", { Name = "Button", Size = UDim2.fromOffset(90, 24), Position = UDim2.new(1, -90, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.Background2, Text = "None", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        self.Button.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                self:StartListening()
            end
        end)
    end
    function Hotkey:StartListening()
        if self._listening then return end
        self._listening = true
        self.Button.Text = "..."
        Core.Util.Tween(self.Button, { BackgroundColor3 = self._theme.Accent }, 0.2)
        local connection
        local UIS = game:GetService("UserInputService")
        self._hotkeyConnections = self._hotkeyConnections or {}
        connection = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyName = input.KeyCode.Name
                self:SetValue(keyName)
                self:StopListening()
                pcall(function() connection:Disconnect() end)
            end
        end)
        table.insert(self._hotkeyConnections, connection)
    end
    function Hotkey:StopListening()
        if not self._listening then return end
        self._listening = false
        Core.Util.Tween(self.Button, { BackgroundColor3 = self._theme.Background2 }, 0.2)
    end
    function Hotkey:SetValue(value, animate)
        -- Convert KeyCode enum to string if needed
        if typeof(value) == "EnumItem" then
            value = value.Name
        end
        self._value = value or "None"
        self.Button.Text = self._value
        if self._callback then self._callback(self._value) end
    end
    function Hotkey:GetValue() return self._value end
    function Hotkey:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Button.BackgroundColor3 = self._listening and self._theme.Accent or self._theme.Background2
        self.Button.TextColor3 = self._theme.TextColor
    end
    function Hotkey:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if self._hotkeyConnections then
            for _, c in ipairs(self._hotkeyConnections) do pcall(function() c:Disconnect() end) end
            self._hotkeyConnections = nil
        end
        if self.Root then self.Root:Destroy() end
    end

    -- Notification
    local Notification = setmetatable({}, {__index = BaseComponent})
    Notification.__index = Notification
    function Notification.new(props)
        local self = BaseComponent.new({ Name = "Notification", Theme = props.Theme or Theme })
        setmetatable(self, Notification)
        
        -- Store position for animations
        self._position = props.Position or "TopRight"
        
        -- Create ScreenGui for notification
        self.ScreenGui = Core.Util.Create("ScreenGui", {
            Name = "StellarNotif_" .. Core.Safety.RandomString(8),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = Core.Safety.GetRoot()
        })
        Core.Safety.ProtectInstance(self.ScreenGui)
        
        self.Root = Core.Util.Create("Frame", { Name = "Notification", Size = UDim2.new(0, 280, 0, 80), Position = self:_getStartPosition(self._position), AnchorPoint = self:_getAnchorPoint(self._position), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = self.ScreenGui })
        self.Title = Core.Util.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, Text = props.Title or "Notification", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        self.Message = Core.Util.Create("TextLabel", { Name = "Message", Size = UDim2.new(1, -16, 1, -40), Position = UDim2.fromOffset(8, 32), BackgroundTransparency = 1, Text = props.Text or "", TextColor3 = self._theme.SubTextColor, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        if self._theme.EnableBrackets then self:_createCornerBrackets() end
        
        -- Apply FX if provided
        if props.FX then
            self._fx = Core.FX.Apply(self.Root, props.FX, self._theme)
        end
        
        if props.Duration then self:_startTimer(props.Duration) end
        self:_animate()
        return self
    end
    function Notification:_getAnchorPoint(position)
        -- Set proper anchor point based on position
        if position == "TopRight" or position == "RightMiddle" or position == "BottomRight" then 
            return Vector2.new(1, 0.5)
        elseif position == "TopLeft" or position == "LeftMiddle" or position == "BottomLeft" then 
            return Vector2.new(0, 0.5)
        elseif position == "TopMiddle" or position == "BottomMiddle" then 
            return Vector2.new(0.5, 0.5)
        end
        return Vector2.new(1, 0.5)  -- Default
    end
    function Notification:_getStartPosition(position)
        -- Support 8 notification positions
        if position == "TopRight" then return UDim2.new(1, 20, 0, 20)
        elseif position == "TopMiddle" then return UDim2.new(0.5, 0, 0, -100)
        elseif position == "TopLeft" then return UDim2.new(0, -20, 0, 20)
        elseif position == "RightMiddle" then return UDim2.new(1, 20, 0.5, 0)
        elseif position == "BottomRight" then return UDim2.new(1, 20, 1, 20)
        elseif position == "LeftMiddle" then return UDim2.new(0, -20, 0.5, 0)
        elseif position == "BottomLeft" then return UDim2.new(0, -20, 1, 20)
        elseif position == "BottomMiddle" then return UDim2.new(0.5, 0, 1, 20) end
        return UDim2.new(1, 20, 0, 20)  -- Default to TopRight
    end
    function Notification:_createCornerBrackets()
        local brackets = { TopLeft = {pos = UDim2.fromOffset(-1, -1), size = UDim2.fromOffset(4, 4)}, TopRight = {pos = UDim2.new(1, -3, 0, -1), size = UDim2.fromOffset(4, 4)}, BottomLeft = {pos = UDim2.new(0, -1, 1, -3), size = UDim2.fromOffset(4, 4)}, BottomRight = {pos = UDim2.new(1, -3, 1, -3), size = UDim2.fromOffset(4, 4)} }
        for name, data in pairs(brackets) do
            local bracket = Core.Util.Create("Frame", { Name = name, Size = data.size, Position = data.pos, BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = self.Root })
            Core.Util.Create("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = bracket })
        end
    end
    function Notification:_startTimer(duration)
        local progress = Core.Util.Create("Frame", { Name = "Progress", Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = self._theme.Accent, BorderSizePixel = 0, Parent = self.Root })
        TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
        task.delay(duration, function() if not self._destroyed then self:Close() end end)
    end
    function Notification:_animate()
        self.Root.Position = self:_getStartPosition(self._position)
        self.Root.BackgroundTransparency = 1
        
        -- Calculate slide direction based on position
        local offsetX, offsetY = 0, 0
        if self._position:match("Right") then offsetX = -40
        elseif self._position:match("Left") then offsetX = 40
        elseif self._position:match("Middle") and self._position:match("Top") then offsetY = 40
        elseif self._position:match("Middle") and self._position:match("Bottom") then offsetY = -40
        end
        
        local targetPos = UDim2.new(self.Root.Position.X.Scale, self.Root.Position.X.Offset + offsetX, self.Root.Position.Y.Scale, self.Root.Position.Y.Offset + offsetY)
        TweenService:Create(self.Root, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos, BackgroundTransparency = 0}):Play()
    end
    function Notification:Close()
        if self._destroyed then return end
        
        -- Calculate slide direction for closing
        local offsetX, offsetY = 0, 0
        if self._position:match("Right") then offsetX = 40
        elseif self._position:match("Left") then offsetX = -40
        elseif self._position:match("Middle") and self._position:match("Top") then offsetY = -40
        elseif self._position:match("Middle") and self._position:match("Bottom") then offsetY = 40
        end
        
        local targetPos = UDim2.new(self.Root.Position.X.Scale, self.Root.Position.X.Offset + offsetX, self.Root.Position.Y.Scale, self.Root.Position.Y.Offset + offsetY)
        TweenService:Create(self.Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = targetPos, BackgroundTransparency = 1}):Play()
        task.delay(0.2, function() self:Destroy() end)
    end
    function Notification:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end

    -- Exports
    UI.Window = Window
    UI.Button = Button
    UI.Toggle = Toggle
    UI.Slider = Slider
    UI.TextInput = TextInput
    UI.Dropdown = Dropdown
    UI.MultiDropdown = MultiDropdown
    UI.Hotkey = Hotkey
    UI.Notification = Notification

    -- Sugar: add helpers onto Window to match Example-style ease
    function Window:AddButton(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local comp = Button.new({ Parent = parent, Text = opts.Text, Callback = opts.Callback, Theme = self._theme, FX = opts.FX })
        comp.Flag = opts.Flag
        table.insert(self._components, comp)
        return comp
    end
    function Window:AddToggle(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local comp = Toggle.new({ Parent = parent, Text = opts.Text, Value = opts.Value, Callback = opts.Callback, Theme = self._theme })
        comp.Flag = opts.Flag
        table.insert(self._components, comp)
        return comp
    end
    function Window:AddSlider(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local comp = Slider.new({ Parent = parent, Text = opts.Text, Min = opts.Min, Max = opts.Max, Step = opts.Step, Value = opts.Value, Callback = opts.Callback, Theme = self._theme })
        comp.Flag = opts.Flag
        table.insert(self._components, comp)
        return comp
    end
    function Window:AddTextbox(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local comp = TextInput.new({ Parent = parent, Text = opts.Text, Placeholder = opts.Placeholder, Callback = opts.Callback, Theme = self._theme })
        comp.Flag = opts.Flag
        table.insert(self._components, comp)
        return comp
    end
    function Window:AddDropdown(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local dd = Dropdown.new({ Parent = parent, Text = opts.Text, Options = opts.Options, Value = opts.Value, Callback = opts.Callback, Theme = self._theme })
        dd:SetOptions(opts.Options or {})
        dd.Flag = opts.Flag
        table.insert(self._components, dd)
        return dd
    end
    function Window:AddMultiDropdown(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local mdd = MultiDropdown.new({ 
            Parent = parent, 
            Text = opts.Text, 
            Options = opts.Options, 
            Values = opts.Values, 
            Value = opts.Value, 
            Callback = opts.Callback, 
            MaxSelections = opts.MaxSelections,
            Theme = self._theme 
        })
        mdd:SetOptions(opts.Options or {})
        mdd.Flag = opts.Flag
        table.insert(self._components, mdd)
        return mdd
    end
    function Window:AddHotkey(opts)
        local parent = (self._currentTab and self._currentTab.Page) or self.Content
        local comp = Hotkey.new({ Parent = parent, Text = opts.Text, Value = opts.Value, Callback = opts.Callback, Theme = self._theme })
        comp.Flag = opts.Flag
        table.insert(self._components, comp)
        return comp
    end

    return UI
end

-- Build UI with default theme
local Theme = Core.Theme
local UI = BuildUI(Theme)

-- Loading splash component
local LoadingSplash = {}
LoadingSplash.__index = LoadingSplash

function LoadingSplash.new(opts)
    opts = opts or {}
    local self = setmetatable({}, LoadingSplash)
    
    self.ScreenGui = Core.Util.Create("ScreenGui", {
        Name = "StellarSplash_" .. Core.Safety.RandomString(8),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = Core.Safety.GetRoot()
    })
    Core.Safety.ProtectInstance(self.ScreenGui)
    
    -- Background
    self.Background = Core.Util.Create("Frame", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Overlays and Theme.Overlays.Color or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = Theme.Overlays and Theme.Overlays.Transparency or 0.3,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    
    -- Main container
    self.Container = Core.Util.Create("Frame", {
        Name = "Container",
        Size = UDim2.fromOffset(400, 200),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window.Background,
        BorderSizePixel = 0,
        Parent = self.Background
    })
    
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = self.Container })
    
    -- Title
    self.Title = Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = opts.Title or "STELLAR",
        TextColor3 = Theme.Window.TitleText,
        Font = Theme.Font,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Version
    self.Version = Core.Util.Create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.fromOffset(16, 56),
        BackgroundTransparency = 1,
        Text = "v" .. (opts.Version or Core.Version),
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Status text
    self.Status = Core.Util.Create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.fromOffset(16, 100),
        BackgroundTransparency = 1,
        Text = opts.Status or "Loading...",
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Progress bar background
    local progressBg = Core.Util.Create("Frame", {
        Name = "ProgressBg",
        Size = UDim2.new(1, -64, 0, 4),
        Position = UDim2.fromOffset(32, 140),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = progressBg })
    
    -- Progress bar fill
    self.ProgressBar = Core.Util.Create("Frame", {
        Name = "ProgressBar",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = progressBg
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = self.ProgressBar })
    
    -- Footer text
    self.Footer = Core.Util.Create("TextLabel", {
        Name = "Footer",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.new(0, 16, 1, -36),
        BackgroundTransparency = 1,
        Text = opts.Footer or "Initializing components...",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Apply FX if provided
    if opts.FX then
        self._fx = Core.FX.Apply(self.Container, opts.FX, Theme)
    end
    
    -- Fade in animation
    self.Container.BackgroundTransparency = 1
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
        elseif child:IsA("Frame") then
            child.BackgroundTransparency = 1
        end
    end
    
    TweenService:Create(self.Container, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        elseif child:IsA("Frame") and child.Name ~= "Container" then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
        end
    end
    
    return self
end

function LoadingSplash:SetProgress(progress, status)
    if self.ProgressBar then
        TweenService:Create(self.ProgressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(progress, 1)}):Play()
    end
    if status and self.Status then
        self.Status.Text = status
    end
end

function LoadingSplash:SetFooter(text)
    if self.Footer then
        self.Footer.Text = text
    end
end

function LoadingSplash:Close()
    if not self.ScreenGui then return end
    
    -- Fade out
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        elseif child:IsA("Frame") and child.Name ~= "Container" then
            TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        end
    end
    TweenService:Create(self.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    TweenService:Create(self.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    
    task.delay(0.35, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)
end

-- Authorization modal
local Authorization = {}
Authorization.__index = Authorization

function Authorization.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Authorization)
    
    self.ValidateCallback = opts.ValidateKey or function(key) return key == "default" end
    self.SuccessCallback = opts.OnSuccess or function() end
    self.FailCallback = opts.OnFail or function() end
    
    self.ScreenGui = Core.Util.Create("ScreenGui", {
        Name = "StellarAuth_" .. Core.Safety.RandomString(8),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = Core.Safety.GetRoot()
    })
    Core.Safety.ProtectInstance(self.ScreenGui)
    
    -- Background
    self.Background = Core.Util.Create("Frame", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Overlays and Theme.Overlays.Color or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = Theme.Overlays and Theme.Overlays.Transparency or 0.3,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    
    -- Main container
    self.Container = Core.Util.Create("Frame", {
        Name = "Container",
        Size = UDim2.fromOffset(400, 250),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window.Background,
        BorderSizePixel = 0,
        Parent = self.Background
    })
    
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = self.Container })
    
    -- Title
    Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = opts.Title or "AUTHORIZATION REQUIRED",
        TextColor3 = Theme.Window.TitleText,
        Font = Theme.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Subtitle
    Core.Util.Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 56),
        BackgroundTransparency = 1,
        Text = opts.Subtitle or "Enter your access key to continue",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Key input box
    local inputBg = Core.Util.Create("Frame", {
        Name = "InputBg",
        Size = UDim2.new(1, -64, 0, 36),
        Position = UDim2.fromOffset(32, 110),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = inputBg })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = inputBg })
    
    self.KeyInput = Core.Util.Create("TextBox", {
        Name = "KeyInput",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Enter key...",
        PlaceholderColor3 = Theme.DisabledText,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBg
    })
    
    -- Submit button
    self.SubmitButton = Core.Util.Create("TextButton", {
        Name = "SubmitButton",
        Size = UDim2.new(1, -64, 0, 36),
        Position = UDim2.fromOffset(32, 160),
        BackgroundColor3 = Theme.Accent,
        Text = "SUBMIT",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Theme.Font,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self.SubmitButton })
    
    -- Status message
    self.StatusLabel = Core.Util.Create("TextLabel", {
        Name = "StatusLabel",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.new(0, 16, 1, -36),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Button interaction
    self.SubmitButton.MouseEnter:Connect(function()
        TweenService:Create(self.SubmitButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(
            math.min(255, Theme.Accent.R * 255 * 1.2),
            math.min(255, Theme.Accent.G * 255 * 1.2),
            math.min(255, Theme.Accent.B * 255 * 1.2)
        )}):Play()
    end)
    
    self.SubmitButton.MouseLeave:Connect(function()
        TweenService:Create(self.SubmitButton, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
    end)
    
    self.SubmitButton.InputBegan:Connect(function(input)
        if Core.Util.IsTouch(input.UserInputType) then
            self:ValidateKey()
        end
    end)
    
    self.KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self:ValidateKey()
        end
    end)
    
    -- Fade in
    self.Container.BackgroundTransparency = 1
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            child.TextTransparency = 1
        elseif child:IsA("Frame") then
            child.BackgroundTransparency = 1
        end
    end
    
    TweenService:Create(self.Container, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        elseif child:IsA("Frame") and child.Name ~= "Container" then
            local targetTrans = (child.Name == "InputBg") and 0 or 1
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = targetTrans}):Play()
        end
    end
    
    task.delay(0.6, function()
        if self.KeyInput then
            self.KeyInput:CaptureFocus()
        end
    end)
    
    return self
end

function Authorization:ValidateKey()
    local key = self.KeyInput.Text
    
    if key == "" then
        self:SetStatus("Please enter a key", Color3.fromRGB(255, 100, 100))
        return
    end
    
    self.SubmitButton.Text = "VALIDATING..."
    self.KeyInput.TextEditable = false
    
    local success = self.ValidateCallback(key)
    
    if success then
        self:SetStatus("Access granted!", Color3.fromRGB(100, 255, 100))
        task.delay(0.5, function()
            self:Close()
            self.SuccessCallback(key)
        end)
    else
        self:SetStatus("Invalid key", Color3.fromRGB(255, 100, 100))
        self.SubmitButton.Text = "SUBMIT"
        self.KeyInput.TextEditable = true
        self.KeyInput.Text = ""
        self.FailCallback(key)
    end
end

function Authorization:SetStatus(text, color)
    if self.StatusLabel then
        self.StatusLabel.Text = text
        if color then
            self.StatusLabel.TextColor3 = color
        end
    end
end

function Authorization:Close()
    if not self.ScreenGui then return end
    
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        elseif child:IsA("Frame") and child.Name ~= "Container" then
            TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        end
    end
    TweenService:Create(self.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    TweenService:Create(self.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    
    task.delay(0.35, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)
end

-- Announcement modal
local Announcement = {}
Announcement.__index = Announcement

function Announcement.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Announcement)
    
    self.Callbacks = {}
    
    -- Use passed theme or fallback to static Theme
    local theme = opts.Theme or Theme
    
    self.ScreenGui = Core.Util.Create("ScreenGui", {
        Name = "StellarAnnounce_" .. Core.Safety.RandomString(8),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = Core.Safety.GetRoot()
    })
    Core.Safety.ProtectInstance(self.ScreenGui)
    
    -- Full-screen background overlay
    self.Background = Core.Util.Create("Frame", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Overlays and theme.Overlays.Color or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = theme.Overlays and theme.Overlays.Transparency or 0.3,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    
    -- Main announcement container
    self.Container = Core.Util.Create("Frame", {
        Name = "Container",
        Size = UDim2.fromOffset(500, 300),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window.Background,
        BorderSizePixel = 0,
        Parent = self.Background
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 2, Parent = self.Container })
    
    -- Title bar with accent
    local titleBar = Core.Util.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    -- No UICorner on title bar - we want sharp bottom corners
    -- Only round the top corners via container's corner
    
    -- Title text
    self.Title = Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = opts.Title or "ANNOUNCEMENT",
        TextColor3 = theme.Window.Background,  -- Contrasting color on accent
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = titleBar
    })
    
    -- Message area
    local messageContainer = Core.Util.Create("Frame", {
        Name = "MessageContainer",
        Size = UDim2.new(1, -32, 1, -130),
        Position = UDim2.fromOffset(16, 60),
        BackgroundTransparency = 1,
        Parent = self.Container
    })
    
    self.Message = Core.Util.Create("TextLabel", {
        Name = "Message",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = opts.Message or "This is an important announcement.",
        TextColor3 = Color3.fromRGB(255, 255, 255),  -- Bright white for visibility
        Font = theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = messageContainer
    })
    
    -- Button container
    local buttonContainer = Core.Util.Create("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -32, 0, 50),
        Position = UDim2.new(0, 16, 1, -66),
        BackgroundTransparency = 1,
        Parent = self.Container
    })
    
    Core.Util.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = buttonContainer
    })
    
    -- Create buttons
    local buttons = opts.Buttons or {{Text = "OK", Primary = true}}
    for i, buttonData in ipairs(buttons) do
        local button = Core.Util.Create("TextButton", {
            Name = "Button_" .. i,
            Size = UDim2.fromOffset(100, 40),
            BackgroundColor3 = buttonData.Primary and theme.Accent or theme.Background2,
            Text = buttonData.Text or "Button",
            TextColor3 = buttonData.Primary and theme.Window.Background or theme.TextColor,
            Font = buttonData.Primary and Enum.Font.GothamBold or theme.Font,
            TextSize = 14,
            LayoutOrder = i,
            BorderSizePixel = 0,
            Parent = buttonContainer
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
        
        if not buttonData.Primary then
            Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = button })
        end
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            if buttonData.Primary then
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
                    math.min(255, theme.Accent.R * 255 * 1.2),
                    math.min(255, theme.Accent.G * 255 * 1.2),
                    math.min(255, theme.Accent.B * 255 * 1.2)
                )}):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Background}):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if buttonData.Primary then
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Accent}):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Background2}):Play()
            end
        end)
        
        button.InputBegan:Connect(function(input)
            if Core.Util.IsTouch(input.UserInputType) then
                -- Prevent double-activations and ensure UI always closes
                if self._closing then return end
                self._closing = true
                -- Disable button visuals immediately
                button.Active = false
                button.AutoButtonColor = false
                -- Always close the announcement first so UI doesn't linger if callback errors
                self:Close()
                -- Run callback safely in background
                if buttonData.Callback then
                    task.spawn(function()
                        local ok, err = pcall(buttonData.Callback)
                        if not ok then warn("[Announcement] Button callback error:", err) end
                    end)
                end
            end
        end)
    end
    
    -- Apply FX if provided
    if opts.FX then
        self._fx = Core.FX.Apply(self.Container, opts.FX, theme)
    end
    
    -- Fade in animation
    self.Container.Size = UDim2.fromOffset(400, 250)
    self.Background.BackgroundTransparency = 1
    self.Container.BackgroundTransparency = 1
    
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child.TextTransparency = 1
        elseif child:IsA("Frame") then
            -- Start transparent for fade-in; we'll restore selective targets below
            child.BackgroundTransparency = 1
        elseif child:IsA("UIStroke") then
            child.Transparency = 1
        end
    end
    
    -- Animate entrance
    TweenService:Create(self.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundTransparency = Theme.Overlays and Theme.Overlays.Transparency or 0.3
    }):Play()
    
    TweenService:Create(self.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(500, 300),
        BackgroundTransparency = 0
    }):Play()
    
    task.delay(0.2, function()
        for _, child in ipairs(self.Container:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            elseif child:IsA("Frame") and child ~= self.Container then
                -- Only make visual frames opaque; keep layout containers transparent
                local targetTrans
                if child.Name == "TitleBar" then
                    targetTrans = 0
                elseif child.Name == "MessageContainer" or child.Name == "ButtonContainer" then
                    targetTrans = 1  -- remain transparent
                else
                    -- Default for other helper frames within buttons/etc.
                    targetTrans = 0
                end
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = targetTrans}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
            end
        end
    end)
    
    return self
end

function Announcement:Close()
    if not self.ScreenGui or self._closed then return end
    self._closed = true

    -- Compute a subtle shrink target based on current size (for smoother feel)
    local curSize = self.Container.AbsoluteSize
    local targetSize = UDim2.fromOffset(math.max(1, curSize.X * 0.92), math.max(1, curSize.Y * 0.92))

    local containerTween = TweenService:Create(self.Container, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = targetSize,
        BackgroundTransparency = 1
    })
    containerTween:Play()

    local bgTween = TweenService:Create(self.Background, TweenInfo.new(0.32, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1
    })
    bgTween:Play()

    -- Fade out children content for smoother exit (text, strokes, and frames)
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        elseif child:IsA("UIStroke") then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
        elseif child:IsA("Frame") and child ~= self.Container then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        end
    end

    -- Immediately disable interactions to avoid lingering hover/click states
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextButton") then
            child.Active = false
            child.AutoButtonColor = false
            child.Selectable = false
        end
    end

    -- Safety: hide visuals shortly after to ensure nothing lingers visually
    task.delay(0.35, function()
        if self.Container then self.Container.Visible = false end
        if self.Background then self.Background.Visible = false end
    end)

    -- Destroy after tweens complete to avoid abrupt disappearance
    task.spawn(function()
        pcall(function() containerTween.Completed:Wait() end)
        pcall(function() bgTween.Completed:Wait() end)
        task.wait(0.02)
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)

    -- Failsafe: hard-destroy after timeout in case tween events don't fire
    task.delay(1.0, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)
end

-- Library API

-- Hot reload: Destroy existing instance if re-executing
local _getgenv = rawget(_G, 'getgenv')
local env = (type(_getgenv) == 'function' and _getgenv() ) or _G
if env.StellarUI then
    if env.StellarUI.Unload then
        env.StellarUI:Unload()
    end
end

local Library = {
    Core = Core,
    Theme = Theme,
    UI = UI,
    Windows = {},
}

-- Store in getgenv() for hot reloading
env.StellarUI = Library

function Library:GetExecutorInfo()
    return Core.Safety.getExecutorInfo()
end

function Library:HasSecureTable()
    return Core.Safety.hasSecureTable()
end

function Library:CreateSecureTable(arraySize, hashSize)
    return Core.Safety.createSecureTable(arraySize, hashSize)
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local theme = opts.Theme or Theme
    local window = UI.Window.new({
        Theme = theme,
        Title = opts.Title or "Stellar",
        SubTitle = opts.SubTitle,
        Size = opts.Size,
        Width = opts.Width,
        Height = opts.Height,
        DockThreshold = opts.DockThreshold,  -- Optional: width threshold for auto-dock (default 450)
        DockWidth = opts.DockWidth,          -- Optional: dock panel width (default 150)
    })
    table.insert(self.Windows, window)
    return window
end

function Library:Notify(opts)
    return UI.Notification.new({
        Theme = self.Theme,
        Title = opts.Title,
        Text = opts.Text,
        Duration = opts.Duration,
        Position = opts.Position,
        FX = opts.FX,
    })
end

function Library:ShowLoadingSplash(opts)
    opts = opts or {}
    return LoadingSplash.new({
        Title = opts.Title or "STELLAR",
        Version = opts.Version or Core.Version,
        Status = opts.Status or "Loading...",
        Footer = opts.Footer or "Initializing components...",
        FX = opts.FX,
    })
end

function Library:RequestAuth(opts)
    opts = opts or {}
    return Authorization.new({
        Title = opts.Title,
        Subtitle = opts.Subtitle,
        ValidateKey = opts.ValidateKey,
        OnSuccess = opts.OnSuccess,
        OnFail = opts.OnFail,
    })
end

function Library:ShowAnnouncement(opts)
    opts = opts or {}
    return Announcement.new({
        Title = opts.Title,
        Message = opts.Message,
        Buttons = opts.Buttons,
        FX = opts.FX,
        Theme = self.Theme,
    })
end

-- Refresh all windows/components after theme changes
function Library:RefreshAll()
    for _, window in ipairs(self.Windows) do
        -- Update window theme
        window._theme = self.Theme
        if window.RefreshTheme then window:RefreshTheme() end
        -- Update child components if tracked
        if window._components then
            for _, comp in ipairs(window._components) do
                if comp and comp.RefreshTheme then
                    comp._theme = self.Theme
                    comp:RefreshTheme()
                end
            end
        end
    end
end

-- Unload/destroy all GUI instances (for hot reload)
function Library:Unload()
    -- Destroy all windows
    for _, window in ipairs(self.Windows) do
        if window and window.Destroy then
            window:Destroy()
        end
    end
    
    -- Clear windows table
    self.Windows = {}
    
    -- Clean up any lingering ScreenGuis
    local root = Core.Safety.GetRoot()
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("ScreenGui") and (
            child.Name:match("^StellarUI_") or 
            child.Name:match("^StellarSplash_") or 
            child.Name:match("^StellarAuth_") or
            child.Name:match("^StellarAnnounce_")
        ) then
            child:Destroy()
        end
    end
end

return Library
