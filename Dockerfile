FROM alpine:3.15
# 依赖安装
RUN apk --no-cache add curl
# 安装openresty
# http://openresty.org/cn/linux-packages.html#alpine
RUN cd /tmp && wget http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub \
    && mv admin@openresty.com-5ea678a6.rsa.pub /etc/apk/keys/ \
    && . /etc/os-release \
    && echo "http://openresty.org/package/alpine/v3.15/main" | tee -a /etc/apk/repositories \
    && apk update \
    && apk --no-cache add openresty openresty-resty openresty-restydoc openresty-static openresty-dbg openresty-pcre

RUN ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log
# 将openresty加入到环境变量中
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"
ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# 基础扩展库
COPY lua/lualib/ /usr/local/openresty/lualib/resty/
# uuid
COPY lua/uuid.lua /usr/local/openresty/nginx/conf/uuid.lua

# 重制nginx配置文件
ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY conf.d/default.conf /usr/local/openresty/nginx/conf/conf.d/

# nginx环境变量
ENV NGINX_CONF_PATH=
# 将本地的sh录入到docker中
ADD entrypoint.sh /
# 将entrypoint.sh 设置可执行
RUN chmod +x /entrypoint.sh
# 工作目录
WORKDIR /usr/local/openresty/nginx/html
# 下载openresty ico
RUN wget -O /usr/local/openresty/nginx/html/favicon.ico http://openresty.org/favicon.ico
# 开放端口
EXPOSE 80 443
# 删除缓存
RUN rm -rf /var/cache/apk/* /tmp/*
# shell不允许被覆盖
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT