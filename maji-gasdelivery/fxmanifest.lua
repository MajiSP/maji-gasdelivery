fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Maji#1118'
description 'Fuel Delivery Job'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'qb-core',
    'qb-target',
}

escrow_ignore {
    'config.lua',
}