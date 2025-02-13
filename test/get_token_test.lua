local lu = require('luaunit')
local libjwt = require('../lib/resty/libjwt')

function TestShouldReturnErrorWhenNotFindingTheToken()
    local headers = {
        ["header_token"] = "token 123",
    }
    local result, err = libjwt.get_token(headers, "header89")
    lu.assertEquals(err, "token not found")
    lu.assertEquals(result, nil )

    local headers = {
        ["header_token"] = "token123",
    }
    local result, err = libjwt.get_token(headers, "header_token")
    lu.assertEquals(err, "token not found")
    lu.assertEquals(result, nil )
end

function TestShouldNotReturnErrorWhenCorrectParameters()
    local headers = {
        ["token"] = "token 123",
    }
    local result, err = libjwt.get_token(headers, "token")
    lu.assertEquals(err, "")
    lu.assertEquals(result, "123" )
end


os.exit( lu.LuaUnit.run() )
