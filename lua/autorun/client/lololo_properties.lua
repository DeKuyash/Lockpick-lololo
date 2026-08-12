

if SERVER then
    net.Receive('lololo.funcs.setPinCount', function(len, ply)
        if not ply:IsAdmin() then return end
        local pinCount = net.ReadInt(8)

        local ent = net.ReadEntity()
        if not IsValid(ent) then return end

        local min = lololo.config.minPinCount
        local max = lololo.config.maxPinCount 
        pinCount = math.Clamp(pinCount, min, max)

        lololo.doors[ent:EntIndex()] = pinCount
    end)
end



properties.Add("lololo_edit_pins", {
    MenuLabel = "Редактировать кол-во пинов",
    Order = 228,
    MenuIcon = "icon16/key_go.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or not IsValid(ply) then return false end
        if not ent:isDoor() then return false end

        return true
    end,

    Action = function()
    end,

    MenuOpen = function(self, option, ent, tr)
        local submenu = option:AddSubMenu()

        local slider = vgui.Create("DNumSlider", submenu)
        slider:SetText(" Кол-во пинов")
        slider:SetMin(lololo.config.minPinCount)
        slider:SetMax(lololo.config.maxPinCount) 
        slider:SetDefaultValue(lololo.config.defaultPinCount)
        slider:SetValue(lololo.config.defaultPinCount)
        slider:SetWide(300)
        slider:SetDecimals(0)

        local button = vgui.Create("DButton", submenu)
        button:SetText("Применить")
        button:Dock(BOTTOM)
        button:SetSize(0, 20)
        button.DoClick = function()
            local value = math.Round(slider:GetValue())

            if value == lololo.config.defaultPinCount then return end

            net.Start('lololo.funcs.setPinCount')
                net.WriteInt(value, 8)
                net.WriteEntity(ent)
            net.SendToServer()
        end
    end,

    Receive = function()
    end
})
