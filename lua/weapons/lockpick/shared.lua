

SWEP = SWEP or {}
SWEP.Primary = SWEP.Primary or {}
SWEP.Secondary = SWEP.Secondary or {}

if SERVER then
    AddCSLuaFile('shared.lua')
    resource.AddFile('sound/lockpick/broken.wav')
    resource.AddFile('sound/lockpick/success.wav')
    resource.AddFile('sound/lockpick/pin.wav')

    sound.Add({name = 'lololo.broken', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/broken.wav'})
    sound.Add({name = 'lololo.success', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/success.wav'})
    sound.Add({name = 'lololo.pin', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/pin.wav'})

    util.AddNetworkString('lololo.ply.freeze')
    util.AddNetworkString('lololo.funcs.reload')
    util.AddNetworkString('lololo.funcs.gameStatus')
    util.AddNetworkString('lololo.emitSound')
    util.AddNetworkString('lololo.sync.speed')


    net.Receive('lololo.funcs.reload', function(len, ply)
        if not IsValid(ply) then return end
        local weapon = ply:GetActiveWeapon()

        if IsValid(weapon) and weapon:GetClass() == 'lockpick' then
            weapon.isSpeedChange = false
        end
    end)

    net.Receive('lololo.emitSound', function(len, ply)
        if not IsValid(ply) then return end
        local soundType = net.ReadString()    

        ply:EmitSound(soundType)
    end)

    net.Receive('lololo.funcs.gameStatus', function(len, ply)
        if not IsValid(ply) then return end
        local weapon = ply:GetActiveWeapon()

        if IsValid(weapon) and weapon:GetClass() == 'lockpick' then
            ply:Freeze(false)
            weapon.isInGame = false
        end
    end)
end



if CLIENT then
    lololo = lololo or {}

    net.Receive('lololo.sync.speed', function(len, ply)
        local newSpeed = net.ReadInt(8)
        lololo.speed = newSpeed
    end)


    SWEP.PrintName = 'Отмычка'
    SWEP.Slot = 5
    SWEP.SlotPos = 5
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = false
end

SWEP.Instructions = 'ЛКМ - Начать взлом \nR - Настроить скорость'
SWEP.Author = 'Kuyash'

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip  = false

SWEP.Category = 'Портфолио'
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.NextStrike  = 0

SWEP.ViewModel = 'models/weapons/c_crowbar.mdl'
SWEP.WorldModel = 'models/weapons/w_crowbar.mdl'

SWEP.Primary.Delay = 0.01
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = 'none'

SWEP.Secondary.Delay = 0.01
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots = 1
SWEP.Secondary.Cone = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = 'none'



function SWEP:Initialize()
    self:SetHoldType('revolver')

    self.speed = self.speed or 1
    self.isSpeedChange = self.isSpeedChange or false
    self.isInGame = self.isInGame or false

    if CLIENT then
        lololo.speed = lololo.speed or 1
    end
end



function SWEP:PrimaryAttack() -- проверяй дверь ли, проверяй в списке замков и бери пинкаунт оттуда
    self.NextStrike = CurTime() + 1

    if SERVER then
        local ply = self.Owner
        if not IsValid(ply) then return end

        self.isInGame = true
        ply:Freeze(true)
        ply:SendLua('lololo.startGame()')
    end
end



function SWEP:Reload()
    if self.isInGame then return end

    if SERVER then
        local ply = self.Owner
       
        if not self.isSpeedChange then
            self.speed = self.speed + 1
            if self.speed > 3 then self.speed = 1 end
            self.isSpeedChange = true

            net.Start('lololo.sync.speed')
                net.WriteInt(self.speed, 8)
            net.Send(ply)

            ply:SendLua('LocalPlayer():ChatPrint("Прибавили скорость. Текущая скорость: " .. lololo.speed)')
        end
    end

    if CLIENT then
        local hookName = 'lololo.reload.buttonUnpress' .. self:EntIndex()

        hook.Add('KeyRelease', hookName, function(ply, key)
            if (key == IN_RELOAD) then
                net.Start('lololo.funcs.reload')
                net.SendToServer()
                hook.Remove('KeyRelease', hookName)
            end
        end)
    end
end



function SWEP:OnRemove()
    if SERVER then 
        local ply = self.Owner
        if not IsValid(ply) then return end

        ply:Freeze(false)
    end

    if CLIENT then
        hook.Remove('KeyRelease', 'lololo.reload.buttonUnpress' .. self:EntIndex())
        lololo.clearAll()
    end
end



function SWEP:Holster()
    if SERVER then 
        local ply = self.Owner
        if not IsValid(ply) then return end

        ply:Freeze(false)
    end

    if CLIENT then
        hook.Remove('KeyRelease', 'lololo.reload.buttonUnpress' .. self:EntIndex())
        lololo.clearAll()
    end

    return true
end



----------------------------------------------------------------------



if CLIENT then
    local ply = LocalPlayer()

    function lololo.clearAll()
        hook.Remove('HUDPaint', 'lololo.menuCreate.hook')
        hook.Remove('HUDPaint', 'lololo.pins.draw')
        hook.Remove('CreateMove', 'lololo.clockwiseChange')

        net.Start('lololo.funcs.gameStatus')
        net.SendToServer()
    end



    function draw.RotatedBox(x, y, w, h, ang, color)
        draw.NoTexture()
        surface.SetDrawColor(color)
        surface.DrawTexturedRectRotated(x, y, w, h, ang)
    end



    function lololo.startGame()
        local pinCount = 1 -- УДАЛИТЬ НАХУЙ

        local angle = 0
        local clockwise = true
        local lockAttack = false
        --local attackLock = false
        local deathZonePin = 5 -- СДЕЛАЙ ЧЕРЕЗ КФГ НАСТРОЙКУ ВСЕХ ЭТИХ ТИПОВ
        local forDelete = pinCount --!!!!!!!!!!!!!!
        local lockpickCount = 100 -- СДЕЛАЙ ЧЕРЕЗ КФГ НАСТРОЙКУ ВСЕХ ЭТИХ ТИПОВ
        local isHit = false

        local centerX = ScrW() / 2
        local centerY = ScrH() / 2

        local interval = 15 -- СДЕЛАЙ ЧЕРЕЗ КФГ НАСТРОЙКУ ВСЕХ ЭТИХ ТИПОВ

        local function pinAnglesCreate() -- ФАНТОМНЫЕ ПИНИ ИЛИ НЕ РЕГАЕТ!!!!
            local pinAngles = {}

            for i = 1, pinCount do --!!!!!!!!!!!!
                local ang
                while true do
                    ang = math.random(1, 360)
                    local isValid = true
                    for _, v in ipairs(pinAngles) do
                        if math.abs(ang - v) <= interval then
                            isValid = false
                            break
                        end
                    end
                    if isValid then
                        table.insert(pinAngles, ang)
                        break
                    end
                end
            end

            return pinAngles
        end

        local pinAngles = pinAnglesCreate()

        local function menuCreate()
            draw.RoundedBox(0, 0, 0, 2000, 2000, Color(92, 154, 190, 240))

            draw.RoundedBox(360, ScrW()/2 - 150, ScrH()/2 - 150, 300, 300, Color(0, 161, 255, 255))
            draw.RoundedBox(360, ScrW()/2 - 125, ScrH()/2 - 125, 250, 250, Color(0, 90, 145, 255))
        
            local posX = centerX + math.cos(math.rad(-angle)) * 100
            local posY = centerY + math.sin(math.rad(-angle)) * 100

            draw.RotatedBox(posX, posY, 50, 12, angle, Color(34, 34, 34))

            hook.Add('CreateMove', 'lololo.clockwiseChange', function(cmd)
                if cmd:KeyDown(IN_ATTACK) then
                    if not lockAttack then
                        clockwise = not clockwise 

                        local attackAngle_min = angle - deathZonePin
                        local attackAngle_max = angle + deathZonePin

                        for k, v in ipairs(pinAngles) do
                            if v >= attackAngle_min and v <= attackAngle_max then
                                table.remove(pinAngles, k)
                                table.insert(pinAngles, k, nil)
                                forDelete = forDelete - 1
                                isHit = true

                                net.Start('lololo.emitSound')
                                    net.WriteString('lololo.pin')
                                net.SendToServer()
                            end
                        end

                        if not isHit then
                            lockpickCount = lockpickCount - 1
                        end

                        if forDelete <= 0 then
                            lololo.clearAll()
                            net.Start('lololo.emitSound')
                                net.WriteString('lololo.success')
                            net.SendToServer()
                        end

                        if lockpickCount <= 0 then
                            lololo.clearAll()
                            net.Start('lololo.emitSound')
                                net.WriteString('lololo.broken')
                            net.SendToServer()
                        end

                        isHit = false
                        lockAttack = true
                    end

                else
                    lockAttack = false 
                end

                if cmd:KeyDown(IN_ATTACK2) then
                    lololo.clearAll()
                end
            end)


            if clockwise then 
                angle = angle - lololo.speed -- по часовой
            else 
                angle = angle + lololo.speed -- против часовой
            end 


            if angle >= 360 then
                angle = 0
            elseif angle <= 0 then
                angle = 360 
            end


            draw.RoundedBox(360, ScrW()/2 - 90, ScrH()/2 - 90, 180, 180, Color(0, 161, 255, 255))

            draw.SimpleText('ЛКМ — Подвигать пин', 'CreditsText', centerX + 220, centerY - 50, Color(74, 228, 255))
            draw.SimpleText('ПКМ — Закрыть меню', 'CreditsText', centerX + 220, centerY - 30, Color(74, 228, 255))
            draw.SimpleText(string.format('Будьте аккуратны, ваше количество отмычек: %s', lockpickCount), 'CreditsText', centerX + 220, centerY - 10, Color(74, 228, 255))
        end

        hook.Add('HUDPaint', 'lololo.pins.draw', function()
            for i = 1, pinCount do --!!!!!!!!!!!!!!!!!!!!!
                local pinAngle = pinAngles[i]
                if pinAngle ~= nil then
                    local posX = centerX + math.cos(math.rad(-pinAngle)) * 100
                    local posY = centerY + math.sin(math.rad(-pinAngle)) * 100
                    draw.RotatedBox(posX, posY, 52, 8, pinAngle, Color(0, 205, 205))
                end
            end

            draw.RoundedBox(360, ScrW()/2 - 90, ScrH()/2 - 90, 180, 180, Color(0, 161, 255, 255))
        end)

        local function MenuCreateHook(speed) -- замыкание (11.08.26 p.s типо легаси код, понятия не имею как и почему это работало еще год назад, работает не трогай)
            hook.Add('HUDPaint', 'lololo.menuCreate.hook', menuCreate) 
        end

        MenuCreateHook(lololo.speed)
    end
end




-- if SERVER then
--     net.Receive('lockpick.ply.Freeze', function()
--         local plyFreeze = net.ReadEntity()
--         plyFreeze:Freeze(false)
    
--     end)
-- end


-- local function clearAll()
--     hook.Remove('HUDPaint', 'MenuCreateHook')
--     hook.Remove('HUDPaint', 'pins.Draw')
--     hook.Remove('CreateMove', 'clockwiseChange')

--     net.Start('lockpick.ply.Freeze')
--         net.WriteEntity(LocalPlayer())
--     net.SendToServer()
-- end

----------------------------------------------------------------------


-- if SERVER then
--     hook.Add('PlayerSay', 'lockpick.Funcs', function(ply, txt)
--         if string.sub(string.lower(txt), 1, 12) == '!setpincount' then
--             local txt = string.reverse(txt)
--             local txtInt = string.sub(txt, 1, 2)
--             local txtInt = string.reverse(txtInt)

--             if math.sqrt(txtInt) == 0 or math.abs(txtInt) > 15 or math.abs(txtInt) < 1 then
--                 ply:ChatPrint('Количество пинов должно быть в пределах от 1 до 15.')
--                 return ''

--             else
--                 local txtInt = math.abs(txtInt)

--                 net.Start('lockpick.Funcs')
--                     net.WriteString('pin')
--                     net.WriteString(txtInt, 5)
--                 net.Send(ply)

--                 ply:ChatPrint(string.format('Количество пинов %s', txtInt))
--                 return ''
--             end

--         end
--     end)


-- end