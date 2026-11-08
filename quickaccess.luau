--!nocheck
--[[
    Anime Card Farm — Quick Access
    ------------------------------------------------------------
    A self-contained dashboard for the game's native systems.

    Features:
      F1  Card Ascension
      F2  Rank Ranking
      F3  Trait Roll
      F4  Infinity Tower
      RightControl  open / hide Quick Access

    The game logic is untouched: every action calls
    ReplicatedStorage.Modules.GuiManager.toggle(GuiName).

    Safe to execute repeatedly. The previous instance is cleaned
    through getgenv() before the new one is built.
]]

--=============================================================
-- CONFIG
--=============================================================

local CONFIG = {
    TITLE = "Anime Card Farm",
    SUBTITLE = "Quick Access  •  Game Tools",
    VERSION = "v2.0.0",
    TOGGLE_KEY = Enum.KeyCode.RightControl,
    WINDOW_WIDTH = 760,
    WINDOW_HEIGHT = 480,
    SIDEBAR_WIDTH = 178,
    HEADER_HEIGHT = 64,

    COLORS = {
        window = Color3.fromRGB(14, 17, 24),
        sidebar = Color3.fromRGB(11, 14, 20),
        headerTop = Color3.fromRGB(22, 27, 39),
        headerBottom = Color3.fromRGB(15, 19, 27),
        content = Color3.fromRGB(14, 17, 24),
        card = Color3.fromRGB(21, 26, 36),
        cardHover = Color3.fromRGB(29, 36, 50),
        chip = Color3.fromRGB(17, 22, 31),
        chipHover = Color3.fromRGB(27, 34, 47),
        navIdle = Color3.fromRGB(11, 14, 20),
        navHover = Color3.fromRGB(21, 27, 38),
        navActive = Color3.fromRGB(24, 31, 44),
        stroke = Color3.fromRGB(40, 49, 64),
        text = Color3.fromRGB(240, 244, 250),
        muted = Color3.fromRGB(137, 148, 168),
        dim = Color3.fromRGB(92, 103, 122),
        accent = Color3.fromRGB(124, 92, 255),
        accentSoft = Color3.fromRGB(35, 28, 62),
        green = Color3.fromRGB(61, 220, 151),
        red = Color3.fromRGB(255, 107, 107),
        amber = Color3.fromRGB(245, 165, 36),
        white = Color3.fromRGB(248, 250, 252),
        dark = Color3.fromRGB(10, 13, 18),
        switchOff = Color3.fromRGB(42, 50, 66),
    },

    FEATURES = {
        {
            id = "cards",
            name = "Card Ascension",
            nav = "Cards",
            gui = "CardAscension",
            key = Enum.KeyCode.F1,
            keyLabel = "F1",
            icon = "layers",
            accent = Color3.fromRGB(139, 92, 246),
            textOnAccent = Color3.fromRGB(248, 250, 252),
            description = "Ascend and upgrade cards at the machine.",
            pageDescription = "Opens the game's native Card Ascension machine through GuiManager.",
        },
        {
            id = "ranking",
            name = "Rank Ranking",
            nav = "Ranking",
            gui = "RankRanking",
            key = Enum.KeyCode.F2,
            keyLabel = "F2",
            icon = "crown",
            accent = Color3.fromRGB(245, 165, 36),
            textOnAccent = Color3.fromRGB(26, 18, 6),
            description = "Reroll rank grades without the NPC.",
            pageDescription = "Opens the game's native rank reroll machine through GuiManager.",
        },
        {
            id = "traits",
            name = "Trait Roll",
            nav = "Traits",
            gui = "TraitRoll",
            key = Enum.KeyCode.F3,
            keyLabel = "F3",
            icon = "wand",
            accent = Color3.fromRGB(53, 208, 224),
            textOnAccent = Color3.fromRGB(6, 32, 38),
            description = "Open the trait machine and roll traits.",
            pageDescription = "Opens the game's native Trait Roll machine through GuiManager.",
        },
        {
            id = "infinity",
            name = "Infinity Tower",
            nav = "Infinity",
            gui = "InfinityTower",
            key = Enum.KeyCode.F4,
            keyLabel = "F4",
            icon = "infinity",
            accent = Color3.fromRGB(61, 220, 151),
            textOnAccent = Color3.fromRGB(5, 32, 24),
            description = "Enter the tower lobby without walking there.",
            pageDescription = "Opens the game's native Infinity Tower interface through GuiManager.",
        },
    },
}

--=============================================================
-- LUCIDE ICONS (verified against frappedevs/lucideblox)
--=============================================================

local ICONS = {
    ["layers"] = "rbxassetid://7743868936",
    ["crown"] = "rbxassetid://7733765398",
    ["wand"] = "rbxassetid://8997388430",
    ["infinity"] = "rbxassetid://7733964640",
    ["layout-dashboard"] = "rbxassetid://7733970318",
    ["settings"] = "rbxassetid://7734053495",
    ["x"] = "rbxassetid://7743878857",
    ["minus"] = "rbxassetid://7734000129",
    ["arrow-up-right"] = "rbxassetid://7733673646",
    ["activity"] = "rbxassetid://7733655755",
    ["key"] = "rbxassetid://7733965118",
    ["circle"] = "rbxassetid://7733919881",
    ["check-circle"] = "rbxassetid://7733919427",
    ["alert-triangle"] = "rbxassetid://7733658504",
    ["info"] = "rbxassetid://7733964719",
    ["box"] = "rbxassetid://7733917120",
    ["shield-check"] = "rbxassetid://7734056411",
}

--=============================================================
-- SERVICES
--=============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--=============================================================
-- CLEANUP / RE-EXECUTION
--=============================================================

local GLOBAL_KEY = "__ACF_QUICKACCESS_V2__"
local GENV = (function()
    local ok, env = pcall(function()
        return getgenv()
    end)
    if ok and type(env) == "table" then
        return env
    end
    return _G
end)()

-- Best-effort cleanup of the old EUGENE build that predates this
-- registry. It could not clean itself, so we look for its title and
-- its very specific hotkey closure before creating anything new.
local function disableLegacyHotkeys()
    local getConnections = rawget(_G, "getconnections") or GENV.getconnections
    if type(getConnections) ~= "function" then
        return
    end

    local ok, connections = pcall(getConnections, UserInputService.InputBegan)
    if not ok or type(connections) ~= "table" then
        return
    end

    local wanted = {
        CardAscension = true,
        RankRanking = true,
        TraitRoll = true,
        InfinityTower = true,
    }

    local function looksLegacy(fn)
        if type(fn) ~= "function" then
            return false
        end

        local infoOk, info = pcall(function()
            return debug.getupvalues and debug.getupvalues(fn) or nil
        end)
        local upvalues = infoOk and info or nil

        if type(upvalues) ~= "table" then
            upvalues = {}
            for index = 1, 64 do
                local upOk, upName, upValue = pcall(debug.getupvalue, fn, index)
                if not upOk or upName == nil then
                    break
                end
                upvalues[index] = upValue
            end
        end

        for _, value in pairs(upvalues) do
            if type(value) == "table" then
                local hits = 0
                for _, entry in pairs(value) do
                    if type(entry) == "string" and wanted[entry] then
                        hits = hits + 1
                    end
                end
                if hits >= 4 then
                    return true
                end
            end
        end

        return false
    end

    for _, connection in ipairs(connections) do
        local callback = connection.Function or connection["function"] or connection.Callback
        if looksLegacy(callback) then
            pcall(function()
                if type(connection.Disable) == "function" then
                    connection:Disable()
                elseif type(connection.Disconnect) == "function" then
                    connection:Disconnect()
                end
            end)
        end
    end
