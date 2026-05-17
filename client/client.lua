--[[
╔══════════════════════════════════════════════════════════════════╗
║    RDE FARMING SYSTEM — CLIENT v1.0.0                            ║
║  ✅ Proximity-based entity loading (LoadRadius / UnloadRadius)    ║
║  ✅ StateBag change handlers                                      ║
║  ✅ ox_target per-spot interact zones                             ║
║  ✅ Full animation system with tool hand prop                     ║
║  ✅ Admin CRUD menu (oxlib context + inputDialog)                 ║
║  ✅ Map blips per area                                            ║
║  ✅ Ground-Z snapping for spawned spots                           ║
║  ✅ Depleted visual state (alpha + outline)                       ║
╚══════════════════════════════════════════════════════════════════╝
]]

local Config = require 'config'

-- ============================================
-- 📦 STATE
-- ============================================

local Player = {
    identifier = nil,
    isAdmin    = false,
    source     = nil,
}

local Areas  = {}    -- [areaId]  = areaData
local Spots  = {}    -- [spotId]  = spotData
local Entities = {}  -- [spotId]  = { entity, zone, blip? }
local Loaded   = {}  -- [spotId]  = true  (currently rendered)

local IsHarvesting = false  -- animation lock

-- ============================================
-- 🔧 UTILITY
-- ============================================

local function Log(msg, level)
    if not Config.Debug and level ~= 'ERROR' then return end
    local prefix = level == 'ERROR' and '^1' or level == 'WARN' and '^3' or '^2'
    print(('%s[RDE Farming]^7 %s'):format(prefix, msg))
end

local function T(key, ...)
    if not Lang or not Lang[key] then return key end
    if select('#', ...) > 0 then
        return string.format(Lang[key], ...)
    end
    return Lang[key]
end

local function LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelValid(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasModelLoaded(hash)
end

local function GetGroundZ(x, y, z)
    local found, gz = GetGroundZFor_3dCoord(x, y, z + 5.0, true)
    if found then return gz end
    return z
end

-- ============================================
-- 🎯 HARVEST ANIMATION + TOOL PROP
-- ============================================

local function StopHarvestAnimation(ped, anim)
    if anim then
        StopAnimTask(ped, anim.dict, anim.anim, 4.0)
    end
    ClearPedTasks(ped)
    lib.hideTextUI()
end

local function PlayHarvestAnimation(area, onComplete)
    if IsHarvesting then return end
    IsHarvesting = true

    local ped     = PlayerPedId()
    local animDef = area.animKey and Animations and Animations[area.animKey]

    if not animDef then
        -- No animation: just wait the default duration
        lib.showTextUI(T('harvest_start'), { position = 'bottom-center', icon = 'leaf' })
        Wait(Config.AnimationDuration)
        lib.hideTextUI()
        IsHarvesting = false
        if onComplete then onComplete() end
        return
    end

    -- Stream animation dictionary
    if not HasAnimDictLoaded(animDef.dict) then
        RequestAnimDict(animDef.dict)
        local timeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(animDef.dict) and GetGameTimer() < timeout do
            Wait(10)
        end
    end

    -- Determine which tool prop to show:
    -- 1) Per-area override (toolProp), 2) Animation default, 3) None
    local toolPropModel = area.toolProp or (animDef.toolProp)
    local toolPropEnt   = nil

    if toolPropModel and toolPropModel ~= '' then
        if LoadModel(toolPropModel) then
            toolPropEnt = CreateObject(joaat(toolPropModel), 0, 0, 0, false, false, false)
            if DoesEntityExist(toolPropEnt) then
                local boneIdx  = animDef.boneIndex or 28422
                local offset   = animDef.propOffset or { x = 0.0, y = 0.0, z = 0.0 }
                local rot      = animDef.propRot    or { x = 0.0, y = 0.0, z = 0.0 }
                AttachEntityToEntity(
                    toolPropEnt, ped,
                    GetPedBoneIndex(ped, boneIdx),
                    offset.x, offset.y, offset.z,
                    rot.x, rot.y, rot.z,
                    true, true, false, true, 1, true
                )
            else
                toolPropEnt = nil
            end
        end
    end

    -- Play animation
    TaskPlayAnim(ped, animDef.dict, animDef.anim, 8.0, 8.0, -1, animDef.flag or 1, 0, false, false, false)

    local duration = animDef.duration or Config.AnimationDuration

    -- Progress bar during animation
    lib.showTextUI(T('harvest_start'), {
        position  = 'bottom-center',
        icon      = 'leaf',
        style = {
            borderRadius    = '12px',
            backgroundColor = 'rgba(17,24,39,0.95)',
            color           = 'white',
            padding         = '14px 22px',
            border          = '2px solid rgba(34,197,94,0.4)',
        }
    })

    Wait(duration)

    -- Cleanup
    StopHarvestAnimation(ped, animDef)

    if toolPropEnt and DoesEntityExist(toolPropEnt) then
        DetachEntity(toolPropEnt, true, true)
        DeleteObject(toolPropEnt)
    end

    IsHarvesting = false
    if onComplete then onComplete() end
