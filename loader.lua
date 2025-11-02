local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/adhandobrak0-spec/ADHAN-HUB/refs/heads/main/main.lua", true))()

local BannerImageID = "10723415766"
local LogoImageID = "10723415766"

local LocalPlayer = Players.LocalPlayer

local DevelopmentMode = false
local DevelopmentCode = "ADHAN"

local SavedSpawnPosition = nil

local MSDisplayEnabled = false
local MSBillboard = nil
local MSUpdateConnection = nil
local MSCharacterConnection = nil

local function CleanupMSDisplay()
    if MSBillboard then
        MSBillboard:Destroy()
        MSBillboard = nil
    end
    
    if MSUpdateConnection then
        MSUpdateConnection:Disconnect()
        MSUpdateConnection = nil
    end
end

local function CreateMSDisplay()
    CleanupMSDisplay()
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Head") then
        return
    end
    
    MSBillboard = Instance.new("BillboardGui")
    MSBillboard.Name = "MSDisplay"
    MSBillboard.Adornee = character.Head
    MSBillboard.Size = UDim2.new(0, 100, 0, 40)
    MSBillboard.StudsOffset = Vector3.new(0, 3, 0)
    MSBillboard.AlwaysOnTop = false
    MSBillboard.Parent = character.Head
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 0.3
    TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.Text = "0 ms"
    TextLabel.Parent = MSBillboard
    
    MSUpdateConnection = RunService.RenderStepped:Connect(function()
        if MSDisplayEnabled and MSBillboard and TextLabel then
            pcall(function()
                local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                TextLabel.Text = math.floor(ping) .. " ms"
                
                if ping < 50 then
                    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif ping < 100 then
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
            end)
        end
    end)
end

local NametagConnections = {}

local function CleanupNametag(player)
    if NametagConnections[player.UserId] then
        local data = NametagConnections[player.UserId]
        
        if data.billboard then
            data.billboard:Destroy()
        end
        
        if data.connections then
            for _, connection in ipairs(data.connections) do
                if connection and typeof(connection) == "RBXScriptConnection" then
                    connection:Disconnect()
                end
            end
        end
        
        NametagConnections[player.UserId] = nil
    end
end

