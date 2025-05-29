#!/bin/bash

# Exit on error
set -e

# ====================================================================
# Logging
# ====================================================================
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

BOLD_BLUE="\033[1;34m"
BOLD_GREE="\033[1;32m"

# Horizontal line
H_LINE="--------------------------------------------------------------------"
H_LIN2="===================================================================="
CYAN_H_LINE="${CYAN}${H_LINE}${RESET}"
BLUE_H_LINE="${BOLD_BLUE}${H_LINE}${RESET}"

# Progress Formatting
PROG_TEXT=$BOLD_BLUE

# --------------------------------------------------------------------
# First console output
# --------------------------------------------------------------------
echo -e "${BOLD_BLUE}$H_LIN2${RESET}"
echo -e "${BOLD_BLUE} Deploying Speech System...${RESET}"
echo -e "${BOLD_BLUE}$H_LIN2${RESET}"


# ====================================================================
# Sandbox or Deployment
# ====================================================================
# Specify if this should be for the "deployment" or "sandbox" instance
# bash deploy.sh --env=sandbox
ENV="deploy"  # default
if [[ "$1" == "--env=sandbox" ]]; then
    ENV="sandbox"
fi

# Domains & Nginx configuration files stem from there
if [ "$ENV" = "sandbox" ]; then
    # Sandbox
    DOMAIN="sandbox.cognibot.org"
    DOMAIN_WWW="www.sandbox.cognibot.org"
    NGINX_CONF="nginx/default.conf.sandbox"
    APP_ENVIRONMENT="sandbox"
    BACKEND_DOCKERFILE="Dockerfile-backend"
else
    # Deployment
    DOMAIN="cognibot.org"
    DOMAIN_WWW="www.cognibot.org"
    NGINX_CONF="nginx/default.conf"
    APP_ENVIRONMENT="deployment"
    BACKEND_DOCKERFILE="Dockerfile-backend-gpu"
fi



# Echo the environment setup
echo -e "${YELLOW}ENV                = $ENV                ${RESET}"
echo -e "${YELLOW}APP_ENVIRONMENT    = $APP_ENVIRONMENT    ${RESET}"
echo -e "${YELLOW}BACKEND_DOCKERFILE = $BACKEND_DOCKERFILE ${RESET}"

# --------------------------------------------------------------------
# Config
# --------------------------------------------------------------------
REPO_URL="https://github.com/amurphy99/v2_benchmarking.git" 
REPO_NAME="v2_benchmarking"
REPO_BRANCH="deployment"

PRJ_DIR="$HOME"
DPL_DIR="$PRJ_DIR/deployment-files"
MDL_DIR="$DPL_DIR/models"
LOG_DIR="$DPL_DIR/logs"
BIO_DIR="$REPO_NAME/backend/chat_app/websocket/biomarkers/biomarker_models"

GCS_BUCKET="gs://v2-deployment-files"

# ====================================================================
# 1) Clear old Docker stuff (optional safety)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}1. Stopping and removing any existing Docker containers...${RESET}"
echo -e "${BLUE_H_LINE}"

# Check if Docker is actually installed first
if ! command -v docker &>/dev/null; then
    echo -e "${GREEN}Docker not installed yet, nothing to clean up...${RESET}"
else
    sudo docker-compose -f "$REPO_NAME/docker-compose.yml" down || true
    echo -e "${CYAN}Pruning unused Docker resources...${RESET}"
    #sudo docker system prune -af --volumes=false || true
fi

# ====================================================================
# 2) Install system dependencies if needed (Docker, Git, Nginx, Certbot)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}2. Install system dependencies (Docker, Git, Nginx, Certbot)...${RESET}"
echo -e "${BLUE_H_LINE}"


# --------------------------------------------------------------------
# Install Docker & Git if needed
# --------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
    echo -e "${CYAN}Installing Docker (Engine + Compose V2 Plugin)...${RESET}"

    # Set up the Docker repository
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
   
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine + Compose plugin
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git
   
    # Enable Docker to run at startup
    sudo systemctl enable docker
    sudo systemctl start docker

