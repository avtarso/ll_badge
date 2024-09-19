lib.locale()

local config = lib.require('config')

local CURRENTLY_USING_BADGE = false

local playerJob = nil

RegisterNetEvent('sendPlayerJob')
AddEventHandler('sendPlayerJob', function(job)
    playerJob = job
    print("Player data received and stored:", playerJob)
end)

function requestPlayerJob()
    TriggerServerEvent('getPlayerJob')
end

local function ensureJobAndExecute(callback)
    if not playerJob then
        requestPlayerJob()
        Citizen.Wait(500)
    end
    if playerJob then
        callback()
    else
        badgeNotify("Failed to get player job", 'error', 3000)
    end
end

local function showBadge()
    ensureJobAndExecute(function()
        CURRENTLY_USING_BADGE = true
        local badge_data = lib.callback.await("ll_badge:retrieveInfo", false)

        SendNUIMessage({ type = "displayBadge", data = badge_data })

        local players = lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()), 3, false)
        if #players > 0 then
            local ply = {}
            for i = 1, #players do
                table.insert(ply, GetPlayerServerId(players[i].id))
            end
            TriggerServerEvent('ll_badge:showbadge', badge_data, ply)
        end

        lib.progressBar({
            duration = config.badge_show_time,
            label = locale('progress_label'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = "move_m@clipboard",
                clip = "idle"
            },
            prop = {
                bone = 60309,
                model = "prop_fib_badge",
                pos = vec3(-0.0400,0.0260,0.0030),
                rot = vec3(120.00,170.00,-13.000)
            },
        })

        CURRENTLY_USING_BADGE = false
    end)
end

function badgeNotify(msg, type, duration)
    if not duration then duration = 3000 end
    lib.notify({
        title = msg,
        type = type,
        duration = duration
    })
    return true
end

RegisterNetEvent('ll_badge:use', function()

    ensureJobAndExecute(function()

        local swimming = IsPedSwimmingUnderWater(cache.ped)
        local incar = IsPedInAnyVehicle(cache.ped, true)
        local job_auth = false
        
        for _, group in pairs (config.job_names) do    
            if group == playerJob then 
                job_auth = true
            end
        end

        if not job_auth then 
            badgeNotify("not_police", 'error', 3000)
            -- badgeNotify("playerJob   ---  " .. playerJob, 'error', 3000)
            return badgeNotify(locale('not_police'), 'error', 3000) 
        end

        if swimming or incar then 
            badgeNotify("swimming or incar", 'error', 3000)
            return badgeNotify(locale('not_now'), 'error', 3000) 
        end

        if CURRENTLY_USING_BADGE then return end

        showBadge()
    end)
end)

RegisterNetEvent('ll_badge:displaybadge')
AddEventHandler('ll_badge:displaybadge', function(data)
    SendNUIMessage({ type = "displayBadge", data = data })
end)

RegisterCommand(config.set_image_command, function()
    ensureJobAndExecute(function()
        for _, group in pairs (config.job_names) do    
            if group == playerJob then 
                job_auth = true
            end
        end

        if not job_auth then 
            print("not job_auth")
            badgeNotify(locale('not_police'), 'error', 3000) 
            return 
        end

        local input = lib.inputDialog(locale('input_title'), {locale('input_text')})
    
        if not input then
            print("not input")
            badgeNotify(locale('no_photo'), 'error', 3000) 
            return 
        end

        local setBadge = lib.callback.await("ll_badge:setBadgePhoto", false, input[1])
        if setBadge then
            lib.alertDialog({
                header = locale('department_name'),
                content = locale('update_badge_photo_success'),
                centered = true,
                cancel = false
            })
        else
            lib.alertDialog({
                header = locale('department_name'),
                content = locale('update_badge_photo_fail'),
                centered = true,
                cancel = false
            })
        end
    end)
end, false)
