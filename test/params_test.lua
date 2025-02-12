local lu = require('luaunit')
local libjwt = require('../lib/resty/libjwt')


function test_should_return_undefined_when_params_is_nil()
    local result, err = libjwt.get_params()
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.get_params(nil)
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )
end


function test_should_return_undefined_when_files_is_nil()
    local params = {["header_token"] = "token"}
    local result, err = libjwt.get_params(params)
    lu.assertEquals(err, "jwks_files is required" )
    lu.assertEquals(result, nil )
end

function test_should_return_values_when_files_is_not_nil()
    local params = {
        ["header_token"] = "token",
        ["jwks_files"] = "files",
    }
    local result, err = libjwt.get_params(params)
    lu.assertEquals(err, "jwks_files is not an array" )
    lu.assertEquals(result, nil )
end

function test_should_return_validated_params()
    local params = {
        ["header_token"] = "token",
        ["jwks_files"] = {"files"},
    }
    local result, err = libjwt.get_params(params)
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {
        header_token = "token",
        jwks_files = {"files"},
    })
end

os.exit( lu.LuaUnit.run() )