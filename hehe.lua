-- [[ SINGLETON CHECK ]] --
if getgenv().ChaLarmHubLoaded then 
    warn("ChaLarmHub is already loaded!")
    return 
end
getgenv().ChaLarmHubLoaded = true

-- [[ 1. SERVICES & GLOBAL VARIABLES ]] --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LP = Players.LocalPlayer
local Options = {}

-- [[ 2. CORE UTILITIES ]] --

-- ANTI-AFK System
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

-- AUTO REJOIN System (Error 277/Disconnect)
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local GuiService = game:GetService("GuiService")
    
    local function Rejoin()
        warn("⚠️ Detected Disconnect! Auto Rejoining...")
        -- Auto Execute on Rejoin
        local qt = queue_on_teleport or (syn and syn.queue_on_teleport)
        if qt then
            qt([[
                task.wait(3)
                local s, err = pcall(function() 
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/ChalaRmmEIEI/sanlam/main/hehe.lua"))()
                end)
                if not s then warn("AutoExec Failed:", err) end
            ]])
        end
        
        if #Players:GetPlayers() <= 1 then
            LP:Kick("Rejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, LP)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end
    end

    -- Listener 1: Error Prompt appearing
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' and child:FindFirstChild('MessageArea') and child.MessageArea:FindFirstChild("ErrorFrame") then
            Rejoin()
        end
    end)
    
    -- Listener 2: Error Message Changed event
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(0.5)
        Rejoin()
    end)
end)

-- LOADING SCREEN (Map Load Safety)
do
    -- Wait for game load first
    if not game:IsLoaded() then game.Loaded:Wait() end
    
    -- Create Loader UI
    local LoaderGui = Instance.new("ScreenGui")
    LoaderGui.Name = "ChaLarmLoader"
    LoaderGui.Parent = game:GetService("CoreGui")
    LoaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Frame = Instance.new("Frame")
    Frame.Parent = LoaderGui
    Frame.BackgroundTransparency = 1 -- Transparent fullscreen (User request)
    Frame.Position = UDim2.new(0, 0, 0, 0)
    Frame.Size = UDim2.new(1, 0, 1, 0)
    
    local Center = Instance.new("Frame")
    Center.Parent = Frame
    Center.AnchorPoint = Vector2.new(0.5, 0.5)
    Center.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark Card Background
    Center.BorderSizePixel = 0
    Center.Position = UDim2.new(0.5, 0, 0.5, 0)
    Center.Size = UDim2.new(0, 350, 0, 120) -- Slightly larger for padding
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Center
    
    local Logo = Instance.new("TextLabel")
    Logo.Parent = Center
    Logo.BackgroundTransparency = 1
    Logo.Position = UDim2.new(0, 0, 0, 15)
    Logo.Size = UDim2.new(1, 0, 0, 35)
    Logo.Font = Enum.Font.GothamBold
    Logo.Text = "ChaLarmHub 🦈"
    Logo.TextColor3 = Color3.fromRGB(127, 0, 255)
    Logo.TextSize = 28
    
    local BarBg = Instance.new("Frame")
    BarBg.Parent = Center
    BarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BarBg.BorderSizePixel = 0
    BarBg.Position = UDim2.new(0.1, 0, 0, 60)
    BarBg.Size = UDim2.new(0.8, 0, 0, 6)
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = BarBg
    
    local Bar = Instance.new("Frame")
    Bar.Parent = BarBg
    Bar.BackgroundColor3 = Color3.fromRGB(127, 0, 255)
    Bar.BorderSizePixel = 0
    Bar.Size = UDim2.new(0, 0, 1, 0)
    
    local BarCorner2 = Instance.new("UICorner")
    BarCorner2.CornerRadius = UDim.new(1, 0)
    BarCorner2.Parent = Bar
    
    local Status = Instance.new("TextLabel")
    Status.Parent = Center
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.new(0, 0, 0, 75)
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Font = Enum.Font.Gotham
    Status.Text = "Loading Assets... 0%"
    Status.TextColor3 = Color3.fromRGB(150, 150, 150)
    Status.TextSize = 14
    
    -- Animation Loop (Approx 10 seconds)
    local totalTime = 10
    local startTime = tick()
    
    while tick() - startTime < totalTime do
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / totalTime, 0, 1)
        local pct = math.floor(progress * 100)
        
        Bar.Size = UDim2.new(progress, 0, 1, 0)
        Status.Text = string.format("Loading Assets... %d%%", pct)
        
        Status.Text = string.format("Loading Assets... %d%%", pct)
        
        task.wait()
    end
    
    LoaderGui:Destroy()
end