local function CreateRGBNametag(player)
    if player.Name ~= "DH4N_COK" then
        return
    end
    
    CleanupNametag(player)
    
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProtectiveNameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 300, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = "ADHAN HUB"
    textLabel.TextStrokeTransparency = 0
    textLabel.Parent = billboard
    
    local connections = {}
    local isActive = true
    
    local rgbConnection = RunService.RenderStepped:Connect(function()
        if not isActive or not billboard or not billboard.Parent then
            return
        end
        
        local hue = tick() * 100 % 360
        textLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
    end)
    table.insert(connections, rgbConnection)
    
    local camera = workspace.CurrentCamera
    local visibilityConnection = RunService.RenderStepped:Connect(function()
        if not isActive or not billboard or not billboard.Parent or not camera then
            return
        end
        
        pcall(function()
            local distance = (camera.CFrame.Position - head.Position).Magnitude
            
            if distance < 50 then
                billboard.Enabled = true
            else
                billboard.Enabled = false
            end
        end)
    end)
    table.insert(connections, visibilityConnection)
    
    local diedConnection = character.Humanoid.Died:Connect(function()
        isActive = false
        CleanupNametag(player)
    end)
    table.insert(connections, diedConnection)
    
    NametagConnections[player.UserId] = {
        billboard = billboard,
        connections = connections,
        isActive = isActive
    }
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Name == "DH4N_COK" then
        if player.Character then
            CreateRGBNametag(player)
        end
        player.CharacterAdded:Connect(function()
            CreateRGBNametag(player)
        end)
        player.CharacterRemoving:Connect(function()
            CleanupNametag(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player.Name == "DH4N_COK" then
        player.CharacterAdded:Connect(function()
            CreateRGBNametag(player)
        end)
        player.CharacterRemoving:Connect(function()
            CleanupNametag(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    CleanupNametag(player)
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if not SavedSpawnPosition then
            SavedSpawnPosition = character.HumanoidRootPart.CFrame
        end
    end
end)

local function RejoinServer()
    pcall(function()
        if SavedSpawnPosition then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    RejoinServer()
end)

CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "RobloxPromptGui" then
        task.wait(0.5)
        RejoinServer()
    end
end)

local Window = WindUI:CreateWindow({
    Title = "ADHAN HUB",
    Icon = "rbxassetid://" .. LogoImageID,
    Author = "Development",
    Folder = "AdhanHub_Data",
    Size = UDim2.fromOffset(580, 460),
    KeySystem = false,
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

local AutoFarmTab = Window:Tab({
    Title = "Auto Farm",
    Icon = "rbxassetid://10747373176"
})

local AutoFarmSection = AutoFarmTab:Section({
    Title = "Auto Farm Features",
    Opened = true
})

local AutoFarmEnabled = false
local AutoFarmConnection = nil

AutoFarmSection:Toggle({
    Title = "Auto Farm (0ms)",
    Description = "Auto clicker tercepat untuk farming",
    Default = false,
    Callback = function(enabled)
        AutoFarmEnabled = enabled
        
        if enabled then
            AutoFarmConnection = RunService.RenderStepped:Connect(function()
                if AutoFarmEnabled then
                    pcall(function()
                        if mouse1press then
                            mouse1press()
                            mouse1release()
                        elseif mouse1click then
                            mouse1click()
                        else
                            local mousePos = UserInputService:GetMouseLocation()
                            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                        end
                    end)
                end
            end)
            
            Window:Notify({
                Title = "Auto Farm",
                Description = "✅ Auto Farm ON (0ms - ULTRA FAST)!",
                Duration = 3
            })
        else
            if AutoFarmConnection then
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
            
            Window:Notify({
                Title = "Auto Farm",
                Description = "❌ Auto Farm OFF!",
                Duration = 3
            })
        end
    end
})

local FishItTab = Window:Tab({
    Title = "FISH IT",
    Icon = "rbxassetid://10747373176"
})

local FishItSection = FishItTab:Section({
    Title = "Game Features",
    Opened = true
})

FishItSection:Button({
    Title = "Super Intan",
    Description = "🔒 LOCKED - Masukkan kode ADHAN di tab Development",
    Callback = function()
        if not DevelopmentMode then
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "🔒 LOCKED! Masukkan kode ADHAN di tab Development untuk unlock!",
                Duration = 5
            })
            return
        end
        
        Window:Notify({
            Title = "Super Intan",
            Description = "✅ Super Intan Activated!",
            Duration = 3
        })
    end
})

local SuperBlandEnabled = false
local SuperBlandConnection = nil
local superBlandDelay = 0
local superBlandInterval = 0.00001

FishItSection:Toggle({
    Title = "Super Bland (0.01ms)",
    Description = "🔒 LOCKED - Ultra fast clicker (lebih cepat dari Fast Clicker)",
    Default = false,
    Callback = function(enabled)
        if not DevelopmentMode then
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "🔒 LOCKED! Masukkan kode ADHAN di tab Development untuk unlock!",
                Duration = 5
            })
            return
        end
        
        SuperBlandEnabled = enabled
        
        if enabled then
            superBlandDelay = 0
            
            SuperBlandConnection = RunService.RenderStepped:Connect(function(deltaTime)
                if SuperBlandEnabled then
                    superBlandDelay = superBlandDelay + deltaTime
                    
                    if superBlandDelay >= superBlandInterval then
                        superBlandDelay = 0
                        
                        pcall(function()
                            if mouse1press then
                                mouse1press()
                                mouse1release()
                            elseif mouse1click then
                                mouse1click()
                            else
                                local mousePos = UserInputService:GetMouseLocation()
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                            end
                        end)
                    end
                end
            end)
            
            Window:Notify({
                Title = "Super Bland",
                Description = "✅ Super Bland ON (ULTRA FAST - 0.01ms)!",
                Duration = 3
            })
        else
            if SuperBlandConnection then
                SuperBlandConnection:Disconnect()
                SuperBlandConnection = nil
            end
            superBlandDelay = 0
            
            Window:Notify({
                Title = "Super Bland",
                Description = "❌ Super Bland OFF!",
                Duration = 3
            })
        end
    end
})

local FastAutoClickerEnabled = false
local AutoClickConnection = nil

FishItSection:Toggle({
    Title = "Fast Auto Clicker (0ms)",
    Description = "Support PC, Mobile & Tablet",
    Default = false,
    Callback = function(enabled)
        FastAutoClickerEnabled = enabled
        
        if enabled then
            local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
            local isTablet = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled
            
            AutoClickConnection = task.spawn(function()
                while FastAutoClickerEnabled do
                    pcall(function()
                        if mouse1press and mouse1release then
                            mouse1press()
                            task.wait()
                            mouse1release()
                        elseif mouse1click then
                            mouse1click()
                        else
                            local mousePos = UserInputService:GetMouseLocation()
                            if isMobile or isTablet then
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                                task.wait()
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                            else
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                task.wait()
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            end
                        end
                    end)
                    task.wait()
                end
            end)
            
            local deviceType = "PC"
            if isMobile then
                deviceType = "Mobile"
            elseif isTablet then
                deviceType = "Tablet"
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "✅ Fast Auto Clicker ON - " .. deviceType,
                Duration = 3
            })
        else
            if AutoClickConnection then
                task.cancel(AutoClickConnection)
                AutoClickConnection = nil
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "❌ Fast Auto Clicker OFF",
                Duration = 3
            })
        end
    end
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "rbxassetid://10734950309"
})

local PlayerSection = PlayerTab:Section({
    Title = "Movement",
    Opened = true
})