else
    echo -e "${GREEN}Docker already installed, skipping...${RESET}"
fi


# --------------------------------------------------------------------
# Install Nginx & Certbot if needed
# --------------------------------------------------------------------
if ! command -v nginx &>/dev/null; then
    echo -e "${CYAN}Installing Nginx + Certbot...${RESET}"
    sudo apt install -y nginx certbot python3-certbot-nginx
    sudo systemctl enable nginx
else
    echo -e "${GREEN}Nginx already installed, skipping...${RESET}"
fi


# ====================================================================
# 3) Download deployment files from GCS Bucket (if not present)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}3. Downloading deployment-files/ from GCS Bucket...${RESET}"
echo -e "${BLUE_H_LINE}"

if [ ! -f "$DPL_DIR/.env" ]; then
    mkdir -p "$DPL_DIR"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/*" "$DPL_DIR/"
else
    echo -e "${GREEN}Deployment files already exist locally, skipping download${RESET}"
fi

# Make the logs folder & a wheels folder
mkdir -p "$LOG_DIR"
mkdir -p "$DPL_DIR/wheels"

# ====================================================================
# 4) Clone / Update the Repository
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}4. Clone or update the repository...${RESET}"
echo -e "${BLUE_H_LINE}"

if [ -d "$REPO_NAME" ]; then
    echo -e "${CYAN}Repo exists, pulling latest changes...${RESET}"
    cd "$REPO_NAME"
    git checkout $REPO_BRANCH
    git pull origin $REPO_BRANCH
    cd ..
else
    echo -e "${CYAN}Cloning repo...${RESET}"
    git clone -b $REPO_BRANCH $REPO_URL
fi

# ====================================================================
# 5) Copy Deployment Files (.env, models)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}5. Copy deployment files into the repository (.env, models)...${RESET}"
echo -e "${BLUE_H_LINE}"

# Copy .env into the repo
echo -e "${CYAN}Copying .env into the repo...${RESET}"
cp "$DPL_DIR/.env" "$REPO_NAME/.env"

# Copy model files into the repo
echo -e "${CYAN}Copying model files into the repo...${RESET}"
cp "$MDL_DIR/Phi-3_finetuned.gguf"             "$REPO_NAME/backend/chat_app/services/Phi-3_finetuned.gguf"
cp "$MDL_DIR/new_LSA.csv"                      "$BIO_DIR/new_LSA.csv"
cp "$MDL_DIR/stanford-parser-4.2.0-models.jar" "$BIO_DIR/stanford-parser-full-2020-11-17/stanford-parser-4.2.0-models.jar"


# ====================================================================
# 6) Configure Nginx (only replace if needed)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}6. Configure Nginx (only replace if needed)...${RESET}"
echo -e "${BLUE_H_LINE}"

# Nginx file paths (repo conf might change between deployment or testing)
NGINX_CONF_PATH="/etc/nginx/sites-available/default"
NGINX_REPO_CONF="$REPO_NAME/$NGINX_CONF"

echo -e "${YELLOW}Target Path: $NGINX_CONF_PATH${RESET}"
echo -e "${YELLOW}Source Path: $NGINX_REPO_CONF${RESET}"

# Copy/Update it if needed
if ! cmp -s "$NGINX_REPO_CONF" "$NGINX_CONF_PATH"; then
    echo -e "${CYAN}Updating Nginx config...${RESET}"
    sudo cp "$NGINX_REPO_CONF" "$NGINX_CONF_PATH"
    sudo nginx -t && sudo systemctl restart nginx
else
    echo -e "${GREEN}Nginx config unchanged, skipping restart...${RESET}"
fi

# ====================================================================
# 7) Run Certbot for HTTPS (only if cert not already issued)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}7. Running Certbot to enable HTTPS...${RESET}"
echo -e "${BLUE_H_LINE}"

# Print the target URLs
echo -e "${YELLOW}Domain:     $DOMAIN     ${RESET}"
echo -e "${YELLOW}Domain WWW: $DOMAIN_WWW ${RESET}"

# Check if Certbot was already done
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    sudo certbot --non-interactive --nginx --agree-tos \
        -d "$DOMAIN" -d "$DOMAIN_WWW" \
        -m amurphy62299@gmail.com
else
    echo -e "${GREEN}SSL certificate already exists, skipping Certbot...${RESET}"
fi



# ====================================================================
# 8) Install GPU Drivers and NVIDIA Container Toolkit (if in deployment)
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}8. Installing NVIDIA GPU drivers and Docker toolkit...${RESET}"
echo -e "${BLUE_H_LINE}"

if [ "$APP_ENVIRONMENT" = "deployment" ]; then
    # --------------------------------------------------------------------
    # Install GPU drivers if nvidia-smi not found
    # --------------------------------------------------------------------
    if ! command -v nvidia-smi &>/dev/null; then
        echo -e "${CYAN}Installing NVIDIA drivers...${RESET}"
        sudo apt update
        sudo apt install -y nvidia-driver-535 nvidia-utils-535
        echo -e "${CYAN}Reboot is recommended after this step for drivers to take effect.${RESET}"
    else
        echo -e "${GREEN}NVIDIA drivers already installed, skipping...${RESET}"
    fi

    # --------------------------------------------------------------------
    # Install NVIDIA Container Toolkit
    # --------------------------------------------------------------------
    if ! command -v nvidia-ctk &>/dev/null; then
        echo -e "${CYAN}Installing NVIDIA Container Toolkit...${RESET}"

        # Get the distribution
        #distribution="ubuntu22.04"  
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        echo -e "${YELLOW}Nvidia Distribution: $distribution ${RESET}"

        # Add the repo
        curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
            sudo tee /etc/apt/trusted.gpg.d/nvidia-container-toolkit.asc

        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        #curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/${distribution}/nvidia-container-toolkit.list | \
            #sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        #curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        #    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        # Update and install
        sudo apt update
        sudo apt install -y nvidia-container-toolkit

        # Configure runtime and restart Docker
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
    
    else
        echo -e "${GREEN}NVIDIA Container Toolkit already installed, skipping...${RESET}"
    fi

    # Test GPU access in Docker
    sudo docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi

else
    echo -e "${GREEN}In sandbox mode, skipping GPU setup... ${RESET}"
fi


# ====================================================================
# 9) Launch Docker Compose in headless mode
# ====================================================================
echo -e "\n${BLUE_H_LINE}"
echo -e "${PROG_TEXT}9. Starting Docker Compose in headless mode...${RESET}"
echo -e "${BLUE_H_LINE}"

# --------------------------------------------------------------------
# Export Environment Variables
# --------------------------------------------------------------------
# We could cd into the repo directory earlier here and save a few lines...
echo "APP_ENVIRONMENT=${APP_ENVIRONMENT}" > "$REPO_NAME/.env.deploy"
echo "BACKEND_DOCKERFILE=${BACKEND_DOCKERFILE}" >> "$REPO_NAME/.env.deploy"
ls -a "$REPO_NAME"
echo -e "\n"

# Adding "-d" to the end puts it in headless mode (sudo docker-compose up --build -d)
cd "$REPO_NAME"
export BACKEND_DOCKERFILE="$BACKEND_DOCKERFILE"
#sudo --preserve-env=BACKEND_DOCKERFILE --gpus all docker-compose up --build -d
sudo --preserve-env=BACKEND_DOCKERFILE docker compose up --build -d

# --------------------------------------------------------------------
# Done
# --------------------------------------------------------------------
echo -e "\n${GREEN}$H_LINE${RESET}"
echo -e "${GREEN} Deployment complete! Visit: https://$DOMAIN ${RESET}"
echo -e "${GREEN}$H_LINE${RESET}\n"