-- CONFIGURATION System
local function GetConfigPath()
    local mapName = "Unknown"
    pcall(function() mapName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
    mapName = mapName:gsub("[^%w%s]", ""):gsub("%s+", "")
    local playerFolder = LP.Name
    return "ChaLarmHub/" .. mapName .. "/" .. playerFolder .. ".json"
end

local lastSaveRequest = 0
local function SaveConfig()
    lastSaveRequest = tick()
    local currentRequest = lastSaveRequest
    
    task.delay(1, function()
        if lastSaveRequest ~= currentRequest then return end
        if not (writefile and makefolder) then return end
        
        local path = GetConfigPath()
        local folder = path:match("(.+)/")
        if not isfolder(folder) then
            local parts = folder:split("/")
            local current = ""
            for i,part in ipairs(parts) do
                current = current .. part
                if not isfolder(current) then makefolder(current) end
                current = current .. "/"
            end
        end
        writefile(path, HttpService:JSONEncode(Options))
    end)
end

local function LoadConfig()
    if not (readfile and isfile) then return end
    local path = GetConfigPath()
    if isfile(path) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success then
            for k, v in pairs(result) do
                Options[k] = v
            end
        end
    end
end
LoadConfig()

-- [[ 3. UI LIBRARIES & INITIALIZATION ]] --

-- Load Libraries
local Cascade = loadstring(game:HttpGet("https://raw.githubusercontent.com/ChalaRmmEIEI/brfsf/refs/heads/main/bsva.lua"))()
local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/ChalaRmmEIEI/brfsf/refs/heads/main/vedw.lua"))()
local ToggleIconScript = "https://raw.githubusercontent.com/ChalaRmmEIEI/brfsf/refs/heads/main/vrdvd1.lua"

-- App Initialization
local App = Cascade.New({ Theme = Cascade.Themes.Dark })
local Icons = {
    Mouse = Cascade.Symbols and Cascade.Symbols.cursorarrow or "rbxassetid://76353347413637",
    Egg = Cascade.Symbols and Cascade.Symbols.basket or "rbxassetid://93773308549052",
    Money = Cascade.Symbols and Cascade.Symbols.dollarsign or "rbxassetid://109669077542924",
    Shop = Cascade.Symbols and Cascade.Symbols.cart or "rbxassetid://71113964288896",
    Settings = Cascade.Symbols and Cascade.Symbols.gear or "rbxassetid://93463417713731"
}

-- Main Window
local Window = App:Window({
    Title = "🌾 Feed and Farm Animal 🦈",
    Subtitle = "🌊 Made By ChaLarm 🦈",
    Folder = "ChaLarmHub",
    Size = UDim2.fromOffset(650, 550),
    Acrylic = true,
    Theme = "Dark"
})

-- Universal Toggle Icon Initialization
task.spawn(function()
    local success, ToggleIcon = pcall(function() return loadstring(game:HttpGet(ToggleIconScript))() end)
    if success and ToggleIcon then
        ToggleIcon.SetCallback(function()
            if Window then
                Window.Minimized = not Window.Minimized
                return Window.Minimized
            end
            return false
        end)
        ToggleIcon.SetColor(Color3.fromRGB(127, 0, 255))
        task.spawn(function()
            local lastState = nil
            while true do
                task.wait(0.2)
                if Window then
                    local currentMinimized = Window.Minimized
                    if currentMinimized ~= lastState then
                        lastState = currentMinimized
                        if ToggleIcon.SetState then ToggleIcon.SetState(currentMinimized) end
                    end
                end
            end
        end)
    end
end)

-- Keybind Toggle Listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = Options.MinimizeKey
    if typeof(key) == "string" then 
        local s, k = pcall(function() return Enum.KeyCode[key] end)
        key = s and k or Enum.KeyCode.RightControl
    else
        key = key or Enum.KeyCode.RightControl
    end
    if input.KeyCode == key then Window.Minimized = not Window.Minimized end
end)

-- Main Categories
local AutoFarmSection = Window:Section({ Title = "Auto Farm" })
local Tabs = {
    OpenEgg = AutoFarmSection:Tab({ Title = "Open Egg", Icon = Icons.Egg }),
    Main = AutoFarmSection:Tab({ Title = "Auto Click", Icon = Icons.Mouse }),
    Egg = AutoFarmSection:Tab({ Title = "Egg Dupe", Icon = Icons.Egg }),
    Money = AutoFarmSection:Tab({ Title = "Auto Money", Icon = Icons.Money }),
    Shop = AutoFarmSection:Tab({ Title = "Shop", Icon = Icons.Shop }),
}

local SettingsSection = Window:Section({ Title = "UI Settings" })
Tabs.Settings = SettingsSection:Tab({ Title = "Settings", Icon = Icons.Settings })


task.spawn(function()
    task.wait(0.5) -- รอให้ UI โหลดเสร็จ
    if Tabs.OpenEgg then
        pcall(function()
            if Tabs.OpenEgg.Select then
                Tabs.OpenEgg:Select()
            end
        end)
    end
end)


-- [[ 4. APPLICATION LOGIC: AUTO FARM ]] --


-- TAB: OPEN EGG
do
    local Tab = Tabs.OpenEgg
    local form = Tab:PageSection({ Title = "🥚 Open Egg", Subtitle = "Auto hatch functionality" }):Form()
    
    local isOpening = false
    
    -- ปุ่ม Open All (วนลูปจนกว่าจะหมด)
    local row1 = form:Row({ SearchIndex = "Open All Eggs" })
    row1:Left():TitleStack({ Title = "🥚 Open All Eggs", Subtitle = "Open all eggs until none left." })
    row1:Right():Button({
        Label = "Open All",
        Pushed = function(self)
            if isOpening then
                Notify("🥚 Open Egg", "⚠️ Already running!", 2)
                return
            end
            
            isOpening = true
            task.spawn(function()
                local sceneName = "\230\136\152\230\150\151\229\156\186\230\153\175" -- 战斗场景
                local incubateName = "\230\173\163\229\156\168\229\173\181\229\140\150\228\184\173" -- 正在孵化中
                local totalOpened = 0
                
                Notify("🥚 Open Egg", "🚀 Starting...", 2)
                
                -- วนลูปจนกว่าจะไม่มีไข่เหลือ
                while isOpening do
                    local foundEggs = false
                    
                    pcall(function()
                        -- หา Player Folder
                        local playerFolder = workspace:FindFirstChild(sceneName)
                        if not playerFolder then return end
                        
                        playerFolder = playerFolder:FindFirstChild(LP.Name)
                        if not playerFolder then return end
                        
                        -- หา Incubate Folder
                        local incubateFolder = playerFolder:FindFirstChild(incubateName)
                        if not incubateFolder then return end
                        
                        -- สแกนหาไข่ทั้งหมด
                        local eggs = {}
                        for _, child in ipairs(incubateFolder:GetChildren()) do
                            if child.Name:match("^HatchingEgg_") then
                                local root = child:FindFirstChild("Root")
                                if root and root:IsA("BasePart") then
                                    local prompt = root:FindFirstChild("ProximityPrompt")
                                    if prompt and prompt.Enabled then
                                        table.insert(eggs, {
                                            Model = child,
                                            Root = root,
                                            Prompt = prompt
                                        })
                                    end
                                end
                            end
                        end
                        
                        -- ถ้าพบไข่
                        if #eggs > 0 then
                            foundEggs = true
                            
                            -- เปิดทั้งหมดพร้อมกัน
                            for i, eggData in ipairs(eggs) do
                                task.spawn(function()
                                    pcall(function()
                                        eggData.Prompt.MaxActivationDistance = math.huge
                                        eggData.Prompt.HoldDuration = 0
                                        fireproximityprompt(eggData.Prompt)
                                        
                                        totalOpened = totalOpened + 1
                                        warn(string.format("🥚 [Total: %d] Opened: %s", totalOpened, eggData.Model.Name))
                                    end)
                                end)
                                task.wait(0.05) -- ป้องกันสแปม
                            end
                            
                            -- รอให้เปิดเสร็จก่อนสแกนใหม่
                            task.wait(2)
                        end
                    end)
                    
                    -- ถ้าไม่เจอไข่ = เสร็จสิ้น
                    if not foundEggs then
                        isOpening = false
                        Notify("🥚 Open Egg", "✅ Finished! Opened " .. totalOpened .. " eggs.", 3)
                        break
                    end
                    
                    task.wait(0.5) -- Delay ก่อนสแกนรอบถัดไป
                end
            end)
        end
    })
