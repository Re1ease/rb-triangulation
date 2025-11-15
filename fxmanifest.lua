fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Re1ease"
version "1.0.0"

shared_scripts {"@ox_lib/init.lua", "shared/*.lua"}
client_script "client/*.lua"
server_script "server/*.lua"

dependencies {
	"qb-core",
	"ox_lib",
	"ox_target"
}