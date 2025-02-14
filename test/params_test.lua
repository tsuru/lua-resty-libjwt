local lu = require('luaunit')
local utils = require('../lib/resty/utils')


function TestShouldReturnUndefinedWhenParamsIsNil()
    local result, err = utils.get_params()
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )

    local result, err = utils.get_params(nil)
    lu.assertEquals(err, "params is required" )
    lu.assertEquals(result, nil )
end


function TestShouldReturnUndefinedWhenFilesIsNil()
    local params = {["header_token"] = "token"}
    local result, err = utils.get_params(params)
    lu.assertEquals(err, "jwks_files is required" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnValuesWhenFilesIsNotNil()
    local params = {
        ["header_token"] = "token",
        ["jwks_files"] = "files",
    }
    local result, err = utils.get_params(params)
    lu.assertEquals(err, "jwks_files is not an array" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnValidatedParams()
    local params = {
        ["header_token"] = "token",
        ["jwks_files"] = {"files"},
    }
    local result, err = utils.get_params(params)
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {
        header_token = "token",
        jwks_files = {"files"},
    })
end

os.exit( lu.LuaUnit.run() )