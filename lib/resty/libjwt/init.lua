local jwks_c = require("resty.libjwt.jwks_c")
local utils = require("resty.libjwt.utils")
local cached = require("resty.libjwt.cached")
local decode = require("resty.libjwt.decode")
local cjson = require("cjson.safe")
local ffi = require("ffi")
local _M = {}
local ngx = ngx

local open = io.open
function _M.read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

local TOKEN_VALID = 0
function _M.validate(user_params)
    local params, err = utils.get_params(user_params)
    if params == nil then
        return false, _M.response_error(err, false)
    end
    if err ~= "" then
        return false, _M.response_error(err, params.return_unauthorized_default)
    end
    local headers = ngx.req.get_headers()

    local token
    token, err = utils.get_token(headers, params.header_token)
    if err ~= "" then
        return false, _M.response_error(err, params.return_unauthorized_default)
    end
    local parsed_token
    parsed_token, err = decode.jwt(token)
    if err ~= nil then
        return nil, _M.response_error(err, params.return_unauthorized_default)
    end
    if parsed_token == nil or parsed_token.header.kid == nil then
        return nil, _M.response_error("kid not found", params.return_unauthorized_default)
    end

    local files_cached = cached:getInstance()
    for _, jwks_file in ipairs(params.jwks_files) do
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
        ffi.gc(jwks_set, jwks_c.jwks_free);
        local checker = jwks_c.jwt_checker_new();
        ffi.gc(checker, jwks_c.jwt_checker_free);
        local jwks_item = jwks_c.jwks_find_bykid(jwks_set, parsed_token.header.kid);
        if jwks_item == nil then
            goto continue
        end
        local alg = jwks_c.jwks_item_alg(jwks_item);

        if alg == jwks_c.JWT_ALG_NONE then
            return nil, _M.response_error("No algorithm found on jwks", params.return_unauthorized_default)
        end

        if alg == jwks_c.JWT_ALG_INVAL then
            return nil, _M.response_error("invalid algorithm found on jwks", params.return_unauthorized_default)
        end

        jwks_c.jwt_checker_setkey(checker, alg, jwks_item);
        local result = jwks_c.jwt_checker_verify(checker, token);
        if result == TOKEN_VALID then
            return parsed_token, ""
        end
        ::continue::
    end
    return nil, _M.response_error("invalid token", params.return_unauthorized_default)
end

function _M.response_error(error_message, return_unauthorized_default)
    if return_unauthorized_default == true then
        ngx.header.content_type = "application/json; charset=utf-8"
        local response = {
            message = error_message
        }
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(cjson.encode(response))
        ngx.exit(ngx.status)
    end
    return error_message
end

return _M