PlayerSection:Slider({
    Title = "WalkSpeed",
    Description = "Ubah kecepatan jalan",
    Default = 16,
    Min = 16,
    Max = 500,
    Callback = function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = value
        end
    end
})

PlayerSection:Slider({
    Title = "JumpPower",
    Description = "Ubah kekuatan lompat",
    Default = 50,
    Min = 50,
    Max = 500,
    Callback = function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = value
        end
    end
})

PlayerSection:Toggle({
    Title = "Fly",
    Description = "Mode terbang (WASD + Space/Shift)",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableFly(enabled, 50)
    end
})

PlayerSection:Toggle({
    Title = "Noclip",
    Description = "Tembus tembok",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableNoclip(enabled)
    end
})

PlayerSection:Toggle({
    Title = "Infinite Jump",
    Description = "Lompat tanpa batas",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableInfiniteJump(enabled)
    end
})

local VisualSection = PlayerTab:Section({
    Title = "Visual",
    Opened = true
})

VisualSection:Toggle({
    Title = "ESP",
    Description = "Lihat player lewat tembok",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableESP(enabled)
    end
})

VisualSection:Toggle({
    Title = "FullBright",
    Description = "Terang penuh tanpa bayangan",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableFullBright(enabled)
    end
})

VisualSection:Toggle({
    Title = "In-Game MS Display",
    Description = "Tampilkan ping di layar",
    Default = false,
    Callback = function(enabled)
        MSDisplayEnabled = enabled
        
        if enabled then
            CreateMSDisplay()
            
            if MSCharacterConnection then
                MSCharacterConnection:Disconnect()
            end
            
            MSCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
                if MSDisplayEnabled then
                    task.wait(0.5)
                    CreateMSDisplay()
                end
            end)
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "✅ MS Display ON!",
                Duration = 2
            })
        else
            CleanupMSDisplay()
            
            if MSCharacterConnection then
                MSCharacterConnection:Disconnect()
                MSCharacterConnection = nil
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "❌ MS Display OFF!",
                Duration = 2
            })
        end
    end
})

local SecurityTab = Window:Tab({
    Title = "Security",
    Icon = "rbxassetid://10747373176"
})

local AntiSection = SecurityTab:Section({
    Title = "Anti Features",
    Opened = true
})

local antiAFKEnabled = false
local antiAFKIdledConnection = nil
local antiAFKHeartbeatConnection = nil

AntiSection:Toggle({
    Title = "Anti AFK",
    Description = "Mencegah kick karena AFK",
    Default = false,
    Callback = function(enabled)
        antiAFKEnabled = enabled
        
        if enabled then
            local VirtualUser = game:GetService("VirtualUser")
            
            antiAFKIdledConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            
            antiAFKHeartbeatConnection = RunService.Heartbeat:Connect(function()
                if antiAFKEnabled then
                    VirtualUser:CaptureController()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti AFK ON!",
                Duration = 2
            })
        else
            if antiAFKIdledConnection then
                antiAFKIdledConnection:Disconnect()
                antiAFKIdledConnection = nil
            end
            
            if antiAFKHeartbeatConnection then
                antiAFKHeartbeatConnection:Disconnect()
                antiAFKHeartbeatConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti AFK OFF!",
                Duration = 2
            })
        end
    end
})

local antiBanEnabled = false
local antiBanConnection = nil

AntiSection:Toggle({
    Title = "Anti Ban/Kick",
    Description = "Auto rejoin jika di-kick/ban dari server",
    Default = false,
    Callback = function(enabled)
        antiBanEnabled = enabled
        
        if enabled then
            antiBanConnection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                if antiBanEnabled then
                    task.wait(0.5)
                    RejoinServer()
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Ban/Kick ON!",
                Duration = 2
            })
        else
            if antiBanConnection then
                antiBanConnection:Disconnect()
                antiBanConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Ban/Kick OFF!",
                Duration = 2
            })
        end
    end
})

local autoRejoinEnabled = false

AntiSection:Toggle({
    Title = "Auto Rejoin (Server Mati)",
    Description = "Otomatis join kembali & teleport ke spawn saat server mati",
    Default = false,
    Callback = function(enabled)
        autoRejoinEnabled = enabled
        
        if enabled then
            Window:Notify({
                Title = "Security",
                Description = "✅ Auto Rejoin ON! Akan otomatis join ulang jika server mati",
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Security",
                Description = "❌ Auto Rejoin OFF!",
                Duration = 2
            })
        end
    end
})

local antiStaffEnabled = false
local staffCheckConnection = nil

