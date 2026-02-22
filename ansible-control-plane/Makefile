# Makefile for automatically deploying AWX via Docker Compose

AWX_VERSION ?= 24.6.1
AWX_REPO = https://github.com/ansible/awx.git
CLONE_DIR = /tmp/awx

.PHONY: all deploy prepare install clean

all: deploy

prepare:
	@echo "Checking for Docker..."
	@docker --version || (echo "Docker not found! Please install Docker first." && exit 1)
	@echo "Checking for Docker Compose..."
	@docker compose version || (echo "Docker Compose not found! Please install Docker Compose first." && exit 1)

install:
	@echo "Cloning official AWX repository (Version: $(AWX_VERSION))..."
	@rm -rf $(CLONE_DIR)
	@git clone -b $(AWX_VERSION) $(AWX_REPO) $(CLONE_DIR)
	
	@echo "Generating custom inventory file..."
	@cp inventory.template $(CLONE_DIR)/tools/docker-compose/inventory
	@echo "Admin password set. Generating secret key..."
	@sed -i "s/__AWX_SECRET_KEY__/$$(openssl rand -base64 30 | tr -dc 'a-zA-Z0-9' | head -c 30)/g" $(CLONE_DIR)/tools/docker-compose/inventory
	
deploy: prepare install
	@echo "Building AWX Docker Compose..."
	@cd $(CLONE_DIR) && make docker-compose-build
	@echo "Starting AWX..."
	@cd $(CLONE_DIR) && make docker-compose
	@echo "\n======= AWX DEPLOYMENT COMPLETE ======="
	@echo "AWX takes about 2-3 minutes to initialize its database migrations."
	@echo "Access the UI at: http://<bastion-public-ip>:8013"
	@echo "Username: admin"
	@echo "Password: Password123!"

clean:
	@echo "Stopping AWX and removing persistent data..."
	@cd $(CLONE_DIR) && make docker-compose-down || true
	@cd $(CLONE_DIR) && make docker-clean-volumes || true
	@rm -rf $(CLONE_DIR)
