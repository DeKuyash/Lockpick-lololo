


if SERVER then 
    include('server/server.lua')
    AddCSLuaFile('client/client.lua')
end

if CLIENT then
    include('client/client.lua')
end