# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;

repeat_each(10);

plan tests => blocks() * repeat_each() * 2;

run_tests();

__DATA__

=== TEST 1: sanity (integer)
--- config
    location /lua {
        echo 2;
    }
--- request
GET /lua
--- response_body
2

=== TEST 2: sanity (string)
--- config
    location = /t {
        content_by_lua_block {
            local ffi = require("ffi");

            -- Define the C functions we need
            ffi.cdef[[
            void* malloc(size_t size);
            void free(void* ptr);
            ]]

            local leak_size = 1024 * 1024
            -- local ptr = ffi.C.malloc(leak_size);
            ngx.say("testing the tsuru")
        }
    }
--- request
GET /t
--- response_body
testing the tsuru

=== TEST 3: sanity (string)
--- config
    location /private {
        content_by_lua_block {
            local libjwt = require("resty.libjwt")
            local cjson = require("cjson.safe")
            local claim, err = libjwt.validate({
                ["jwks_files"] = {"/usr/share/tokens/jwks.json"},
            })
            if claim then
                local claim_str = cjson.encode(claim) or "Invalid Claim"
                ngx.log(ngx.ERR, "JWT Claims: " .. claim_str)
                ngx.status = ngx.HTTP_OK
                return ngx.say(claim_str)
            end
            ngx.status = ngx.HTTP_UNAUTHORIZED
            local response = {
                message = "Unauthorized"
            }
            return ngx.say(cjson.encode(response))
        }
    }
--- request
GET /private
--- response_body
{"message":"Unauthorized"}
--- no_error_log
[error]