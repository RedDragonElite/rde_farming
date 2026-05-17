--[[
╔══════════════════════════════════════════════════════════════════╗
║    RDE FARMING SYSTEM — SERVER v1.0.0                            ║
║  ✅ ox_core only (Ox.GetPlayer, stateId, hasPermission)          ║
║  ✅ oxmysql async                                                 ║
║  ✅ ox_inventory server-side item give                            ║
║  ✅ Full CRUD for Areas + Spots                                   ║
║  ✅ Spot respawn scheduler                                        ║
║  ✅ GlobalState StateBag sync                                     ║
║  ✅ Rate limiting, anti-spam, distance validation                 ║
╚══════════════════════════════════════════════════════════════════╝
]]

local Config = require 'config'

-- ============================================
-- 📦 STATE
-- ============================================

local State = {
    areas  = {},   -- [areaId] = areaData
    spots  = {},   -- [spotId] = spotData
    ready  = false,
}

-- Harvest cooldowns: [source][spotId] = timestamp
local HarvestCooldowns = {}
-- Respawn queue:     [spotId] = respawn_at_ms (server GetGameTimer)
local RespawnQueue     = {}

-- ============================================
-- 🔧 UTILITY
-- ============================================

local function Log(msg, level)
    if not Config.Debug and level ~= 'ERROR' then return end
    local prefix = level == 'ERROR' and '^1' or level == 'WARN' and '^3' or '^2'
    print(string.format('%s[RDE Farming SERVER]^7 %s', prefix, msg))
end

local function DbBool(v) return (v == true or v == 1) and 1 or 0 end
local function BoolDb(v) return v == 1 or v == '1' or v == true end

local function GenerateId(prefix)
    return string.format('%s_%x%x', prefix, os.time(), math.random(100000, 999999))
end

local function Notify(source, title, description, ntype)
    if not source or source <= 0 then return end
    TriggerClientEvent('ox_lib:notify', source, {
        title       = title,
        description = description,
        type        = ntype or 'inform',
    })
end

-- ============================================
-- 🔐 PERMISSION
-- ============================================

local function IsAdmin(source)
    if not source or source == 0 then return true end
    if Config.AllowAcePermissions then
        if IsPlayerAceAllowed(source, 'command') or IsPlayerAceAllowed(source, 'admin') then
            return true
        end
    end
    local player = Ox.GetPlayer(source)
    if not player then return false end
    if player.hasPermission and player.hasPermission('admin') then return true end
    if player.getGroups then
        local groups = player.getGroups()
        for name, _ in pairs(groups) do
            if Config.AdminGroups[name] then return true end
        end
    end
    return false
end

local function GetIdentifier(source)
    local player = Ox.GetPlayer(source)
    if not player then return nil end
    if player.stateId then return tostring(player.stateId) end
    if player.charId  then return tostring(player.charId)  end
    if player.userId  then return tostring(player.userId)  end
    for _, id in ipairs(GetPlayerIdentifiers(source) or {}) do
        if id:find('steam:') or id:find('license:') then return id end
    end
    return nil
end

-- ============================================
-- 📡 STATEBAG SYNC
-- ============================================

local function SyncArea(areaId, data)
    local key = Config.StatebagPrefix .. 'area_' .. areaId
    if data then
        GlobalState[key] = data
        TriggerClientEvent('rde_farming:areaUpdate', -1, areaId, data)
    else
        GlobalState[key] = { _deleted = true }
        TriggerClientEvent('rde_farming:areaDelete', -1, areaId)
        SetTimeout(2000, function() GlobalState[key] = nil end)
    end
end

local function SyncSpot(spotId, data)
    local key = Config.StatebagPrefix .. 'spot_' .. spotId
    if data then
        GlobalState[key] = data
        TriggerClientEvent('rde_farming:spotUpdate', -1, spotId, data)
    else
        GlobalState[key] = { _deleted = true }
        TriggerClientEvent('rde_farming:spotDelete', -1, spotId)
        SetTimeout(2000, function() GlobalState[key] = nil end)
    end
end

-- ============================================
-- 🗄️ DATABASE SETUP
-- ============================================

