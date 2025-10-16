local lu = require('luaunit')
local utils = require('../lib/resty/libjwt/utils')


function TestShouldReturnErrorPatternInvalid()
    local params = {
        iss = { exact = "tsuru" },
        aud = { one_of = { "audience1", "audience2" } },
        sub = { pattern = ".*@g%.globo" },
    }
    local claims = {
        iss = "tsuru",
        aud = "audience1",
        sub = "tsuru.team",
    }
    local err
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "Claim 'sub' does not match required pattern")
end

function TestShouldReturnErrorOneOfInvalid()
    local params = {
        iss = { exact = "tsuru" },
        aud = { one_of = { "audience1", "audience2" } },
        sub = { pattern = ".*@g%.globo" },
    }
    local claims = {
        iss = "tsuru",
        aud = "audience3",
        sub = "tsuru.team@g.globo",
    }
    local err
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "Claim 'aud' must be one of the allowed values")
end

function TestShouldReturnErrorExactInvalid()
    local params = {
        iss = { exact = "tsuru" },
        aud = { one_of = { "audience1", "audience2" } },
        sub = { pattern = ".*@g%.globo" },
    }
    local claims = {
        iss = "tsuruu",
        aud = "audience1",
        sub = "tsuru.team@g.globo",
    }
    local err
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "Claim 'iss' must be exactly 'tsuru'")
end

function TestShouldReturnOkInValidation()
    local params = {
        iss = { exact = "tsuru" },
        aud = { one_of = { "audience1", "audience2" } },
        sub = { pattern = ".*@g%.globo" },
    }
    local claims = {
        iss = "tsuru",
        aud = "audience1",
        sub = "tsuru.team@g.globo",
    }
    local err
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "")
end

function TestShouldSupportArray()
    local params = {
        {
            iss = {exact = "tsuru"},
            aud = {one_of = {"audience1", "audience2"}},
            sub = {pattern = ".*@g%.globo"}
        }, {
            iss = {exact = "kubernetes"},
            aud = {one_of = {"audience3", "audience4"}},
            sub = {pattern = ".*@corp%.globo%.com"}
        }
    }
    local claims = {
        iss = "tsuru",
        aud = "audience1",
        sub = "tsuru.team@g.globo"
    }
    local err
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "")

    claims = {
        iss = "kubernetes",
        aud = "audience4",
        sub = "kubernetes4.team@corp.globo.com"
    }
    err = utils.validate_claims(params, claims)
    lu.assertEquals(err, "")

    claims = {iss = "tsuru", aud = "audience4", sub = "tsuru.team@g.globo"}
    err = utils.validate_claims(params, claims)
    lu.assertNotEquals(err, "")
end

os.exit(lu.LuaUnit.run())