end

-- ============================================
-- 🏗️ SPOT ENTITY MANAGEMENT
-- ============================================

local function CreateSpotEntity(spotId)
    local spot = Spots[spotId]
    if not spot then return end
    local area = Areas[spot.areaId]
    if not area then return end

    if Entities[spotId] then return end  -- already loaded

    local px, py, pz = spot.position.x, spot.position.y, spot.position.z

    -- Ground snap
    local gz = GetGroundZ(px, py, pz)
    if gz then pz = gz end

    if not LoadModel(area.propModel) then
        Log(('Model load failed: %s'):format(area.propModel), 'ERROR')
        return
    end

    local entity = CreateObject(joaat(area.propModel), px, py, pz, false, false, false)
    if not DoesEntityExist(entity) then return end

    SetEntityRotation(entity, 0.0, 0.0, spot.rotZ or 0.0, 2, true)
    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, true)

    -- Visual: depleted = ghost alpha + outline
    if spot.isDepleted then
        SetEntityAlpha(entity, Config.Colors.depletedAlpha, false)
        SetEntityDrawOutline(entity, true)
        SetEntityDrawOutlineColor(
            Config.Colors.adminOutline.r,
            Config.Colors.adminOutline.g,
            Config.Colors.adminOutline.b,
            255
        )
    end

    -- ox_target zone
    local zoneId = nil
    local min, max = GetModelDimensions(joaat(area.propModel))
    local size = vec3(
        math.max(0.5, (max.x - min.x) * Config.TargetSizeMultiplier),
        math.max(0.5, (max.y - min.y) * Config.TargetSizeMultiplier),
        math.max(0.5, (max.z - min.z) * Config.TargetSizeMultiplier)
    )

    local function BuildTargetOptions()
        if spot.isDepleted then
            return {{
                name     = 'farm_depleted_' .. spotId,
                icon     = 'hourglass-half',
                iconColor = '#f59e0b',
                label    = T('target_depleted'),
                onSelect = function()
                    lib.notify({ title = T('warning_title'), description = T('harvest_depleted'), type = 'warning' })
                end,
            }}
        end

        local label = area.toolItem and area.toolItem ~= ''
            and T('target_harvest_tool', area.toolItem)
            or  T('target_harvest')

        return {{
            name      = 'farm_harvest_' .. spotId,
            icon      = 'hand-scissors',
            iconColor = '#22c55e',
            label     = label,
            distance  = Config.TargetDistance,
            onSelect  = function()
                if IsHarvesting then return end

                local playerPos = GetEntityCoords(PlayerPedId())

                -- Play animation, then trigger server on complete
                PlayHarvestAnimation(area, function()
                    local pos = GetEntityCoords(PlayerPedId())
                    TriggerServerEvent('rde_farming:harvest', spotId, {
                        x = pos.x, y = pos.y, z = pos.z
                    })
                end)
            end,
        }}
    end

    local ok, id = pcall(function()
        return exports.ox_target:addBoxZone({
            coords   = vec3(px, py, pz),
            size     = size,
            rotation = spot.rotZ or 0.0,
            debug    = Config.Debug,
            options  = BuildTargetOptions(),
            distance = Config.TargetDistance,
        })
    end)
    if ok and id then zoneId = id end

    Entities[spotId] = {
        entity  = entity,
        zone    = zoneId,
        groundZ = gz,
    }
    Loaded[spotId] = true

    -- Update groundZ in position (patch for next sync cycle)
    spot.position.z = pz
    Spots[spotId] = spot

    Log(('Spot loaded: %s'):format(spotId), 'INFO')
