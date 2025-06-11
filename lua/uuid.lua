-- install lua package
-- 
-- luarocks install lua-resty-jit-uuid
-- 
-- curl -fSL https://raw.githubusercontent.com/thibaultcha/lua-resty-jit-uuid/master/lib/resty/jit-uuid.lua  -o /usr/local/openresty/lualib/resty/jit-uuid.lua
-- 
-- luarocks install lua-resty-cookie
-- 
-- curl -fSL https://raw.githubusercontent.com/cloudflare/lua-resty-cookie/master/lib/resty/cookie.lua -o /usr/local/openresty/lualib/resty/cookie.lua
-- 

-- curl -fSL https://raw.githubusercontent.com/chihqiang/docker-openresty/main/lua/uuid.lua -o /usr/local/openresty/nginx/conf/uuid.lua
-- 
-- 将此文件放在/usr/local/openresty/nginx/conf/目录下
-- http {
--     .............................
--     header_filter_by_lua_file conf/uuid.lua;
--     .............................
-- }
-- 引入 uuid 库
local uuidlib = require('resty.jit-uuid')
-- 引入 cookie 库
local cookielib = require "resty.cookie"
-- 创建 cookie 对象
local cookie, err = cookielib:new()
if not cookie then
    -- 如果创建 cookie 对象失败则记录日志并退出
    ngx.log(ngx.ERR, err)
end
-- 获取所有的请求头
local headers = ngx.req.get_headers()
-- 获取 header 中的 uuid
local uuid_from_header = headers["_uuid"]
-- 获取 cookie 中的 uuid
local uuid_from_cookie, err = cookie:get("_uuid")

if uuid_from_cookie then
    uuid = uuid_from_cookie
    ngx.header['_uuid'] = uuid
else
    -- 如果 uuid 不存在于 cookie 中则生成新的 uuid，并将其存储到 cookie 中
    local uuid = uuid_from_header or uuidlib.generate_v4()
    local ok, err = cookie:set({
        key = "_uuid",
        value = uuid,
        path = "/",
        http_only = true,
        secure = true,
        max_age = 60*60*24*365 -- 一年过期
    })
    ngx.header['_uuid'] = uuid
    if not ok then
        -- 如果存储失败则记录日志
        ngx.log(ngx.ERR, err)
    end
end
