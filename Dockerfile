FROM rust:1.83-slim AS builder

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libaio1 \
        unzip \
        curl \
        python3.11 \
        python3.11-dev \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*


RUN pip3 install --break-system-packages --no-cache-dir maturin==1.4.0


RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip && \
    [ -f instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip ] || { echo "Basic Light download failed"; exit 1; } && \
    mkdir -p /opt/oracle && \
    unzip instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip -d /opt/oracle && \
    rm instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip

RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-tools-linux.x64-21.9.0.0.0dbru.zip && \
    [ -f instantclient-tools-linux.x64-21.9.0.0.0dbru.zip ] || { echo "Tools download failed"; exit 1; } && \
    unzip instantclient-tools-linux.x64-21.9.0.0.0dbru.zip -d /opt/oracle && \
    rm instantclient-tools-linux.x64-21.9.0.0.0dbru.zip && \
    [ -f /opt/oracle/instantclient_21_9/sqlldr ] || { echo "sqlldr not found after unzip"; exit 1; }


COPY Cargo.toml Cargo.lock ./
COPY vendor /opt/cargo-vendor
RUN mkdir -p .cargo && \
    printf '[source.crates-io]\nreplace-with = "vendored-sources"\n\n[source.vendored-sources]\ndirectory = "/opt/cargo-vendor"\n[net]\noffline = true\n' \
        > /usr/local/cargo/config.toml

RUN mkdir src && echo "fn main() {}" > src/main.rs
ENV PYO3_PYTHON=/usr/bin/python3.11    
RUN cargo fetch --locked && cargo build --release && rm -rf src

ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_21_9:${LD_LIBRARY_PATH:-}"
ENV ORACLE_HOME="/opt/oracle/instantclient_21_9"
ENV PATH="/opt/oracle/instantclient_21_9:$PATH"


FROM builder AS rust_offline_oracle_base


