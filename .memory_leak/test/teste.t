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
    location /public {
        default_type application/json;
        return 200 '{"message": "Hello, World!"}\n';
    }
--- request
GET /public
--- response_body
{"message": "Hello, World!"}

=== TEST 3: sanity (string)
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