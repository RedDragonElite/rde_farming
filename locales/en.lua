-- locales/en.lua  — RDE Farming System
-- Always loaded. Config.Locale controls which Lang table wins at runtime.

Lang_en = {
    -- General
    ['error_title']          = '❌ Error',
    ['success_title']        = '✅ Success',
    ['warning_title']        = '⚠️ Warning',
    ['info_title']           = 'ℹ️ Info',
    ['no_permission']        = 'You do not have permission to do this.',
    ['not_admin']            = 'Admin access required.',

    -- Harvest / Gather
    ['harvest_start']        = 'Harvesting…',
    ['harvest_done']         = 'Gathered %dx %s.',
    ['harvest_depleted']     = 'Nothing left here. Come back later.',
    ['harvest_no_tool']      = 'You need a %s to harvest this.',
    ['harvest_cooldown']     = 'You need to wait a moment.',
    ['harvest_inv_full']     = 'Your inventory is full.',

    -- Target labels
    ['target_harvest']       = 'Harvest',
    ['target_harvest_tool']  = 'Harvest (needs %s)',
    ['target_depleted']      = 'Depleted — Respawning…',

    -- Admin Menu
    ['menu_title']           = '🌿 RDE Farming — Admin',
    ['menu_create_area']     = 'Create Farming Area',
    ['menu_create_desc']     = 'Define a new area with spot spawning config',
    ['menu_list_areas']      = 'Manage Areas',
    ['menu_list_desc']       = 'View, edit or delete existing areas',
    ['menu_no_areas']        = 'No farming areas configured yet.',

    -- Area editor — input labels
    ['input_area_name']      = 'Area Name',
    ['input_area_name_ph']   = 'e.g. Iron Mine',
    ['input_prop_model']     = 'Prop Model',
    ['input_prop_model_ph']  = 'e.g. prop_rock_3_a',
    ['input_prop_model_desc']= 'Valid GTA5 prop / object model name',
    ['input_tool_item']      = 'Required Tool Item',
    ['input_tool_item_ph']   = 'e.g. pickaxe  (leave blank = no tool needed)',
    ['input_tool_prop']      = 'Tool Hand Prop Model',
    ['input_tool_prop_ph']   = 'e.g. prop_tool_pickaxe  (held while harvesting)',
    ['input_item_reward']    = 'Reward Item',
    ['input_item_reward_ph'] = 'e.g. iron_ore',
    ['input_gather_min']     = 'Min Gather Amount',
    ['input_gather_max']     = 'Max Gather Amount',
    ['input_max_spots']      = 'Max Active Spots',
    ['input_respawn_time']   = 'Respawn Time (seconds)',
    ['input_spawn_radius']   = 'Spot Spawn Radius (meters)',
    ['input_animation']      = 'Harvest Animation Key',
    ['input_animation_ph']   = 'e.g. axe_chop  (see animations.lua for keys)',
    ['input_blip']           = 'Show Map Blip?',
    ['input_center_hint']    = 'Center: stand where you want, then confirm.',

    -- Area manager
    ['area_edit']            = 'Edit',
    ['area_delete']          = 'Delete',
    ['area_set_center']      = 'Move Center Here',
    ['area_toggle_active']   = 'Toggle Active',
    ['area_info']            = 'Area Info',
    ['area_active']          = '✅ Active',
    ['area_inactive']        = '⏸ Inactive',
    ['area_deleted']         = 'Area deleted.',
    ['area_saved']           = 'Area saved.',
    ['area_center_set']      = 'Area center updated to your position.',

    -- Spot status
    ['spot_available']       = 'Available',
    ['spot_depleted']        = 'Depleted',
}

-- Runtime locale selection (runs after config.lua is loaded)
if Config and Config.Locale == 'en' then
    Lang = Lang_en
end