AntiSection:Toggle({
    Title = "Anti Admin/Dev/Staff",
    Description = "Auto hop server jika ada admin",
    Default = false,
    Callback = function(enabled)
        antiStaffEnabled = enabled
        
        if enabled then
            local staffKeywords = {"admin", "dev", "developer", "staff", "mod", "moderator", "owner", "creator"}
            
            local function checkAndHop(player)
                if antiStaffEnabled then
                    local playerName = player.Name:lower()
                    local playerDisplay = player.DisplayName:lower()
                    
                    for _, keyword in ipairs(staffKeywords) do
                        if string.find(playerName, keyword) or string.find(playerDisplay, keyword) then
                            Window:Notify({
                                Title = "Security Alert",
                                Description = "⚠️ STAFF DETECTED! Hopping server...",
                                Duration = 3
                            })
                            
                            task.wait(1)
                            
                            pcall(function()
                                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            end)
                            
                            return true
                        end
                    end
                end
                return false
            end
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if checkAndHop(player) then
                        break
                    end
                end
            end
            
            staffCheckConnection = Players.PlayerAdded:Connect(function(player)
                checkAndHop(player)
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Staff ON!",
                Duration = 2
            })
        else
            if staffCheckConnection then
                staffCheckConnection:Disconnect()
                staffCheckConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Staff OFF!",
                Duration = 2
            })
        end
    end
})

local antiTrollEnabled = false
local savedTrollPosition = nil
local antiTrollConnection = nil

AntiSection:Toggle({
    Title = "Anti Troll",
    Description = "Kembali ke posisi jika dipaksa bergerak",
    Default = false,
    Callback = function(enabled)
        antiTrollEnabled = enabled
        local character = LocalPlayer.Character
        
        if enabled and character and character:FindFirstChild("HumanoidRootPart") then
            savedTrollPosition = character.HumanoidRootPart.CFrame
            
            antiTrollConnection = RunService.Heartbeat:Connect(function()
                if antiTrollEnabled and character and character:FindFirstChild("HumanoidRootPart") and savedTrollPosition then
                    local currentPos = character.HumanoidRootPart.Position
                    local savedPos = savedTrollPosition.Position
                    local distance = (currentPos - savedPos).Magnitude
                    
                    if distance > 5 then
                        character.HumanoidRootPart.CFrame = savedTrollPosition
                    end
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Troll ON!",
                Duration = 2
            })
        else
            if antiTrollConnection then
                antiTrollConnection:Disconnect()
                antiTrollConnection = nil
            end
            savedTrollPosition = nil
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Troll OFF!",
                Duration = 2
            })
        end
    end
})

local DevelopmentTab = Window:Tab({
    Title = "Development",
    Icon = "rbxassetid://10747373176"
})

local DevLoginSection = DevelopmentTab:Section({
    Title = "Development Login",
    Opened = true
})

DevLoginSection:Input({
    Title = "Masukkan Kode Development",
    Description = "Kode: ADHAN",
    Placeholder = "Masukkan kode ADHAN...",
    Callback = function(value)
        if value == DevelopmentCode then
            DevelopmentMode = true
            Window:Notify({
                Title = "Development Panel",
                Description = "✅ Access Granted! Semua fitur unlocked!",
                Duration = 5
            })
        else
            Window:Notify({
                Title = "Development Panel",
                Description = "❌ Kode salah!",
                Duration = 3
            })
        end
    end
})

local DexSection = DevelopmentTab:Section({
    Title = "Developer Tools",
    Opened = true
})

DexSection:Button({
    Title = "Dex Explorer",
    Description = "🔒 LOCKED - Masukkan kode ADHAN",
    Callback = function()
        if not DevelopmentMode then
            Window:Notify({
                Title = "Dex Explorer",
                Description = "🔒 LOCKED!",
                Duration = 5
            })
            return
        end
        
        Window:Notify({
            Title = "Dex Explorer",
            Description = "Coming soon...",
            Duration = 5
        })
    end
})

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "rbxassetid://10747373176"
})

local CombatSection = CombatTab:Section({
    Title = "God Mode",
    Opened = true
})

CombatSection:Toggle({
    Title = "God Mode",
    Description = "HP unlimited",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableGodMode(enabled)
    end
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "rbxassetid://10734924532"
})

local MiscSection = MiscTab:Section({
    Title = "Utilities"
})

MiscSection:Button({
    Title = "Reset Character",
    Description = "Reset karakter Anda",
    Callback = function()
        WindUI.Fitur.ResetCharacter()
    end
})

local DiscordSection = MiscTab:Section({
    Title = "Community"
})

DiscordSection:Button({
    Title = "Join Discord",
    Description = "discord.gg/adhanhub",
    Callback = function()
        Window:Notify({
            Title = "ADHAN HUB",
            Description = "Discord: discord.gg/adhanhub",
            Duration = 5
        })
    end
})

