fx_version 'cerulean'

game 'gta5'
description 'The Core resource that provides the functionalities for all other resources.'
lua54 'yes'
version '1.13.4'

shared_scripts {
	'init/locale.lua',

	'init/shared/config/main.lua',
    'init/shared/config/weapons.lua',
    'init/shared/config/adjustments.lua',

    'init/shared/main.lua',
    'init/shared/functions.lua',
    'init/shared/modules/*.lua',
	'configs/**/*.lua',
	'@ox_lib/init.lua'
}

server_scripts {
	'lib/oxmysql/lib/MySQL.lua',
	'lib/oxmysql/dist/build.js',
	'init/server/sessionmanager.lua',
    'init/shared/config/logs.lua',
	'init/server/common.lua',
	'init/server/modules/callback.lua',
	'init/server/classes/player.lua',
	'init/server/classes/vehicle.lua',
	'init/server/classes/overrides/*.lua',
	'init/server/functions.lua',
	'init/server/modules/onesync.lua',
	'init/server/modules/paycheck.lua',
	'init/server/main.lua',
	'init/server/modules/commands.lua',
	'init/server/bridge/**/*.lua',
	'init/server/modules/npwd.lua',
	'init/server/modules/createJob.lua',
	'configs/main.lua',
	'configs/**/*.lua',
	'modules/**/server/*.lua',
	'esx/**/server/*.lua',
}

client_scripts {
	'init/client/spawnmanager.lua',
    'init/client/main.lua',
	'init/client/functions.lua',
	'init/client/modules/wrapper.lua',
	'init/client/modules/callback.lua',
    'init/client/modules/adjustments.lua',
	'init/client/modules/points.lua',

	'init/client/modules/events.lua',

	'init/client/modules/actions.lua',
	'init/client/modules/death.lua',
	'init/client/modules/npwd.lua',
    'init/client/modules/interactions.lua',
	'init/client/modules/scaleform.lua',
	'init/client/modules/streaming.lua',
	'init/client/game.lua',
	'lib/oxmysql/ui.lua',
	'configs/main.lua',
	'lib/menu/rageui.lua',
	'configs/**/*.lua',
	'modules/**/client/*.lua',
	'esx/**/client/*.lua',
}

client_exports {
    'Game'
}

ui_page 'lib/oxmysql/web/build/index.html'

files {
	'init/imports.lua',
	'init/locales/*.lua',
	'init/locale.js',
    "init/client/imports/*.lua",
	'lib/oxmysql/web/build/index.html',
	'lib/oxmysql/web/build/**/*',
}

dependencies {
	'/native:0x6AE51D4B',
    '/native:0xA61C8FC6',
}

provide 'mysql-async'
provide 'ghmattimysql'

convar_category 'OxMySQL' {
	'Configuration',
	{
		{ 'Connection string', 'mysql_connection_string', 'CV_STRING', 'mysql://user:password@localhost/database' },
		{ 'Debug', 'mysql_debug', 'CV_BOOL', 'false' }
	}
}

exports {
    'GetBind'
}