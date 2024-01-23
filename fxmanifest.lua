fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Maji#1118'
description 'Fuel Delivery Job'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua'
}
client_scripts {
    'client/main.lua',
}
server_script 'server/main.lua'

dependencies {
    'qb-core',
    'qb-target'
}
