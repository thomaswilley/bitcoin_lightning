# syntax=docker/dockerfile:1
FROM ubuntu:22.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for the Bitcoin version
ENV BITCOIN_VERSION=25.0
ENV BITCOIN_URL=https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz

# Download and extract Bitcoin Core
RUN wget ${BITCOIN_URL} -O bitcoin.tar.gz && \
    tar -xzf bitcoin.tar.gz && \
    mv bitcoin-${BITCOIN_VERSION} /opt/bitcoin && \
    rm bitcoin.tar.gz

# Add Bitcoin Core binaries to the PATH
ENV PATH="/opt/bitcoin/bin:${PATH}"

# Expose Bitcoin ports (RPC, P2P)
EXPOSE 8332 8333

# Create a volume for Bitcoin data (matches the location used in entrypoint.sh)
VOLUME ["/root/.bitcoin"]

# Copy the entrypoint script into the image
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the entrypoint script as the container's entrypoint.
ENTRYPOINT ["/entrypoint.sh"]