Window:Notify({
    Title = "ADHAN HUB",
    Description = "✅ Loaded successfully!",
    Duration = 5
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/adhandobrak0-spec/ADHAN-HUB/refs/heads/main/main.lua", true))()

local BannerImageID = "10723415766"
local LogoImageID = "10723415766"

local LocalPlayer = Players.LocalPlayer

local DevelopmentMode = false
local DevelopmentCode = "ADHAN"

local SavedSpawnPosition = nil

local MSDisplayEnabled = false
local MSBillboard = nil
local MSUpdateConnection = nil
local MSCharacterConnection = nil

local function CleanupMSDisplay()
    if MSBillboard then
        MSBillboard:Destroy()
        MSBillboard = nil
    end
    
    if MSUpdateConnection then
        MSUpdateConnection:Disconnect()
        MSUpdateConnection = nil
    end
end

local function CreateMSDisplay()
    CleanupMSDisplay()
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Head") then
        return
    end
    
    MSBillboard = Instance.new("BillboardGui")
    MSBillboard.Name = "MSDisplay"
    MSBillboard.Adornee = character.Head
    MSBillboard.Size = UDim2.new(0, 100, 0, 40)
    MSBillboard.StudsOffset = Vector3.new(0, 3, 0)
    MSBillboard.AlwaysOnTop = false
    MSBillboard.Parent = character.Head
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 0.3
    TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.Text = "0 ms"
    TextLabel.Parent = MSBillboard
    
    MSUpdateConnection = RunService.RenderStepped:Connect(function()
        if MSDisplayEnabled and MSBillboard and TextLabel then
            pcall(function()
                local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                TextLabel.Text = math.floor(ping) .. " ms"
                
                if ping < 50 then
                    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif ping < 100 then
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
            end)
        end
    end)
end

local NametagConnections = {}

local function CleanupNametag(player)
    if NametagConnections[player.UserId] then
        local data = NametagConnections[player.UserId]
        
        if data.billboard then
            data.billboard:Destroy()
        end
        
        if data.connections then
            for _, connection in ipairs(data.connections) do
                if connection and typeof(connection) == "RBXScriptConnection" then
                    connection:Disconnect()
                end
            end
        end
        
        NametagConnections[player.UserId] = nil
    end
end

local function CreateRGBNametag(player)
    if player.Name ~= "DH4N_COK" then
        return
    end
    
    CleanupNametag(player)
    
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProtectiveNameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 300, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = "ADHAN HUB"
    textLabel.TextStrokeTransparency = 0
    textLabel.Parent = billboard
    
    local connections = {}
    local isActive = true
    
    local rgbConnection = RunService.RenderStepped:Connect(function()
        if not isActive or not billboard or not billboard.Parent then
            return
        end
        
        local hue = tick() * 100 % 360
        textLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
    end)
    table.insert(connections, rgbConnection)
    
    local camera = workspace.CurrentCamera
    local visibilityConnection = RunService.RenderStepped:Connect(function()
        if not isActive or not billboard or not billboard.Parent or not camera then
            return
        end
        
        pcall(function()
            local distance = (camera.CFrame.Position - head.Position).Magnitude
            
            if distance < 50 then
                billboard.Enabled = true
            else
                billboard.Enabled = false
            end
        end)
    end)
    table.insert(connections, visibilityConnection)
    
    local diedConnection = character.Humanoid.Died:Connect(function()
        isActive = false
        CleanupNametag(player)
    end)
    table.insert(connections, diedConnection)
    
    NametagConnections[player.UserId] = {
        billboard = billboard,
        connections = connections,
        isActive = isActive
    }
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Name == "DH4N_COK" then
        if player.Character then
            CreateRGBNametag(player)
        end
        player.CharacterAdded:Connect(function()
            CreateRGBNametag(player)
        end)
        player.CharacterRemoving:Connect(function()
            CleanupNametag(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player.Name == "DH4N_COK" then
        player.CharacterAdded:Connect(function()
            CreateRGBNametag(player)
        end)
        player.CharacterRemoving:Connect(function()
            CleanupNametag(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    CleanupNametag(player)
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if not SavedSpawnPosition then
            SavedSpawnPosition = character.HumanoidRootPart.CFrame
        end
    end
end)

local function RejoinServer()
    pcall(function()
        if SavedSpawnPosition then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    RejoinServer()
end)

CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "RobloxPromptGui" then
        task.wait(0.5)
        RejoinServer()
    end
end)

local Window = WindUI:CreateWindow({
    Title = "ADHAN HUB",
    Icon = "rbxassetid://" .. LogoImageID,
    Author = "Development",
    Folder = "AdhanHub_Data",
    Size = UDim2.fromOffset(580, 460),
    KeySystem = false,
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

local AutoFarmTab = Window:Tab({
    Title = "Auto Farm",
    Icon = "rbxassetid://10747373176"
})

local AutoFarmSection = AutoFarmTab:Section({
    Title = "Auto Farm Features",
    Opened = true
})

local AutoFarmEnabled = false
local AutoFarmConnection = nil

AutoFarmSection:Toggle({
    Title = "Auto Farm (0ms)",
    Description = "Auto clicker tercepat untuk farming",
    Default = false,
    Callback = function(enabled)
        AutoFarmEnabled = enabled
        
        if enabled then
            AutoFarmConnection = RunService.RenderStepped:Connect(function()
                if AutoFarmEnabled then
                    pcall(function()
                        if mouse1press then
                            mouse1press()
                            mouse1release()
                        elseif mouse1click then
                            mouse1click()
                        else
                            local mousePos = UserInputService:GetMouseLocation()
                            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                        end
                    end)
                end
            end)
            
            Window:Notify({
                Title = "Auto Farm",
                Description = "✅ Auto Farm ON (0ms - ULTRA FAST)!",
                Duration = 3
            })
        else
            if AutoFarmConnection then
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
            
            Window:Notify({
                Title = "Auto Farm",
                Description = "❌ Auto Farm OFF!",
                Duration = 3
            })
        end
    end
})

local FishItTab = Window:Tab({
    Title = "FISH IT",
    Icon = "rbxassetid://10747373176"
})

local FishItSection = FishItTab:Section({
    Title = "Game Features",
    Opened = true
})

FishItSection:Button({
    Title = "Super Intan",
    Description = "🔒 LOCKED - Masukkan kode ADHAN di tab Development",
    Callback = function()
        if not DevelopmentMode then
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "🔒 LOCKED! Masukkan kode ADHAN di tab Development untuk unlock!",
                Duration = 5
            })
            return
        end
        
        Window:Notify({
            Title = "Super Intan",
            Description = "✅ Super Intan Activated!",
            Duration = 3
        })
    end
})

local SuperBlandEnabled = false
local SuperBlandConnection = nil
local superBlandDelay = 0
local superBlandInterval = 0.00001

FishItSection:Toggle({
    Title = "Super Bland (0.01ms)",
    Description = "🔒 LOCKED - Ultra fast clicker (lebih cepat dari Fast Clicker)",
    Default = false,
    Callback = function(enabled)
        if not DevelopmentMode then
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "🔒 LOCKED! Masukkan kode ADHAN di tab Development untuk unlock!",
                Duration = 5
            })
            return
        end
        
        SuperBlandEnabled = enabled
        
        if enabled then
            superBlandDelay = 0
            
            SuperBlandConnection = RunService.RenderStepped:Connect(function(deltaTime)
                if SuperBlandEnabled then
                    superBlandDelay = superBlandDelay + deltaTime
                    
                    if superBlandDelay >= superBlandInterval then
                        superBlandDelay = 0
                        
                        pcall(function()
                            if mouse1press then
                                mouse1press()
                                mouse1release()
                            elseif mouse1click then
                                mouse1click()
                            else
                                local mousePos = UserInputService:GetMouseLocation()
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                            end
                        end)
                    end
                end
            end)
            
            Window:Notify({
                Title = "Super Bland",
                Description = "✅ Super Bland ON (ULTRA FAST - 0.01ms)!",
                Duration = 3
            })
        else
            if SuperBlandConnection then
                SuperBlandConnection:Disconnect()
                SuperBlandConnection = nil
            end
            superBlandDelay = 0
            
            Window:Notify({
                Title = "Super Bland",
                Description = "❌ Super Bland OFF!",
                Duration = 3
            })
        end
    end
})

local FastAutoClickerEnabled = false
local AutoClickConnection = nil

FishItSection:Toggle({
    Title = "Fast Auto Clicker (0ms)",
    Description = "Support PC, Mobile & Tablet",
    Default = false,
    Callback = function(enabled)
        FastAutoClickerEnabled = enabled
        
        if enabled then
            local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
            local isTablet = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled
            
            AutoClickConnection = task.spawn(function()
                while FastAutoClickerEnabled do
                    pcall(function()
                        if mouse1press and mouse1release then
                            mouse1press()
                            task.wait()
                            mouse1release()
                        elseif mouse1click then
                            mouse1click()
                        else
                            local mousePos = UserInputService:GetMouseLocation()
                            if isMobile or isTablet then
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                                task.wait()
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                            else
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                task.wait()
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            end
                        end
                    end)
                    task.wait()
                end
            end)
            
            local deviceType = "PC"
            if isMobile then
                deviceType = "Mobile"
            elseif isTablet then
                deviceType = "Tablet"
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "✅ Fast Auto Clicker ON - " .. deviceType,
                Duration = 3
            })
        else
            if AutoClickConnection then
                task.cancel(AutoClickConnection)
                AutoClickConnection = nil
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "❌ Fast Auto Clicker OFF",
                Duration = 3
            })
        end
    end
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "rbxassetid://10734950309"
})

