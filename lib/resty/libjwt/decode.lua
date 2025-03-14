local b64 = require("ngx.base64")
local cjson = require("cjson.safe")

local _M = {}


local function fast_jwt_split(str)
    local first_dot = string.find(str, ".", 1, true)
    if not first_dot then return nil, nil, nil, "invalid JWT" end

    local second_dot = string.find(str, ".", first_dot + 1, true)
    if not second_dot then return nil, nil, nil, "invalid JWT" end

    return str:sub(1, first_dot - 1), str:sub(first_dot + 1, second_dot - 1),
           str:sub(second_dot + 1), nil

end


function _M.jwt(jwt)
    local header_b64, payload_b64, signature_b64, header, err
    header_b64, payload_b64, signature_b64, err = fast_jwt_split(jwt)
    if err then
        return nil, err
    end

    header, err = b64.decode_base64url(header_b64)
    if err then
        return nil, err
    end

    local payload
    payload, err = b64.decode_base64url(payload_b64)
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
