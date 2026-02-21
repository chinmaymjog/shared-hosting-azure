FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies (Minimal)
RUN apt-get update && apt-get install -y \
    wget sudo mysql-client software-properties-common \
    fontconfig openjdk-17-jre less vim \
    python3 python3-pip python3-venv \
    openssh-client sshpass && \
    # Setup Jenkins Repository
    mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key && \
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null && \
    apt-get update -qq && \
    apt-get install -y -qq jenkins && \
    # Sudoers setup
    echo "jenkins ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/jenkins && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup Ansible VENV
# We create it, install everything, then give ownership to jenkins
RUN python3 -m venv /opt/ansible-venv && \
    /opt/ansible-venv/bin/pip install --upgrade pip && \
    /opt/ansible-venv/bin/pip install ansible pymysql az-cli && \
    /opt/ansible-venv/bin/pip install -r https://raw.githubusercontent.com/ansible-collections/azure/refs/heads/dev/requirements.txt
# 3. Environment & Paths
ENV PATH="/opt/ansible-venv/bin:$PATH"

EXPOSE 8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]