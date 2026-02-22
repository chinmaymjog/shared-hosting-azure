# Custom Semaphore image with Azure CLI and Python dependencies
FROM semaphoreui/semaphore:v2.10.32

USER root

# Install dependencies for Azure CLI and OpenSSL playbooks
# The base image is Alpine-based
RUN apk update && \
    apk add --no-cache \
    python3 \
    py3-pip \
    py3-cryptography \
    curl \
    bash \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    make

# Install Azure CLI via pip (Alpine friendly)
RUN pip3 install --no-cache-dir azure-cli --break-system-packages

USER semaphore