end

local function cleanupLegacyGui()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local found = false
            for _, descendant in ipairs(gui:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    local text = descendant.Text
                    if type(text) == "string"
                        and string.find(text, "Anime Card Farm", 1, true)
                        and string.find(text, "Quick Access", 1, true) then
                        found = true
                        break
                    end
                end
            end
            if found then
                pcall(function()
                    gui:Destroy()
                end)
            end
        end
    end
end

local previous = GENV[GLOBAL_KEY]
if type(previous) == "table" and type(previous.cleanup) == "function" then
    pcall(previous.cleanup)
end
GENV[GLOBAL_KEY] = nil

pcall(disableLegacyHotkeys)
pcall(cleanupLegacyGui)

local State = {
    alive = true,
    gui = nil,
    scaler = nil,
    window = nil,
    shadow = nil,
    pill = nil,
    baseScale = 1,
    scaling = false,
    viewScale = nil,
    toastContainer = nil,
    statusDot = nil,
    statusText = nil,
    guiManager = nil,
    guiError = nil,
    open = false,
    minimized = false,
    animToken = 0,
    activePage = "dashboard",
    pages = {},
    navButtons = {},
    navHover = {},
    windowTweens = {},
    connections = {},
    toasts = {},
    toastOrder = 0,
    closeAfterOpen = true,
}

local API = {}

local function cleanup()
    if not State.alive then
        return
    end
    State.alive = false

    for _, connection in ipairs(State.connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    State.connections = {}

    for _, tween in pairs(State.windowTweens) do
        pcall(function()
            tween:Cancel()
        end)
    end
    State.windowTweens = {}

    if State.gui then
        pcall(function()
            State.gui:Destroy()
        end)
    end

    State.gui = nil
    State.pages = {}
    State.navButtons = {}
    State.toasts = {}

    if GENV[GLOBAL_KEY] == API then
        GENV[GLOBAL_KEY] = nil
    end
end

API.cleanup = cleanup
GENV[GLOBAL_KEY] = API

--=============================================================
-- HELPERS
--=============================================================

local function create(className, properties, parent)
    local instance = Instance.new(className)
    if properties then
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                local ok = pcall(function()
                    instance[property] = value
                end)
                if not ok then
                    warn(("[QuickAccess] Could not set %s.%s"):format(className, tostring(property)))
                end
            end
        end
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function connect(signal, callback)
    if not signal then
        return nil
    end
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if ok and connection then
        table.insert(State.connections, connection)
        return connection
    end
    if not ok then
        warn("[QuickAccess] Failed to connect signal:", connection)
    end
    return nil
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CONFIG.COLORS.stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function tweenObject(instance, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration or 0.16,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function tweenKeyed(key, instance, duration, properties, style, direction)
    local previousTween = State.windowTweens[key]
    if previousTween then
        pcall(function()
            previousTween:Cancel()
        end)
    end
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    State.windowTweens[key] = tween
    tween:Play()
    return tween
end

local function shade(color, amount)
    return Color3.new(
        math.clamp(color.R + amount, 0, 1),
        math.clamp(color.G + amount, 0, 1),
        math.clamp(color.B + amount, 0, 1)
    )
end

local function createText(parent, properties)
    local defaults = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextColor3 = CONFIG.COLORS.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }
    for key, value in pairs(properties or {}) do
        defaults[key] = value
    end
    return create("TextLabel", defaults, parent)
end

local function createIcon(parent, iconName, size, color)
    local asset = ICONS[iconName]
    if not asset then
        warn(("[QuickAccess] Unknown Lucide icon '%s'"):format(tostring(iconName)))
        asset = ICONS.circle
    end
    return create("ImageLabel", {
        Name = "Icon_" .. tostring(iconName),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = asset,
        ImageColor3 = color or CONFIG.COLORS.text,
        Size = UDim2.fromOffset(size or 16, size or 16),
        ScaleType = Enum.ScaleType.Fit,
    }, parent)
end

local function centerIcon(icon)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
end

local function createChip(parent, text, color, width)
    local chip = create("Frame", {
        Name = "Chip",
        BackgroundColor3 = CONFIG.COLORS.chip,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width or math.max(30, #text * 6 + 12), 20),
    }, parent)
    addCorner(chip, 6)
    addStroke(chip, CONFIG.COLORS.stroke, 1, 0.25)
    createText(chip, {
        Text = text,
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        TextColor3 = color or CONFIG.COLORS.muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamMedium,
    })
    return chip
end

local function createDivider(parent, y, inset)
    inset = inset or 0
    return create("Frame", {
        BackgroundColor3 = CONFIG.COLORS.stroke,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(inset, y),
        Size = UDim2.new(1, -inset * 2, 0, 1),
    }, parent)
end

local function createSectionLabel(parent, text, y, x)
    x = x or 0
    return createText(parent, {
        Text = string.upper(text),
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.new(1, -x, 0, 12),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
        Font = Enum.Font.GothamBold,
    })
end

local function createPageHeader(page, title, subtitle)
    createText(page, {
        Text = title,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 24),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
    })
    createText(page, {
        Text = subtitle,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 0, 16),
        TextSize = 11,
        TextColor3 = CONFIG.COLORS.muted,
    })
    createDivider(page, 52, 0)
end

local function createScrollingPage(content, id, canvasHeight)
    local page = create("ScrollingFrame", {
        Name = "Page_" .. id,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, canvasHeight or 380),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.COLORS.stroke,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Visible = false,
    }, content)
    return page
end

--=============================================================
-- STATUS / TOASTS
--=============================================================

local function setStatus(ready, text, color)
    if State.statusDot then
        State.statusDot.BackgroundColor3 = color or (ready and CONFIG.COLORS.green) or CONFIG.COLORS.red
    end
    if State.statusText then
        State.statusText.Text = text
        State.statusText.TextColor3 = ready and CONFIG.COLORS.muted or (color or CONFIG.COLORS.red)
    end
end

