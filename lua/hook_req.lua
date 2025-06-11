
-- 
-- curl -fSL https://raw.githubusercontent.com/chihqiang/docker-openresty/main/lua/hook_req.lua -o /usr/local/openresty/nginx/conf/hook_req.lua
-- 
-- 
-- 将此文件放在/usr/local/openresty/nginx/conf/目录下
-- http {
--     .............................
--      error_log /usr/local/openresty/nginx/logs/access.log debug;
--      access_by_lua_file conf/hook_req.lua;
--     .............................
-- }

-- 加载 cjson.safe 模块，用于安全的 JSON 编码和解码
local cjson = require "cjson.safe"

-- 读取请求体，必须调用此方法后，才能通过 ngx.req.get_body_data() 或 ngx.req.get_post_args() 获取请求体内容
ngx.req.read_body()

-- 定义函数：获取当前时间，格式为 "YYYY-MM-DD HH:MM:SS"
local function current_time()
    -- 使用 ngx.now() 获取当前时间戳，然后转换为日期表
    local t = os.date("*t", ngx.now())
    -- 格式化时间字符串，保证数字位数和格式统一
    return string.format(
        "%04d-%02d-%02d %02d:%02d:%02d",
        t.year, t.month, t.day, t.hour, t.min, t.sec
    )
end

-- 调用函数获取当前时间字符串
local time_str = current_time()

-- 获取 HTTP 请求方法，若无则返回 "-"
local method = ngx.req.get_method() or "-"

-- 获取请求的完整 URI（含查询字符串），若无则返回 "-"
local uri = ngx.var.request_uri or "-"

-- 获取所有请求头，返回一个表（table）
local headers = ngx.req.get_headers()

-- 获取请求头中的 Content-Type，默认空字符串
local content_type = ngx.var.http_content_type or ""

-- 初始化变量用于保存请求体内容
local body = {}

-- 判断请求 Content-Type 是否为文件上传类型 multipart/form-data
if content_type:find("multipart/form-data", 1, true) then
    -- 文件上传不处理，直接赋空表
    body = { form_data ={} }
else
    -- 读取请求体数据
    local body_data = ngx.req.get_body_data()
    if content_type:find("application/json", 1, true) then
        -- 尝试解码 JSON，失败则赋空表
        body = cjson.decode(body_data or "") or {}
    elseif content_type:find("application/x-www-form-urlencoded", 1, true) then
        local post_args, err = ngx.req.get_post_args()
        if not post_args then
            -- 解析失败时，body 直接赋空表，不记录错误
            body = { form = {} }
        else
            body = { form = post_args }
        end
    elseif body_data then
        -- 其他类型原样放入 raw 字段
        body = { raw = body_data }
    else
        body = {}
    end
end


-- 构造日志行，包含时间、请求方法、URI、请求头及请求体（均为 JSON 格式字符串）
local log_line = string.format(
    "%s %s %s H:%s data:%s",
    time_str,
    method,
    uri,
    cjson.encode(headers),
    cjson.encode(body)
)

-- 将日志写入 Nginx error_log，日志级别为 DEBUG
ngx.log(ngx.DEBUG, "[hook_req]", log_line)
