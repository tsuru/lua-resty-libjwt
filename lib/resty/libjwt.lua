local _M = {}

function _M.get_params(params)
    local result = {
        header_token = "Authorization",
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

function _M.validate(params)
    local params, err = _M.get_params(params)
    if err ~= "" then
        return nil, err
    end
    return false, "Not implemented"
end




return _M