end

local function RemoveSpotEntity(spotId)
    local e = Entities[spotId]
    if not e then return end

    if e.zone then
        pcall(function() exports.ox_target:removeZone(e.zone) end)
    end
    if e.entity and DoesEntityExist(e.entity) then
        DeleteEntity(e.entity)
    end

    Entities[spotId] = nil
    Loaded[spotId]   = nil
    Log(('Spot unloaded: %s'):format(spotId), 'INFO')
end

local function UpdateSpotVisual(spotId)
    -- Called when a spot changes depleted status.
    -- Cheapest approach: remove + re-create entity with new visual state.
    RemoveSpotEntity(spotId)
    Wait(50)
    CreateSpotEntity(spotId)
end

-- ============================================
-- 🗺️ BLIPS
-- ============================================

local AreaBlips = {}

local function CreateAreaBlip(areaId, area)
    if not Config.ShowBlips or not area.showBlip then return end
    if AreaBlips[areaId] then return end

    local blip = AddBlipForCoord(area.center.x, area.center.y, area.center.z)
    SetBlipSprite(blip, Config.Colors.areaBlip.sprite)
    SetBlipColour(blip, Config.Colors.areaBlip.color)
    SetBlipScale(blip, Config.Colors.areaBlip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(area.name or Config.BlipLabel)
    EndTextCommandSetBlipName(blip)

    AreaBlips[areaId] = blip
end

local function RemoveAreaBlip(areaId)
    if AreaBlips[areaId] then
        RemoveBlip(AreaBlips[areaId])
        AreaBlips[areaId] = nil
    end
end

-- ============================================
-- 🌍 PROXIMITY LOADING THREAD
-- ============================================

CreateThread(function()
    while true do
        Wait(Config.ProximityTick)

        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local load  = Config.LoadRadius
        local unload = Config.UnloadRadius

        -- Load nearby spots
        for spotId, spot in pairs(Spots) do
            if not Loaded[spotId] then
                local dx = pos.x - spot.position.x
                local dy = pos.y - spot.position.y
                local dz = pos.z - spot.position.z
                if math.sqrt(dx*dx + dy*dy + dz*dz) <= load then
                    CreateSpotEntity(spotId)
                end
            end
        end

        -- Unload far spots
        for spotId, _ in pairs(Loaded) do
            local spot = Spots[spotId]
            if spot then
                local dx = pos.x - spot.position.x
                local dy = pos.y - spot.position.y
                local dz = pos.z - spot.position.z
                if math.sqrt(dx*dx + dy*dy + dz*dz) > unload then
                    RemoveSpotEntity(spotId)
                end
            else
                RemoveSpotEntity(spotId)
            end
        end
    end
end)

-- ============================================
-- 📡 STATEBAG / NET EVENTS
-- ============================================

-- Area update (create or change)
RegisterNetEvent('rde_farming:areaUpdate', function(areaId, data)
    if data._deleted then
        Areas[areaId] = nil
        RemoveAreaBlip(areaId)
        return
    end
    Areas[areaId] = data
    RemoveAreaBlip(areaId)
    if data.isActive then
        CreateAreaBlip(areaId, data)
    end
end)

RegisterNetEvent('rde_farming:areaDelete', function(areaId)
    Areas[areaId] = nil
    RemoveAreaBlip(areaId)
end)

-- Spot update (state change: available / depleted / new)
RegisterNetEvent('rde_farming:spotUpdate', function(spotId, data)
    if data._deleted then
        RemoveSpotEntity(spotId)
        Spots[spotId] = nil
        return
    end

    local existed  = Spots[spotId]
    Spots[spotId]  = data

    if Loaded[spotId] then
        -- Only update visual if depleted status changed
        if not existed or existed.isDepleted ~= data.isDepleted then
            UpdateSpotVisual(spotId)
        end
    end
end)

RegisterNetEvent('rde_farming:spotDelete', function(spotId)
    RemoveSpotEntity(spotId)
    Spots[spotId] = nil
end)

-- Full initial load
RegisterNetEvent('rde_farming:loadAll', function(payload)
    Player.isAdmin = payload.isAdmin or false

    -- Areas
    for id, area in pairs(payload.areas or {}) do
        Areas[id] = area
        if area.isActive then
            CreateAreaBlip(id, area)
        end
    end

    -- Spots
    for id, spot in pairs(payload.spots or {}) do
        Spots[id] = spot
    end

    Log(('Loaded %d areas, %d spots'):format(
        table.count and table.count(payload.areas or {}) or 0,
        table.count and table.count(payload.spots or {}) or 0
    ), 'INFO')
end)

-- StateBag fallback (for late-join or restart scenarios)
AddStateBagChangeHandler(Config.StatebagPrefix, nil, function(bagName, key, value)
    if not value then return end

    if key:find('area_') then
        local areaId = key:gsub(Config.StatebagPrefix .. 'area_', '')
        if value._deleted then
            Areas[areaId] = nil
            RemoveAreaBlip(areaId)
        else
            Areas[areaId] = value
            RemoveAreaBlip(areaId)
            if value.isActive then CreateAreaBlip(areaId, value) end
        end

    elseif key:find('spot_') then
        local spotId = key:gsub(Config.StatebagPrefix .. 'spot_', '')
        if value._deleted then
            RemoveSpotEntity(spotId)
            Spots[spotId] = nil
        else
            local old = Spots[spotId]
            Spots[spotId] = value
            if Loaded[spotId] and old and old.isDepleted ~= value.isDepleted then
                UpdateSpotVisual(spotId)
            end
        end
    end
end)

-- ============================================
-- 🎛️ ADMIN CRUD MENU
-- ============================================

local function AdminConfirm(title, content, cb)
    local result = lib.alertDialog({
        header   = title,
        content  = content,
        centered = true,
        cancel   = true,
        labels   = { confirm = '✅ Yes', cancel = '❌ No' },
    })
    if result == 'confirm' and cb then cb() end
end

local function OpenAreaEditor(existingArea)
    -- Build animation key list for dropdown hint
    local animHint = 'Keys: '
    if AnimationKeys then
        animHint = animHint .. table.concat(AnimationKeys, ', ')
    end

    local fields = {
        { type = 'input',    label = T('input_area_name'),    required = true,  placeholder = T('input_area_name_ph'),   default = existingArea and existingArea.name },
        { type = 'input',    label = T('input_prop_model'),   required = true,  placeholder = T('input_prop_model_ph'),  description = T('input_prop_model_desc'), default = existingArea and existingArea.propModel },
        { type = 'input',    label = T('input_tool_item'),    required = false, placeholder = T('input_tool_item_ph'),   default = existingArea and existingArea.toolItem or '' },
        { type = 'input',    label = T('input_tool_prop'),    required = false, placeholder = T('input_tool_prop_ph'),   default = existingArea and existingArea.toolProp or '' },
        { type = 'input',    label = T('input_item_reward'),  required = true,  placeholder = T('input_item_reward_ph'), default = existingArea and existingArea.rewardItem },
        { type = 'number',   label = T('input_gather_min'),   required = true,  default = existingArea and existingArea.gatherMin or Config.DefaultGatherMin, min = 1,   max = 100 },
        { type = 'number',   label = T('input_gather_max'),   required = true,  default = existingArea and existingArea.gatherMax or Config.DefaultGatherMax, min = 1,   max = 100 },
        { type = 'number',   label = T('input_max_spots'),    required = true,  default = existingArea and existingArea.maxSpots or 5,   min = 1,   max = 50  },
        { type = 'number',   label = T('input_respawn_time'), required = true,  default = existingArea and existingArea.respawnTime or 300, min = 10, max = 86400 },
        { type = 'number',   label = T('input_spawn_radius'), required = true,  default = existingArea and existingArea.spawnRadius or 30, min = 5,  max = 500 },
        { type = 'input',    label = T('input_animation'),    required = false, placeholder = T('input_animation_ph'), description = animHint, default = existingArea and existingArea.animKey or '' },
        { type = 'checkbox', label = T('input_blip'),         checked  = existingArea == nil or existingArea.showBlip },
    }

    local result = lib.inputDialog(
        existingArea and ('✏️ Edit: ' .. existingArea.name) or '🌿 Create Farming Area',
        fields
    )

    if not result then return end

    -- Get player's current coords as area center (create) or keep existing (edit)
    local center
    if not existingArea then
        local ped = PlayerPedId()
        local c   = GetEntityCoords(ped)
        center = { x = c.x, y = c.y, z = c.z }
    else
        center = existingArea.center
    end

    local data = {
        name        = result[1],
        propModel   = result[2],
        toolItem    = result[3] or '',
        toolProp    = result[4] or '',
        rewardItem  = result[5],
        gatherMin   = result[6],
        gatherMax   = result[7],
        maxSpots    = result[8],
        respawnTime = result[9],
        spawnRadius = result[10],
        animKey     = result[11] or '',
        showBlip    = result[12],
        center      = center,
    }

    if existingArea then
        TriggerServerEvent('rde_farming:editArea', existingArea.id, data)
    else
        lib.notify({
            title       = T('info_title'),
            description = T('input_center_hint'),
            type        = 'inform',
            duration    = 4000,
        })
        TriggerServerEvent('rde_farming:createArea', data)
    end
end

local function OpenAreaList()
    TriggerServerEvent('rde_farming:requestAreas')
end

-- Admin receives area list
RegisterNetEvent('rde_farming:receiveAreas', function(areas)
    if not Player.isAdmin then return end

    local options = {}

    -- Sort areas by name
    local sorted = {}
    for id, area in pairs(areas) do
        sorted[#sorted + 1] = { id = id, area = area }
    end
    table.sort(sorted, function(a, b) return (a.area.name or '') < (b.area.name or '') end)

    if #sorted == 0 then
        lib.notify({ title = T('info_title'), description = T('menu_no_areas'), type = 'inform' })
        return
    end

    for _, entry in ipairs(sorted) do
        local id   = entry.id
        local area = entry.area
        local statusLabel = area.isActive and T('area_active') or T('area_inactive')
        local spotCount   = 0
        for _, spot in pairs(Spots) do
            if spot.areaId == id then spotCount = spotCount + 1 end
        end

        options[#options + 1] = {
            title       = area.name .. '  ' .. statusLabel,
            description = ('Prop: %s | Reward: %s | Spots: %d'):format(
                area.propModel, area.rewardItem, spotCount
            ),
            icon        = 'map-marker-alt',
            iconColor   = area.isActive and '#22c55e' or '#6b7280',
            arrow       = true,
            onSelect    = function()
                lib.registerContext({
                    id    = 'rde_farm_area_detail',
                    title = '📍 ' .. area.name,
                    menu  = 'rde_farm_list',
                    options = {
                        {
                            title       = '✏️ ' .. T('area_edit'),
                            description = 'Edit all settings for this area',
                            icon        = 'pen',
                            iconColor   = '#3b82f6',
                            onSelect    = function() OpenAreaEditor(area) end,
                        },
                        {
                            title       = '📍 ' .. T('area_set_center'),
                            description = 'Move the spawn center to your current position',
                            icon        = 'crosshairs',
                            iconColor   = '#f59e0b',
                            onSelect    = function()
                                local c = GetEntityCoords(PlayerPedId())
                                TriggerServerEvent('rde_farming:setAreaCenter', id, { x = c.x, y = c.y, z = c.z })
                            end,
                        },
                        {
                            title       = '🔁 Regenerate Spots',
                            description = 'Delete and respawn all spots for this area',
                            icon        = 'sync-alt',
                            iconColor   = '#8b5cf6',
                            onSelect    = function()
                                AdminConfirm('Regenerate Spots?', 'This deletes all existing spots and creates new ones.', function()
                                    TriggerServerEvent('rde_farming:regenSpots', id)
                                end)
                            end,
                        },
                        {
                            title       = (area.isActive and '⏸ Deactivate' or '▶️ Activate'),
                            description = T('area_toggle_active'),
                            icon        = area.isActive and 'pause' or 'play',
                            iconColor   = area.isActive and '#f59e0b' or '#22c55e',
                            onSelect    = function()
                                TriggerServerEvent('rde_farming:toggleArea', id)
                            end,
                        },
                        {
                            title       = '🗑️ ' .. T('area_delete'),
                            description = 'Permanently delete this area and all its spots',
                            icon        = 'trash-alt',
                            iconColor   = '#ef4444',
                            onSelect    = function()
                                AdminConfirm(
                                    'Delete Area?',
                                    ('Really delete "%s"? This cannot be undone.'):format(area.name),
                                    function()
                                        TriggerServerEvent('rde_farming:deleteArea', id)
                                    end
                                )
                            end,
                        },
                    },
                })
                lib.showContext('rde_farm_area_detail')
            end,
        }
    end

    lib.registerContext({
        id      = 'rde_farm_list',
        title   = '📋 Farming Areas (' .. #sorted .. ')',
        menu    = 'rde_farm_admin',
        options = options,
    })
    lib.showContext('rde_farm_list')
end)

local function OpenAdminMenu()
    if not Player.isAdmin then
        lib.notify({ title = T('error_title'), description = T('not_admin'), type = 'error' })
        return
    end

    lib.registerContext({
        id      = 'rde_farm_admin',
        title   = T('menu_title'),
        options = {
            {
                title       = '➕ ' .. T('menu_create_area'),
                description = T('menu_create_desc'),
                icon        = 'plus-circle',
                iconColor   = '#22c55e',
                onSelect    = function() OpenAreaEditor(nil) end,
            },
            {
                title       = '📋 ' .. T('menu_list_areas'),
                description = T('menu_list_desc'),
                icon        = 'list',
                iconColor   = '#3b82f6',
                onSelect    = function() OpenAreaList() end,
            },
            {
                title       = '📊 Statistics',
                description = 'Loaded areas, spots, entities',
                icon        = 'chart-bar',
                iconColor   = '#8b5cf6',
                onSelect    = function()
                    local areaCount, spotCount, loadedCount = 0, 0, 0
                    for _ in pairs(Areas)   do areaCount  = areaCount  + 1 end
                    for _ in pairs(Spots)   do spotCount  = spotCount  + 1 end
                    for _ in pairs(Loaded)  do loadedCount = loadedCount + 1 end
                    lib.notify({
                        title       = '📊 Farming Stats',
                        description = ('Areas: %d | Spots total: %d | Entities loaded: %d'):format(
                            areaCount, spotCount, loadedCount
                        ),
                        type     = 'info',
                        duration = 8000,
                    })
                end,
            },
        },
    })

    lib.showContext('rde_farm_admin')
end

-- ============================================
-- 🎮 COMMANDS
-- ============================================

RegisterCommand('farming',      function() OpenAdminMenu() end, false)
RegisterCommand('farmingadmin', function() OpenAdminMenu() end, false)

-- ============================================
-- 🚀 INITIALIZATION
-- ============================================

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(2000)
    TriggerServerEvent('rde_farming:init')
end)

print('^2[RDE | Farming]^7 Client v1.0.0 loaded ✅ proximity | animations | ox_target | admin CRUD')
