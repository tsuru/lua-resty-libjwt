local lu = require('luaunit')
local utils = require('../lib/resty/libjwt/utils')

function TestShouldReturnErrorWhenNotFindingTheToken()
    local headers, result, err
    headers = {
        ["header_token"] = "token 123",
    }

    result, err = utils.get_token(headers, "header89")
    lu.assertEquals(err, "token not found")
    lu.assertEquals(result, nil)

    headers = {
        ["header_token"] = "token123",
    }
    result, err = utils.get_token(headers, "header_token")
    lu.assertEquals(err, "token not found")
    lu.assertEquals(result, nil)
end

function TestShouldNotReturnErrorWhenCorrectParameters()
    local headers = {
        ["token"] = "token 123",
    }
    local result, err = utils.get_token(headers, "token")
    lu.assertEquals(err, "")
    lu.assertEquals(result, "123")
end

os.exit(lu.LuaUnit.run())
