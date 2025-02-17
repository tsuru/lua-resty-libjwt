local lu = require('luaunit')
local utils = require('../lib/resty/libjwt/utils')


function TestShouldReturnErrorBecauseIsNotStringOfParam()
    local result, err = utils.split(1, ",")
    lu.assertEquals(err, "param should be a string" )
    lu.assertEquals(result, nil )

    local result, err = utils.split(nil)
    lu.assertEquals(err, "param is required" )
    lu.assertEquals(result, nil )

    local result, err = utils.split({}, ",")
    lu.assertEquals(err, "param should be a string" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnErrorBecauseIsNotStringOfSeparator()
    local result, err = utils.split("123456", 1)
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )

    local result, err = utils.split("123456", {})
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )

    local result, err = utils.split("123456", "")
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )
end


function TestShouldNotReturnErrorWithValidParameters()
    local result, err = utils.split("123456", ",")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123456"} )

    local result, err = utils.split("123 456", ",")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123 456"} )

    local result, err = utils.split("123 456", " ")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123","456"} )

    local result, err = utils.split("123;456", ";")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123","456"} )

    local result, err = utils.split("000; 123", ";")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"000"," 123"} )
end

os.exit( lu.LuaUnit.run() )