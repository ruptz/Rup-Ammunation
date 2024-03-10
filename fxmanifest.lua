fx_version "cerulean"
game "gta5"

title "Rup-Ammunation"
description "Gun Store"
author "Ruptz"
version "1.0.0"

shared_script "config.lua"

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "server/server.lua"
}

client_scripts {
    "client/NativeUI.lua",
    "client/menu.lua",
    "client/client.lua"
}
