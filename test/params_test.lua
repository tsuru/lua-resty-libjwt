local lu = require('luaunit')
local libjwt = require('../lib/resty/libjwt')


function TestShouldReturnUndefinedWhenParamsIsNil()
    local result, err = libjwt.get_params()
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.get_params(nil)
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )
end


function TestShouldReturnUndefinedWhenFilesIsNil()
    local params = {["header_token"] = "token"}
    local result, err = libjwt.get_params(params)
    lu.assertEquals(err, "jwks_files is required" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnValuesWhenFilesIsNotNil()
    local params = {
        ["header_token"] = "token",
        ["jwks_files"] = "files",
    }
    local result, err = libjwt.get_params(params)
    lu.assertEquals(err, "jwks_files is not an array" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnValidatedParams()
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