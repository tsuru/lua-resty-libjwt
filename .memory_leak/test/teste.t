# vim:set ft= ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(10);
run_tests();

__DATA__

=== TEST 1: sanity (string)
--- config
    location /private {
        content_by_lua_block {
            local libjwt = require("resty.libjwt")
            local cjson = require("cjson.safe")
            local token, err = libjwt.validate({
                jwks_files = {"/usr/share/tokens/jwks.json"},
            })
            if token then
                ngx.status = ngx.HTTP_OK
                local response = {
                    message = "ok"
                }
                return ngx.say(cjson.encode(response))
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
--- more_headers
Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImtpZC10c3VydSIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwiZW1haWwiOiJ0c3VydUB0c3VydS5jb20iLCJleHAiOjIwNTY5OTA3ODEsImlhdCI6MTc0MTYzMDc4MSwibmFtZSI6IlRzdXJ1Iiwic3ViIjoiMTIzNDU2Nzg5MCJ9.osEVAXF1ysV3pwoeOwaPSZK97AzMDMqCD-cyZ4ALHhLatBHszXrPqn6sJxUQdvET_RK0IJyJd15mw-Y1EMZ6WLKBjeV_iWuapQ9-7gh6sQoloZZ0V0ZNfXlbqCGoTXHb-xInFsGEgV6rj4R-5Sl1r96UiYpLdav8GmT3lKrRPILCLvihXFtiuhrUX1rmNhbiKqlIDyAPtG8rjqQzqEDqKkYH2bApjSrgsyevG9do31vbnEljukON-Hc5MgQK7zr4ZF3Ozi4m0JRy3jeIWVzpsWm9dRnTb9mcOfuY5EQP7NhFBXu-H4H-RwvStfZhfN8J9FbOR8jGEEDhUYHsLaRXNQ
--- response_body
{"message":"ok"}
--- no_error_log
[error]