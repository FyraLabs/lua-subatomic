local version = _VERSION:match("%d+%.%d+")
package.path = 'lua_modules/share/lua/' .. version ..
    '/?.lua;lua_modules/share/lua/' .. version ..
    '/?/init.lua;' .. package.path .. ';src/?.lua'

local subatomic_token = os.getenv("SUBATOMIC_TOKEN")


local inspect = require('inspect')
local satm = require("satm")

-- print(inspect(satm))
satm:set_token(subatomic_token)

local keys = satm:keys()
print(inspect(keys))

local key = satm:get_key(keys[1].id)
print(inspect(key))


