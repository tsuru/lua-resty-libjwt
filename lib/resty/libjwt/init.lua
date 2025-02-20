local jwks_c = require("resty.libjwt.jwks_c")
local utils = require("resty.libjwt.utils")
local cached = require("resty.libjwt.cached")

local _M = {}

local open = io.open
function _M.read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

local TOKEN_VALID = 0
function _M.validate(params)
    local params, err = utils.get_params(params)
    if err ~= "" then
        return false, err
    end
    local headers = ngx.req.get_headers()
    local token, err = utils.get_token(headers, params.header_token)
    if err ~= "" then
        return false, err
    end
    local parsed_token, err = utils.decode_jwt(token)
    if err ~= nil then
        return nil, err
    end
    if parsed_token == nil or parsed_token.header.kid == nil then
        return nil, "kid not found"
    end

    local files_cached = cached:getInstance()
    for i, jwks_file in ipairs(params.jwks_files) do
        local file
        if files_cached:get(jwks_file) == nil then
            file = _M.read_file(jwks_file)
            if file == nil then
                goto continue
            end
            files_cached:set(jwks_file, file)
        else
            file = files_cached:get(jwks_file)
        end
        local jwks_set = jwks_c.jwks_create(file);
        local checker = jwks_c.jwt_checker_new();
        local jwks_item = jwks_c.jwks_find_bykid(jwks_set, parsed_token.header.kid);
        if jwks_item == nil then
            goto continue
        end
        jwks_c.jwt_checker_setkey(checker, jwks_c.JWT_ALG_RS256, jwks_item);
        local result = jwks_c.jwt_checker_verify(checker, token);
        if result == TOKEN_VALID then
            return parsed_token, ""
        end
        ::continue::
    end
    return nil, "token not valid"
end

return _M