local function refreshStatus()
    if not State.guiManager then
        setStatus(false, "GuiManager unavailable", CONFIG.COLORS.red)
        return
    end
    if not PlayerGui:FindFirstChild("GuiMid") then
        setStatus(false, "Waiting for GuiMid", CONFIG.COLORS.amber)
        return
    end
    setStatus(true, "GuiManager ready", CONFIG.COLORS.green)
end

local TOAST_STYLES = {
    success = { icon = "check-circle", color = CONFIG.COLORS.green },
    error = { icon = "alert-triangle", color = CONFIG.COLORS.red },
    info = { icon = "info", color = CONFIG.COLORS.accent },
}

local function notify(message, kind)
    if not State.alive or not State.toastContainer or not State.toastContainer.Parent then
        return
    end

    kind = kind or "info"
    local style = TOAST_STYLES[kind] or TOAST_STYLES.info

    for index = #State.toasts, 1, -1 do
        local toast = State.toasts[index]
        if not toast.Parent then
            table.remove(State.toasts, index)
        end
    end
    while #State.toasts >= 4 do
        local oldest = table.remove(State.toasts, 1)
        if oldest then
            pcall(function()
                oldest:Destroy()
            end)
        end
    end

    State.toastOrder = State.toastOrder + 1

    local toast = create("CanvasGroup", {
        Name = "Toast",
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(280, 44),
        GroupTransparency = 1,
        LayoutOrder = State.toastOrder,
    }, State.toastContainer)
    addCorner(toast, 10)
    addStroke(toast, style.color, 1, 0.55)

    local scale = create("UIScale", { Scale = 0.96 }, toast)
    local icon = createIcon(toast, style.icon, 16, style.color)
    icon.Position = UDim2.fromOffset(14, 14)
    createText(toast, {
        Text = message,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -54, 1, 0),
        TextSize = 11,
        TextColor3 = CONFIG.COLORS.text,
        TextWrapped = true,
        Font = Enum.Font.GothamMedium,
    })

    table.insert(State.toasts, toast)

    tweenObject(toast, 0.18, { GroupTransparency = 0 })
    tweenObject(scale, 0.18, { Scale = 1 })

    task.delay(2.6, function()
        if not State.alive or not toast.Parent then
            return
        end
        tweenObject(toast, 0.18, { GroupTransparency = 1 })
        tweenObject(scale, 0.18, { Scale = 0.96 })
        task.delay(0.2, function()
            if toast and toast.Parent then
                toast:Destroy()
            end
        end)
    end)
end

--=============================================================
-- WINDOW OPEN / CLOSE
--=============================================================

local function setOpen(open, options)
    options = options or {}
    if not State.scaler or not State.scaler.Parent then
        return
    end

    State.animToken = State.animToken + 1
    local token = State.animToken
    State.open = open == true

    if State.open then
        State.scaler.Visible = true
        State.pill.Visible = false
        State.minimized = false

        if options.instant then
            State.scaling = false
            State.window.GroupTransparency = 0
            if State.viewScale then
                State.viewScale.Scale = State.baseScale
            end
            State.shadow.BackgroundTransparency = 0.55
        else
            State.scaling = true
            State.window.GroupTransparency = 1
            if State.viewScale then
                State.viewScale.Scale = State.baseScale * 0.965
            end
            State.shadow.BackgroundTransparency = 1

            tweenKeyed("window", State.window, 0.2, { GroupTransparency = 0 })
            if State.viewScale then
                tweenKeyed(
                    "scale",
                    State.viewScale,
                    0.28,
                    { Scale = State.baseScale },
                    Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out
                )
            end
            tweenKeyed("shadow", State.shadow, 0.22, { BackgroundTransparency = 0.55 })

            task.delay(0.3, function()
                if not State.alive or State.animToken ~= token then
                    return
                end
                State.scaling = false
                if State.viewScale then
                    State.viewScale.Scale = State.baseScale
                end
            end)
        end

        refreshStatus()
        return
    end

    local showPill = options.showPill == true

    if options.instant then
        State.scaling = false
        State.window.GroupTransparency = 1
        if State.viewScale then
            State.viewScale.Scale = State.baseScale * 0.965
        end
        State.shadow.BackgroundTransparency = 1
        State.scaler.Visible = false
        State.pill.Visible = showPill
        State.minimized = showPill
        return
    end

    State.scaling = true
    tweenKeyed("window", State.window, 0.18, { GroupTransparency = 1 })
    if State.viewScale then
        tweenKeyed(
            "scale",
            State.viewScale,
            0.18,
            { Scale = State.baseScale * 0.965 },
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        )
    end
    tweenKeyed("shadow", State.shadow, 0.18, { BackgroundTransparency = 1 })

    task.delay(0.19, function()
        if not State.alive or State.animToken ~= token or State.open then
            return
        end
        State.scaling = false
        State.scaler.Visible = false
        State.pill.Visible = showPill
        State.minimized = showPill
    end)
end

local function toggleMenu()
    if State.open then
        setOpen(false)
    else
        setOpen(true)
    end
end

API.toggle = toggleMenu
API.setOpen = setOpen

--=============================================================
-- PAGES / NAVIGATION
--=============================================================

local function setPage(id)
    if not State.pages[id] then
        id = "dashboard"
    end
    State.activePage = id

    for pageId, page in pairs(State.pages) do
        page.Visible = pageId == id
    end

    for pageId, item in pairs(State.navButtons) do
        local active = pageId == id
        item.bar.Visible = active
        item.bar.BackgroundColor3 = item.accent

        if active then
            item.button.BackgroundColor3 = CONFIG.COLORS.navActive
            item.icon.ImageColor3 = item.accent
            item.label.TextColor3 = CONFIG.COLORS.text
            if item.hint then
                item.hint.TextColor3 = CONFIG.COLORS.muted
            end
        else
            item.button.BackgroundColor3 = State.navHover[pageId]
                and CONFIG.COLORS.navHover
                or CONFIG.COLORS.navIdle
            item.icon.ImageColor3 = CONFIG.COLORS.muted
            item.label.TextColor3 = CONFIG.COLORS.muted
            if item.hint then
                item.hint.TextColor3 = CONFIG.COLORS.dim
            end
        end
    end
end

API.setPage = setPage

--=============================================================
-- FUNCTION OPENERS
--=============================================================

local function findGameGui(name)
    local guiMid = PlayerGui:FindFirstChild("GuiMid")
    if not guiMid then
        return nil
    end
    return guiMid:FindFirstChild(name)
end

local function loadGuiManager()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if not modules then
        return nil, "Modules folder was not found"
    end

    local module = modules:FindFirstChild("GuiManager")
    if not module then
        return nil, "GuiManager module was not found"
    end

    local ok, result = pcall(require, module)
    if not ok then
        return nil, "GuiManager failed to load: " .. tostring(result)
    end
    if type(result) ~= "table" or type(result.toggle) ~= "function" then
        return nil, "GuiManager.toggle is unavailable"
    end
    return result, nil