local PlayerSection = PlayerTab:Section({
    Title = "Movement",
    Opened = true
})

PlayerSection:Slider({
    Title = "WalkSpeed",
    Description = "Ubah kecepatan jalan",
    Default = 16,
    Min = 16,
    Max = 500,
    Callback = function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = value
        end
    end
})

PlayerSection:Slider({
    Title = "JumpPower",
    Description = "Ubah kekuatan lompat",
    Default = 50,
    Min = 50,
    Max = 500,
    Callback = function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = value
        end
    end
})

PlayerSection:Toggle({
    Title = "Fly",
    Description = "Mode terbang (WASD + Space/Shift)",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableFly(enabled, 50)
    end
})

PlayerSection:Toggle({
    Title = "Noclip",
    Description = "Tembus tembok",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableNoclip(enabled)
    end
})

PlayerSection:Toggle({
    Title = "Infinite Jump",
    Description = "Lompat tanpa batas",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableInfiniteJump(enabled)
    end
})

local VisualSection = PlayerTab:Section({
    Title = "Visual",
    Opened = true
})

VisualSection:Toggle({
    Title = "ESP",
    Description = "Lihat player lewat tembok",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableESP(enabled)
    end
})

VisualSection:Toggle({
    Title = "FullBright",
    Description = "Terang penuh tanpa bayangan",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableFullBright(enabled)
    end
})

