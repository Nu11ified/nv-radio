fx_version 'cerulean'
game 'gta5'

name 'nv-radio'
description 'Radio & proximity voice management UI'
version '1.0.0'
author 'NV'

lua54 'yes'

dependency 'nv-voice'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/nui_bridge.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
}
