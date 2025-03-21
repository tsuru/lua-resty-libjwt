# lua-resty-libjwt

[![LuaRocks](https://img.shields.io/badge/LuaRocks-lua--resty--libjwt-blue.svg)](https://luarocks.org/modules/tsuru/lua-resty-libjwt)

## Overview

The **lua-resty-libjwt** module is a **Lua** library with **C** bindings that validates JWT tokens directly in **Nginx**. Built with **OpenResty** and leveraging **FFI** (Foreign Function Interface), it provides Lua bindings to [libjwt](https://github.com/benmcollins/libjwt). By handling JWT validation at the Nginx level, it prevents unauthorized requests from reaching the API, reducing the load on application servers.

## Requirements

* [Nginx](https://nginx.org) with the [Lua module](https://github.com/openresty/lua-nginx-module)
* [libjwt](https://github.com/benmcollins/libjwt) (≥ 3.2.0)
* [lua-cjson](https://luarocks.org/modules/openresty/lua-cjson) (≥ 2.1.0)

## Install

You can easily install it with [Luarocks](https://luarocks.org):

```bash
luarocks install lua-resty-libjwt
```

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
local token, err = libjwt.validate({
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
local token, err = libjwt.validate()
if token then
    ngx.log(ngx.ERR, "Valid JWT token: ", token)
else
    ngx.log(ngx.ERR, "Token validation error: ", err)
end

```

### Claims-based Authorization

Some backends are restricted so that only certain users can access them, allowing us to restrict access based on [Claims].

See the Lua configuration `validate_claims` below:

```lua
local libjwt = require("resty.libjwt")
libjwt.validate({
    jwks_files = {"/etc/nginx/jwks.json"},
    validate_claims = {
        iss = {exact = "myiss"},
        aud = {one_of = {"audience1", "audience2"}},
        sub = {pattern = ".*@mycompany%.com"},
    },
})
```

#### Validation Types

Note that we have 3 types of validations:

* `{exact = "TERM"}`: ensures that a claim must be exactly equal to TERM, otherwise the user will receive a 403 (Forbidden)
* `{one_of = {"TERM1", "TERM2"}}`: allows a list of permitted CLAIMS, if not in the list the user will receive a 403 (Forbidden)
* `{pattern = ".*@mycompany%.com"}`: Allows validation using [Lua Pattern Matching](https://www.lua.org/pil/20.2.html), an expression language similar to Regex. In the example above, we can ensure that only users from the mycompany.com domain can access; if the expression doesn't match, the user will receive a 403 (Forbidden)


## Final Considerations

- Ensure that the **jwks.json** file is accessible by Nginx.
- If using a **custom header_token**, make sure the client is sending it correctly.
- The module improves system efficiency by preventing unauthorized requests from reaching the API.