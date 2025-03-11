FROM debian:12.9 as libjwt-builder

WORKDIR /home/app
RUN apt update
RUN apt install -y git cmake \
    make \
    gcc g++ \
    pkg-config\
    libjansson-dev \
    libssl-dev 

RUN git clone --depth 1 --branch v3.2.0 https://github.com/benmcollins/libjwt.git && \
    mkdir libjwt/build && \
    cd libjwt/build && cmake .. && make && make install

FROM openresty/openresty:1.25.3.2-3-bullseye-valgrind

RUN apt update
RUN apt install -y cpanminus valgrind libjansson-dev
RUN cpanm -v --notest Test::Nginx

COPY ./lib/resty/libjwt /usr/local/openresty/lualib/resty/libjwt
COPY ./lib/resty/libjwt /usr/local/openresty-valgrind/lualib/resty/libjwt
COPY --from=libjwt-builder /usr/local/lib/libjwt.so /usr/local/lib/libjwt.so
RUN ldconfig

COPY ./.memory_leak/test /t
COPY ./.memory_leak/valgrind.suppress /valgrind.suppress
COPY ./.memory_leak/valgrind.awk /valgrind.awk
COPY ./.memory_leak/test_memory_leak.sh /test_memory_leak.sh
CMD ["/bin/bash", "-c", "/test_memory_leak.sh"]