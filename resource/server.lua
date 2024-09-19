QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.AddItem('ll_badge', {
    name = 'll_badge',
    label = 'LL Police Badge',
    weight = 250,
    type = 'item',
    image = 'll_badge.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A police badge.'
})

function RegisterUsableItem(item, cb)
    QBCore.Functions.CreateUseableItem(item, cb)
end

function GetPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

function GetIdentifier(source)
    local player = GetPlayer(source)
    return player.PlayerData.citizenid
end

function GetPlayerJobInfo(source)
    local player = GetPlayer(source)
    local job = player.PlayerData.job
    local jobInfo = {
        name = job.name,
        label = job.label,
        grade = job.grade,
        gradeName = job.grade.name,
    }
    return jobInfo
end

function GetName(source)
    local player = GetPlayer(source)
    return player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
end

RegisterNetEvent('getPlayerJob')
AddEventHandler('getPlayerJob', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local job = player.PlayerData.job.name
    TriggerClientEvent('sendPlayerJob', src, job)
end)

function badgeNotify(msg, type, duration)
    if not duration then duration = 3000 end
    lib2.notify({
        title = msg,
        type = type,
        duration = duration
    })
    return true
end

lib.locale()

local config = lib.require('config')

lib.callback.register("ll_badge:retrieveInfo", function(source)
    local badge_data = {}
    local identifier = GetIdentifier(source)
    local job = GetPlayerJobInfo(source)
    badge_data.rank = job.gradeName  or "Unknown" 
    badge_data.name = GetName(source)
    local table = MySQL.single.await('SELECT `image` FROM `ll_badge_photos` WHERE `identifier` = ? LIMIT 1', {
        identifier
    })
    badge_data.photo = table ~= nil and table.image or nil
    return badge_data
end)

lib.callback.register("ll_badge:setBadgePhoto", function(source, photo)
    local identifier = GetIdentifier(source)
    local image = MySQL.single.await('SELECT `image` FROM `ll_badge_photos` WHERE `identifier` = ? LIMIT 1', {
        identifier
    })

    local id 

    if not image then 

        id = MySQL.insert.await('INSERT INTO `ll_badge_photos` (identifier, image) VALUES (?, ?)', {
            identifier, photo
        })
    else 

        id = MySQL.update.await('UPDATE `ll_badge_photos` SET image = ? WHERE identifier = ?', {
            photo, identifier
        })
    end
    return id
end)

RegisterNetEvent('ll_badge:showbadge')
AddEventHandler('ll_badge:showbadge', function(data, ply)
    for i, player in pairs(ply) do
        TriggerClientEvent('ll_badge:displaybadge', player, data)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local tableExists, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM ll_badge_photos')

    if not tableExists then
        MySQL.query([[CREATE TABLE IF NOT EXISTS `ll_badge_photos` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `identifier` VARCHAR(50) NOT NULL,
        `image` longtext NOT NULL,
        PRIMARY KEY (`id`)
        )]])

        lib.print.info('[Last Legend Scripts] Deployed database table for ll_badge_photos')
    end

    RegisterUsableItem(config.badge_item_name, function(source)
        TriggerClientEvent('ll_badge:use', source)
    end)
end)


