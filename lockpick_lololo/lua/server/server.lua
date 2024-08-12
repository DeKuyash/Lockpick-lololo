


util.AddNetworkString('lockpick.Funcs')
util.AddNetworkString('plyFreeze')

hook.Add('PlayerSay', 'lockpick.Funcs', function(ply, txt)
   if string.lower(txt) == '!lockpick' then
        net.Start('lockpick.Funcs')
            net.WriteString('lockpick')
        net.Send(ply)

        ply:Freeze(true)

        return ''

    
    elseif string.sub(string.lower(txt), 1, 9) == '!setspeed' then
        local txt = string.reverse(txt)
        local txtInt = string.sub(txt, 1, 2)
        local txtInt = string.reverse(txtInt)
        if math.sqrt(txtInt) == 0 or math.abs(txtInt) > 3 or math.abs(txtInt) < 1 then
            ply:ChatPrint('Скорость должна быть в пределах от 1 до 3. (На деле уже на 2 сложно)')
            return ''

        else
            local txtInt = math.abs(txtInt)

            net.Start('lockpick.Funcs')
                net.WriteString('speed')
                net.WriteString(txtInt, 3)
            net.Send(ply)

            ply:ChatPrint(string.format('Установлена скорость %s', txtInt))
            return ''
        end

       
    elseif string.sub(string.lower(txt), 1, 12) == '!setpincount' then
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



net.Receive('plyFreeze', function()
    local ply = net.ReadEntity()
    local freeze = net.ReadBool()

    ply:Freeze(false)

end)