VisualSection:Toggle({
    Title = "In-Game MS Display",
    Description = "Tampilkan ping di layar",
    Default = false,
    Callback = function(enabled)
        MSDisplayEnabled = enabled
        
        if enabled then
            CreateMSDisplay()
            
            if MSCharacterConnection then
                MSCharacterConnection:Disconnect()
            end
            
            MSCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
                if MSDisplayEnabled then
                    task.wait(0.5)
                    CreateMSDisplay()
                end
            end)
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "✅ MS Display ON!",
                Duration = 2
            })
        else
            CleanupMSDisplay()
            
            if MSCharacterConnection then
                MSCharacterConnection:Disconnect()
                MSCharacterConnection = nil
            end
            
            Window:Notify({
                Title = "ADHAN HUB",
                Description = "❌ MS Display OFF!",
                Duration = 2
            })
        end
    end
})

local SecurityTab = Window:Tab({
    Title = "Security",
    Icon = "rbxassetid://10747373176"
})

local AntiSection = SecurityTab:Section({
    Title = "Anti Features",
    Opened = true
})

local antiAFKEnabled = false
local antiAFKIdledConnection = nil
local antiAFKHeartbeatConnection = nil

AntiSection:Toggle({
    Title = "Anti AFK",
    Description = "Mencegah kick karena AFK",
    Default = false,
    Callback = function(enabled)
        antiAFKEnabled = enabled
        
        if enabled then
            local VirtualUser = game:GetService("VirtualUser")
            
            antiAFKIdledConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            
            antiAFKHeartbeatConnection = RunService.Heartbeat:Connect(function()
                if antiAFKEnabled then
                    VirtualUser:CaptureController()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti AFK ON!",
                Duration = 2
            })
        else
            if antiAFKIdledConnection then
                antiAFKIdledConnection:Disconnect()
                antiAFKIdledConnection = nil
            end
            
            if antiAFKHeartbeatConnection then
                antiAFKHeartbeatConnection:Disconnect()
                antiAFKHeartbeatConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti AFK OFF!",
                Duration = 2
            })
        end
    end
})

local antiBanEnabled = false
local antiBanConnection = nil

AntiSection:Toggle({
    Title = "Anti Ban/Kick",
    Description = "Auto rejoin jika di-kick/ban dari server",
    Default = false,
    Callback = function(enabled)
        antiBanEnabled = enabled
        
        if enabled then
            antiBanConnection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                if antiBanEnabled then
                    task.wait(0.5)
                    RejoinServer()
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Ban/Kick ON!",
                Duration = 2
            })
        else
            if antiBanConnection then
                antiBanConnection:Disconnect()
                antiBanConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Ban/Kick OFF!",
                Duration = 2
            })
        end
    end
})

local autoRejoinEnabled = false

AntiSection:Toggle({
    Title = "Auto Rejoin (Server Mati)",
    Description = "Otomatis join kembali & teleport ke spawn saat server mati",
    Default = false,
    Callback = function(enabled)
        autoRejoinEnabled = enabled
        
        if enabled then
            Window:Notify({
                Title = "Security",
                Description = "✅ Auto Rejoin ON! Akan otomatis join ulang jika server mati",
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Security",
                Description = "❌ Auto Rejoin OFF!",
                Duration = 2
            })
        end
    end
})

local antiStaffEnabled = false
local staffCheckConnection = nil