end

-- TAB: MAIN (Auto Click & Fruit)
do
    local Tab = Tabs.Main
    
    -- Clicker
    do
        local form = Tab:PageSection({ Title = "Auto Clicker 🖱️", Subtitle = "Auto click functionality" }):Form()
        local AutoClickEnabled, ClickConn = false, nil
        local ClickRemote = ReplicatedStorage.Msg.RemoteFunction
        
        local row = form:Row({ SearchIndex = "Auto Click Fruit Machine" })
        row:Left():TitleStack({ Title = "Auto Click Fruit Machine", Subtitle = "Automatically clicks the machine." })
        row:Right():Toggle({
            Value = Options.AutoClickFruit or false,
            ValueChanged = function(self, v)
                Options.AutoClickFruit = v
                SaveConfig()
                AutoClickEnabled = v
                if v then
                    local lastClick = 0
                    ClickConn = RunService.RenderStepped:Connect(function()
                        if AutoClickEnabled then 
                            local now = tick()
                            if now - lastClick >= 0.1 then
                                lastClick = now
                                task.spawn(function() pcall(ClickRemote.InvokeServer, ClickRemote, "\xE7\x82\xB9\xE5\x87\xBB\xE6\xB0\xB4\xE6\x9E\x9C\xE6\x9C\xBA\xE5\x99\xA8", 1) end)
                            end
                        end
                    end)
                else
                    if ClickConn then ClickConn:Disconnect(); ClickConn = nil end
                end
            end
        })
    end

    -- Global Fruit Collection
    do
        local form = Tab:PageSection({ Title = "🍎 Fruit Collection (Global)", Subtitle = "Master Control" }):Form()
        local Master_On, Master_Hr = false, 1
        local CollectRemote = ReplicatedStorage.Msg.RemoteFunction

        local row1 = form:Row({ SearchIndex = "Auto Collect ALL" })
        row1:Left():TitleStack({ Title = "🌟 Auto Collect ALL", Subtitle = "Toggle all slots collection." })
        row1:Right():Toggle({ 
            Value = Options.MasterCollect_Enabled or false, 
            ValueChanged = function(self, v) 
                Options.MasterCollect_Enabled = v
                SaveConfig()
                Master_On = v 
            end 
        })

        local row2 = form:Row({ SearchIndex = "Global Delay" })
        local defaultDelay = Options.MasterCollect_Delay or 1
        Master_Hr = defaultDelay
        local delayTitle = row2:Left():TitleStack({ Title = "⏱️ Global Delay ("..Master_Hr..")", Subtitle = "Interval in hours." })
        row2:Right():Slider({
            Value = defaultDelay, Minimum = 1, Maximum = 24, Step = 1,
            ValueChanged = function(s, v)
                Options.MasterCollect_Delay = v
                SaveConfig()
                Master_Hr = v
                delayTitle.Title = "⏱️ Global Delay ("..math.floor(v)..")"
            end
        })
        
        task.spawn(function() 
            while true do 
                if Master_On then 
                    Notify("🚜 Master Collect", "Collecting...", 3)
                    local limits = {[1]=1, [2]=1, [3]=4, [4]=6}
                    for sid,lim in pairs(limits) do
                        for i=1,lim do 
                            task.spawn(function() pcall(CollectRemote.InvokeServer, CollectRemote, "\230\148\182\232\142\183\230\176\180\230\158\156", {sid, i}) end) 
                        end
                    end
                    task.wait(Master_Hr * 3600) 
                else task.wait(5) end 
            end 
        end)
    end

    -- Independent Slot Collection
    do
        local form = Tab:PageSection({ Title = "🎰 Independent Slots", Subtitle = "Configure slots individually." }):Form()
        local CollectRemote = ReplicatedStorage.Msg.RemoteFunction
        local function simpleCollect(sid, iter)
            for i=1,iter do task.spawn(function() pcall(CollectRemote.InvokeServer, CollectRemote, "\230\148\182\232\142\183\230\176\180\230\158\156", {sid, i}) end) end
        end

        local S1, S2, S3, S4 = false, false, false, false
        local T1, T2, T3, T4 = 5, 5, 1, 1

        local r1 = form:Row({ SearchIndex = "Auto Slot 1" })
        r1:Left():TitleStack({ Title = "Auto Slot 1 🎰", Subtitle = "Collect Slot 1." })
        r1:Right():Toggle({ Value = false, ValueChanged = function(s,v) S1=v end })
        local r2 = form:Row({ SearchIndex = "Slot 1 Delay" })
        local t1Title = r2:Left():TitleStack({ Title = "⏱️ Slot 1 Delay ("..T1..")", Subtitle = "Minutes." })
        r2:Right():Slider({ Value = 5, Minimum=1, Maximum=60, Step=1, ValueChanged = function(s,v) T1=v; t1Title.Title = "⏱️ Slot 1 Delay ("..math.floor(v)..")" end })

        local r3 = form:Row({ SearchIndex = "Auto Slot 2" })
        r3:Left():TitleStack({ Title = "Auto Slot 2 🎰", Subtitle = "Collect Slot 2." })
        r3:Right():Toggle({ Value = false, ValueChanged = function(s,v) S2=v end })
        local r4 = form:Row({ SearchIndex = "Slot 2 Delay" })
        local t2Title = r4:Left():TitleStack({ Title = "⏱️Slot 2 Delay ("..T2..")", Subtitle = "Minutes." })
        r4:Right():Slider({ Value = 5, Minimum=1, Maximum=60, Step=1, ValueChanged = function(s,v) T2=v; t2Title.Title = "Slot 2 Delay ("..math.floor(v)..")" end })

        local r5 = form:Row({ SearchIndex = "Auto Slot 3" })
        r5:Left():TitleStack({ Title = "Auto Slot 3", Subtitle = "Collect Slot 3." })
        r5:Right():Toggle({ Value = false, ValueChanged = function(s,v) S3=v end })
        local r6 = form:Row({ SearchIndex = "Slot 3 Delay" })
        local t3Title = r6:Left():TitleStack({ Title = "⏱️Slot 3 Delay ("..T3..")", Subtitle = "Hours." })
        r6:Right():Slider({ Value = 1, Minimum=1, Maximum=24, Step=1, ValueChanged = function(s,v) T3=v; t3Title.Title = "Slot 3 Delay ("..math.floor(v)..")" end })

        local r7 = form:Row({ SearchIndex = "Auto Slot 4" })
        r7:Left():TitleStack({ Title = "Auto Slot 4 🎰", Subtitle = "Collect Slot 4." })
        r7:Right():Toggle({ Value = false, ValueChanged = function(s,v) S4=v end })
        local r8 = form:Row({ SearchIndex = "Slot 4 Delay" })
        local t4Title = r8:Left():TitleStack({ Title = "⏱️Slot 4 Delay ("..T4..")", Subtitle = "Hours." })
        r8:Right():Slider({ Value = 1, Minimum=1, Maximum=24, Step=1, ValueChanged = function(s,v) T4=v; t4Title.Title = "Slot 4 Delay ("..math.floor(v)..")" end })

        task.spawn(function() while true do if S1 then simpleCollect(1,1); task.wait(T1*60) else task.wait(5) end end end)
        task.spawn(function() while true do if S2 then simpleCollect(2,1); task.wait(T2*60) else task.wait(5) end end end)
        task.spawn(function() while true do if S3 then simpleCollect(3,4); task.wait(T3*3600) else task.wait(5) end end end)
        task.spawn(function() while true do if S4 then simpleCollect(4,6); task.wait(T4*3600) else task.wait(5) end end end)
    end
