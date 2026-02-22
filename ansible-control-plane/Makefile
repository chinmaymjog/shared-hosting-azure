# Makefile for automatically deploying Ansible Semaphore via Docker Compose

.PHONY: all deploy clean status logs

all: deploy

deploy:
	@echo "Checking for Docker..."
	@docker --version || (echo "Docker not found! Please install Docker first." && exit 1)
	@echo "Checking for Docker Compose..."
	@docker compose version || (echo "Docker Compose not found! Please install Docker Compose first." && exit 1)
	@echo "Ensuring required directories exist..."
	@mkdir -p vars site-data backup
	@echo "Building custom Semaphore image..."
	@docker compose build
	@echo "Starting Ansible Semaphore..."
	@docker compose up -d
	@echo "\n======= SEMAPHORE DEPLOYMENT COMPLETE ======="
	@echo "Access the UI at: http://<bastion-public-ip>:3000"
	@echo "Username: admin"
	@echo "Password: Password123!"

status:
	@docker compose ps

logs:
	@docker compose logs -f

clean:
	@echo "Stopping Semaphore and removing persistent data..."
	@docker compose down -v || true