local function SetupDatabase(cb)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS rde_farming_areas (
            id            VARCHAR(64)   PRIMARY KEY,
            name          VARCHAR(128)  NOT NULL,
            center_x      FLOAT         NOT NULL,
            center_y      FLOAT         NOT NULL,
            center_z      FLOAT         NOT NULL,
            spawn_radius  FLOAT         NOT NULL  DEFAULT 30.0,
            prop_model    VARCHAR(128)  NOT NULL,
            tool_item     VARCHAR(64)   NULL,
            tool_prop     VARCHAR(128)  NULL,
            anim_key      VARCHAR(64)   NULL,
            reward_item   VARCHAR(64)   NOT NULL,
            gather_min    INT           NOT NULL  DEFAULT 1,
            gather_max    INT           NOT NULL  DEFAULT 3,
            max_spots     INT           NOT NULL  DEFAULT 5,
            respawn_time  INT           NOT NULL  DEFAULT 300,
            show_blip     TINYINT(1)    NOT NULL  DEFAULT 1,
            is_active     TINYINT(1)    NOT NULL  DEFAULT 1,
            created_by    VARCHAR(64)   NOT NULL,
            created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {}, function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS rde_farming_spots (
                id          VARCHAR(64)   PRIMARY KEY,
                area_id     VARCHAR(64)   NOT NULL,
                pos_x       FLOAT         NOT NULL,
                pos_y       FLOAT         NOT NULL,
                pos_z       FLOAT         NOT NULL,
                rot_z       FLOAT         NOT NULL DEFAULT 0.0,
                is_depleted TINYINT(1)    NOT NULL DEFAULT 0,
                depleted_at BIGINT        NULL,
                INDEX idx_area   (area_id),
                INDEX idx_depleted (is_depleted),
                FOREIGN KEY (area_id) REFERENCES rde_farming_areas(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {}, function()
            Log('Database ready', 'INFO')
            if cb then cb() end
        end)
    end)
end

-- ============================================
-- 🌱 SPOT GENERATION
-- Places N spots randomly inside the area radius.
-- Called on area create and when spots are missing.
-- ============================================

local function GenerateSpots(area)
    local count   = area.maxSpots
    local radius  = area.spawnRadius
    local cx, cy, cz = area.center.x, area.center.y, area.center.z

    for i = 1, count do
        local angle = math.rad(math.random(0, 359))
        local dist  = math.sqrt(math.random()) * radius   -- uniform disc distribution
        local px    = cx + dist * math.cos(angle)
        local py    = cy + dist * math.sin(angle)
        local pz    = cz   -- client will groundz-snap on first render
        local rz    = Config.RandomRotateZ and math.random(0, 359) * 1.0 or 0.0

        local spotId = GenerateId('spot')
        local spotData = {
            id        = spotId,
            areaId    = area.id,
            position  = { x = px, y = py, z = pz },
            rotZ      = rz,
            isDepleted = false,
            depletedAt = nil,
        }

        MySQL.query(
            'INSERT INTO rde_farming_spots (id, area_id, pos_x, pos_y, pos_z, rot_z, is_depleted) VALUES (?, ?, ?, ?, ?, ?, 0)',
            { spotId, area.id, px, py, pz, rz },
            function(result)
                if result then
                    State.spots[spotId] = spotData
                    SyncSpot(spotId, spotData)
                    Log(('Spot generated: %s for area %s'):format(spotId, area.id), 'INFO')
                end
            end
        )
    end
end

-- ============================================
-- 📂 LOAD FROM DATABASE
-- ============================================

local function LoadAreas(cb)
    MySQL.query('SELECT * FROM rde_farming_areas WHERE is_active = 1', {}, function(rows)
        if not rows then
            if cb then cb() end
            return
        end
        for _, row in ipairs(rows) do
            local areaData = {
                id          = row.id,
                name        = row.name,
                center      = { x = row.center_x, y = row.center_y, z = row.center_z },
                spawnRadius = row.spawn_radius,
                propModel   = row.prop_model,
                toolItem    = row.tool_item,
                toolProp    = row.tool_prop,
                animKey     = row.anim_key,
                rewardItem  = row.reward_item,
                gatherMin   = row.gather_min,
                gatherMax   = row.gather_max,
                maxSpots    = row.max_spots,
                respawnTime = row.respawn_time,
                showBlip    = BoolDb(row.show_blip),
                isActive    = true,
                createdBy   = row.created_by,
            }
            State.areas[row.id] = areaData
            SyncArea(row.id, areaData)
        end
        Log(('Loaded %d areas'):format(#rows), 'INFO')
        if cb then cb() end
    end)
end

local function LoadSpots(cb)
    MySQL.query('SELECT s.* FROM rde_farming_spots s INNER JOIN rde_farming_areas a ON s.area_id = a.id WHERE a.is_active = 1', {}, function(rows)
        if not rows then
            if cb then cb() end
            return
        end
        local now = os.time() * 1000
        for _, row in ipairs(rows) do
            local area       = State.areas[row.area_id]
            if not area then goto continue end

            local depletedAt = row.depleted_at and tonumber(row.depleted_at) or nil
            local isDepleted = BoolDb(row.is_depleted)

            -- If depleted_at has passed respawn timer → mark as available already
            if isDepleted and depletedAt then
                local respawnMs = area.respawnTime * 1000
                if (now - depletedAt) >= respawnMs then
                    isDepleted = false
                    depletedAt = nil
                    MySQL.query('UPDATE rde_farming_spots SET is_depleted = 0, depleted_at = NULL WHERE id = ?', { row.id })
                end
            end

            local spotData = {
                id         = row.id,
                areaId     = row.area_id,
                position   = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
                rotZ       = row.rot_z,
                isDepleted = isDepleted,
                depletedAt = depletedAt,
            }

            State.spots[row.id] = spotData

            -- Queue for respawn if still depleted
            if isDepleted and depletedAt then
                local respawnMs = area.respawnTime * 1000
                local remaining = respawnMs - (now - depletedAt)
                if remaining > 0 then
                    RespawnQueue[row.id] = GetGameTimer() + remaining
                end
            end

            SyncSpot(row.id, spotData)
            ::continue::
        end
        Log(('Loaded %d spots'):format(#rows), 'INFO')
        if cb then cb() end
    end)
end

-- ============================================
-- 🔄 RESPAWN LOOP
-- ============================================

CreateThread(function()
    while true do
        Wait(Config.RespawnCheckTick)
        local now = GetGameTimer()
        for spotId, respawnAt in pairs(RespawnQueue) do
            if now >= respawnAt then
                RespawnQueue[spotId] = nil
                local spot = State.spots[spotId]
                if spot and spot.isDepleted then
                    spot.isDepleted = false
                    spot.depletedAt = nil
                    State.spots[spotId] = spot
                    MySQL.query('UPDATE rde_farming_spots SET is_depleted = 0, depleted_at = NULL WHERE id = ?', { spotId })
                    SyncSpot(spotId, spot)
                    Log(('Spot respawned: %s'):format(spotId), 'INFO')
                end
            end
        end
    end
end)

-- ============================================
-- 🌾 HARVEST EVENT
-- ============================================

RegisterNetEvent('rde_farming:harvest', function(spotId, playerPos)
    local source = source

    -- Validate player exists
    local player = Ox.GetPlayer(source)
    if not player then return end

    local spot = State.spots[spotId]
    if not spot then
        Notify(source, '❌', 'Invalid spot.', 'error')
        return
    end

    local area = State.areas[spot.areaId]
    if not area or not area.isActive then
        Notify(source, '❌', 'Area not active.', 'error')
        return
    end

    -- Depleted check
    if spot.isDepleted then
        Notify(source, '⚠️', 'Spot is depleted.', 'warning')
        return
    end

    -- Server-side distance validation (anti-cheat)
    if playerPos then
        local dx = playerPos.x - spot.position.x
        local dy = playerPos.y - spot.position.y
        local dz = playerPos.z - spot.position.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        if dist > 10.0 then
            Log(('Harvest distance exploit: player %d, dist=%.1f'):format(source, dist), 'WARN')
            return
        end
    end

    -- Per-player cooldown
    if not HarvestCooldowns[source] then HarvestCooldowns[source] = {} end
    local lastHarvest = HarvestCooldowns[source][spotId]
    if lastHarvest and (GetGameTimer() - lastHarvest) < Config.HarvestCooldown then
        Notify(source, '⏱️', 'Wait a moment.', 'warning')
        return
    end

    -- Tool check
    if area.toolItem and area.toolItem ~= '' then
        local hasItem = exports.ox_inventory:GetItem(source, area.toolItem, nil, true)
        if not hasItem or hasItem < 1 then
            Notify(source,
                '❌ Missing Tool',
                ('You need a %s.'):format(area.toolItem),
                'error'
            )
            return
        end
    end

    -- Calculate gather amount
    local gmin   = area.gatherMin or Config.DefaultGatherMin
    local gmax   = area.gatherMax or Config.DefaultGatherMax
    local amount = math.random(gmin, gmax)

    -- Give item
    local added = exports.ox_inventory:AddItem(source, area.rewardItem, amount)
    if not added then
        Notify(source, '❌', 'Inventory full.', 'error')
        return
    end

    -- Set cooldown
    HarvestCooldowns[source][spotId] = GetGameTimer()

    -- Mark depleted
    local nowMs = os.time() * 1000
    spot.isDepleted = true
    spot.depletedAt = nowMs
    State.spots[spotId] = spot

    MySQL.query(
        'UPDATE rde_farming_spots SET is_depleted = 1, depleted_at = ? WHERE id = ?',
        { nowMs, spotId }
    )

    -- Queue respawn
    local respawnMs = area.respawnTime * 1000
    RespawnQueue[spotId] = GetGameTimer() + respawnMs

    -- Sync to all clients
    SyncSpot(spotId, spot)

    -- Notify harvester
    Notify(source,
        '🌿 Harvested',
        ('Got %dx %s'):format(amount, area.rewardItem),
        'success'
    )

    Log(('Player %d harvested %dx %s from spot %s'):format(source, amount, area.rewardItem, spotId), 'INFO')
end)

-- ============================================
-- 🛠️ ADMIN CRUD — CREATE AREA
-- ============================================

RegisterNetEvent('rde_farming:createArea', function(data)
    local source = source
    if not IsAdmin(source) then
        Notify(source, '❌', 'No permission.', 'error')
        return
    end

    local identifier = GetIdentifier(source)
    if not identifier then
        Notify(source, '❌', 'Player identifier error.', 'error')
        return
    end

    -- Validate required fields
    if not data.name or not data.propModel or not data.rewardItem then
        Notify(source, '❌', 'Missing required fields.', 'error')
        return
    end

    local areaId = GenerateId('area')
    local areaData = {
        id          = areaId,
        name        = data.name,
        center      = data.center,
        spawnRadius = tonumber(data.spawnRadius)  or 30.0,
        propModel   = data.propModel,
        toolItem    = (data.toolItem  ~= '' and data.toolItem)  or nil,
        toolProp    = (data.toolProp  ~= '' and data.toolProp)  or nil,
        animKey     = (data.animKey   ~= '' and data.animKey)   or nil,
        rewardItem  = data.rewardItem,
        gatherMin   = tonumber(data.gatherMin)    or Config.DefaultGatherMin,
        gatherMax   = tonumber(data.gatherMax)    or Config.DefaultGatherMax,
        maxSpots    = tonumber(data.maxSpots)     or 5,
        respawnTime = tonumber(data.respawnTime)  or 300,
        showBlip    = data.showBlip ~= false,
        isActive    = true,
        createdBy   = identifier,
    }

    MySQL.query(
        [[INSERT INTO rde_farming_areas
          (id, name, center_x, center_y, center_z, spawn_radius, prop_model,
           tool_item, tool_prop, anim_key, reward_item, gather_min, gather_max,
           max_spots, respawn_time, show_blip, is_active, created_by)
          VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,?)]],
        {
            areaId,
            areaData.name,
            areaData.center.x, areaData.center.y, areaData.center.z,
            areaData.spawnRadius,
            areaData.propModel,
            areaData.toolItem,
            areaData.toolProp,
            areaData.animKey,
            areaData.rewardItem,
            areaData.gatherMin,
            areaData.gatherMax,
            areaData.maxSpots,
            areaData.respawnTime,
            DbBool(areaData.showBlip),
            areaData.createdBy,
        },
        function(result)
            if result then
                State.areas[areaId] = areaData
                SyncArea(areaId, areaData)
                GenerateSpots(areaData)
                Notify(source, '✅', ('Area "%s" created.'):format(areaData.name), 'success')
                Log(('Area created: %s by %s'):format(areaId, identifier), 'INFO')
            else
                Notify(source, '❌', 'Database error.', 'error')
            end
        end
    )
end)

-- ============================================
-- 🛠️ ADMIN CRUD — EDIT AREA
-- ============================================

RegisterNetEvent('rde_farming:editArea', function(areaId, data)
    local source = source
    if not IsAdmin(source) then
        Notify(source, '❌', 'No permission.', 'error')
        return
    end

    local area = State.areas[areaId]
    if not area then
        Notify(source, '❌', 'Area not found.', 'error')
        return
    end

    -- Merge changes
    local updated = {
        id          = areaId,
        name        = data.name        or area.name,
        center      = data.center      or area.center,
        spawnRadius = tonumber(data.spawnRadius) or area.spawnRadius,
        propModel   = data.propModel   or area.propModel,
        toolItem    = (data.toolItem ~= '' and data.toolItem)  or nil,
        toolProp    = (data.toolProp ~= '' and data.toolProp)  or nil,
        animKey     = (data.animKey  ~= '' and data.animKey)   or nil,
        rewardItem  = data.rewardItem  or area.rewardItem,
        gatherMin   = tonumber(data.gatherMin)   or area.gatherMin,
        gatherMax   = tonumber(data.gatherMax)   or area.gatherMax,
        maxSpots    = tonumber(data.maxSpots)    or area.maxSpots,
        respawnTime = tonumber(data.respawnTime) or area.respawnTime,
        showBlip    = data.showBlip ~= false,
        isActive    = area.isActive,
        createdBy   = area.createdBy,
    }

    MySQL.query(
        [[UPDATE rde_farming_areas SET
          name=?, center_x=?, center_y=?, center_z=?, spawn_radius=?,
          prop_model=?, tool_item=?, tool_prop=?, anim_key=?,
          reward_item=?, gather_min=?, gather_max=?, max_spots=?,
          respawn_time=?, show_blip=?
          WHERE id=?]],
        {
            updated.name,
            updated.center.x, updated.center.y, updated.center.z,
            updated.spawnRadius,
            updated.propModel,
            updated.toolItem,
            updated.toolProp,
            updated.animKey,
            updated.rewardItem,
            updated.gatherMin,
            updated.gatherMax,
            updated.maxSpots,
            updated.respawnTime,
            DbBool(updated.showBlip),
            areaId,
        },
        function(result)
            if result then
                State.areas[areaId] = updated
                SyncArea(areaId, updated)
                Notify(source, '✅', ('Area "%s" updated.'):format(updated.name), 'success')
                Log(('Area edited: %s'):format(areaId), 'INFO')
            else
                Notify(source, '❌', 'Database error.', 'error')
            end
        end
    )
end)

-- ============================================
-- 🛠️ ADMIN CRUD — DELETE AREA
-- ============================================

RegisterNetEvent('rde_farming:deleteArea', function(areaId)
    local source = source
    if not IsAdmin(source) then
        Notify(source, '❌', 'No permission.', 'error')
        return
    end

    local area = State.areas[areaId]
    if not area then
        Notify(source, '❌', 'Area not found.', 'error')
        return
    end

    -- Remove all spots from state and respawn queue
    for spotId, spot in pairs(State.spots) do
        if spot.areaId == areaId then
            RespawnQueue[spotId] = nil
            SyncSpot(spotId, nil)
            State.spots[spotId] = nil
        end
    end

    -- CASCADE DELETE handles spots in DB
    MySQL.query('DELETE FROM rde_farming_areas WHERE id = ?', { areaId }, function(result)
        if result then
            SyncArea(areaId, nil)
            State.areas[areaId] = nil
            Notify(source, '✅', ('Area "%s" deleted.'):format(area.name), 'success')
            Log(('Area deleted: %s'):format(areaId), 'INFO')
        else
            Notify(source, '❌', 'Database error.', 'error')
        end
    end)
end)

-- ============================================
-- 🛠️ ADMIN CRUD — TOGGLE AREA ACTIVE
-- ============================================

RegisterNetEvent('rde_farming:toggleArea', function(areaId)
    local source = source
    if not IsAdmin(source) then return end

    local area = State.areas[areaId]
    if not area then return end

    area.isActive = not area.isActive
    State.areas[areaId] = area

    MySQL.query('UPDATE rde_farming_areas SET is_active = ? WHERE id = ?',
        { DbBool(area.isActive), areaId },
        function(result)
            if result then
                SyncArea(areaId, area)
                Notify(source, '✅',
                    ('Area %s is now %s.'):format(area.name, area.isActive and 'active' or 'inactive'),
                    'success'
                )
            end
        end
    )
end)

-- ============================================
-- 🛠️ ADMIN — SET AREA CENTER TO PLAYER POS
-- ============================================

RegisterNetEvent('rde_farming:setAreaCenter', function(areaId, newCenter)
    local source = source
    if not IsAdmin(source) then return end

    local area = State.areas[areaId]
    if not area then return end

    area.center = newCenter
    State.areas[areaId] = area

    MySQL.query('UPDATE rde_farming_areas SET center_x=?, center_y=?, center_z=? WHERE id=?',
        { newCenter.x, newCenter.y, newCenter.z, areaId },
        function()
            SyncArea(areaId, area)
            Notify(source, '✅', 'Area center updated.', 'success')
        end
    )
end)

-- ============================================
-- 🛠️ ADMIN — REGENERATE SPOTS
-- Wipes existing spots for area and creates fresh ones
-- ============================================

RegisterNetEvent('rde_farming:regenSpots', function(areaId)
    local source = source
    if not IsAdmin(source) then return end

    local area = State.areas[areaId]
    if not area then return end

    -- Remove old spots
    for spotId, spot in pairs(State.spots) do
        if spot.areaId == areaId then
            RespawnQueue[spotId] = nil
            SyncSpot(spotId, nil)
            State.spots[spotId] = nil
        end
    end

    MySQL.query('DELETE FROM rde_farming_spots WHERE area_id = ?', { areaId }, function()
        GenerateSpots(area)
        Notify(source, '✅', 'Spots regenerated.', 'success')
    end)
end)

-- ============================================
-- 📋 ADMIN — REQUEST AREA LIST
-- Returns all areas (including inactive) to requesting admin
-- ============================================

RegisterNetEvent('rde_farming:requestAreas', function()
    local source = source
    if not IsAdmin(source) then return end

    TriggerClientEvent('rde_farming:receiveAreas', source, State.areas)
end)

-- ============================================
-- 🚀 INIT — Player Joins
-- ============================================

RegisterNetEvent('rde_farming:init', function()
    local source = source
    while not State.ready do Wait(100) end

    local isAdmin = IsAdmin(source)

    -- Send all areas (active only for non-admins)
    local areas = {}
    for id, area in pairs(State.areas) do
        if area.isActive or isAdmin then
            areas[id] = area
        end
    end

    -- Send all spots
    local spots = {}
    for id, spot in pairs(State.spots) do
        local area = State.areas[spot.areaId]
        if area and (area.isActive or isAdmin) then
            spots[id] = spot
        end
    end

    TriggerClientEvent('rde_farming:loadAll', source, {
        areas   = areas,
        spots   = spots,
        isAdmin = isAdmin,
    })

    Log(('Player %d initialised (admin: %s)'):format(source, tostring(isAdmin)), 'INFO')
end)

-- ============================================
-- 🚀 RESOURCE START
-- ============================================

AddEventHandler('onResourceStart', function(name)
    if name ~= GetCurrentResourceName() then return end

    local attempts = 0
    while not Ox and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    if not Ox then
        Log('ox_core not found! Cannot start.', 'ERROR')
        return
    end

    SetupDatabase(function()
        LoadAreas(function()
            LoadSpots(function()
                State.ready = true
                Log('RDE Farming ready ✅', 'INFO')

                -- Init any already connected players (resource restart scenario)
                for _, playerId in ipairs(GetPlayers()) do
                    local src = tonumber(playerId)
                    if src then
                        TriggerEvent('rde_farming:init', src)
                    end
                end
            end)
        end)
    end)
end)

-- ============================================
-- 🧹 CLEANUP THREADS
-- ============================================

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for key in pairs(GlobalState) do
        if key:find(Config.StatebagPrefix) then
            GlobalState[key] = nil
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    HarvestCooldowns[source] = nil
end)

CreateThread(function()
    while true do
        Wait(Config.CleanupInterval)
        local cutoff = GetGameTimer() - 600000
        for src, spotMap in pairs(HarvestCooldowns) do
            for spotId, ts in pairs(spotMap) do
                if ts < cutoff then spotMap[spotId] = nil end
            end
        end
        Log('Cooldown cache cleaned', 'INFO')
    end
end)

print('^2[RDE | Farming]^7 Server v1.0.0 loaded ✅')
