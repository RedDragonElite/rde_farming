--[[
╔══════════════════════════════════════════════════════════════════╗
║         RDE FARMING SYSTEM — CONFIG v1.0.0                       ║
║  ✅ Full Admin CRUD Ingame                                        ║
║  ✅ Dynamic Prop Spawning with Proximity Loading                  ║
║  ✅ StateBag Sync (ox_core pattern)                               ║
║  ✅ Tool Requirements + ox_target Harvest                         ║
║  ✅ Animations per Tool/Action                                    ║
║  ✅ Auto-Respawn after Harvest Cooldown                           ║
║  ✅ Zero external dependencies                                    ║
╚══════════════════════════════════════════════════════════════════╝
]]

local Config = {}

-- ============================================
-- 🐛 DEBUG
-- ============================================
Config.Debug = false

-- ============================================
-- 🌐 LOCALE
-- Default language, available: 'en', 'de'
-- ============================================
Config.Locale = 'en'

-- ============================================
-- 🔐 PERMISSIONS
-- ============================================
Config.AllowAcePermissions = true

Config.AdminGroups = {
    ['admin']      = true,
    ['superadmin'] = true,
    ['owner']      = true,
    ['moderator']  = true,
}

-- ============================================
-- 🗄️ DATABASE
-- ============================================
Config.DBTableAreas  = 'rde_farming_areas'
Config.DBTableSpots  = 'rde_farming_spots'
Config.StatebagPrefix = 'rde_farm_'

-- ============================================
-- 🌍 PROXIMITY LOADING
-- Spots outside this range are NOT rendered.
-- Reduces entity count drastically.
-- ============================================
Config.LoadRadius    = 150.0   -- Spots render within this distance
Config.UnloadRadius  = 170.0   -- Spots despawn beyond this distance (hysteresis)
Config.ProximityTick = 1500    -- ms between proximity checks (per client)

-- ============================================
-- 🎯 TARGET / HARVEST SETTINGS
-- ============================================
Config.TargetDistance      = 2.5    -- ox_target interaction distance
Config.TargetSizeMultiplier = 1.2   -- Box zone size relative to prop model

-- ============================================
-- ⏱️ TIMING
-- ============================================
Config.HarvestCooldown    = 3000   -- ms: min time between harvests per spot (anti-spam)
Config.RespawnCheckTick   = 5000   -- ms: server checks for respawn every N ms
Config.AnimationDuration  = 4000   -- ms: default animation length if not defined per animation
Config.PropFadeTick       = 100    -- ms: how fast depleted prop fades out

-- ============================================
-- 🎲 GATHER AMOUNTS (global defaults, overridable per area)
-- ============================================
Config.DefaultGatherMin = 1
Config.DefaultGatherMax = 3

-- ============================================
-- 📦 TOOL PROP MODELS (displayed in player hand while harvesting)
-- The admin inputs these when creating/editing an area.
-- These are sane defaults shown in the admin menu as examples.
-- ============================================
Config.ExampleToolProps = {
    { name = 'Pickaxe',  model = 'prop_tool_pickaxe' },
    { name = 'Axe',      model = 'prop_cs_hand_axe'  },
    { name = 'Knife',    model = 'prop_cs_knife'      },
    { name = 'Shovel',   model = 'prop_tool_shovel'   },
    { name = 'Bottle',   model = 'prop_amb_whiskey_jd01a' },
    { name = 'Bag',      model = 'ba_prop_battle_bag_01a' },
}

-- ============================================
-- 🎨 VISUAL SETTINGS
-- ============================================
Config.Colors = {
    adminOutline  = { r = 255, g = 60,  b = 60  },   -- Red outline on depleted spots
    depletedAlpha = 80,                                -- Alpha on depleted prop (ghosted)
    areaBlip      = {
        sprite = 280,   -- circle blip
        color  = 2,     -- green
        scale  = 0.6,
    },
}

-- ============================================
-- 📍 AREA BLIPS
-- Admin can toggle blips per area.
-- Players only see blips for areas they are allowed to farm.
-- ============================================
Config.ShowBlips    = true
Config.BlipLabel    = 'Farming Area'

-- ============================================
-- 🔒 PROP PLACEMENT DEFAULTS
-- Used when server spawns new spot props.
-- ============================================
Config.DefaultRotation  = { x = 0.0, y = 0.0, z = 0.0 }
Config.RandomRotateZ    = true   -- Randomise Z-rotation of spawned spot props for variety

-- ============================================
-- 🧹 SERVER CLEANUP
-- ============================================
Config.CleanupInterval  = 600000  -- ms: how often server purges old cooldown/cache entries

return Config
