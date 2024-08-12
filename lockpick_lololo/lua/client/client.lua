


local pinCount = 15 -- 15 пинов максимум, выше не ставить, иначе рекурсия!
local speed = 1


local function startAll()

    -- Переменные — подготовка
    local angle = 0
    local clockwise = true
    local lockAttack = false
    local attackLock = false
    local deathZonePin = 5
    local forDelete = pinCount
    local freeze = false
    local lockpickCount = 10
    local IsHit = false

    local centerX = ScrW() / 2
    local centerY = ScrH() / 2



    local function ClearAll()
        hook.Remove('HUDPaint', 'MenuCreateHook')
        hook.Remove('HUDPaint', 'pins.Draw')
        hook.Remove('CreateMove', 'clockwiseChange')

        freeze = true
        net.Start('plyFreeze')
            net.WriteEntity(LocalPlayer())
            net.WriteBool(freeze)
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
         
                        end
                    end

                    if not IsHit then
                        lockpickCount = lockpickCount - 1
                    end

                    if forDelete == 0 or lockpickCount == 0 then
                        ClearAll()
                        
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



    -- Хук

    local function MenuCreateHook(speed) -- Замыкание
        hook.Add('HUDPaint', 'MenuCreateHook', MenuCreate) 
    end


    -- Вызов функций

    MenuCreateHook(speed)

end




net.Receive('lockpick.Funcs', function()

    local key = net.ReadString()
    
    if key == 'lockpick' then
        hook.Remove('HUDPaint', 'MenuCreateHook')
        hook.Remove('HUDPaint', 'pins.Draw')
        gui.EnableScreenClicker(false)
        hook.Remove('CreateMove', 'clockwiseChange')

        startAll()

    elseif key == 'speed' then

        local speedInt = net.ReadString()
        speed = speedInt
        


    elseif key == 'pin' then

        local pins = net.ReadString()
        pinCount = pins
    
    end

end)