AntiSection:Toggle({
    Title = "Anti Admin/Dev/Staff",
    Description = "Auto hop server jika ada admin",
    Default = false,
    Callback = function(enabled)
        antiStaffEnabled = enabled
        
        if enabled then
            local staffKeywords = {"admin", "dev", "developer", "staff", "mod", "moderator", "owner", "creator"}
            
            local function checkAndHop(player)
                if antiStaffEnabled then
                    local playerName = player.Name:lower()
                    local playerDisplay = player.DisplayName:lower()
                    
                    for _, keyword in ipairs(staffKeywords) do
                        if string.find(playerName, keyword) or string.find(playerDisplay, keyword) then
                            Window:Notify({
                                Title = "Security Alert",
                                Description = "⚠️ STAFF DETECTED! Hopping server...",
                                Duration = 3
                            })
                            
                            task.wait(1)
                            
                            pcall(function()
                                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            end)
                            
                            return true
                        end
                    end
                end
                return false
            end
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if checkAndHop(player) then
                        break
                    end
                end
            end
            
            staffCheckConnection = Players.PlayerAdded:Connect(function(player)
                checkAndHop(player)
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Staff ON!",
                Duration = 2
            })
        else
            if staffCheckConnection then
                staffCheckConnection:Disconnect()
                staffCheckConnection = nil
            end
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Staff OFF!",
                Duration = 2
            })
        end
    end
})

local antiTrollEnabled = false
local savedTrollPosition = nil
local antiTrollConnection = nil

AntiSection:Toggle({
    Title = "Anti Troll",
    Description = "Kembali ke posisi jika dipaksa bergerak",
    Default = false,
    Callback = function(enabled)
        antiTrollEnabled = enabled
        local character = LocalPlayer.Character
        
        if enabled and character and character:FindFirstChild("HumanoidRootPart") then
            savedTrollPosition = character.HumanoidRootPart.CFrame
            
            antiTrollConnection = RunService.Heartbeat:Connect(function()
                if antiTrollEnabled and character and character:FindFirstChild("HumanoidRootPart") and savedTrollPosition then
                    local currentPos = character.HumanoidRootPart.Position
                    local savedPos = savedTrollPosition.Position
                    local distance = (currentPos - savedPos).Magnitude
                    
                    if distance > 5 then
                        character.HumanoidRootPart.CFrame = savedTrollPosition
                    end
                end
            end)
            
            Window:Notify({
                Title = "Security",
                Description = "✅ Anti Troll ON!",
                Duration = 2
            })
        else
            if antiTrollConnection then
                antiTrollConnection:Disconnect()
                antiTrollConnection = nil
            end
            savedTrollPosition = nil
            
            Window:Notify({
                Title = "Security",
                Description = "❌ Anti Troll OFF!",
                Duration = 2
            })
        end
    end
})

local DevelopmentTab = Window:Tab({
    Title = "Development",
    Icon = "rbxassetid://10747373176"
})

local DevLoginSection = DevelopmentTab:Section({
    Title = "Development Login",
    Opened = true
})

DevLoginSection:Input({
    Title = "Masukkan Kode Development",
    Description = "Kode: ADHAN",
    Placeholder = "Masukkan kode ADHAN...",
    Callback = function(value)
        if value == DevelopmentCode then
            DevelopmentMode = true
            Window:Notify({
                Title = "Development Panel",
                Description = "✅ Access Granted! Semua fitur unlocked!",
                Duration = 5
            })
        else
            Window:Notify({
                Title = "Development Panel",
                Description = "❌ Kode salah!",
                Duration = 3
            })
        end
    end
})

local DexSection = DevelopmentTab:Section({
    Title = "Developer Tools",
    Opened = true
})

DexSection:Button({
    Title = "Dex Explorer",
    Description = "🔒 LOCKED - Masukkan kode ADHAN",
    Callback = function()
        if not DevelopmentMode then
            Window:Notify({
                Title = "Dex Explorer",
                Description = "🔒 LOCKED!",
                Duration = 5
            })
            return
        end
        
        Window:Notify({
            Title = "Dex Explorer",
            Description = "Coming soon...",
            Duration = 5
        })
    end
})

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "rbxassetid://10747373176"
})

local CombatSection = CombatTab:Section({
    Title = "God Mode",
    Opened = true
})

CombatSection:Toggle({
    Title = "God Mode",
    Description = "HP unlimited",
    Default = false,
    Callback = function(enabled)
        WindUI.Fitur.EnableGodMode(enabled)
    end
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "rbxassetid://10734924532"
})

local MiscSection = MiscTab:Section({
    Title = "Utilities"
})

MiscSection:Button({
    Title = "Reset Character",
    Description = "Reset karakter Anda",
    Callback = function()
        WindUI.Fitur.ResetCharacter()
    end
})

local DiscordSection = MiscTab:Section({
    Title = "Community"
})

DiscordSection:Button({
    Title = "Join Discord",
    Description = "discord.gg/adhanhub",
    Callback = function()
        Window:Notify({
            Title = "ADHAN HUB",
            Description = "Discord: discord.gg/adhanhub",
            Duration = 5
        })
    end
})

Window:Notify({
    Title = "ADHAN HUB",
    Description = "✅ Loaded successfully!",
    Duration = 5
})
