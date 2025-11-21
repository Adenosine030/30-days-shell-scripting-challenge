#!/bin/bash

### ------------------------------------
### Day 16: Deployment Script
### Automates pulling latest code, testing, backing up,
### deploying, restarting service, and verifying success
### ------------------------------------

# CONFIGURATION (edit these paths for your machine)
APP_DIR="$HOME/myapp"
BACKUP_DIR="$HOME/myapp_backups"
SERVICE_NAME="myapp.service"      # Example systemd service

# COLORS FOR CLEANER OUTPUT
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${YELLOW}=== Starting Deployment Script ===${NC}"

### ------------------------------------
### 1. BACKUP CURRENT VERSION
### ------------------------------------

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Backing up current version...${NC}"
cp -r "$APP_DIR" "$BACKUP_DIR/app_backup_$TIMESTAMP"

echo -e "${GREEN}Backup created at: $BACKUP_DIR/app_backup_$TIMESTAMP${NC}"


### ------------------------------------
### 2. PULL LATEST CODE
### ------------------------------------

echo -e "${YELLOW}Pulling latest code from Git...${NC}"
cd "$APP_DIR" || exit 1

git pull origin main
if [ $? -ne 0 ]; then
    echo -e "${RED}Git pull failed! Aborting deployment.${NC}"
    exit 1
fi


### ------------------------------------
### 3. RUN TESTS (SIMULATED)
### ------------------------------------

echo -e "${YELLOW}Running tests...${NC}"
sleep 2

# SIMULATE TEST RESULT (random pass/fail)
TEST_RESULT=$(( RANDOM % 2 ))

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}All tests PASSED! Proceeding with deployment.${NC}"
else
    echo -e "${RED}Tests FAILED! Rolling back...${NC}"
    rm -rf "$APP_DIR"
    cp -r "$BACKUP_DIR/app_backup_$TIMESTAMP" "$APP_DIR"
    echo -e "${GREEN}Rollback completed.${NC}"
    exit 1
fi


### ------------------------------------
### 4. DEPLOY NEW VERSION
### ------------------------------------

echo -e "${YELLOW}Deploying new version...${NC}"
sleep 2
echo -e "${GREEN}Deployment completed.${NC}"


### ------------------------------------
### 5. RESTART SERVICE
### ------------------------------------

echo -e "${YELLOW}Restarting service: $SERVICE_NAME${NC}"
sudo systemctl restart "$SERVICE_NAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}Service failed to restart! Rolling back...${NC}"
    rm -rf "$APP_DIR"
    cp -r "$BACKUP_DIR/app_backup_$TIMESTAMP" "$APP_DIR"
    sudo systemctl restart "$SERVICE_NAME"
    exit 1
fi


### ------------------------------------
### 6. VERIFY DEPLOYMENT
### ------------------------------------

echo -e "${YELLOW}Verifying deployment...${NC}"
sleep 2

SERVICE_STATUS=$(systemctl is-active "$SERVICE_NAME")

if [ "$SERVICE_STATUS" = "active" ]; then
    echo -e "${GREEN}Deployment SUCCESSFUL! Service is running.${NC}"
else
    echo -e "${RED}Verification FAILED! Rolling back...${NC}"
    rm -rf "$APP_DIR"
    cp -r "$BACKUP_DIR/app_backup_$TIMESTAMP" "$APP_DIR"
    sudo systemctl restart "$SERVICE_NAME"
fi

echo -e "${YELLOW}=== Deployment Script Completed ===${NC}"
