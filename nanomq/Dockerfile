ARG BUILD_FROM

FROM ${BUILD_FROM}

ARG NANOMQ_VERSION=master

RUN apk add --no-cache --virtual .build-deps \
        git \
        cmake \
        samurai \
        clang \
        clang-static \
        clang-dev \
        llvm-dev \
        llvm-static \
    && apk add --no-cache \
        mbedtls-dev \
        pwgen \
    && git clone --recurse-submodules --shallow-submodules -b ${NANOMQ_VERSION} https://github.com/nanomq/nanomq \
    && mkdir nanomq/build && cd nanomq/build \
    && cmake \
        -DNNG_ENABLE_TLS=ON \
        -DBUILD_BENCH=ON \
        -DNNG_ENABLE_SQLITE=ON \
        -DENABLE_RULE_ENGINE=ON \
        -DENABLE_ACL=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        .. \
    && ninja install \
    && cd / \
    && rm -rf /nanomq \
    && apk del .build-deps

ADD rootfs /