end

-- TAB: EGG DUPE
do
    local Tab = Tabs.Egg
    local form = Tab:PageSection({ Title = "⚠️ Dupe Settings", Subtitle = "Configure cloning parameters" }):Form()
    
    -- Load Options / Defaults
    Options.DupeTarget = Options.DupeTarget or "IdKaiKirati_28402"
    Options.DupeRejoinDelay = Options.DupeRejoinDelay or 5
    Options.AutoDupe = Options.AutoDupe or false

    local EggDupeRun = false

    -- Dupe Logic
    local function StartDupe()
        if EggDupeRun then return end
        EggDupeRun = true
        
        task.spawn(function()
            local sceneName = "\230\136\152\230\150\151\229\156\186\230\153\175"
            local incubateName = "\230\173\163\229\156\168\229\173\181\229\140\150\228\184\173"
            
            local s, f = pcall(function() return workspace:WaitForChild(sceneName, 5):WaitForChild(Options.DupeTarget, 5):WaitForChild(incubateName, 5) end)
            
            if s and f then
                local eggs = {}
                for _,c in ipairs(f:GetChildren()) do if c.Name:find("HatchingEgg_") then table.insert(eggs,c) end end
                
                if #eggs > 0 then
                    Notify("🌀 Dupe", "Buying "..#eggs.." Eggs", 3)
                    for _,e in ipairs(eggs) do 
                        pcall(function() ReplicatedStorage.Msg.RemoteEvent:FireServer("\xE8\xB4\xAD\xE4\xB9\xB0\xE8\x9B\x8B", e) end)
                        task.wait(0.1) 
                    end
                    
                    -- Rejoin Logic
                    if Options.AutoDupe then
                        local qt = queue_on_teleport or (syn and syn.queue_on_teleport)
                        if qt then
                            qt([[
                                task.wait(3)
                                local s, err = pcall(function() 
                                    loadstring(game:HttpGet("https://raw.githubusercontent.com/ChalaRmmEIEI/sanlam/main/hehe.lua"))()
                                end)
                                if not s then warn("AutoExec Failed:", err) end
                            ]])
                        end
                    end

                    local delayTime = Options.DupeRejoinDelay or 5
                    Notify("🌀 Dupe", "Rejoining in " .. delayTime .. "s...", 2)
                    task.wait(delayTime)
                    
                    if #Players:GetPlayers() <= 1 then 
                        LP:Kick("\nDupe Done Wait For Rejoin...")
                        task.wait()
                        TeleportService:Teleport(game.PlaceId, LP)
                    else 
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
                    end
                else 
                    Notify("🌀 Dupe", "No Eggs Found", 3) 
                end
            else 
                Notify("🌀 Dupe", "Target Not Found", 3) 
            end
            EggDupeRun = false
        end)
    end

    local r1 = form:Row({ SearchIndex = "Target Name" })
    r1:Left():TitleStack({ Title = "👤 Target Name", Subtitle = "The name of the player to target." })
    r1:Right():TextField({ 
        Placeholder = "Target", 
        Value = Options.DupeTarget, 
        ValueChanged = function(s,v) Options.DupeTarget = v; SaveConfig() end 
    })
    
    local r2 = form:Row({ SearchIndex = "Rejoin Delay" })
    local rejoinTitle = r2:Left():TitleStack({ Title = "⌛Rejoin Delay ("..Options.DupeRejoinDelay..")", Subtitle = "Seconds to wait before rejoining." })
    r2:Right():Slider({ 
        Value = Options.DupeRejoinDelay, Minimum = 3, Maximum = 30, Step = 1, 
        ValueChanged = function(s,v) 
            Options.DupeRejoinDelay = v; SaveConfig()
            rejoinTitle.Title = "Rejoin Delay ("..math.floor(v)..")" 
        end 
    })

    -- Auto Execute Toggle
    local r_auto = form:Row({ SearchIndex = "Auto Execute" })
    r_auto:Left():TitleStack({ Title = "🔁 Auto Execute", Subtitle = "Auto run script & dupe on rejoin." })
    r_auto:Right():Toggle({
        Value = Options.AutoDupe,
        ValueChanged = function(s,v) Options.AutoDupe = v; SaveConfig() end
    })

    local r3 = form:Row({ SearchIndex = "Start Dupe" })
    r3:Left():TitleStack({ Title = "Start Dupe✅", Subtitle = "Begin the duplication process." })
    r3:Right():Button({ Label = "Start", Pushed = function(self) StartDupe() end })
end

-- TAB: AUTO MONEY
do
    local Tab = Tabs.Money
    local form = Tab:PageSection({ Title = "💰 Money Farm", Subtitle = "Auto collect currency" }):Form()
    local AutoMoneyOn, MoneyInt = false, 300
    local MoneyRemote = ReplicatedStorage.Msg.RemoteEvent

    local r1 = form:Row({ SearchIndex = "Interval" })
    local defaultInt = Options.AutoMoney_Interval or 5
    MoneyInt = defaultInt * 60
    local intTitle = r1:Left():TitleStack({ Title = "⏱️ Interval ("..defaultInt..")", Subtitle = "Time in minutes between collections." })
    r1:Right():Slider({ 
        Value = defaultInt, Minimum = 5, Maximum = 720, Step = 1, 
        ValueChanged = function(s,v) 
            Options.AutoMoney_Interval = v
            SaveConfig()
            MoneyInt = v * 60; 
            intTitle.Title = "Interval ("..math.floor(v)..")" 
        end 
    })

    local r2 = form:Row({ SearchIndex = "Auto Collect" })
    r2:Left():TitleStack({ Title = "💸Auto Collect", Subtitle = "Enable automated collection loop." })
    r2:Right():Toggle({
        Value = Options.AutoMoney_Enabled or false, 
        ValueChanged = function(s,v)
            Options.AutoMoney_Enabled = v
            SaveConfig()
            AutoMoneyOn = v
            if v then
                task.spawn(function()
                    while AutoMoneyOn do
                        pcall(function()
                            local f = workspace:FindFirstChild("\230\136\152\230\150\151\229\156\186\230\153\175")
                            if f and f:FindFirstChild(LP.Name) and f[LP.Name]:FindFirstChild("HerosFolder") then
                                for _,h in ipairs(f[LP.Name]["HerosFolder"]:GetChildren()) do
                                    if tonumber(h.Name) then 
                                        task.spawn(function() pcall(MoneyRemote.FireServer, MoneyRemote, "\xE9\xA2\x86\xE5\x8F\x96\xE5\x8A\xA8\xE7\x89\xA9\xE8\xB5\x9A\xE7\x9A\x84\xE9\x92\xB1", tonumber(h.Name)) end)
                                    end
                                end
                            end
                        end)
                        task.wait(MoneyInt)
                    end
                end)
            end
        end
    })

    local r3 = form:Row({ SearchIndex = "Manual Action" })
    r3:Left():TitleStack({ Title = "Manual Action💸", Subtitle = "Collect money immediately." })
    r3:Right():Button({
        Label = "Collect",
        Pushed = function(self)
            task.spawn(function()
                pcall(function() 
                    local f = workspace:FindFirstChild("\230\136\152\230\150\151\229\156\186\230\153\175")
                    if f and f:FindFirstChild(LP.Name) and f[LP.Name]:FindFirstChild("HerosFolder") then
                        for _,h in ipairs(f[LP.Name]["HerosFolder"]:GetChildren()) do 
                            if tonumber(h.Name) then task.spawn(function() pcall(MoneyRemote.FireServer, MoneyRemote, "\xE9\xA2\x86\xE5\x8F\x96\xE5\x8A\xA8\xE7\x89\xA9\xE8\xB5\x9A\xE7\x9A\x84\xE9\x92\xB1", tonumber(h.Name)) end) end 
                        end 
                        Notify("💰 Success", "Collected Money", 2)
                    end
                end)
            end)
        end
    })
end

-- TAB: SHOP (Egg Sniper & Potions)
do
    local Tab = Tabs.Shop
    
    -- Player Stats
    do
        local form = Tab:PageSection({ Title = "📊 Player Information", Subtitle = "Stats overview" }):Form()
        local StatsRow = form:Row({ SearchIndex = "Current Stats" })
        StatsRow:Left():TitleStack({ Title = "📊 Current Stats", Subtitle = "Wheat and Coins." })
        local StatsLabel = StatsRow:Right():Label({ Text = "Loading...", TextSize = 13, TextColor3 = Color3.new(0.8,0.8,0.8) })
        task.spawn(function()
            while true do
                pcall(function()
                    local ls, w, c = LP:FindFirstChild("leaderstats"), nil, nil
                    if ls then w = ls:FindFirstChild("🌾Wheat") or ls:FindFirstChild("Wheat"); c = ls:FindFirstChild("💰Coins") or ls:FindFirstChild("Coins") end
                    if StatsLabel then StatsLabel.Text = "🌾Wheat: "..(w and w.Value or 0).." | 💰Coins: "..(c and c.Value or 0) end
                end)
                task.wait(2)
            end
        end)
    end

    -- Egg Sniper
    do
        local form = Tab:PageSection({ Title = "🥚 Egg Sniper", Subtitle = "Automated egg purchasing" }):Form()
        local AutoBuyEgg, BuyLimit, BuyCount = false, 1, 0
        local SelEggs, SelMagic, MagicFilter = {}, {}, false
        local AutoBuyTog, MagicDropdown

        local r1 = form:Row({ SearchIndex = "Select Eggs" })
        r1:Left():TitleStack({ Title = "🥚 Select Eggs", Subtitle = "Eggs to target." })
        r1:Right():PullDownButton({
            Options = {"Plain Egg", "Mud Egg", "Hydro Egg", "Speckled Egg", "Tentacle Egg", "Frost Egg", "Demon Egg", "Horn Egg", "Cacti Egg", "Volt Egg", "Plume Egg", "Tiger Egg", "Archaeopteryx Egg"}, 
            Multi = true,  
            Value = Options.Shop_SelEggs or {},
            Label = (Options.Shop_SelEggs and #Options.Shop_SelEggs > 0 and Options.Shop_SelEggs[1]..",") or "",
            ValueChanged = function(s,v) 
                Options.Shop_SelEggs = (type(v)=="table" and v) or {v}
                SaveConfig()
                SelEggs = Options.Shop_SelEggs
                table.sort(SelEggs)
            end
        })

        local MagicOptionsBase = {"Rainbow", "Butterfly", "Blood", "Galaxy", "Flower", "Glitch", "Snow", "Venom"}
        local MagicRow = form:Row({ SearchIndex = "Select Magic" })
        MagicRow:Left():TitleStack({ Title = "✨Select Magic", Subtitle = "Magic types to filter." })
        MagicDropdown = MagicRow:Right():PullDownButton({
            Options = MagicOptionsBase, 
            Multi = true, 
            Value = Options.Shop_SelMagic or {},
            Label = (Options.Shop_SelMagic and #Options.Shop_SelMagic > 0 and Options.Shop_SelMagic[1]..",") or "",
            ValueChanged = function(s, v)
                if not v or type(v) ~= "table" then return end
                Options.Shop_SelMagic = v
                SaveConfig()
                SelMagic = v
                table.sort(SelMagic)
            end
        })

        local r2 = form:Row({ SearchIndex = "Strict Magic" })
        r2:Left():TitleStack({ Title = "✨Strict Magic", Subtitle = "Only buy if magic matches." })
        r2:Right():Toggle({ 
            Value = Options.Shop_MagicFilter or false, 
            ValueChanged = function(s,v) 
                Options.Shop_MagicFilter = v
                SaveConfig()
                MagicFilter = v 
            end 
        })

        local r3 = form:Row({ SearchIndex = "Buy Limit" })
        local defaultLimit = Options.Shop_BuyLimit or 5
        BuyLimit = defaultLimit
        local limitTitle = r3:Left():TitleStack({ Title = "🥚 Buy Limit ("..BuyLimit..")", Subtitle = "Max eggs to buy per run." })
        r3:Right():Slider({ 
            Value = defaultLimit, 
            Minimum = 1, 
            Maximum = 50, 
            Step = 1, 
            ValueChanged = function(s,v) 
                Options.Shop_BuyLimit = v
                SaveConfig()
                BuyLimit = v
                limitTitle.Title = "🥚 Buy Limit ("..math.floor(v)..")" 
            end 
        })
        
        local r4 = form:Row({ SearchIndex = "Auto Buy" })
        r4:Left():TitleStack({ Title = "💸Auto Buy", Subtitle = "Start sniper loop." })
        AutoBuyTog = r4:Right():Toggle({
            Value = Options.Shop_AutoBuyEgg or false,
            ValueChanged = function(self, v)
                Options.Shop_AutoBuyEgg = v
                SaveConfig()
                AutoBuyEgg = v
                BuyCount = 0
                
                if v then
                    task.spawn(function()
                        local sceneName = "\230\136\152\230\150\151\229\156\186\230\153\175"
                        local conveyorName = "\228\188\160\233\128\129\229\184\166\228\184\138\231\154\132\232\155\139"
                        local BuyRemote = ReplicatedStorage.Msg.RemoteEvent
                        local function getEggName(p) 
                            local m
                            for _,c in ipairs(p:GetChildren()) do 
                                if c:IsA("Model") and not c.Name:find("Root") then 
                                    m = c 
                                    break 
                                end 
                            end
                            if not m then return "Unknown" end
                            local i = m:FindFirstChild("EggInfo", true) or m:FindFirstChild("HatchEggInfo", true)
                            if i and i:FindFirstChild("Frame") and i.Frame:FindFirstChild("ZhName") then 
                                return i.Frame.ZhName.Text 
                            end
                            return m.Name 
                        end
                        
                        local function getEggMagic(p) 
                            local m
                            for _,c in ipairs(p:GetChildren()) do 
                                if c:IsA("Model") and not c.Name:find("Root") then 
                                    m = c 
                                    break 
                                end 
                            end
                            if not m then return "None" end
                            local i = m:FindFirstChild("EggInfo", true) or m:FindFirstChild("HatchEggInfo", true)
                            if i and i.Frame:FindFirstChild("Magic") and i.Frame.Magic:IsA("TextLabel") then 
                                return i.Frame.Magic.ContentText ~= "" and i.Frame.Magic.ContentText or i.Frame.Magic.Text 
                            end
                            return "None" 
                        end
                        
                        local function getInner(p) 
                            for _,c in ipairs(p:GetChildren()) do 
                                if c:IsA("Model") and not c.Name:find("Root") then 
                                    return c 
                                end 
                            end 
                            return nil 
                        end
                        
                        while AutoBuyEgg do
                            local shouldStop = false
                            if MagicFilter then
                                shouldStop = (#SelMagic == 0)
                            else
                                shouldStop = (BuyCount >= BuyLimit)
                            end
                            
                            if shouldStop then 
                                AutoBuyEgg = false
                                pcall(function() AutoBuyTog.Value = false end)
                                
                                if MagicFilter and #Options.Shop_SelMagic > 0 then
                                    Notify("✅ Done", "Got all selected Magic! (" .. BuyCount .. " eggs)", 3)
                                    SelMagic = {}
                                    MagicDropdown.Value = {}
                                    Options.Shop_SelMagic = {}
                                    SaveConfig()
                                else
                                    Notify("✅ Done", "Limit Reached (" .. BuyCount .. " eggs)", 3)
                                end
                                break 
                            end
                            
                            local s, f = pcall(function() 
                                return workspace[sceneName][LP.Name][conveyorName] 
                            end)
                            
                            if s and f then
                                for _, p in ipairs(f:GetChildren()) do
                                    if not AutoBuyEgg or BuyCount >= BuyLimit then break end
                                    
                                    if p.Name:find("Egg_") and p:IsA("BasePart") then
                                        local eName = getEggName(p) or ""
                                        local eMagic = getEggMagic(p) or "None"
                                        local magicOk = true
                                        
                                        if MagicFilter then 
                                            magicOk = false
                                            for _, m in ipairs(SelMagic) do 
                                                if eMagic:find(m) then 
                                                    magicOk = true 
                                                    break 
                                                end 
                                            end 
                                        end
                                        
                                        if magicOk then
                                            local typeOk = (#SelEggs == 0)
                                            if not typeOk then 
                                                for _, t in ipairs(SelEggs) do 
                                                    if eName:find(t) or t:find(eName) then 
                                                        typeOk = true 
                                                        break 
                                                    end 
                                                end 
                                            end
                                            
                                            if typeOk then
                                                pcall(function()
                                                    local mod = getInner(p)
                                                    if mod then 
                                                        local pro = mod:FindFirstChild("ProximityPrompt", true)
                                                        if pro then 
                                                            pro.MaxActivationDistance = math.huge
                                                            pro.HoldDuration = 0
                                                            fireproximityprompt(pro) 
                                                        end
                                                        
                                                        BuyRemote:FireServer("\232\180\173\228\185\176\232\155\139", mod)
                                                        
                                                        if MagicFilter and eMagic ~= "None" then
                                                            warn(string.format("🥚 [Sniper] %s | %s bought!", eName or "Unknown", eMagic))
                                                        else
                                                            warn(string.format("🥚 [Sniper] %s bought!", eName or "Unknown"))
                                                        end

                                                        BuyCount = BuyCount + 1 
                                                        
                                                        -- ลบ Magic ที่ซื้อแล้วออกจาก Dropdown
                                                        if MagicFilter and eMagic ~= "None" then
                                                            local magicFound = false
                                                            for idx = #SelMagic, 1, -1 do 
                                                                if eMagic:find(SelMagic[idx]) then 
                                                                    warn(string.format("✅ Removed '%s' from selection", SelMagic[idx]))
                                                                    table.remove(SelMagic, idx)
                                                                    magicFound = true
                                                                    break 
                                                                end 
                                                            end
                                                            
                                                            if magicFound then
                                                                MagicDropdown.Value = SelMagic
                                                                Options.Shop_SelMagic = SelMagic
                                                                SaveConfig()
                                                            end
                                                        end
                                                    end 
                                                end)
                                                
                                                task.wait(0.3)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            
                            task.wait(0.2)
                        end
                    end)
                end
            end
        })
    end

    -- Potions
    do
        local form = Tab:PageSection({ Title = "🧪 Potions", Subtitle = "Power-up shop" }):Form()
        local PotionList = {["Size Potion"]=15000001, ["Rebirth Potion"]=15000002, ["Enchant Potion"]=15000003}
        local SelPotions, AutoPot = {}, false
        local PotionRemote = ReplicatedStorage.Msg.RemoteFunction
        
        local r1 = form:Row({ SearchIndex = "Select Potions" })
        r1:Left():TitleStack({ Title = "🧪 Select Potions", Subtitle = "Potions to buy." })
        r1:Right():PullDownButton({
            Options = {"Size Potion", "Rebirth Potion", "Enchant Potion"}, Multi = true, 
            Value = Options.Shop_SelPotions or {},
            Label = (Options.Shop_SelPotions and #Options.Shop_SelPotions > 0 and Options.Shop_SelPotions[1]..",") or "",
            ValueChanged = function(s,v) 
                Options.Shop_SelPotions = (type(v)=="table" and v) or {v}; SaveConfig(); SelPotions = {}
                for _,k in ipairs(Options.Shop_SelPotions) do if PotionList[k] then table.insert(SelPotions, PotionList[k]) end end
            end
        })
        
        local function buyPot()
            if not LP:FindFirstChild("MagicShop") then return end
            for _,pid in ipairs(SelPotions) do 
                local s=LP.MagicShop:FindFirstChild(tostring(pid))
                if s and s.Value>0 then 
                    for i=1,s.Value do 
                        task.spawn(function() 
                            pcall(PotionRemote.InvokeServer, PotionRemote, "\xE8\xB4\xAD\xE4\xB9\xB0\xE9\xAD\x94\xE6\xB3\x95\xE8\x8D\xAF\xE6\xB0\xB4", {pid,1}) 
                            
                            -- [NEW] Potion Identification & Warn
                            local pName = "Unknown Potion"
                            for name, id in pairs(PotionList) do if id == pid then pName = name break end end
                            warn("🧪 [Shop] " .. pName .. " is buy")
                        end)
                        task.wait(0.1) 
                    end 
                end 
            end
        end

        local r2 = form:Row({ SearchIndex = "Auto Buy Potions" })
        r2:Left():TitleStack({ Title = "💸Auto Buy", Subtitle = "⌛Every 5 minutes (xx:00, xx:05)" })
        r2:Right():Toggle({
            Value = Options.Shop_AutoPotions or false,
            ValueChanged = function(s,v)
                Options.Shop_AutoPotions = v; SaveConfig(); AutoPot=v
                if v then 
                    task.spawn(buyPot)
                    task.spawn(function() 
                        local lt="" 
                        while AutoPot do 
                            local d=os.date("*t")
                            if d.min%5==0 and lt~=(d.hour..":"..d.min) then lt=(d.hour..":"..d.min); task.wait(10); buyPot() end
                            task.wait(5)
                        end 
                    end) 
                end
            end
        })
    end
end

-- [[ 5. APPLICATION LOGIC: UI SETTINGS ]] --

do
    local tab = Tabs.Settings
    
    -- Appearance
    do 
        local form = tab:PageSection({ Title = "🎨 Appearance" }):Form() 

        local r1 = form:Row({ SearchIndex = "Dark mode" })
        r1:Left():TitleStack({ Title = "🌙 Dark mode", Subtitle = "Uses a dark color palette." })
        r1:Right():Toggle({ 
            Value = (Options.Theme_Type == "Dark") or (App.Theme == Cascade.Themes.Dark), 
            ValueChanged = function(s, v)
                Options.Theme_Type = v and "Dark" or "Light"; SaveConfig()
                App.Theme = v and Cascade.Themes.Dark or Cascade.Themes.Light 
            end 
        })

        local r2 = form:Row({ SearchIndex = "Low Graphics" })
        r2:Left():TitleStack({ Title = "📉 Low Graphics", Subtitle = "Maximum performance optimization for mobile units." })
        r2:Right():Button({
            Label = "Activate", 
            Pushed = function()
                if getgenv and getgenv().LowGraphicsActive then Notify("Low Graphics", "Already activated!", 2); return end
                if getgenv then getgenv().LowGraphicsActive = true end
                
                -- ⚙️ GRAPHICS & LIGHTING
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                pcall(function() Lighting.GlobalShadows = false end)
                
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or 
                       effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") then
                        effect.Enabled = false
                    end
                end
                
                -- 🌊 TERRAIN
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0; terrain.WaterReflectance = 0; terrain.WaterTransparency = 1; terrain.Decoration = false
                    terrain.WaterColor = Color3.new(0, 0, 0)
                end
                
                -- 📦 GLOBAL ASSETS & CHARACTERS
                local optimizedCount = 0
                for _, desc in pairs(workspace:GetDescendants()) do
                    pcall(function()
                        if desc:IsA("BasePart") then
                            desc.CastShadow = false
                            -- Simplify Characters
                            if desc.Parent:FindFirstChildOfClass("Humanoid") then desc.CastShadow = false end
                        elseif desc:IsA("Decal") or desc:IsA("Texture") then
                            desc.Transparency = 1
                        elseif desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Smoke") or 
                               desc:IsA("Sparkles") or desc:IsA("Trail") or desc:IsA("Beam") then
                            desc.Enabled = false
                        elseif desc:IsA("Accessory") then
                            desc:Destroy()
                        end
                    end)
                    optimizedCount = optimizedCount + 1
                    if optimizedCount % 100 == 0 then task.wait() end
                end

                -- 🖥️ 3D RENDERING (EXTREME)
                pcall(function() RunService:Set3dRenderingEnabled(false) end)
                
                Notify("📉 Low Graphics", "Optimized for Mobile! (3D Rendering Disabled)", 5)
            end
        })

        local r3 = form:Row({ SearchIndex = "Unlock FPS" })
        r3:Left():TitleStack({ Title = "Unlock FPS", Subtitle = "Set FPS Cap to 999." })
        r3:Right():Button({ Label = "Unlock", Pushed = function() if setfpscap then setfpscap(999) end; Notify("FPS", "Unlocked", 2) end })
    end

    -- Effects
    do
        local form = tab:PageSection({ Title = "✨ Effects", Subtitle = "Resource intensive effects." }):Form()
        Window.Dropshadow = Options.UI_Dropshadow or false
        Window.UIBlur = Options.UI_Blur or false
        
        local r1 = form:Row({ SearchIndex = "Dropshadow" })
        r1:Left():TitleStack({ Title = "Dropshadow", Subtitle = "Shadow effect on window." })
        r1:Right():Toggle({ Value = Options.UI_Dropshadow or false, ValueChanged = function(s,v) Options.UI_Dropshadow = v; SaveConfig(); Window.Dropshadow = v end })

        local r2 = form:Row({ SearchIndex = "Background blur" })
        r2:Left():TitleStack({ Title = "Background blur", Subtitle = "Blur effect behind window." })
        r2:Right():Toggle({ Value = Options.UI_Blur or false, ValueChanged = function(s,v) Options.UI_Blur = v; SaveConfig(); Window.UIBlur = v end })
    end

    -- Unlock Luck GP
    do
        local form = tab:PageSection({ Title = "🍀 Luck Unlocker", Subtitle = "Unlock Lucky GamePasses" }):Form()
        
        local r1 = form:Row({ SearchIndex = "Unlock Luck GP" })
        r1:Left():TitleStack({ Title = "Unlock Luck GP", Subtitle = "Unlock Lucky 1 & 2 only." })
        r1:Right():Button({
            Label = "Unlock Luck GP",
            Pushed = function(self)
                local gpFolder = LP:FindFirstChild("GamePass")
                if gpFolder then
                    local targets = { "Lucky1", "Lucky2" }
                    local count = 0
                    for _, tName in ipairs(targets) do
                        local gp = gpFolder:FindFirstChild(tName)
                        if gp and (gp:IsA("NumberValue") or gp:IsA("IntValue")) then
                            gp.Value = 1
                            count = count + 1
                        end
                    end
                    Notify("🍀 Unlocker", "Unlocked " .. count .. " Lucky Passes!", 3)
                else
                    Notify("🍀 Unlocker", "GamePass folder not found!", 3)
                end
            end
        })
    end

    -- Interface
    do
        local form = tab:PageSection({ Title = "📱 Interface" }):Form()
        local r1 = form:Row({ SearchIndex = "Minimize Keybind" })
        r1:Left():TitleStack({ Title = "⌨️ Minimize Keybind", Subtitle = "Key to toggle UI visibility." })
        local currentKey = Options.MinimizeKey
        if typeof(currentKey) == "string" then
            local s, k = pcall(function() return Enum.KeyCode[currentKey] end)
            currentKey = s and k or Enum.KeyCode.RightControl
        else
            currentKey = currentKey or Enum.KeyCode.RightControl
        end
        r1:Right():KeybindField({
            Value = currentKey,
            ValueChanged = function(s, v) Options.MinimizeKey = v.Name; SaveConfig() end
        })
        local r2 = form:Row({ SearchIndex = "Auto Hide UI" })
        r2:Left():TitleStack({ Title = "Auto Hide UI", Subtitle = "Minimize after 10s on launch." })
        r2:Right():Toggle({ Value = Options.UI_AutoHide or false, ValueChanged = function(s, v) Options.UI_AutoHide = v; SaveConfig() end })
    end
end

-- [[ 6. FINAL INITIALIZATION ]] --

-- Auto Hide Execution
task.spawn(function()
    if Options.UI_AutoHide then
        task.wait(10)
        Window.Minimized = true
    end
end)

Notify("ChaLarmHub 🦈", "Ui is Loaded ✅", 5)
