if SERVER then
    AddCSLuaFile('shared.lua')
    resource.AddFile('sound/lockpick/broken.wav')
    resource.AddFile('sound/lockpick/success.wav')
    resource.AddFile('sound/lockpick/pin.wav')

    sound.Add({name = 'broken', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/broken.wav'})
    sound.Add({name = 'success', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/success.wav'})
    sound.Add({name = 'pin', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/pin.wav'})

end

if CLIENT then
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

end



function SWEP:PrimaryAttack()
    if CurTime() < self.NextStrike then return end
    self.NextStrike = CurTime() + 5

    
    if SERVER then
        util.AddNetworkString('ply.Freeze')
        local ply = self.Owner
        net.Start('lockpick.Funcs')
            net.WriteString('lockpick')
        net.Send(ply)
        
        ply:Freeze(true)

    end
end




local lever = false
function SWEP:Reload()
    if SERVER then
        local ply = self.Owner
        local key = 'speed'
       
        if lever == false then
            net.Start('lockpick.Funcs')
                net.WriteString(key)
            net.Send(ply)
            lever = true
        end

        hook.Add('Think', 'lockpick.PressReloadCheck', function()
            if ply:KeyReleased(IN_RELOAD) and lever == true then
                lever = false
                hook.Remove('Think', 'lockpick.PressReloadCheck')

            end
        end)

    end
end




----------------------------------------------------------------------



if SERVER then
    util.AddNetworkString('lockpick.Funcs')
    util.AddNetworkString('lockpick.Sound')

    hook.Add('PlayerSay', 'lockpick.Funcs', function(ply, txt)
        if string.sub(string.lower(txt), 1, 12) == '!setpincount' then
            local txt = string.reverse(txt)
            local txtInt = string.sub(txt, 1, 2)
            local txtInt = string.reverse(txtInt)

            if math.sqrt(txtInt) == 0 or math.abs(txtInt) > 15 or math.abs(txtInt) < 1 then
                ply:ChatPrint('Количество пинов должно быть в пределах от 1 до 15.')
                return ''

            else
                local txtInt = math.abs(txtInt)

                net.Start('lockpick.Funcs')
                    net.WriteString('pin')
                    net.WriteString(txtInt, 5)
                net.Send(ply)

                ply:ChatPrint(string.format('Количество пинов %s', txtInt))
                return ''
            end

        end
    end)


    net.Receive('lockpick.Sound', function()
        local ply = net.ReadEntity()
        local soundType = net.ReadString()    
        ply:EmitSound(soundType)

    end)


end





if CLIENT then
    local pinCount = 15 -- 15 пинов максимум, выше не ставить, иначе рекурсия!
    local speed = 1
    local ply = LocalPlayer()

    local function startAll()

        -- Переменные — подготовка
        local angle = 0
        local clockwise = true
        local lockAttack = false
        local attackLock = false
        local deathZonePin = 5
        local forDelete = pinCount
        local lockpickCount = 4
        local IsHit = false

        local centerX = ScrW() / 2
        local centerY = ScrH() / 2



        local function ClearAll()
            hook.Remove('HUDPaint', 'MenuCreateHook')
            hook.Remove('HUDPaint', 'pins.Draw')
            hook.Remove('CreateMove', 'clockwiseChange')

            net.Start('ply.Freeze')
                net.WriteEntity(LocalPlayer())
            net.SendToServer()

        end

        function draw.RotatedBox(x, y, w, h, ang, color)
            draw.NoTexture()
            surface.SetDrawColor(color)
            surface.DrawTexturedRectRotated(x, y, w, h, ang)
        end


        -- Функции

        local interval = 15

        local function pinAnglesCreate()
            local pinAngles = {}

            for i = 1, pinCount do
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

        local function MenuCreate()

            draw.RoundedBox(0, 0, 0, 2000, 2000, Color(92, 154, 190, 240))

            --

            draw.RoundedBox(360, ScrW()/2 - 150, ScrH()/2 - 150, 300, 300, Color(0, 161, 255, 255))
            draw.RoundedBox(360, ScrW()/2 - 125, ScrH()/2 - 125, 250, 250, Color(0, 90, 145, 255))

            --

            local posX = centerX + math.cos(math.rad(-angle)) * 100
            local posY = centerY + math.sin(math.rad(-angle)) * 100

            draw.RotatedBox(posX, posY, 50, 12, angle, Color(34, 34, 34))


            hook.Add('CreateMove', 'clockwiseChange', function(cmd)
                if cmd:KeyDown(IN_ATTACK) then
                    if not lockAttack then
                        clockwise = not clockwise 

                        local attackAngle_min = angle - deathZonePin
                        local attackAngle_max = angle + deathZonePin

                        for k, v in pairs(pinAngles) do
                            if v >= attackAngle_min and v <= attackAngle_max then
                                table.remove(pinAngles, k)
                                table.insert(pinAngles, k, nil)
                                forDelete = forDelete - 1
                                IsHit = true

                                net.Start('lockpick.Sound')
                                    net.WriteEntity(LocalPlayer())
                                    net.WriteString('pin')
                                net.SendToServer()
            
                            end
                        end

                        if not IsHit then
                            lockpickCount = lockpickCount - 1
                        end

                        if forDelete == 0 then
                            ClearAll()
                            net.Start('lockpick.Sound')
                                net.WriteEntity(LocalPlayer())
                                net.WriteString('success')
                            net.SendToServer()

                        end

                        if lockpickCount == 0 then
                            ClearAll()
                            net.Start('lockpick.Sound')
                                net.WriteEntity(LocalPlayer())
                                net.WriteString('broken')
                            net.SendToServer()

                        end

                        IsHit = false
                        lockAttack = true
                    end

                else
                    lockAttack = false 

                end

                if cmd:KeyDown(IN_ATTACK2) then
                    ClearAll()
                    
                end
            end)


            if clockwise then
                angle = angle - speed -- по часовой

            else
                angle = angle + speed -- против часовой

            end

            if angle >= 360 then
                angle = 0

            elseif angle <= 0 then
                angle = 360    
            
            end

            --

            draw.RoundedBox(360, ScrW()/2 - 90, ScrH()/2 - 90, 180, 180, Color(0, 161, 255, 255))

            --

            draw.SimpleText('ЛКМ — Подвигать пин', 'CreditsText', centerX + 220, centerY - 50, Color(74, 228, 255))
            draw.SimpleText('ПКМ — Закрыть меню', 'CreditsText', centerX + 220, centerY - 30, Color(74, 228, 255))
            draw.SimpleText(string.format('Будьте аккуратны, ваше количество отмычек: %s', lockpickCount), 'CreditsText', centerX + 220, centerY - 10, Color(74, 228, 255))

        end



        hook.Add('HUDPaint', 'pins.Draw', function()
            for i = 1, pinCount do
                local pinAngle = pinAngles[i]
                if pinAngle ~= nil then
                    local posX = centerX + math.cos(math.rad(-pinAngle)) * 100
                    local posY = centerY + math.sin(math.rad(-pinAngle)) * 100
                    draw.RotatedBox(posX, posY, 52, 8, pinAngle, Color(0, 205, 205))
                end
            end

            draw.RoundedBox(360, ScrW()/2 - 90, ScrH()/2 - 90, 180, 180, Color(0, 161, 255, 255))

        end)




        local function MenuCreateHook(speed) -- Замыкание
            hook.Add('HUDPaint', 'MenuCreateHook', MenuCreate) 
        end

        MenuCreateHook(speed)

    end





    net.Receive('lockpick.Funcs', function()
        local key = net.ReadString()
        local ply = LocalPlayer()

        if key == 'speed' then
            speed = speed + 1
            if speed > 3 then
                speed = 1
            end
            ply:ChatPrint(string.format('Установлена скорость %s', speed))


        elseif key == 'pin' then
            local pins = net.ReadString()
            pinCount = pins

        
        elseif key == 'lockpick' then
            hook.Remove('HUDPaint', 'MenuCreateHook')
            hook.Remove('HUDPaint', 'pins.Draw')
            hook.Remove('CreateMove', 'clockwiseChange')
            gui.EnableScreenClicker(false)

            startAll()
        end


    end)
end




if SERVER then
    net.Receive('ply.Freeze', function()
        local plyFreeze = net.ReadEntity()
        plyFreeze:Freeze(false)
    
    
    end)
end