local b64 = require("ngx.base64")
local cjson = require("cjson.safe")

local _M = {}

function _M.jwt(jwt)
    local header_b64, payload_b64, signature_b64 = jwt:match("([^%.]+)%.([^%.]+)%.([^%.]+)")
    if not (header_b64 and payload_b64 and signature_b64) then
        return nil, "JWT invalid"
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
