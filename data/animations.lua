--[[
╔══════════════════════════════════════════════════════════════════╗
║  RDE FARMING — ANIMATION LIBRARY  data/animations.lua            ║
║  Admin selects an animation KEY when creating/editing an area.   ║
║  Add custom entries freely — key must be unique.                  ║
╚══════════════════════════════════════════════════════════════════╝

Entry format:
    key        — unique string, admin enters this in the menu
    dict       — animation dictionary (streamed if needed)
    anim       — animation clip name
    duration   — ms to play before harvest completes (overrides Config.AnimationDuration)
    flag       — animflag bitmask (49 = loop+upperbody, 1 = loop, 0 = once)
    toolProp   — prop model attached to BONE 28422 (right hand) while animation plays
                 (overridden by per-area toolPropModel if set)
    boneIndex  — attachment bone index (default 28422 = right hand)
    propOffset — {x,y,z} local offset of the held prop
    propRot    — {x,y,z} local rotation of the held prop
]]

Animations = {

    -- ─────────────────── MINING / PICKAXE ───────────────────
    ['pickaxe_mine'] = {
        dict       = 'amb@world_human_picnic@male@base',
        anim       = 'base',
        duration   = 5000,
        flag       = 1,
        toolProp   = 'prop_tool_pickaxe',
        boneIndex  = 28422,
        propOffset = { x = 0.0,  y = 0.0,  z = -0.02 },
        propRot    = { x = 20.0, y = -10.0, z = 0.0  },
    },

    -- ─────────────────── CHOPPING / AXE ─────────────────────
    ['axe_chop'] = {
        dict       = 'amb@world_human_cheering@male_b@idle_a',
        anim       = 'idle_a',
        duration   = 4500,
        flag       = 1,
        toolProp   = 'prop_cs_hand_axe',
        boneIndex  = 28422,
        propOffset = { x = 0.05, y = 0.0,  z = 0.0  },
        propRot    = { x = 0.0,  y = 0.0,  z = 0.0  },
    },

    -- ─────────────────── DIGGING / SHOVEL ───────────────────
    ['shovel_dig'] = {
        dict       = 'amb@world_human_gardener_plant@male@idle_a',
        anim       = 'idle_a',
        duration   = 5500,
        flag       = 1,
        toolProp   = 'prop_tool_shovel',
        boneIndex  = 28422,
        propOffset = { x = 0.0,  y = 0.0,  z = -0.05 },
        propRot    = { x = 30.0, y = 0.0,  z = 0.0   },
    },

    -- ─────────────────── PICKING / HANDS ────────────────────
    ['hand_pick'] = {
        dict       = 'amb@world_human_aa_smoke@male@idle_a',
        anim       = 'idle_a',
        duration   = 3000,
        flag       = 1,
        toolProp   = nil,
        boneIndex  = 28422,
        propOffset = { x = 0.0, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── CUTTING / KNIFE ────────────────────
    ['knife_cut'] = {
        dict       = 'melee@large_wpn@streamed_core',
        anim       = 'heavy_block',
        duration   = 3500,
        flag       = 1,
        toolProp   = 'prop_cs_knife',
        boneIndex  = 28422,
        propOffset = { x = 0.0,  y = 0.0,  z = 0.0 },
        propRot    = { x = -20.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── COLLECTING / CROUCHING ─────────────
    ['crouch_collect'] = {
        dict       = 'missfbi4prepp1',
        anim       = '_idle_garbage_man',
        duration   = 4000,
        flag       = 1,
        toolProp   = nil,
        boneIndex  = 28422,
        propOffset = { x = 0.0, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── FISHING (WITHOUT ROD) ──────────────
    ['hand_fish'] = {
        dict       = 'timetable@ron@ig_5_couch',
        anim       = 'ig_5_couch',
        duration   = 6000,
        flag       = 1,
        toolProp   = nil,
        boneIndex  = 28422,
        propOffset = { x = 0.0, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── FILLING BOTTLE ─────────────────────
    ['bottle_fill'] = {
        dict       = 'amb@world_human_drinking@beer@male@idle_a',
        anim       = 'idle_a',
        duration   = 4000,
        flag       = 1,
        toolProp   = 'prop_amb_whiskey_jd01a',
        boneIndex  = 28422,
        propOffset = { x = 0.04, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0,  y = 0.0, z = 0.0 },
    },

    -- ─────────────────── FARMING / PLANT CARE ───────────────
    ['plant_tend'] = {
        dict       = 'amb@world_human_gardener_plant@male@idle_a',
        anim       = 'idle_a',
        duration   = 5000,
        flag       = 1,
        toolProp   = nil,
        boneIndex  = 28422,
        propOffset = { x = 0.0, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── SCAVENGING / SEARCH ────────────────
    ['search_ground'] = {
        dict       = 'amb@world_human_aa_smoke@male@idle_a',
        anim       = 'idle_a',
        duration   = 4000,
        flag       = 1,
        toolProp   = nil,
        boneIndex  = 28422,
        propOffset = { x = 0.0, y = 0.0, z = 0.0 },
        propRot    = { x = 0.0, y = 0.0, z = 0.0 },
    },

    -- ─────────────────── HAMMERING ──────────────────────────
    ['hammer_work'] = {
        dict       = 'missfbi4prepp1',
        anim       = '_idle_garbage_man',
        duration   = 4500,
        flag       = 1,
        toolProp   = 'prop_tool_hammer',
        boneIndex  = 28422,
        propOffset = { x = 0.0,  y = 0.0, z = -0.03 },
        propRot    = { x = 10.0, y = 0.0, z = 0.0   },
    },
}

-- Build sorted key list for admin dropdown display
AnimationKeys = {}
for k in pairs(Animations) do
    AnimationKeys[#AnimationKeys + 1] = k
end
table.sort(AnimationKeys)
