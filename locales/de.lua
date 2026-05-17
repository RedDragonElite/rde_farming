-- locales/de.lua  — RDE Farming System
-- Always loaded. Config.Locale controls which Lang table wins at runtime.

Lang_de = {
    -- General
    ['error_title']          = '❌ Fehler',
    ['success_title']        = '✅ Erfolg',
    ['warning_title']        = '⚠️ Warnung',
    ['info_title']           = 'ℹ️ Info',
    ['no_permission']        = 'Du hast keine Berechtigung dafür.',
    ['not_admin']            = 'Admin-Zugang erforderlich.',

    -- Harvest / Gather
    ['harvest_start']        = 'Ernte läuft…',
    ['harvest_done']         = '%dx %s gesammelt.',
    ['harvest_depleted']     = 'Hier ist nichts mehr. Komm später wieder.',
    ['harvest_no_tool']      = 'Du brauchst %s um das zu ernten.',
    ['harvest_cooldown']     = 'Warte einen Moment.',
    ['harvest_inv_full']     = 'Dein Inventar ist voll.',

    -- Target labels
    ['target_harvest']       = 'Ernten',
    ['target_harvest_tool']  = 'Ernten (braucht %s)',
    ['target_depleted']      = 'Erschöpft — Respawnt…',

    -- Admin Menu
    ['menu_title']           = '🌿 RDE Farming — Admin',
    ['menu_create_area']     = 'Farming-Area erstellen',
    ['menu_create_desc']     = 'Neue Area mit Spot-Spawn-Config definieren',
    ['menu_list_areas']      = 'Areas verwalten',
    ['menu_list_desc']       = 'Bestehende Areas ansehen, bearbeiten oder löschen',
    ['menu_no_areas']        = 'Noch keine Farming-Areas konfiguriert.',

    -- Area editor — input labels
    ['input_area_name']      = 'Area-Name',
    ['input_area_name_ph']   = 'z.B. Eisenmine',
    ['input_prop_model']     = 'Prop-Model',
    ['input_prop_model_ph']  = 'z.B. prop_rock_3_a',
    ['input_prop_model_desc']= 'Gültiger GTA5-Prop/Objekt-Modellname',
    ['input_tool_item']      = 'Benötigtes Tool-Item',
    ['input_tool_item_ph']   = 'z.B. pickaxe  (leer lassen = kein Tool nötig)',
    ['input_tool_prop']      = 'Tool-Hand-Prop-Model',
    ['input_tool_prop_ph']   = 'z.B. prop_tool_pickaxe  (wird beim Ernten gehalten)',
    ['input_item_reward']    = 'Belohnungsitem',
    ['input_item_reward_ph'] = 'z.B. iron_ore',
    ['input_gather_min']     = 'Min. Erntemenge',
    ['input_gather_max']     = 'Max. Erntemenge',
    ['input_max_spots']      = 'Max. aktive Spots',
    ['input_respawn_time']   = 'Respawnzeit (Sekunden)',
    ['input_spawn_radius']   = 'Spot-Spawn-Radius (Meter)',
    ['input_animation']      = 'Ernte-Animations-Key',
    ['input_animation_ph']   = 'z.B. axe_chop  (siehe animations.lua für Keys)',
    ['input_blip']           = 'Karten-Blip anzeigen?',
    ['input_center_hint']    = 'Mitte: Steh wo du willst, dann bestätigen.',

    -- Area manager
    ['area_edit']            = 'Bearbeiten',
    ['area_delete']          = 'Löschen',
    ['area_set_center']      = 'Mitte hierher setzen',
    ['area_toggle_active']   = 'Aktivierung umschalten',
    ['area_info']            = 'Area-Info',
    ['area_active']          = '✅ Aktiv',
    ['area_inactive']        = '⏸ Inaktiv',
    ['area_deleted']         = 'Area gelöscht.',
    ['area_saved']           = 'Area gespeichert.',
    ['area_center_set']      = 'Area-Mitte auf deine Position gesetzt.',

    -- Spot status
    ['spot_available']       = 'Verfügbar',
    ['spot_depleted']        = 'Erschöpft',
}

-- Runtime locale selection (runs after config.lua is loaded)
if Config and Config.Locale == 'de' then
    Lang = Lang_de
end

-- Fallback: if no locale matched yet, default to English
if not Lang then
    Lang = Lang_en
end