end

local function openFeature(feature)
    if not feature then
        return false
    end

    if not State.guiManager then
        notify("GuiManager is not available.", "error")
        return false
    end

    if not findGameGui(feature.gui) then
        notify(("GUI '%s' was not found."):format(feature.gui), "error")
        return false
    end

    local ok, err = pcall(State.guiManager.toggle, feature.gui)
    if not ok then
        warn("[QuickAccess] toggle failed:", err)
        notify("Could not open " .. feature.name .. ".", "error")
        return false
    end

    notify(feature.name .. " opened.", "success")
    if State.closeAfterOpen and (State.open or State.minimized) then
        setOpen(false)
    end
    return true
end

local function openFeatureById(id)
    for _, feature in ipairs(CONFIG.FEATURES) do
        if feature.id == id then
            return openFeature(feature)
        end
    end
    return false
end

API.open = openFeatureById

--=============================================================
-- SMALL CONTROLS
--=============================================================

local function createIconButton(parent, iconName, position, hoverColor, normalIcon, hoverIcon)
    local button = create("TextButton", {
        Name = "IconButton_" .. iconName,
        Size = UDim2.fromOffset(28, 28),
        Position = position,
        BackgroundColor3 = hoverColor,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Text = "",
    }, parent)
    addCorner(button, 7)

    local icon = createIcon(button, iconName, 14, normalIcon or CONFIG.COLORS.muted)
    centerIcon(icon)

    connect(button.MouseEnter, function()
        tweenObject(button, 0.14, { BackgroundTransparency = 0 })
        tweenObject(icon, 0.14, { ImageColor3 = hoverIcon or CONFIG.COLORS.text })
    end)
    connect(button.MouseLeave, function()
        tweenObject(button, 0.14, { BackgroundTransparency = 1 })
        tweenObject(icon, 0.14, { ImageColor3 = normalIcon or CONFIG.COLORS.muted })
    end)

    return button, icon
end

local function createGhostButton(parent, text, width)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(width or 76, 28),
        BackgroundColor3 = CONFIG.COLORS.chip,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, parent)
    addCorner(button, 7)
    addStroke(button, CONFIG.COLORS.stroke, 1, 0.2)

    local scale = create("UIScale", { Scale = 1 }, button)
    createText(button, {
        Text = text,
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = CONFIG.COLORS.text,
    })

    connect(button.MouseEnter, function()
        tweenObject(button, 0.14, { BackgroundColor3 = CONFIG.COLORS.chipHover })
    end)
    connect(button.MouseLeave, function()
        tweenObject(button, 0.14, { BackgroundColor3 = CONFIG.COLORS.chip })
    end)
    connect(button.MouseButton1Down, function()
        tweenObject(scale, 0.08, { Scale = 0.97 })
    end)
    connect(button.MouseButton1Up, function()
        tweenObject(scale, 0.12, { Scale = 1 })
    end)

    return button
end

local function createPrimaryButton(parent, feature, onClick)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(140, 36),
        BackgroundColor3 = feature.accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, parent)
    addCorner(button, 9)

    local scale = create("UIScale", { Scale = 1 }, button)
    createText(button, {
        Text = "Open",
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -48, 1, 0),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = feature.textOnAccent,
    })
    local icon = createIcon(button, "arrow-up-right", 14, feature.textOnAccent)
    icon.AnchorPoint = Vector2.new(1, 0.5)
    icon.Position = UDim2.new(1, -16, 0.5, 0)

    connect(button.MouseEnter, function()
        tweenObject(button, 0.15, { BackgroundColor3 = shade(feature.accent, 0.1) })
    end)
    connect(button.MouseLeave, function()
        tweenObject(button, 0.15, { BackgroundColor3 = feature.accent })
    end)
    connect(button.MouseButton1Down, function()
        tweenObject(scale, 0.08, { Scale = 0.97 })
    end)
    connect(button.MouseButton1Up, function()
        tweenObject(scale, 0.12, { Scale = 1 })
    end)
    connect(button.MouseButton1Click, onClick)

    return button
end

local function createSwitch(parent, initial, onChanged)
    local on = initial == true
    local track = create("TextButton", {
        Name = "Switch",
        Size = UDim2.fromOffset(38, 20),
        BackgroundColor3 = on and CONFIG.COLORS.accent or CONFIG.COLORS.switchOff,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, parent)
    addCorner(track, 10)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(on and 21 or 3, 3),
        BackgroundColor3 = CONFIG.COLORS.white,
        BorderSizePixel = 0,
    }, track)
    addCorner(knob, 7)

    local function render(animate)
        if animate then
            tweenObject(track, 0.16, {
                BackgroundColor3 = on and CONFIG.COLORS.accent or CONFIG.COLORS.switchOff,
            })
            tweenObject(knob, 0.16, {
                Position = UDim2.fromOffset(on and 21 or 3, 3),
            })
        else
            track.BackgroundColor3 = on and CONFIG.COLORS.accent or CONFIG.COLORS.switchOff
            knob.Position = UDim2.fromOffset(on and 21 or 3, 3)
        end
    end

    connect(track.MouseButton1Click, function()
        on = not on
        render(true)
        if onChanged then
            onChanged(on)
        end
    end)

    return {
        track = track,
        set = function(value)
            on = value == true
            render(true)
        end,
    }
end

--=============================================================
-- HEADER
--=============================================================

