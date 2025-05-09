# 宿主安装/卸载
~~~
curl -sSL https://raw.githubusercontent.com/chihqiang/docker-openresty/main/install.sh | bash
curl -sSL https://raw.githubusercontent.com/chihqiang/docker-openresty/main/uninstall.sh | bash
~~~

# alpine
~~~~
docker build -t  zhiqiangwang/openresty:latest  .
~~~~

# luarocks包管理

~~~
# 安装第三方包
ARG LUAROCKS_VERSION=3.9.0
RUN apk add --no-cache --virtual .build-deps perl-dev
RUN apk add --no-cache bash build-base libintl linux-headers make musl outils-md5 perl unzip wget gettext curl
RUN cd /tmp && curl -fSL https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o luarocks-${LUAROCKS_VERSION}.tar.gz && \
    tar -xzvf luarocks-${LUAROCKS_VERSION}.tar.gz && \
    cd luarocks-${LUAROCKS_VERSION} && \
    ./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit --lua-suffix=jit-2.1.0-beta3 --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
    make build && make install
# 将luarocks包管理工具加入到环境变量中
ENV PATH=$PATH:/usr/local/openresty/luajit/bin
~~~

