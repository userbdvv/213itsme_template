fx_version 'cerulean'
game 'gta5'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/assets/**/**'
}

client_script 'client.lua'

server_script {
	'@game/lib/oxmysql/lib/MySQL.lua',
	"server.lua"
}