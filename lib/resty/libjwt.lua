local jwks_c = require("resty.jwks_c")

local _M = {}

function _M.get_params(params)
    local result = {
        header_token = "Authorization",
        jwks_files = {},
    }
    if params == nil then
        return nil, "params is required"
    end

    if params["header_token"] ~= nil then
        result.header_token = params["header_token"]
    end
    if params["jwks_files"] == nil then
        return nil, "jwks_files is required"
    end
    if type(params["jwks_files"]) ~= "table" then
        return nil, "jwks_files is not an array"
    end
    result.jwks_files = params["jwks_files"]
    return result, ""
end


function _M.split(str, sep)
    if str == "" or str == nil then
        return nil, "param is required"
    end
    if type(str) ~= "string" then
        return nil, "param should be a string"
    end
    if type(sep) ~= "string" or sep == "" then
        return nil, "separator should be a string"
    end
    local result = {}
    for match in (str .. sep):gmatch("(.-)" .. sep) do
        table.insert(result, match)
    end
    return result, ""
end


local open = io.open
function _M.read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end


function _M.get_token(headers, field_token)
    local auth_header = headers[field_token]
    local jwtToken, err = _M.split(auth_header, " ")
    if err == "param is required" then
        return nil, "token not found"
    end
    if err ~= "" then
        return nil, err 
    end
    if jwtToken[2] == nil then
        return nil, "token not found"
    end
    return jwtToken[2], ""
end

function _M.validate( params)
    local params, err = _M.get_params(params)
    if err ~= "" then
        return false, err
    end

    local headers = ngx.req.get_headers()
    local token, err = _M.get_token(headers, params.header_token)
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