FROM alpine:3.21.2 as libjwt-builder

WORKDIR /home/app
RUN apk add --no-cache git cmake make gcc g++ jansson-dev openssl-dev 
RUN git clone --depth 1 --branch v3.2.0 https://github.com/benmcollins/libjwt.git && \
    mkdir libjwt/build && \
    cd libjwt/build && cmake .. && make && make install

FROM openresty/openresty:1.25.3.2-3-bullseye-valgrind

RUN apt update
RUN apt install -y cpanminus valgrind libjansson-dev  # Substituí apk por apt
RUN cpanm -v --notest Test::Nginx

COPY ./lib/resty/libjwt /usr/local/openresty/lualib/resty/libjwt
COPY --from=libjwt-builder /usr/local/lib/libjwt.so /usr/local/lib/libjwt.so
RUN ldconfig  # Atualiza cache do linker para garantir que libjwt seja encontrada

COPY ./.memory_leak/test /t
COPY ./.memory_leak/valgrind.suppress /valgrind.suppress
COPY ./.memory_leak/valgrind.awk /valgrind.awk
COPY ./.memory_leak/test_memory_leak.sh /test_memory_leak.sh
CMD ["/bin/bash", "-c", "/test_memory_leak.sh"]
