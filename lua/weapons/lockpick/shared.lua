

SWEP = SWEP or {}
SWEP.Primary = SWEP.Primary or {}
SWEP.Secondary = SWEP.Secondary or {}

lololo = lololo or {}
lololo.config = lololo.config or {}
lololo.doors = lololo.doors or {}


if SERVER then
    AddCSLuaFile('shared.lua')
    resource.AddFile('sound/lockpick/broken.wav')
    resource.AddFile('sound/lockpick/success.wav')
    resource.AddFile('sound/lockpick/pin.wav')

    sound.Add({name = 'lololo.broken', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/broken.wav'})
    sound.Add({name = 'lololo.success', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/success.wav'})
    sound.Add({name = 'lololo.pin', channel = CHAN_AUTO, volume = 1, level = 80, sound = 'lockpick/pin.wav'})

    --util.AddNetworkString('lololo.ply.freeze')
    util.AddNetworkString('lololo.funcs.reload')
    util.AddNetworkString('lololo.funcs.gameStatus')
    util.AddNetworkString('lololo.funcs.gameStart')
    util.AddNetworkString('lololo.emitSound')
    util.AddNetworkString('lololo.sync.speed')
    util.AddNetworkString('lololo.funcs.setPinCount')


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
        if not ply:GetEyeTrace().Entity:isDoor() or not ply:GetActiveWeapon().isInGame then return end

        local isSuccess = net.ReadBool()
        local weapon = ply:GetActiveWeapon()

        if IsValid(weapon) and weapon:GetClass() == 'lockpick' then
            ply:Freeze(false)
            weapon.isInGame = false
        end

        if isSuccess then
            local ent = weapon.lockpickedEnt
            if not IsValid(ent) then return end

            ent:keysUnLock()
        end

        weapon.NextStrike = CurTime() + lololo.config.nextHit
        weapon.lockpickedEnt = nil
    end)
end

if CLIENT then
    net.Receive('lololo.sync.speed', function(len, ply)
        local newSpeed = net.ReadInt(8)
        lololo.speed = newSpeed
    end)

    net.Receive('lololo.funcs.gameStart', function(len, ply)
        local pinCount = net.ReadInt(8)
        lololo.startGame(pinCount)
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
    self.lockpickedEnt = self.lockpickedEnt or nil

    if CLIENT then
        lololo.speed = lololo.speed or 1
    end
end



function SWEP:PrimaryAttack()
    if CurTime() < self.NextStrike then return end
    self.NextStrike = CurTime() + lololo.config.nextHit

    if SERVER then
        local ply = self.Owner
        if not IsValid(ply) then return end

        local targetEnt = ply:GetEyeTrace().Entity
        if not IsValid(targetEnt) then return end

        if ply:EyePos():Distance(targetEnt:GetPos()) > 90 or targetEnt:getKeysNonOwnable() then return end

        local value = lololo.doors[targetEnt:EntIndex()]
        local pinCount = value or lololo.config.defaultPinCount

        self.isInGame = true
        self.lockpickedEnt = targetEnt
        ply:Freeze(true)

        net.Start('lololo.funcs.gameStart')
            net.WriteInt(pinCount, 8)
        net.Send(ply)
    end
end



function SWEP:SecondaryAttack()
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
        lololo.isGameFinishSuccess(false)
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
        lololo.isGameFinishSuccess(false)
    end

    return true
end



----------------------------------------------------------------------



if CLIENT then
    local ply = LocalPlayer()

    function lololo.isGameFinishSuccess(isSuccess)
        hook.Remove('HUDPaint', 'lololo.draw.menu')
        hook.Remove('HUDPaint', 'lololo.draw.pins')
        hook.Remove('CreateMove', 'lololo.catch')

        net.Start('lololo.funcs.gameStatus')
            net.WriteBool(isSuccess)
        net.SendToServer()
    end



    function draw.RotatedBox(x, y, w, h, ang, color)
        draw.NoTexture()
        surface.SetDrawColor(color)
        surface.DrawTexturedRectRotated(x, y, w, h, ang)
    end



    function lololo.startGame(pinCount)
        local angle = 0
        local clockwise = true
        local lockAttack = false
        local deathZonePin = lololo.config.deathZonePin
        local forDelete = pinCount
        local lockpickCount = lololo.config.lockpickCount
        local isHit = false
        local attackAngle_min
        local attackAngle_max
        local indToRemove
        local pinAngle

        local centerX = ScrW() / 2
        local centerY = ScrH() / 2

        local interval = 15

        local function pinAnglesCreate()
            local pinAngles = {}
            local ang
            local isValid = false

            for i = 1, pinCount do
                while true do
                    ang = math.random(1, 360)
                    isValid = true
                    for _, v in ipairs(pinAngles) do
                        if math.abs(ang - v) <= interval then
                            isValid = false
                            break
                        end
                    end

                    if isValid then
                        pinAngles[#pinAngles + 1] = ang
                        break
                    end
                end
            end

            return pinAngles
        end

        local pinAngles = pinAnglesCreate()

        hook.Add('HUDPaint', 'lololo.draw.menu', function()
            draw.RoundedBox(0, 0, 0, 2000, 2000, Color(92, 154, 190, 240))

            draw.RoundedBox(360, ScrW()/2 - 150, ScrH()/2 - 150, 300, 300, Color(0, 161, 255, 255))
            draw.RoundedBox(360, ScrW()/2 - 125, ScrH()/2 - 125, 250, 250, Color(0, 90, 145, 255))
        
            local posX = centerX + math.cos(math.rad(-angle)) * 100
            local posY = centerY + math.sin(math.rad(-angle)) * 100

            draw.RotatedBox(posX, posY, 50, 12, angle, Color(34, 34, 34))

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
        end)


        hook.Add('HUDPaint', 'lololo.draw.pins', function()
            for i = 1, #pinAngles do
                pinAngle = pinAngles[i]
                local posX = centerX + math.cos(math.rad(-pinAngle)) * 100
                local posY = centerY + math.sin(math.rad(-pinAngle)) * 100
                draw.RotatedBox(posX, posY, 52, 8, pinAngle, Color(0, 205, 205))
            end

            draw.RoundedBox(360, ScrW()/2 - 90, ScrH()/2 - 90, 180, 180, Color(0, 161, 255, 255))
        end)



        hook.Add('CreateMove', 'lololo.catch', function(cmd)
            if cmd:KeyDown(IN_ATTACK) then 
                if not lockAttack then
                    clockwise = not clockwise

                    attackAngle_min = angle - deathZonePin
                    attackAngle_max = angle + deathZonePin

                    for k, v in ipairs(pinAngles) do
                        if v >= attackAngle_min and v <= attackAngle_max then
                            indToRemove = k
                            isHit = true

                            net.Start('lololo.emitSound')
                                net.WriteString('lololo.pin')
                            net.SendToServer()

                            break
                        end
                    end
                    
                    if isHit then
                        table.remove(pinAngles, indToRemove)
                        forDelete = forDelete - 1
                        indToRemove = -1

                    else
                        lockpickCount = lockpickCount - 1
                    end

                    if forDelete <= 0 then -- закончились пины
                        net.Start('lololo.emitSound')
                            net.WriteString('lololo.success')
                        net.SendToServer()
                        lololo.isGameFinishSuccess(true)
                    end

                    if lockpickCount <= 0 then -- закончились отмычки
                        net.Start('lololo.emitSound')
                            net.WriteString('lololo.broken')
                        net.SendToServer()
                        lololo.isGameFinishSuccess(false)
                    end

                    isHit = false
                    lockAttack = true
                end

            else
                lockAttack = false
            end

            if cmd:KeyDown(IN_ATTACK2) then
                lololo.isGameFinishSuccess(false)
            end
        end)
    end
end