# syntax=docker/dockerfile:1
#
# Build args:
#   NGSPICE_VARIANT  stable | dev          (default: stable)
#   NGSPICE_VERSION  release number        (default: 46, ignored for dev)
#
# Examples:
#   docker build .                                         # stable 46
#   docker build --build-arg NGSPICE_VERSION=45 .         # stable 45
#   docker build --build-arg NGSPICE_VARIANT=dev .        # latest master

ARG NGSPICE_VARIANT=stable
ARG NGSPICE_VERSION=46

# ── Builder ────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS builder

ARG NGSPICE_VARIANT
ARG NGSPICE_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        git \
        ca-certificates \
        bison \
        flex \
        libreadline-dev \
        libfftw3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN if [ "$NGSPICE_VARIANT" = "stable" ]; then \
        git clone --depth 1 \
            --branch "ngspice-${NGSPICE_VERSION}" \
            https://git.code.sf.net/p/ngspice/ngspice . ; \
    else \
        git clone --depth 1 \
            https://git.code.sf.net/p/ngspice/ngspice . ; \
    fi

RUN ./autogen.sh && \
    ./configure \
        --prefix=/usr/local \
        --enable-xspice \
        --enable-cider \
        --disable-debug \
        --with-readline=yes \
        --without-x && \
    make -j"$(nproc)" && \
    make install DESTDIR=/install

# ── Runtime ────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libreadline8 \
        libfftw3-double3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install/usr/local /usr/local
RUN ldconfig

ENTRYPOINT ["ngspice"]
