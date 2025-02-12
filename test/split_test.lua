local lu = require('luaunit')
local libjwt = require('../lib/resty/libjwt')


function TestShouldReturnErrorBecauseIsNotStringOfParam()
    local result, err = libjwt.split(1, ",")
    lu.assertEquals(err, "param should be a string" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.split(nil)
    lu.assertEquals(err, "param is required" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.split({}, ",")
    lu.assertEquals(err, "param should be a string" )
    lu.assertEquals(result, nil )
end

function TestShouldReturnErrorBecauseIsNotStringOfSeparator()
    local result, err = libjwt.split("123456", 1)
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.split("123456", {})
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )

    local result, err = libjwt.split("123456", "")
    lu.assertEquals(err, "separator should be a string" )
    lu.assertEquals(result, nil )
end


function TestShouldNotReturnErrorWithValidParameters()
    local result, err = libjwt.split("123456", ",")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123456"} )

    local result, err = libjwt.split("123 456", ",")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123 456"} )

    local result, err = libjwt.split("123 456", " ")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123","456"} )

    local result, err = libjwt.split("123;456", ";")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"123","456"} )

    local result, err = libjwt.split("000; 123", ";")
    lu.assertEquals(err, "" )
    lu.assertEquals(result, {"000"," 123"} )
end



os.exit( lu.LuaUnit.run() )