```lua
-- Load Rayfield UI Library
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/Rayfield/main/source.lua', true))()
end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Workspace       = game:GetService("Workspace")
local LocalPlayer     = Players.LocalPlayer
local Character       = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid        = Character:WaitForChild("Humanoid")

local State = {
    KillAura        = false,
    KillAuraRange   = 30,
    KillAuraDmg     = 9999,
    AutoFarm        = false,
    ESP             = false,
    Noclip          = false,
    SpeedHack       = false,
    SpeedValue      = 50,
    GodMode         = false,
    AuraLoop        = nil,
    FarmLoop        = nil,
    CollectLoop     = nil,
}

local function GetAllEnemies()
    local enemies = {}
    for _, model in pairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= Character then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                table.insert(enemies, model)
            end
        end
    end
    return enemies
end

local function GetNearestEnemy()
    local nearest, nearestDist = nil, math.huge
    for _, enemy in pairs(GetAllEnemies()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = enemy
            end
        end
    end
    return nearest
end

local function DamageEnemy(enemy, amount)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        pcall(function()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("hit") or v.Name:lower():find("attack")) then
                    v:FireServer(enemy, amount)
                end
            end
        end)
        pcall(function() hum.Health = 0 end)
    end
end

local ESPObjects = {}

local function CreateESP(model)
    pcall(function()
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = hrp
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 80, 80)
        label.TextStrokeTransparency = 0
        label.Text = "👻 " .. model.Name
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = billboard
        ESPObjects[model] = billboard
    end)
end

local function ClearESP()
    for model, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local Window = Rayfield:CreateWindow({
    Name = "👻 Anime Ghosts Hub",
    LoadingTitle = "Anime Ghosts Hub",
    LoadingSubtitle = "Delta Mobile Compatible",
    ConfigurationSaving = { Enabled = true, FileName = "AnimeGhostsHub" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
CombatTab:CreateSection("Kill Aura")

CombatTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(val)
        State.KillAura = val
        if val then
            State.AuraLoop = RunService.Heartbeat:Connect(function()
                if not State.KillAura then return end
                pcall(function()
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                    if not HumanoidRootPart then return end
                    for _, enemy in pairs(GetAllEnemies()) do
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                            if dist <= State.KillAuraRange then
                                DamageEnemy(enemy, State.KillAuraDmg)
                            end
                        end
                    end
                end)
            end)
        else
            if State.AuraLoop then State.AuraLoop:Disconnect() State.AuraLoop = nil end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {5, 150},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "KillAuraRange",
    Callback = function(val) State.KillAuraRange = val end,
})

CombatTab:CreateSlider({
    Name = "Kill Aura Damage",
    Range = {100, 999999},
    Increment = 1000,
    Suffix = " dmg",
    CurrentValue = 9999,
    Flag = "KillAuraDmg",
    Callback = function(val) State.KillAuraDmg = val end,
})

CombatTab:CreateSection("Auto Farm")

CombatTab:CreateToggle({
    Name = "Auto Farm (Nearest Enemy)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(val)
        State.AutoFarm = val
        if val then
            State.FarmLoop = RunService.Heartbeat:Connect(function()
                if not State.AutoFarm then return end
                pcall(function()
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                    Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                    if not HumanoidRootPart or not Humanoid then return end
                    local nearest = GetNearestEnemy()
                    if nearest then
                        local hrp = nearest:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            Humanoid:MoveTo(hrp.Position)
                            local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                            if dist < 15 then DamageEnemy(nearest, State.KillAuraDmg) end
                        end
                    end
                end)
            end)
        else
            if State.FarmLoop then State.FarmLoop:Disconnect() State.FarmLoop = nil end
        end
    end,
})

CombatTab:CreateToggle({
    Name = "Teleport To Enemies (Instant Farm)",
    CurrentValue = false,
    Flag = "TeleportFarm",
    Callback = function(val)
        if val then
            task.spawn(function()
                while val do
                    task.wait(0.3)
                    pcall(function()
                        Character = LocalPlayer.Character
                        HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                        if not HumanoidRootPart then return end
                        for _, enemy in pairs(GetAllEnemies()) do
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
                                DamageEnemy(enemy, 999999)
                                task.wait(0.05)
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local PlayerTab = Window:CreateTab("🧍 Player", 4483362458)
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(val)
        State.SpeedHack = val
        pcall(function()
            Character = LocalPlayer.Character
            Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then Humanoid.WalkSpeed = val and State.SpeedValue or 16 end
        end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 5,
    Suffix = " speed",
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(val)
        State.SpeedValue = val
        if State.SpeedHack then
            pcall(function()
                Character = LocalPlayer.Character
                Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.WalkSpeed = val end
            end)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(val)
        State.InfJump = val
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if State.InfJump then
                pcall(function()
                    Character = LocalPlayer.Character
                    Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end
        end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = " power",
    CurrentValue = 100,
    Flag = "JumpPower",
    Callback = function(val)
        pcall(function()
            Character = LocalPlayer.Character
            Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then Humanoid.JumpPower = val end
        end)
    end,
})

PlayerTab:CreateSection("God Mode")

PlayerTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(val)
        State.GodMode = val
        if val then
            task.spawn(function()
                while State.GodMode do
                    task.wait(0.1)
                    pcall(function()
                        Character = LocalPlayer.Character
                        Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                        if Humanoid then Humanoid.Health = Humanoid.MaxHealth end
                    end)
                end
            end)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(val)
        State.Noclip = val
        RunService.Stepped:Connect(function()
            if State.Noclip then
                pcall(function()
                    Character = LocalPlayer.Character
                    if Character then
                        for _, part in pairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end
        end)
    end,
})

local FarmTab = Window:CreateTab("🌀 Auto Farm", 4483362458)
FarmTab:CreateSection("Mass Kill")

FarmTab:CreateButton({
    Name = "Mass Kill All Enemies",
    Callback = function()
        local count = 0
        for _, enemy in pairs(GetAllEnemies()) do
            DamageEnemy(enemy, 999999)
            count = count + 1
        end
        Rayfield:Notify({ Title = "Mass Kill", Content = "Killed " .. count .. " enemies!", Duration = 3, Image = 4483362458 })
    end,
})

FarmTab:CreateButton({
    Name = "Teleport & Kill All",
    Callback = function()
        task.spawn(function()
            for _, enemy in pairs(GetAllEnemies()) do
                pcall(function()
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                    local hrp = enemy:FindFirstChild("HumanoidRootPart")
                    if HumanoidRootPart and hrp then
                        HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
                        DamageEnemy(enemy, 999999)
                        task.wait(0.1)
                    end
                end)
            end
        end)
    end,
})

local VisualTab = Window:CreateTab("🔮 Visuals", 4483362458)
VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "Enemy ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(val)
        State.ESP = val
        if val then
            task.spawn(function()
                while State.ESP do
                    task.wait(2)
                    ClearESP()
                    for _, enemy in pairs(GetAllEnemies()) do CreateESP(enemy) end
                end
            end)
        else
            ClearESP()
        end
    end,
})

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(val)
        pcall(function()
            local lighting = game:GetService("Lighting")
            if val then
                lighting.Brightness = 10
                lighting.GlobalShadows = false
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
            else
                lighting.Brightness = 1
                lighting.GlobalShadows = true
                lighting.Ambient = Color3.fromRGB(127, 127, 127)
            end
        end)
    end,
})

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(val)
        if val then
            local vu = game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end,
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
    end,
})

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    if State.SpeedHack then Humanoid.WalkSpeed = State.SpeedValue end
end)

task.wait(1)
Rayfield:Notify({
    Title = "👻 Anime Ghosts Hub Loaded!",
    Content = "All features ready! Enable Kill Aura + Auto Farm for best results.",
    Duration = 5,
    Image = 4483362458,
})