local function createHeader(window)
    local header = create("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, CONFIG.HEADER_HEIGHT),
    }, window)

    local logoBack = create("Frame", {
        Name = "LogoBack",
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.fromOffset(18, 15),
        BackgroundColor3 = CONFIG.COLORS.accent,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
    }, header)
    addCorner(logoBack, 10)
    addStroke(logoBack, CONFIG.COLORS.accent, 1, 0.55)

    local logo = createIcon(logoBack, "layers", 18, CONFIG.COLORS.accent)
    centerIcon(logo)

    createText(header, {
        Text = CONFIG.TITLE,
        Position = UDim2.fromOffset(62, 11),
        Size = UDim2.new(0, 300, 0, 20),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    createText(header, {
        Text = CONFIG.SUBTITLE,
        Position = UDim2.fromOffset(62, 31),
        Size = UDim2.new(0, 320, 0, 14),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })

    local minimize, minimizeIcon = createIconButton(
        header,
        "minus",
        UDim2.new(1, -78, 0, 18),
        CONFIG.COLORS.navHover,
        CONFIG.COLORS.muted,
        CONFIG.COLORS.text
    )
    local close, closeIcon = createIconButton(
        header,
        "x",
        UDim2.new(1, -42, 0, 18),
        Color3.fromRGB(45, 23, 30),
        CONFIG.COLORS.muted,
        CONFIG.COLORS.red
    )

    connect(minimize.MouseButton1Click, function()
        setOpen(false, { showPill = true })
    end)
    connect(close.MouseButton1Click, function()
        setOpen(false)
    end)

    create("Frame", {
        BackgroundColor3 = CONFIG.COLORS.stroke,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
    }, header)

    return header, minimize, minimizeIcon, close, closeIcon
end

--=============================================================
-- SIDEBAR
--=============================================================

local function createSidebar(window)
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(12, 76),
        Size = UDim2.new(0, CONFIG.SIDEBAR_WIDTH, 1, -88),
        BackgroundColor3 = CONFIG.COLORS.sidebar,
        BorderSizePixel = 0,
    }, window)
    addCorner(sidebar, 14)
    addStroke(sidebar, CONFIG.COLORS.stroke, 1, 0.55)

    local navItems = {
        { id = "dashboard", label = "Dashboard", icon = "layout-dashboard", hint = nil },
        { id = "cards", label = "Cards", icon = "layers", hint = "F1" },
        { id = "ranking", label = "Ranking", icon = "crown", hint = "F2" },
        { id = "traits", label = "Traits", icon = "wand", hint = "F3" },
        { id = "infinity", label = "Infinity", icon = "infinity", hint = "F4" },
    }

    createSectionLabel(sidebar, "Quick", 16, 16)

    local navOffset = 34
    for index, item in ipairs(navItems) do
        local feature
        for _, candidate in ipairs(CONFIG.FEATURES) do
            if candidate.id == item.id then
                feature = candidate
                break
            end
        end

        local accent = feature and feature.accent or CONFIG.COLORS.accent
        local hint = feature and feature.keyLabel or item.hint

        local button = create("TextButton", {
            Name = "Nav_" .. item.id,
            Size = UDim2.new(1, -24, 0, 34),
            Position = UDim2.fromOffset(12, navOffset + (index - 1) * 38),
            BackgroundColor3 = CONFIG.COLORS.navIdle,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, sidebar)
        addCorner(button, 9)

        local activeBar = create("Frame", {
            Name = "ActiveBar",
            Size = UDim2.fromOffset(3, 16),
            Position = UDim2.fromOffset(-1, 9),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Visible = false,
        }, button)
        addCorner(activeBar, 2)

        local icon = createIcon(button, item.icon, 16, CONFIG.COLORS.muted)
        icon.Position = UDim2.fromOffset(12, 9)

        local label = createText(button, {
            Text = item.label,
            Position = UDim2.fromOffset(38, 0),
            Size = UDim2.new(1, -82, 1, 0),
            TextSize = 12,
            TextColor3 = CONFIG.COLORS.muted,
            Font = Enum.Font.GothamMedium,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local hintLabel
        if hint then
            hintLabel = createText(button, {
                Text = hint,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(48, 14),
                TextSize = 10,
                TextColor3 = CONFIG.COLORS.dim,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        end

        State.navButtons[item.id] = {
            button = button,
            icon = icon,
            label = label,
            hint = hintLabel,
            bar = activeBar,
            accent = accent,
        }

        connect(button.MouseEnter, function()
            State.navHover[item.id] = true
            if State.activePage ~= item.id then
                tweenObject(button, 0.14, { BackgroundColor3 = CONFIG.COLORS.navHover })
                tweenObject(icon, 0.14, { ImageColor3 = CONFIG.COLORS.text })
            end
        end)
        connect(button.MouseLeave, function()
            State.navHover[item.id] = nil
            if State.activePage ~= item.id then
                tweenObject(button, 0.14, { BackgroundColor3 = CONFIG.COLORS.navIdle })
                tweenObject(icon, 0.14, { ImageColor3 = CONFIG.COLORS.muted })
            end
        end)
        connect(button.MouseButton1Click, function()
            setPage(item.id)
        end)
    end

    createSectionLabel(sidebar, "System", 236, 16)

    local settingsButton = create("TextButton", {
        Name = "Nav_settings",
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.fromOffset(12, 254),
        BackgroundColor3 = CONFIG.COLORS.navIdle,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, sidebar)
    addCorner(settingsButton, 9)

    local settingsBar = create("Frame", {
        Name = "ActiveBar",
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.fromOffset(-1, 9),
        BackgroundColor3 = CONFIG.COLORS.accent,
        BorderSizePixel = 0,
        Visible = false,
    }, settingsButton)
    addCorner(settingsBar, 2)

    local settingsIcon = createIcon(settingsButton, "settings", 16, CONFIG.COLORS.muted)
    settingsIcon.Position = UDim2.fromOffset(12, 9)
    local settingsLabel = createText(settingsButton, {
        Text = "Settings",
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -50, 1, 0),
        TextSize = 12,
        TextColor3 = CONFIG.COLORS.muted,
        Font = Enum.Font.GothamMedium,
    })

    State.navButtons.settings = {
        button = settingsButton,
        icon = settingsIcon,
        label = settingsLabel,
        bar = settingsBar,
        accent = CONFIG.COLORS.accent,
    }

    connect(settingsButton.MouseEnter, function()
        State.navHover.settings = true
        if State.activePage ~= "settings" then
            tweenObject(settingsButton, 0.14, { BackgroundColor3 = CONFIG.COLORS.navHover })
            tweenObject(settingsIcon, 0.14, { ImageColor3 = CONFIG.COLORS.text })
        end
    end)
    connect(settingsButton.MouseLeave, function()
        State.navHover.settings = nil
        if State.activePage ~= "settings" then
            tweenObject(settingsButton, 0.14, { BackgroundColor3 = CONFIG.COLORS.navIdle })
            tweenObject(settingsIcon, 0.14, { ImageColor3 = CONFIG.COLORS.muted })
        end
    end)
    connect(settingsButton.MouseButton1Click, function()
        setPage("settings")
    end)

    create("Frame", {
        BackgroundColor3 = CONFIG.COLORS.stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 1, -66),
        Size = UDim2.new(1, -28, 0, 1),
    }, sidebar)

    local dot = create("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, 16, 1, -46),
        BackgroundColor3 = CONFIG.COLORS.amber,
        BorderSizePixel = 0,
    }, sidebar)
    addCorner(dot, 3)
    State.statusDot = dot

    State.statusText = createText(sidebar, {
        Text = "Checking system...",
        Position = UDim2.new(0, 30, 1, -51),
        Size = UDim2.new(1, -42, 0, 16),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    createText(sidebar, {
        Text = CONFIG.VERSION .. "  •  local UI",
        Position = UDim2.new(0, 16, 1, -28),
        Size = UDim2.new(1, -30, 0, 14),
        TextSize = 9,
        TextColor3 = CONFIG.COLORS.dim,
    })

    return sidebar
end

--=============================================================
-- FEATURE CARDS
--=============================================================

local function createFeatureCard(parent, feature, order)
    local card = create("TextButton", {
        Name = "Card_" .. feature.id,
        BackgroundColor3 = CONFIG.COLORS.card,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = order,
    }, parent)
    addCorner(card, 12)
    local stroke = addStroke(card, CONFIG.COLORS.stroke, 1, 0.15)
    local scale = create("UIScale", { Scale = 1 }, card)

    local iconBack = create("Frame", {
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.fromOffset(14, 14),
        BackgroundColor3 = feature.accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
    }, card)
    addCorner(iconBack, 10)

    local icon = createIcon(iconBack, feature.icon, 18, feature.accent)
    centerIcon(icon)

    local chip = createChip(card, feature.keyLabel, CONFIG.COLORS.muted, 34)
    chip.AnchorPoint = Vector2.new(1, 0)
    chip.Position = UDim2.new(1, -14, 0, 16)

    createText(card, {
        Text = feature.name,
        Position = UDim2.fromOffset(60, 13),
        Size = UDim2.new(1, -118, 0, 20),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    createText(card, {
        Text = feature.description,
        Position = UDim2.fromOffset(14, 54),
        Size = UDim2.new(1, -28, 0, 30),
        TextSize = 11,
        TextColor3 = CONFIG.COLORS.muted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })

    createDivider(card, 88, 14)

    createText(card, {
        Text = "Open",
        Position = UDim2.fromOffset(14, 94),
        Size = UDim2.new(1, -52, 0, 16),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = feature.accent,
    })

    local arrow = createIcon(card, "arrow-up-right", 13, feature.accent)
    arrow.AnchorPoint = Vector2.new(1, 0)
    arrow.Position = UDim2.new(1, -14, 0, 92)

    local hovered = false

    local function renderHover(isHovered)
        hovered = isHovered
        card.ZIndex = isHovered and 3 or 1
        tweenObject(card, 0.16, {
            BackgroundColor3 = isHovered and CONFIG.COLORS.cardHover or CONFIG.COLORS.card,
        })
        tweenObject(stroke, 0.16, {
            Color = isHovered and feature.accent or CONFIG.COLORS.stroke,
            Transparency = isHovered and 0.45 or 0.15,
        })
        tweenObject(iconBack, 0.16, {
            BackgroundTransparency = isHovered and 0.76 or 0.86,
        })
        tweenObject(icon, 0.16, {
            ImageColor3 = isHovered and CONFIG.COLORS.white or feature.accent,
        })
        tweenObject(scale, 0.16, {
            Scale = isHovered and 1.012 or 1,
        })
    end

    connect(card.MouseEnter, function()
        renderHover(true)
    end)
    connect(card.MouseLeave, function()
        renderHover(false)
    end)
    connect(card.MouseButton1Down, function()
        tweenObject(scale, 0.08, { Scale = 0.985 })
    end)
    connect(card.MouseButton1Up, function()
        tweenObject(scale, 0.12, { Scale = hovered and 1.012 or 1 })
    end)
    connect(card.MouseButton1Click, function()
        openFeature(feature)
    end)

    return card
end

--=============================================================
-- DASHBOARD PAGE
--=============================================================

local function buildDashboardPage(page)
    createPageHeader(
        page,
        "Quick Access",
        "Open the game's card systems without walking to an NPC."
    )

    local grid = create("Frame", {
        Name = "FeatureGrid",
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 0, 248),
        BackgroundTransparency = 1,
    }, page)

    local layout = create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 118),
        CellPadding = UDim2.fromOffset(12, 12),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    for index, feature in ipairs(CONFIG.FEATURES) do
        createFeatureCard(grid, feature, index)
    end

    local tip = create("Frame", {
        Name = "Tip",
        Position = UDim2.fromOffset(0, 332),
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(tip, 10)
    addStroke(tip, CONFIG.COLORS.stroke, 1, 0.45)

    local tipIcon = createIcon(tip, "info", 14, CONFIG.COLORS.accent)
    tipIcon.Position = UDim2.fromOffset(14, 13)

    createText(tip, {
        Text = "Tip  •  Press RightControl to hide this menu. F1-F4 work anywhere.",
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -52, 1, 0),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })

    return layout
end

--=============================================================
-- FEATURE PAGE
--=============================================================

local function buildFeaturePage(page, feature)
    createPageHeader(page, feature.name, feature.pageDescription)

    local hero = create("Frame", {
        Name = "Hero",
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(hero, 14)
    addStroke(hero, CONFIG.COLORS.stroke, 1, 0.15)

    local iconBack = create("Frame", {
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.fromOffset(18, 18),
        BackgroundColor3 = feature.accent,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
    }, hero)
    addCorner(iconBack, 12)

    local icon = createIcon(iconBack, feature.icon, 22, feature.accent)
    centerIcon(icon)

    createText(hero, {
        Text = feature.name,
        Position = UDim2.fromOffset(80, 20),
        Size = UDim2.new(1, -260, 0, 22),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    createText(hero, {
        Text = "Native game interface  •  GuiManager.toggle",
        Position = UDim2.fromOffset(80, 44),
        Size = UDim2.new(1, -110, 0, 16),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })

    local hotkeyChip = createChip(hero, feature.keyLabel, feature.accent, 38)
    hotkeyChip.Position = UDim2.fromOffset(80, 70)

    local targetChip = createChip(hero, feature.gui, CONFIG.COLORS.muted)
    targetChip.Position = UDim2.fromOffset(126, 70)

    local openButton = createPrimaryButton(hero, feature, function()
        openFeature(feature)
    end)
    openButton.AnchorPoint = Vector2.new(1, 1)
    openButton.Position = UDim2.new(1, -18, 1, -18)

    createText(hero, {
        Text = "Press " .. feature.keyLabel .. " anywhere, or use the button below.",
        Position = UDim2.fromOffset(18, 110),
        Size = UDim2.new(1, -220, 0, 16),
        TextSize = 11,
        TextColor3 = CONFIG.COLORS.muted,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local details = create("Frame", {
        Name = "Details",
        Position = UDim2.fromOffset(0, 234),
        Size = UDim2.new(1, 0, 0, 138),
        BackgroundColor3 = CONFIG.COLORS.chip,
        BorderSizePixel = 0,
    }, page)
    addCorner(details, 12)
    addStroke(details, CONFIG.COLORS.stroke, 1, 0.45)

    local rows = {
        { label = "Game GUI", value = feature.gui, icon = "box" },
        { label = "Hotkey", value = feature.keyLabel .. "  (works while the menu is hidden)", icon = "key" },
        { label = "Launcher", value = "ReplicatedStorage.Modules.GuiManager", icon = "activity" },
    }

    for index, row in ipairs(rows) do
        local y = 12 + (index - 1) * 40

        local rowIcon = createIcon(details, row.icon, 14, feature.accent)
        rowIcon.Position = UDim2.fromOffset(16, y + 1)

        createText(details, {
            Text = row.label,
            Position = UDim2.fromOffset(40, y),
            Size = UDim2.new(0, 120, 0, 16),
            TextSize = 10,
            TextColor3 = CONFIG.COLORS.muted,
        })
        createText(details, {
            Text = row.value,
            Position = UDim2.fromOffset(160, y),
            Size = UDim2.new(1, -176, 0, 16),
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextColor3 = CONFIG.COLORS.text,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        if index < #rows then
            createDivider(details, y + 27, 16)
        end
    end

    createText(page, {
        Text = "Tip  •  Press " .. feature.keyLabel .. " from anywhere, or open this page and use the button above.",
        Position = UDim2.fromOffset(2, 384),
        Size = UDim2.new(1, -4, 0, 16),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.dim,
    })
end

--=============================================================
-- SETTINGS PAGE
--=============================================================

local function buildSettingsPage(page)
    createPageHeader(page, "Settings", "Preferences, key bindings, and window controls.")

    createSectionLabel(page, "Behavior", 68)

    local behavior = create("Frame", {
        Position = UDim2.fromOffset(0, 86),
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(behavior, 12)
    addStroke(behavior, CONFIG.COLORS.stroke, 1, 0.35)

    createText(behavior, {
        Text = "Close after opening",
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -100, 0, 16),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    })
    createText(behavior, {
        Text = "Hide Quick Access when a feature launches.",
        Position = UDim2.fromOffset(16, 28),
        Size = UDim2.new(1, -100, 0, 14),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })

    local switch = createSwitch(behavior, State.closeAfterOpen, function(value)
        State.closeAfterOpen = value
    end)
    switch.track.AnchorPoint = Vector2.new(1, 0.5)
    switch.track.Position = UDim2.new(1, -16, 0.5, 0)

    createSectionLabel(page, "Window", 160)

    local windowPanel = create("Frame", {
        Position = UDim2.fromOffset(0, 178),
        Size = UDim2.new(1, 0, 0, 116),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(windowPanel, 12)
    addStroke(windowPanel, CONFIG.COLORS.stroke, 1, 0.35)

    createText(windowPanel, {
        Text = "Reset position",
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -120, 0, 16),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    })
    createText(windowPanel, {
        Text = "Center the window on screen.",
        Position = UDim2.fromOffset(16, 28),
        Size = UDim2.new(1, -120, 0, 14),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })
    local resetButton = createGhostButton(windowPanel, "Reset", 72)
    resetButton.AnchorPoint = Vector2.new(1, 0.5)
    resetButton.Position = UDim2.new(1, -16, 0.5, -29)
    connect(resetButton.MouseButton1Click, function()
        if State.scaler then
            tweenObject(State.scaler, 0.2, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
            })
        end
        notify("Window position reset.", "info")
    end)

    createDivider(windowPanel, 58, 16)

    createText(windowPanel, {
        Text = "Hide menu",
        Position = UDim2.fromOffset(16, 68),
        Size = UDim2.new(1, -120, 0, 16),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    })
    createText(windowPanel, {
        Text = "Reopen anytime with RightControl.",
        Position = UDim2.fromOffset(16, 86),
        Size = UDim2.new(1, -120, 0, 14),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })
    local hideButton = createGhostButton(windowPanel, "Hide", 72)
    hideButton.AnchorPoint = Vector2.new(1, 0.5)
    hideButton.Position = UDim2.new(1, -16, 0.5, 29)
    connect(hideButton.MouseButton1Click, function()
        setOpen(false)
    end)

    createSectionLabel(page, "Hotkeys", 310)

    local hotkeyRows = {
        { label = "Card Ascension", key = "F1" },
        { label = "Rank Ranking", key = "F2" },
        { label = "Trait Roll", key = "F3" },
        { label = "Infinity Tower", key = "F4" },
        { label = "Open / hide Quick Access", key = "RightCtrl" },
    }

    local hotkeysPanel = create("Frame", {
        Position = UDim2.fromOffset(0, 328),
        Size = UDim2.new(1, 0, 0, #hotkeyRows * 36),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(hotkeysPanel, 12)
    addStroke(hotkeysPanel, CONFIG.COLORS.stroke, 1, 0.35)

    for index, row in ipairs(hotkeyRows) do
        local y = (index - 1) * 36

        createText(hotkeysPanel, {
            Text = row.label,
            Position = UDim2.fromOffset(16, y),
            Size = UDim2.new(1, -110, 0, 36),
            TextSize = 11,
            TextColor3 = CONFIG.COLORS.text,
        })

        local chip = createChip(hotkeysPanel, row.key, CONFIG.COLORS.muted, row.key == "RightCtrl" and 58 or 34)
        chip.AnchorPoint = Vector2.new(1, 0.5)
        chip.Position = UDim2.new(1, -16, 0, y + 18)

        if index < #hotkeyRows then
            createDivider(hotkeysPanel, y + 35, 16)
        end
    end

    createSectionLabel(page, "About", 524)

    local about = create("Frame", {
        Position = UDim2.fromOffset(0, 542),
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
    }, page)
    addCorner(about, 12)
    addStroke(about, CONFIG.COLORS.stroke, 1, 0.35)

    local shield = createIcon(about, "shield-check", 16, CONFIG.COLORS.green)
    shield.Position = UDim2.fromOffset(16, 21)

    createText(about, {
        Text = "Anime Card Farm  •  Quick Access",
        Position = UDim2.fromOffset(42, 10),
        Size = UDim2.new(1, -60, 0, 16),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    })
    createText(about, {
        Text = "Local-only UI. No extra remotes, no game logic replaced.",
        Position = UDim2.fromOffset(42, 28),
        Size = UDim2.new(1, -60, 0, 14),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.muted,
    })

    createText(about, {
        Text = CONFIG.VERSION,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(60, 16),
        TextSize = 10,
        TextColor3 = CONFIG.COLORS.dim,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
end

--=============================================================
-- DRAG
--=============================================================

local function setupDrag(handle, anchor)
    handle.Active = true

    local dragging = false
    local startMouse = nil
    local startPosition = nil

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        startMouse = input.Position
        startPosition = anchor.Position
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging or not startMouse or not startPosition then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local scale = State.viewScale and State.viewScale.Scale or 1
        if scale <= 0 then
            scale = 1
        end
        local rawDelta = input.Position - startMouse
        local delta = Vector2.new(rawDelta.X / scale, rawDelta.Y / scale)
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1280, 720)
        local windowWidth = CONFIG.WINDOW_WIDTH * (State.baseScale or 1)
        local windowHeight = CONFIG.WINDOW_HEIGHT * (State.baseScale or 1)
        local maxX = math.max(0, (viewport.X - windowWidth) / 2 - 16)
        local maxY = math.max(0, (viewport.Y - windowHeight) / 2 - 16)

        local x = math.clamp(startPosition.X.Offset + delta.X, -maxX, maxX)
        local y = math.clamp(startPosition.Y.Offset + delta.Y, -maxY, maxY)

        anchor.Position = UDim2.new(startPosition.X.Scale, x, startPosition.Y.Scale, y)
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            startMouse = nil
            startPosition = nil
        end
    end)
end

--=============================================================
-- MAIN WINDOW
--=============================================================

local function createWindow()
    local screenGui = create("ScreenGui", {
        Name = "ACF_QuickAccess",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PlayerGui)
    State.gui = screenGui

    local scaler = create("Frame", {
        Name = "WindowAnchor",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false,
        ZIndex = 10,
    }, screenGui)
    State.scaler = scaler

    State.viewScale = create("UIScale", {
        Scale = 1,
    }, scaler)

    local cameraConnection = nil
    local function updateViewportScale()
        if not State.viewScale then
            return
        end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        State.baseScale = math.clamp(math.min(viewport.X / 1400, viewport.Y / 800), 0.85, 1.5)
        if not State.scaling then
            State.viewScale.Scale = State.baseScale
        end
    end
    local function bindCamera()
        if cameraConnection then
            pcall(function()
                cameraConnection:Disconnect()
            end)
            cameraConnection = nil
        end
        updateViewportScale()
        local camera = workspace.CurrentCamera
        if camera then
            cameraConnection = connect(
                camera:GetPropertyChangedSignal("ViewportSize"),
                updateViewportScale
            )
        end
    end
    bindCamera()
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)

    local shadow = create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.fromScale(1, 1),
    }, scaler)
    addCorner(shadow, 18)
    State.shadow = shadow

    local window = create("CanvasGroup", {
        Name = "Window",
        BackgroundColor3 = CONFIG.COLORS.window,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true,
    }, scaler)
    addCorner(window, 16)
    addStroke(window, CONFIG.COLORS.stroke, 1, 0.05)
    State.window = window

    local headerBack = create("Frame", {
        Name = "HeaderBack",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, CONFIG.HEADER_HEIGHT),
    }, window)
    local headerCorner = addCorner(headerBack, 16)
    headerCorner.BottomLeftRadius = UDim.new(0, 0)
    headerCorner.BottomRightRadius = UDim.new(0, 0)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.COLORS.headerTop),
            ColorSequenceKeypoint.new(1, CONFIG.COLORS.headerBottom),
        }),
    }, headerBack)

    local header = createHeader(window)
    setupDrag(header, scaler)

    createSidebar(window)

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(202, CONFIG.HEADER_HEIGHT),
        Size = UDim2.new(1, -220, 1, -78),
    }, window)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 10),
    }, content)

    State.pages.dashboard = createScrollingPage(content, "dashboard", 380)
    buildDashboardPage(State.pages.dashboard)

    for _, feature in ipairs(CONFIG.FEATURES) do
        local page = createScrollingPage(content, feature.id, 440)
        buildFeaturePage(page, feature)
        State.pages[feature.id] = page
    end

    State.pages.settings = createScrollingPage(content, "settings", 640)
    buildSettingsPage(State.pages.settings)

    local pill = create("TextButton", {
        Name = "LauncherPill",
        BackgroundColor3 = CONFIG.COLORS.card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(190, 42),
        Position = UDim2.new(0, 16, 1, -16),
        AnchorPoint = Vector2.new(0, 1),
        Visible = false,
        ZIndex = 20,
    }, screenGui)
    addCorner(pill, 21)
    addStroke(pill, CONFIG.COLORS.stroke, 1, 0.3)
    State.pill = pill

    local pillIcon = createIcon(pill, "layers", 16, CONFIG.COLORS.accent)
    pillIcon.Position = UDim2.fromOffset(14, 13)

    createText(pill, {
        Text = "Quick Access",
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -98, 1, 0),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    })

    local pillChip = createChip(pill, "RCtrl", CONFIG.COLORS.muted, 46)
    pillChip.AnchorPoint = Vector2.new(1, 0.5)
    pillChip.Position = UDim2.new(1, -12, 0.5, 0)

    connect(pill.MouseEnter, function()
        tweenObject(pill, 0.14, { BackgroundColor3 = CONFIG.COLORS.cardHover })
    end)
    connect(pill.MouseLeave, function()
        tweenObject(pill, 0.14, { BackgroundColor3 = CONFIG.COLORS.card })
    end)
    connect(pill.MouseButton1Click, function()
        setOpen(true)
    end)

    local toastContainer = create("Frame", {
        Name = "Toasts",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(280, 220),
        Position = UDim2.new(1, -18, 1, -18),
        AnchorPoint = Vector2.new(1, 1),
        Active = false,
        ZIndex = 30,
    }, screenGui)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, toastContainer)
    State.toastContainer = toastContainer

    setPage("dashboard")
    refreshStatus()

    return screenGui
end

--=============================================================
-- HOTKEYS
--=============================================================

local function setupHotkeys()
    local featureByKey = {}
    for _, feature in ipairs(CONFIG.FEATURES) do
        featureByKey[feature.key] = feature
    end

    local lastToggle = 0

    connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end

        local key = input.KeyCode

        -- One handler, one branch per key. F1-F4 can never reach
        -- the menu toggle, and RightControl can never open a feature.
        if key == CONFIG.TOGGLE_KEY then
            local now = os.clock()
            if now - lastToggle < 0.2 then
                return
            end
            lastToggle = now
            toggleMenu()
            return
        end

        local feature = featureByKey[key]
        if feature then
            openFeature(feature)
        end
    end)
end

--=============================================================
-- INITIALIZATION
--=============================================================

local function preloadIcons()
    if not State.gui or not State.gui.Parent then
        return
    end

    local images = {}
    for _, descendant in ipairs(State.gui:GetDescendants()) do
        if descendant:IsA("ImageLabel") and descendant.Image ~= "" then
            table.insert(images, descendant)
        end
    end

    if #images == 0 then
        return
    end

    local ok, err = pcall(function()
        ContentProvider:PreloadAsync(images)
    end)
    if not ok then
        warn("[QuickAccess] Icon preload failed:", err)
    end
end

local function init()
    State.guiManager, State.guiError = loadGuiManager()
    createWindow()
    setupHotkeys()
    task.spawn(preloadIcons)

    connect(PlayerGui.ChildAdded, function(child)
        if child.Name == "GuiMid" then
            refreshStatus()
        end
    end)
    connect(PlayerGui.ChildRemoved, function(child)
        if child.Name == "GuiMid" then
            refreshStatus()
        end
    end)

    setOpen(true)

    if State.guiManager then
        notify("Quick Access ready  •  RightControl to toggle.", "success")
    else
        notify(State.guiError or "GuiManager is unavailable.", "error")
    end
end

init()
