fx_version 'cerulean'
game 'gta5'

author      'RDE | SerpentsByte'
description 'RDE Farming System — Dynamic resource gathering with full admin CRUD, proximity loading, StateBag sync, animations, tool requirements and ox_target integration.'
version     '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'config.lua',
    'locales/en.lua',   -- loads Lang_en first
    'locales/de.lua',   -- sets Lang = Lang_de if locale is 'de', else falls back to Lang_en
}

client_scripts {
    'data/animations.lua',
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

dependencies {
    'ox_core',
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
}

lua54 'yes'
