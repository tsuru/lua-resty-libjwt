local b64 = require("ngx.base64")
local cjson = require("cjson.safe")
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

function _M.decode_jwt(jwt)
    local header_b64, payload_b64, signature_b64 = jwt:match("([^%.]+)%.([^%.]+)%.([^%.]+)")
    if not (header_b64 and payload_b64 and signature_b64) then
        error("JWT invalid")
    end

    local header, err = b64.decode_base64url(header_b64)
    if err then
        return nil, err
    end

    local payload, err = b64.decode_base64url(payload_b64)
    if err then
        return nil, err
    end

    local header_json = cjson.decode(header)
    if not header_json then
        return nil, "Failed to parse header JSON"
    end

    local claim_json = cjson.decode(payload)
    if not claim_json then
        return nil, "Failed to parse payload JSON"
    end

    return {
        header = header_json,
        claim = claim_json,
        signature_b64 = signature_b64,
    }, nil
end

return _M
