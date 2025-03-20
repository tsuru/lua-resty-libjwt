local jwks_c = require("resty.libjwt.jwks_c")
local utils = require("resty.libjwt.utils")
local cached = require("resty.libjwt.cached")
local decode = require("resty.libjwt.decode")
local cjson = require("cjson.safe")
local ffi = require("ffi")
local _M = {}
local ngx = ngx

local open = io.open
local function _read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

local TOKEN_VALID = 0
local JWKS_CACHE_TTL = 300

local function _authenticate(params)
    local headers = ngx.req.get_headers()
    local token, err

    token, err = utils.get_token(headers, params.header_token)
    if err ~= "" then
        return nil, err
    end
    local parsed_token
    parsed_token, err = decode.jwt(token)
    if err ~= nil then
        return nil, err
    end
    if parsed_token == nil or parsed_token.header.kid == nil then
        return nil, "kid not found"
    end

    local files_cached = cached:getInstance()
    for _, jwks_file in ipairs(params.jwks_files) do
        local jwks_set = files_cached:get(jwks_file)
        if jwks_set == nil then
            local file = _read_file(jwks_file)
            if file == nil then
                goto continue
            end
            jwks_set = jwks_c.jwks_create(file);
            ffi.gc(jwks_set, jwks_c.jwks_item_free_all);
            files_cached:set(jwks_file, jwks_set, JWKS_CACHE_TTL)
        end
        local checker = jwks_c.jwt_checker_new();
        ffi.gc(checker, jwks_c.jwt_checker_free);
        local jwks_item = jwks_c.jwks_find_bykid(jwks_set, parsed_token.header.kid);
        if jwks_item == nil then
            goto continue
        end
        local alg = jwks_c.jwks_item_alg(jwks_item);

        if alg == jwks_c.JWT_ALG_NONE then
            return nil, "No algorithm found on jwks"
        end

        if alg == jwks_c.JWT_ALG_INVAL then
            return nil, "invalid algorithm found on jwks"
        end

        jwks_c.jwt_checker_setkey(checker, alg, jwks_item);
        local result = jwks_c.jwt_checker_verify(checker, token);
        if result == TOKEN_VALID then
            return parsed_token, ""
        end
        ::continue::
    end

    return nil, "invalid token"
end

local function _extract_claims(token, params)
    for _, claim in ipairs(params.extract_claims) do
        if token.claim[claim] ~= nil then
            ngx.var["jwt_" .. claim] = token.claim[claim]
        end
    end
end

local function _response_error(error_message, return_unauthorized_default, status)
    if return_unauthorized_default == true then
        ngx.header.content_type = "application/json; charset=utf-8"
        local response = {
            message = error_message
        }
        ngx.status = status
        ngx.say(cjson.encode(response))
        ngx.exit(ngx.status)
    end
    return error_message
end

function _M.validate(user_params)
    if ngx.req.get_method() == "OPTIONS" then
        return nil
    end
    local params, err = utils.get_params(user_params)
    if params == nil then
        return nil, _response_error(err, true, ngx.HTTP_UNAUTHORIZED)
    end

    local parsed_token
    parsed_token, err = _authenticate(params)
    if err ~= "" then
        return nil, _response_error(err, params.return_unauthorized_default, ngx.HTTP_UNAUTHORIZED)
    end

    local claims_extracted;
    claims_extracted, err = pcall(_extract_claims, parsed_token, params)
    if not claims_extracted then
        return nil, _response_error(err, params.return_unauthorized_default, ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    err = utils.validate_claims(params.validate_claims, parsed_token.claim)
    if err ~= "" then
        return nil, _response_error(err, params.return_unauthorized_default, ngx.HTTP_FORBIDDEN)
    end

    return parsed_token, ""
end

return _M
