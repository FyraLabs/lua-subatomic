package = "lua-subatomic"
version = "dev-1"
source = {
   url = "git+https://github.com/FyraLabs/lua-subatomic.git"
}
description = {
   summary = "This repository contains the Lua bindings for the Subatomic REST API so you can create Subatomic management scripts in Lua.",
   detailed = [[
This repository contains the Lua bindings for the Subatomic REST API so you can create Subatomic management scripts in Lua.
]],
   homepage = "https://terra.fyralabs.com",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      satm = "src/satm.lua"
   }
}

dependencies = {
   "http >= 0.4",
   "lua-json >= 1"
}