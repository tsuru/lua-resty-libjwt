FROM debian:12.9

WORKDIR /home/app
RUN apt update
RUN apt install -y git cmake \
    make \
    gcc g++ \
    pkg-config\
    libjansson-dev \
    libssl-dev 

RUN git clone --depth 1 --branch master https://github.com/benmcollins/libjwt.git && \
    mkdir libjwt/build && \
    cd libjwt/build && cmake .. && make && make install


## install openresty-valgrind

RUN DEBIAN_FRONTEND=noninteractive apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    ca-certificates \
    gettext-base \
    gnupg2 \
    lsb-base \
    lsb-release \
    software-properties-common \
    wget gnupg ca-certificates
RUN wget -qO - "https://openresty.org/package/pubkey.gpg" | gpg --dearmor > /etc/apt/trusted.gpg.d/openresty-keyring.gpg \
    && chown root:root /etc/apt/trusted.gpg.d/openresty-keyring.gpg \
    && chmod ugo+r /etc/apt/trusted.gpg.d/openresty-keyring.gpg \
    && chmod go-w /etc/apt/trusted.gpg.d/openresty-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/openresty-keyring.gpg] https://openresty.org/package/debian $(grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release) openresty" | tee /etc/apt/sources.list.d/openresty.list

ENV PATH="$PATH:/usr/local/openresty-valgrind/luajit/bin:/usr/local/openresty-valgrind/nginx/sbin:/usr/local/openresty-valgrind/bin"


# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openresty-valgrind valgrind

RUN mkdir -p /var/run/openresty \
    && ln -sf /dev/stdout /usr/local/openresty-valgrind/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty-valgrind/nginx/logs/error.log

RUN DEBIAN_FRONTEND=noninteractive apt update \
    && DEBIAN_FRONTEND=noninteractive  apt install -y cpanminus valgrind libjansson-dev

RUN cpanm -v --notest Test::Nginx

COPY ./lib/resty/libjwt /usr/local/openresty/lualib/resty/libjwt
COPY ./lib/resty/libjwt /usr/local/openresty-valgrind/lualib/resty/libjwt

WORKDIR /
COPY ./tokens/jwks.json /usr/share/tokens/jwks.json
COPY ./.memory_leak/test /t
COPY ./.memory_leak/valgrind.suppress /valgrind.suppress
COPY ./.memory_leak/valgrind.awk /valgrind.awk
COPY ./.memory_leak/test_memory_leak.sh /test_memory_leak.sh
CMD ["/bin/bash", "-c", "/test_memory_leak.sh"]