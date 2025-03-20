package = "lua-resty-libjwt"
version = "0.2.0-1"
source = {
   url = "git://github.com/tsuru/lua-resty-libjwt.git",
   tag = "v0.2.0"
}
description = {
   summary = "Lua bindings to libjwt (https://github.com/benmcollins/libjwt) using FFI",
   homepage = "https://github.com/tsuru/lua-resty-libjwt",
   license = "3-clause BSD",
   maintainer = "Tsuru <tsuru@g.globo>"
}
dependencies = {
   "lua >= 5.1",
   "lua-cjson >= 2.1.0.10-1",
}
build = {
   type = "builtin",
   modules = {
      ["resty.libjwt"] = "lib/resty/libjwt/init.lua",
      ["resty.libjwt.cached"] = "lib/resty/libjwt/cached.lua",
      ["resty.libjwt.decode"] = "lib/resty/libjwt/decode.lua",
      ["resty.libjwt.jwks_c"] = "lib/resty/libjwt/jwks_c.lua",
      ["resty.libjwt.utils"] = "lib/resty/libjwt/utils.lua",
   }
}