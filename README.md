# Libjwt Module Documentation

## Overview

The **lua-resty-libjwt** module is written in **Lua** with **C** and is designed to validate JWT tokens directly in **Nginx**. This prevents requests from being processed by the API, reducing the load on application servers.

# lua-resty-libjwt
Lua bindings to libjwt (https://github.com/benmcollins/libjwt) using FFI

The module was developed using **OpenResty** and is implemented as a Lua module.

## Configuration and Usage

To use **Libjwt**, you need to provide the path to the **jwks.json** file, which contains the public keys for JWT token verification.

### Configuration Parameters

The module accepts the following parameters:

### `jwks_files` (Required)

- An **array of paths** pointing to files containing **JWKS (JSON Web Key Set)** keys.
- At least one file must be valid; otherwise, an error will be returned.

**Configuration example:**

```lua
libjwt.validate({
    jwks_files = {"/usr/share/tokens/jwks.json"}
})
```

### `header_token` (Optional)

- Defines the **HTTP header field** where the JWT token will be retrieved.
- The default value is **"Authorization"**.
- If the token is in a different header, this value can be modified.

**Example:**

```lua
libjwt.validate({
    jwks_files = {"/usr/share/tokens/jwks.json"},
    header_token = "X-Custom-Token"
})
```

### `return_unauthorized_default` (Optional)

- Defines whether a **401 Unauthorized** response should be automatically returned if the token is invalid.
- The default value is **true** (automatically generates an error).
- If set to **false**, the error must be handled manually in `nginx.conf`.

**Example:**

```lua
libjwt.validate({
    jwks_files = {"/usr/share/tokens/jwks.json"},
    return_unauthorized_default = false
})

```

If `return_unauthorized_default` is **false**, the error must be handled directly:

```lua
local claim, err = libjwt.validate({
    jwks_files = {"/usr/share/tokens/jwks.json"},
    return_unauthorized_default = false
})
```

## Example Nginx Configuration

Here is an example of how to configure **libjwt** in `nginx.conf`:

```perl
server {
    listen 80;
    location /private {
        access_by_lua_block {
            local libjwt = require("resty.libjwt")
            local token, err = libjwt.validate({
                jwks_files = {"/usr/share/tokens/jwks.json"}
            })
            if token then
                -- You may add logic as needed, accessing the JWT claims:
                -- token.claim.sub
                -- token.claim.iss
            end
        }

        proxy_pass http://your_backend;
    }
}

```

### JWT Token Validation

The `libjwt.validate()` function returns the **decoded claim** of the token or an error if the token is invalid.

**Example:**

```lua
local claim, err = libjwt.validate()
if claim then
    ngx.log(ngx.ERR, "Valid JWT token: ", claim)
else
    ngx.log(ngx.ERR, "Token validation error: ", err)
end

```

## Final Considerations

- Ensure that the **jwks.json** file is accessible by Nginx.
- If using a **custom header_token**, make sure the client is sending it correctly.
- The module improves system efficiency by preventing unauthorized requests from reaching the API.