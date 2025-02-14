local jwks_c = require("resty.jwks_c")
local utils = require("resty.utils")
local _M = {}

local open = io.open
function _M.read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

function _M.validate( params)
    local params, err = utils.get_params(params)
    if err ~= "" then
        return false, err
    end
    local headers = ngx.req.get_headers()
    local token, err = utils.get_token(headers, params.header_token)
    if err ~= "" then
        return false, err
    end
    for i, jwks_file in ipairs(params.jwks_files) do
        local jwks = _M.read_file(jwks_file)
        if jwks == nil then
            return false, "jwks file not found"
        end
        local jwks_set = jwks_c.jwks_create(jwks);
        local jwks_item = jwks_c.jwks_item_get(jwks_set, 0);
        local checker = jwks_c.jwt_checker_new();
        jwks_c.jwt_checker_setkey(checker, jwks_c.JWT_ALG_RS256, jwks_item);
        local result = jwks_c.jwt_checker_verify(checker, token);
        if result == 0 then
            return true, ""
        end
    end
    return false, "token not valid"
end

return _M