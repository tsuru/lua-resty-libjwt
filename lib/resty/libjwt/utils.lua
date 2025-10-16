local _M = {}

function _M.get_params(params)
    local result = {
        header_token = "Authorization",
        jwks_files = {},
        return_unauthorized_default = true,
        extract_claims = {},
        validate_claims = {},
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
    if params["return_unauthorized_default"] ~= nil then
        result.return_unauthorized_default = params["return_unauthorized_default"]
    end
    if params["extract_claims"] ~= nil then
        if type(params["extract_claims"]) ~= "table" then
            return nil, "extract_claims is not an array"
        end
        result.extract_claims = params["extract_claims"]
    end
    if params["validate_claims"] ~= nil then
        if type(params["validate_claims"]) ~= "table" then
            return nil, "validate_claims is not an array"
        end
        result.validate_claims = params["validate_claims"]
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

local function validate_claims_inner(validate_claims, claims)
    for claim_name, validation in pairs(validate_claims) do
        local claim_value = claims[claim_name]
        if claim_value == nil then
            return "Claim '" .. claim_name .. "' is missing"
        end
        if validation.exact ~= nil then
            if claim_value ~= validation.exact then
                return "Claim '" .. claim_name .. "' must be exactly '" .. validation.exact .. "'"
            end
        end
        if validation.one_of ~= nil then
            local found = false
            for _, allowed_value in ipairs(validation.one_of) do
                if claim_value == allowed_value then
                    found = true
                    break
                end
            end
            if not found then
                return "Claim '" .. claim_name .. "' must be one of the allowed values"
            end
        end
        if validation.pattern ~= nil then
            if not string.match(claim_value, validation.pattern) then
                return "Claim '" .. claim_name .. "' does not match required pattern"
            end
        end
    end
    return ""
end

local function is_array_of_tables(t)
    if type(t) ~= "table" then
        return false
     end

    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end

        if type(t[i]) ~= "table" then
            return false
        end

    end
    return true
end

function _M.validate_claims(validate_claims, claims)
    if not validate_claims then return "" end

    if is_array_of_tables(validate_claims) then
        local errors = {}
        for i, v in ipairs(validate_claims) do

            local result = validate_claims_inner(v, claims)
            if result == "" then return "" end

            table.insert(errors, "validate_claims constraint number " .. i ..
                             ": " .. result)
        end

        return table.concat(errors, " OR ")
    end

    return validate_claims_inner(validate_claims, claims)
end

return _M
