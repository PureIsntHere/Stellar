--!nocheck
-- Stellar ThemeManager - External theme system

return function()
    local ThemeManager = {}
    ThemeManager.Library = nil
    ThemeManager.Presets = {}

    function ThemeManager:SetLibrary(Library)
        self.Library = Library
        return self
    end

    -- Helper functions
    local function clamp01(x)
        if x < 0 then return 0 elseif x > 1 then return 1 else return x end
    end
    local function rgb(hex)
        hex = hex:gsub('#','')
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        return Color3.fromRGB(r, g, b)
    end
    local function lighten(color, pct)
        local r, g, b = color.R, color.G, color.B
        return Color3.new(clamp01(r + (1 - r) * pct), clamp01(g + (1 - g) * pct), clamp01(b + (1 - b) * pct))
    end
    local function darken(color, pct)
        local r, g, b = color.R, color.G, color.B
        return Color3.new(clamp01(r * (1 - pct)), clamp01(g * (1 - pct)), clamp01(b * (1 - pct)))
    end

    local function deepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local seen = {}
        local function _copy(t)
            if type(t) ~= 'table' then return t end
            if seen[t] then return seen[t] end
            local out = {}
            seen[t] = out
            for k, v in pairs(t) do
                out[k] = (type(v) == 'table') and _copy(v) or v
            end
            return out
        end
        return _copy(tbl)
    end

    -- Merge helper for theme overrides
    local function merge(into, from)
        if type(into) ~= 'table' or type(from) ~= 'table' then return into end
        for k, v in pairs(from) do
            if type(v) == 'table' then
                if type(into[k]) ~= 'table' then into[k] = {} end
                for kk, vv in pairs(v) do into[k][kk] = vv end
            else
                into[k] = v
            end
        end
        return into
    end

    -- Build theme from palette
    local function buildTheme(p)
        local bg = p.bg; local bg2 = p.bg2 or darken(bg, 0.08)
        local bg3 = p.bg3 or darken(bg2, 0.08)
        local text = p.text
        local sub = p.sub or lighten(text, -0.25)
        local disabled = p.disabled or lighten(sub, -0.15)
        local accent = p.accent
        local accentDim = p.accentDim or darken(accent, 0.35)
        local border = p.border or darken(bg, 0.4)
        local bracket = p.bracket or lighten(border, 0.35)
        local fx = p.fx or {}
        return {
            Background = bg,
            Background2 = bg2,
            Background3 = bg3,
            TextColor = text,
            SubTextColor = sub,
            DisabledText = disabled,
            Accent = accent,
            AccentDim = accentDim,
            Border = border,
            Window = {
                Background = bg,
                TitleText = text,
                SubtitleText = sub,
                Border = border,
                CornerBrackets = bracket,
            },
            Tab = {
                IdleFill = bg2,
                ActiveFill = bg,
                IdleText = sub,
                ActiveText = text,
                Border = border,
            },
            FX = {
                CornerBrackets = bracket,
                ScanlineColor = fx.ScanlineColor or text,
                ScanlineTransparency = fx.ScanlineTransparency or 0.85,
                ScanlineSpeed = fx.ScanlineSpeed or 60,
                TopSweepColor = fx.TopSweepColor or bracket,
                TopSweepThickness = fx.TopSweepThickness or 2,
                TopSweepSpeed = fx.TopSweepSpeed or 180,
                TopSweepGap = fx.TopSweepGap or 26,
                TopSweepLength = fx.TopSweepLength or 120,
                GridColor = fx.GridColor or (p.grid or border),
                GridAlpha = fx.GridAlpha or 0.06,
                GridGap = fx.GridGap or 16,
            }
        }
    end

    -- Preset themes
    ThemeManager.Presets = {
        ["Nord"] = buildTheme({ 
            bg = rgb('#2E3440'), 
            bg2 = rgb('#3B4252'), 
            bg3 = rgb('#434C5E'),
            text = rgb('#E5E9F0'), 
            sub = rgb('#D8DEE9'), 
            disabled = rgb('#81A1C1'),
            accent = rgb('#88C0D0'), 
            accentDim = rgb('#5E81AC'),
            border = rgb('#4C566A'),
            bracket = rgb('#616E88'),
            fx = {
                ScanlineColor = rgb('#8FBCBB'),
                ScanlineTransparency = 0.88,
                ScanlineSpeed = 55,
                TopSweepColor = rgb('#5E81AC'),
                TopSweepThickness = 2,
                TopSweepSpeed = 160,
                TopSweepGap = 28,
                TopSweepLength = 140,
                GridColor = rgb('#4C566A'),
                GridAlpha = 0.05,
                GridGap = 18
            }
        }),
        ["Dracula"] = buildTheme({ 
            bg = rgb('#1E1F29'), 
            bg2 = rgb('#282A36'), 
            bg3 = rgb('#21222C'),
            text = rgb('#F8F8F2'), 
            sub = rgb('#E2E2DC'), 
            disabled = rgb('#6272A4'),
            accent = rgb('#BD93F9'), 
            accentDim = rgb('#6272A4'), 
            border = rgb('#44475A'),
            bracket = rgb('#625F6B'),
            fx = {
                ScanlineColor = rgb('#FF79C6'),
                ScanlineTransparency = 0.82,
                ScanlineSpeed = 70,
                TopSweepColor = rgb('#BD93F9'),
                TopSweepThickness = 3,
                TopSweepSpeed = 200,
                TopSweepGap = 32,
                TopSweepLength = 160,
                GridColor = rgb('#44475A'),
                GridAlpha = 0.08,
                GridGap = 16
            }
        }),
        ["Tokyo Night"] = buildTheme({ 
            bg = rgb('#1A1B26'), 
            bg2 = rgb('#24283B'), 
            bg3 = rgb('#1F2335'),
            text = rgb('#C0CAF5'), 
            sub = rgb('#A9B1D6'), 
            disabled = rgb('#565F89'),
            accent = rgb('#7AA2F7'), 
            accentDim = rgb('#3D59A1'),
            border = rgb('#3B4261'),
            bracket = rgb('#565F89'),
            fx = {
                ScanlineColor = rgb('#BB9AF7'),
                ScanlineTransparency = 0.86,
                ScanlineSpeed = 65,
                TopSweepColor = rgb('#7AA2F7'),
                TopSweepThickness = 2,
                TopSweepSpeed = 175,
                TopSweepGap = 26,
                TopSweepLength = 130,
                GridColor = rgb('#3B4261'),
                GridAlpha = 0.06,
                GridGap = 20
            }
        }),
        ["Catppuccin Mocha"] = buildTheme({ 
            bg = rgb('#1E1E2E'), 
            bg2 = rgb('#181825'), 
            bg3 = rgb('#11111B'),
            text = rgb('#CDD6F4'), 
            sub = rgb('#A6ADC8'), 
            disabled = rgb('#6C7086'),
            accent = rgb('#89B4FA'), 
            accentDim = rgb('#74C7EC'),
            border = rgb('#313244'),
            bracket = rgb('#45475A'),
            fx = {
                ScanlineColor = rgb('#F5C2E7'),
                ScanlineTransparency = 0.87,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#89B4FA'),
                TopSweepThickness = 2,
                TopSweepSpeed = 150,
                TopSweepGap = 24,
                TopSweepLength = 125,
                GridColor = rgb('#313244'),
                GridAlpha = 0.04,
                GridGap = 22
            }
        }),
        ["Rose Pine"] = buildTheme({ 
            bg = rgb('#191724'), 
            bg2 = rgb('#1F1D2E'), 
            bg3 = rgb('#26233A'),
            text = rgb('#E0DEF4'), 
            sub = rgb('#908CAA'), 
            disabled = rgb('#6E6A86'),
            accent = rgb('#C4A7E7'), 
            accentDim = rgb('#9CCFD8'),
            border = rgb('#26233A'),
            bracket = rgb('#403D52'),
            fx = {
                ScanlineColor = rgb('#EBBCBA'),
                ScanlineTransparency = 0.85,
                ScanlineSpeed = 60,
                TopSweepColor = rgb('#C4A7E7'),
                TopSweepThickness = 2,
                TopSweepSpeed = 180,
                TopSweepGap = 24,
                TopSweepLength = 120,
                GridColor = rgb('#26233A'),
                GridAlpha = 0.06,
                GridGap = 16
            }
        }),
        ["One Dark"] = buildTheme({ 
            bg = rgb('#21252B'), 
            bg2 = rgb('#282C34'), 
            bg3 = rgb('#1E2127'),
            text = rgb('#D7DAE0'), 
            sub = rgb('#979DA6'), 
            disabled = rgb('#5C6370'),
            accent = rgb('#61AFEF'), 
            accentDim = rgb('#56B6C2'),
            border = rgb('#3E4451'),
            bracket = rgb('#528BFF'),
            fx = {
                ScanlineColor = rgb('#98C379'),
                ScanlineTransparency = 0.84,
                ScanlineSpeed = 72,
                TopSweepColor = rgb('#61AFEF'),
                TopSweepThickness = 2,
                TopSweepSpeed = 190,
                TopSweepGap = 30,
                TopSweepLength = 145,
                GridColor = rgb('#3E4451'),
                GridAlpha = 0.07,
                GridGap = 18
            }
        }),
        ["Gruvbox Dark"] = buildTheme({ 
            bg = rgb('#282828'), 
            bg2 = rgb('#32302F'), 
            bg3 = rgb('#1D2021'),
            text = rgb('#EBDBB2'), 
            sub = rgb('#D5C4A1'), 
            disabled = rgb('#A89984'),
            accent = rgb('#FE8019'), 
            accentDim = rgb('#D65D0E'),
            border = rgb('#504945'),
            bracket = rgb('#665C54'),
            fx = {
                ScanlineColor = rgb('#FABD2F'),
                ScanlineTransparency = 0.83,
                ScanlineSpeed = 58,
                TopSweepColor = rgb('#FE8019'),
                TopSweepThickness = 3,
                TopSweepSpeed = 165,
                TopSweepGap = 28,
                TopSweepLength = 135,
                GridColor = rgb('#504945'),
                GridAlpha = 0.08,
                GridGap = 20
            }
        }),
        ["Monokai"] = buildTheme({ 
            bg = rgb('#1E1F1C'), 
            bg2 = rgb('#272822'), 
            bg3 = rgb('#1A1B17'),
            text = rgb('#F8F8F2'), 
            sub = rgb('#E2E2DC'), 
            disabled = rgb('#75715E'),
            accent = rgb('#66D9EF'), 
            accentDim = rgb('#A6E22E'),
            border = rgb('#3E3D32'),
            bracket = rgb('#49483E'),
            fx = {
                ScanlineColor = rgb('#F92672'),
                ScanlineTransparency = 0.80,
                ScanlineSpeed = 75,
                TopSweepColor = rgb('#66D9EF'),
                TopSweepThickness = 2,
                TopSweepSpeed = 210,
                TopSweepGap = 35,
                TopSweepLength = 155,
                GridColor = rgb('#3E3D32'),
                GridAlpha = 0.09,
                GridGap = 14
            }
        }),
        ["Solarized Dark"] = buildTheme({ 
            bg = rgb('#002B36'), 
            bg2 = rgb('#073642'), 
            bg3 = rgb('#001F27'),
            text = rgb('#EEE8D5'), 
            sub = rgb('#93A1A1'), 
            disabled = rgb('#657B83'),
            accent = rgb('#268BD2'), 
            accentDim = rgb('#2AA198'),
            border = rgb('#586E75'),
            bracket = rgb('#839496'),
            fx = {
                ScanlineColor = rgb('#D33682'),
                ScanlineTransparency = 0.88,
                ScanlineSpeed = 52,
                TopSweepColor = rgb('#268BD2'),
                TopSweepThickness = 2,
                TopSweepSpeed = 140,
                TopSweepGap = 22,
                TopSweepLength = 110,
                GridColor = rgb('#586E75'),
                GridAlpha = 0.05,
                GridGap = 24
            }
        }),
        ["GitHub Dark"] = buildTheme({ 
            bg = rgb('#0D1117'), 
            bg2 = rgb('#161B22'), 
            bg3 = rgb('#010409'),
            text = rgb('#C9D1D9'), 
            sub = rgb('#8B949E'), 
            disabled = rgb('#6E7681'),
            accent = rgb('#58A6FF'), 
            accentDim = rgb('#1F6FEB'),
            border = rgb('#30363D'),
            bracket = rgb('#484F58'),
            fx = {
                ScanlineColor = rgb('#F85149'),
                ScanlineTransparency = 0.86,
                ScanlineSpeed = 68,
                TopSweepColor = rgb('#58A6FF'),
                TopSweepThickness = 2,
                TopSweepSpeed = 185,
                TopSweepGap = 26,
                TopSweepLength = 140,
                GridColor = rgb('#30363D'),
                GridAlpha = 0.06,
                GridGap = 18
            }
        }),
        ["Material Palenight"] = buildTheme({ 
            bg = rgb('#292D3E'), 
            bg2 = rgb('#1B1E2B'), 
            bg3 = rgb('#212431'),
            text = rgb('#BFC7D5'), 
            sub = rgb('#A6ACCD'), 
            disabled = rgb('#676E95'),
            accent = rgb('#82AAFF'), 
            accentDim = rgb('#C792EA'),
            border = rgb('#444A73'),
            bracket = rgb('#5F6890'),
            fx = {
                ScanlineColor = rgb('#FFCB6B'),
                ScanlineTransparency = 0.85,
                ScanlineSpeed = 63,
                TopSweepColor = rgb('#82AAFF'),
                TopSweepThickness = 2,
                TopSweepSpeed = 170,
                TopSweepGap = 25,
                TopSweepLength = 128,
                GridColor = rgb('#444A73'),
                GridAlpha = 0.07,
                GridGap = 19
            }
        }),
        ["Everforest Dark"] = buildTheme({ 
            bg = rgb('#2B3339'), 
            bg2 = rgb('#323C41'), 
            bg3 = rgb('#272E33'),
            text = rgb('#D3C6AA'), 
            sub = rgb('#A7C080'), 
            disabled = rgb('#859289'),
            accent = rgb('#7FBBB3'), 
            accentDim = rgb('#83C092'),
            border = rgb('#4B565C'),
            bracket = rgb('#5A6873'),
            fx = {
                ScanlineColor = rgb('#E69875'),
                ScanlineTransparency = 0.87,
                ScanlineSpeed = 45,
                TopSweepColor = rgb('#7FBBB3'),
                TopSweepThickness = 2,
                TopSweepSpeed = 155,
                TopSweepGap = 27,
                TopSweepLength = 132,
                GridColor = rgb('#4B565C'),
                GridAlpha = 0.05,
                GridGap = 21
            }
        }),
        ["Ayu Mirage"] = buildTheme({ 
            bg = rgb('#1F2430'), 
            bg2 = rgb('#242936'), 
            bg3 = rgb('#1A1F2B'),
            text = rgb('#D9D7CE'), 
            sub = rgb('#B8CFE6'), 
            disabled = rgb('#707A8C'),
            accent = rgb('#59C2FF'), 
            accentDim = rgb('#5CCFE6'),
            border = rgb('#3D4252'),
            bracket = rgb('#4D5566'),
            fx = {
                ScanlineColor = rgb('#FFD580'),
                ScanlineTransparency = 0.84,
                ScanlineSpeed = 67,
                TopSweepColor = rgb('#59C2FF'),
                TopSweepThickness = 2,
                TopSweepSpeed = 175,
                TopSweepGap = 29,
                TopSweepLength = 138,
                GridColor = rgb('#3D4252'),
                GridAlpha = 0.06,
                GridGap = 17
            }
        }),
        ["October"] = buildTheme({ 
            bg = Color3.fromRGB(20, 8, 8), 
            bg2 = Color3.fromRGB(30, 15, 15), 
            bg3 = Color3.fromRGB(15, 5, 5),
            text = Color3.fromRGB(255, 200, 100), 
            sub = Color3.fromRGB(255, 140, 60), 
            disabled = Color3.fromRGB(200, 120, 40),
            accent = Color3.fromRGB(255, 100, 0), 
            accentDim = Color3.fromRGB(200, 80, 0),
            border = Color3.fromRGB(80, 40, 20),
            bracket = Color3.fromRGB(120, 60, 30),
            fx = {
                ScanlineColor = Color3.fromRGB(255, 200, 100),
                ScanlineTransparency = 0.85,
                ScanlineSpeed = 45,
                TopSweepColor = Color3.fromRGB(255, 100, 0),
                TopSweepThickness = 2,
                TopSweepSpeed = 140,
                TopSweepGap = 30,
                TopSweepLength = 150,
                GridColor = Color3.fromRGB(80, 40, 20),
                GridAlpha = 0.06,
                GridGap = 20
            }
        }),
        ["Solarized Light"] = buildTheme({ 
            bg = rgb('#FDF6E3'), 
            bg2 = rgb('#EEE8D5'), 
            bg3 = rgb('#F7F0DD'),
            text = rgb('#073642'), 
            sub = rgb('#586E75'), 
            disabled = rgb('#657B83'),
            accent = rgb('#268BD2'), 
            accentDim = rgb('#D33682'),
            border = rgb('#93A1A1'),
            bracket = rgb('#839496'),
            fx = {
                ScanlineColor = rgb('#CB4B16'),
                ScanlineTransparency = 0.90,
                ScanlineSpeed = 40,
                TopSweepColor = rgb('#268BD2'),
                TopSweepThickness = 1,
                TopSweepSpeed = 120,
                TopSweepGap = 20,
                TopSweepLength = 100,
                GridColor = rgb('#93A1A1'),
                GridAlpha = 0.03,
                GridGap = 26
            }
        }),
        ["One Light"] = buildTheme({ 
            bg = rgb('#FAFAFA'), 
            bg2 = rgb('#F0F0F0'), 
            bg3 = rgb('#E5E5E5'),
            text = rgb('#383A42'), 
            sub = rgb('#6A737D'), 
            disabled = rgb('#A0A1A7'),
            accent = rgb('#61AFEF'), 
            accentDim = rgb('#4078F2'),
            border = rgb('#D0D0D0'),
            bracket = rgb('#C0C0C0'),
            fx = {
                ScanlineColor = rgb('#50A14F'),
                ScanlineTransparency = 0.92,
                ScanlineSpeed = 35,
                TopSweepColor = rgb('#61AFEF'),
                TopSweepThickness = 1,
                TopSweepSpeed = 110,
                TopSweepGap = 18,
                TopSweepLength = 95,
                GridColor = rgb('#D0D0D0'),
                GridAlpha = 0.02,
                GridGap = 28
            }
        }),
    }

    function ThemeManager:SetTheme(theme)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        if type(theme) == "string" then
            local preset = self:GetTheme(theme)
            assert(preset, ("ThemeManager: theme '%s' not found"):format(theme))
            theme = preset
        end
        merge(self.Library.Theme, theme or {})
        -- propagate changes
        if self.Library.RefreshAll then
            self.Library:RefreshAll()
        end
    end

    function ThemeManager:GetTheme(name)
        local preset = self.Presets[name]
        if not preset then return nil end
        return deepCopy(preset)
    end

    function ThemeManager:ListThemes()
        local names = {}
        for k in pairs(self.Presets) do table.insert(names, k) end
        table.sort(names)
        return names
    end

    function ThemeManager:ApplyToWindow(window)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        if not window then return end
        window._theme = self.Library.Theme
        if window.RefreshTheme then window:RefreshTheme() end
        if window._components then
            for _, comp in ipairs(window._components) do
                if comp and comp.RefreshTheme then
                    comp._theme = self.Library.Theme
                    comp:RefreshTheme()
                end
            end
        end
    end

    function ThemeManager:SaveToJSON()
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        local HttpService = game:GetService('HttpService')
        return HttpService:JSONEncode(self.Library.Theme)
    end

    function ThemeManager:LoadFromJSON(json)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        local HttpService = game:GetService('HttpService')
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
        if ok and type(decoded) == 'table' then
            self:SetTheme(decoded)
            return true
        end
        return false
    end

    return ThemeManager
end